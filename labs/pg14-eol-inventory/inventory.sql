-- PostgreSQL 14 EOL inventory. Read-only. Run in each database you plan to upgrade.
-- Check 6 reads pg_authid, which needs a superuser: it fails on RDS, Aurora and Azure.
\echo '== 1. Server version'
SELECT current_setting('server_version') AS server_version,
       current_setting('server_version_num')::int AS server_version_num,
       current_setting('server_version_num')::int / 10000 AS major;

\echo '== 2. Installed extensions in this database'
SELECT e.extname, e.extversion,
       a.default_version AS packaged_default
FROM pg_extension e
LEFT JOIN pg_available_extensions a ON a.name = e.extname
ORDER BY e.extname;

\echo '== 3. Logical replication slots (CDC, Debezium, DMS, subscriptions)'
SELECT slot_name, plugin, database, active,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind
FROM pg_replication_slots
WHERE slot_type = 'logical';

\echo '== 4. Settings changed from default that later versions removed'
SELECT name, setting, source
FROM pg_settings
WHERE name IN ('vacuum_defer_cleanup_age', 'promote_trigger_file',
               'old_snapshot_threshold', 'db_user_namespace',
               'force_parallel_mode', 'stats_temp_directory')
  AND source NOT IN ('default', 'override');

\echo '== 5. Functions in languages or calls removed after 14'
SELECT n.nspname, p.proname, l.lanname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
JOIN pg_language l ON l.oid = p.prolang
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND (l.lanname IN ('plpython2u', 'plpythonu')
       OR p.prosrc ~* '\m(pg_start_backup|pg_stop_backup)\M');

\echo '== 6. Roles with MD5 password hashes (deprecated in PostgreSQL 18)'
SELECT rolname FROM pg_authid WHERE rolpassword LIKE 'md5%';

\echo '== 7. Database sizes'
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database WHERE datallowconn ORDER BY pg_database_size(datname) DESC;
