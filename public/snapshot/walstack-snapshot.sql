-- =====================================================================
-- WalStack PostgreSQL Snapshot (v1.1)
-- https://walstack.io/snapshot
--
-- Reads PostgreSQL statistics and catalog views into a plain-text report.
-- It does not write data, change persistent settings, create objects,
-- execute application queries, run EXPLAIN, or read application rows.
-- Statements have a 10-second timeout and a 1-second lock timeout.
--
--   psql -X -h <host> -p 5432 -U <user> -d <database> \
--        -f walstack-snapshot.sql -o walstack-snapshot-1.txt
--
-- If possible, run twice about an hour apart during a busy period.
-- Save the second run as walstack-snapshot-2.txt. Compare the change in
-- counters, accounting for resets, rather than relying on totals alone.
--
-- Review and redact each file before sending it to walstack.io/snapshot.
-- Run on PostgreSQL 13 or newer with a login that can connect to the
-- application database and has the built-in pg_monitor role.
--   On RDS/Aurora, an administrator can run: GRANT pg_monitor TO <user>;
--
-- show_query_text off omits query text. PostgreSQL usually normalizes
-- literals to $1, $2, etc., but some captured text can contain literals.
-- show_schema off omits the column listing. Index and foreign key
-- definitions and other names may still expose schema details.
--
-- Optional sections depend on your version, extensions, and permissions.
-- If a statement times out on a lock, the script continues to the next
-- statement. Review terminal errors as well as the snapshot output.
-- =====================================================================

\set show_query_text on
\set show_schema on

\set QUIET on
\set ON_ERROR_STOP on
\pset pager off
\pset footer off
\timing off

-- These settings apply only to this psql connection.
SET default_transaction_read_only = on;
SET statement_timeout = '10s';
SET lock_timeout = '1s';
SET search_path = pg_catalog, pg_temp;

SELECT EXISTS (
         SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'
       ) AS has_pgss,
       coalesce((
         SELECT n.nspname
         FROM pg_extension e
         JOIN pg_namespace n ON n.oid = e.extnamespace
         WHERE e.extname = 'pg_stat_statements'
       ), 'pg_catalog') AS pgss_schema,
       current_setting('server_version_num')::int >= 170000 AS pg17
\gset
SELECT to_regclass(format('%I.pg_stat_statements_info', :'pgss_schema')) IS NOT NULL AS has_pgss_info
\gset
\set ON_ERROR_STOP off

\qecho 'WalStack PostgreSQL Snapshot v1.1'

\qecho
\qecho '=== 1. Server and version ==='
SELECT version() AS version,
       current_setting('server_version_num') AS version_num,
       pg_postmaster_start_time() AS server_started,
       now() AS snapshot_taken,
       pg_is_in_recovery() AS is_replica,
       current_database() AS database;

\qecho
\qecho '=== 2. Key settings ==='
SELECT name, setting, unit, source
FROM pg_settings
WHERE name IN (
  'shared_buffers','effective_cache_size','work_mem','maintenance_work_mem',
  'max_connections','random_page_cost','effective_io_concurrency',
  'default_statistics_target','jit','track_io_timing',
  'autovacuum','autovacuum_max_workers','autovacuum_naptime',
  'autovacuum_vacuum_scale_factor','autovacuum_analyze_scale_factor',
  'autovacuum_vacuum_cost_limit','statement_timeout',
  'idle_in_transaction_session_timeout','shared_preload_libraries',
  'pg_stat_statements.max','pg_stat_statements.track',
  'auto_explain.log_min_duration','max_parallel_workers_per_gather',
  'plan_cache_mode','checkpoint_timeout','max_wal_size')
ORDER BY name;

\qecho
\qecho '=== 3. Installed extensions ==='
SELECT extname, extversion FROM pg_extension ORDER BY extname;

\qecho
\qecho '=== 4. Database sizes and cache hit ratio ==='
SELECT datname,
       pg_size_pretty(pg_database_size(datname)) AS size,
       numbackends AS connections,
       round(100.0 * blks_hit / nullif(blks_hit + blks_read, 0), 2) AS cache_hit_pct,
       xact_commit, xact_rollback, deadlocks, temp_files,
       pg_size_pretty(temp_bytes) AS temp_written,
       stats_reset
FROM pg_stat_database
WHERE datname IS NOT NULL AND datname NOT IN ('template0','template1','rdsadmin')
ORDER BY pg_database_size(datname) DESC;

\qecho
\qecho '=== 5. pg_stat_statements status (resets and evictions) ==='
\if :has_pgss_info
SELECT dealloc AS statements_evicted, stats_reset FROM :"pgss_schema".pg_stat_statements_info;
\else
\qecho '(unavailable with this extension setup)'
\endif

\if :has_pgss
\qecho
\qecho '=== 6. Top 50 queries by total execution time (cumulative since reset) ==='
SELECT queryid,
       calls,
       round(total_exec_time::numeric / 1000, 1) AS total_sec,
       round(mean_exec_time::numeric, 2) AS mean_ms,
       round((100 * total_exec_time / nullif(sum(total_exec_time) OVER (), 0))::numeric, 1) AS pct_of_total,
       rows,
       shared_blks_hit, shared_blks_read, temp_blks_written
\if :show_query_text
       , left(regexp_replace(query, '\s+', ' ', 'g'), 300) AS query
\endif
FROM :"pgss_schema".pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY total_exec_time DESC
LIMIT 50;

\qecho
\qecho '=== 7. Top 10 queries by mean time (called at least 50 times) ==='
SELECT queryid, calls,
       round(mean_exec_time::numeric, 2) AS mean_ms,
       round(max_exec_time::numeric, 2) AS max_ms,
       round(stddev_exec_time::numeric, 2) AS stddev_ms
\if :show_query_text
       , left(regexp_replace(query, '\s+', ' ', 'g'), 300) AS query
\endif
FROM :"pgss_schema".pg_stat_statements
WHERE calls >= 50
  AND dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY mean_exec_time DESC
LIMIT 10;
\else
\qecho '=== 6–7. Query timings unavailable (pg_stat_statements is not installed in this database) ==='
\endif

\qecho
\qecho '=== 8. Largest 20 tables: size, rows, dead rows, vacuum/analyze ==='
SELECT s.schemaname || '.' || s.relname AS table_name,
       pg_size_pretty(pg_total_relation_size(s.relid)) AS total_size,
       pg_size_pretty(pg_relation_size(s.relid)) AS table_size,
       pg_size_pretty(pg_indexes_size(s.relid)) AS indexes_size,
       s.n_live_tup, s.n_dead_tup,
       round(100.0 * s.n_dead_tup / nullif(s.n_live_tup + s.n_dead_tup, 0), 1) AS dead_pct,
       s.n_tup_ins, s.n_tup_upd, s.n_tup_hot_upd, s.n_tup_del,
       s.seq_scan, s.idx_scan, s.n_mod_since_analyze,
       greatest(s.last_vacuum, s.last_autovacuum) AS last_vacuum,
       greatest(s.last_analyze, s.last_autoanalyze) AS last_analyze
FROM pg_stat_user_tables s
ORDER BY pg_total_relation_size(s.relid) DESC
LIMIT 20;

\qecho
\qecho '=== 9. Index definitions on the 20 largest tables (schema only, no data) ==='
WITH t AS (
  SELECT relid FROM pg_stat_user_tables
  ORDER BY pg_total_relation_size(relid) DESC LIMIT 20
)
SELECT s.schemaname || '.' || s.relname AS table_name,
       s.indexrelname AS index_name,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan,
       i.indisvalid AS is_valid,
       pg_get_indexdef(s.indexrelid) AS definition
FROM pg_stat_user_indexes s
JOIN t ON t.relid = s.relid
JOIN pg_index i ON i.indexrelid = s.indexrelid
ORDER BY pg_total_relation_size(s.relid) DESC, s.indexrelname;

\qecho
\qecho '=== 10. Column names and types of the 10 largest tables (no data) ==='
\if :show_schema
WITH t AS (
  SELECT relid FROM pg_stat_user_tables
  ORDER BY pg_total_relation_size(relid) DESC LIMIT 10
)
SELECT a.attrelid::regclass AS table_name,
       a.attnum AS pos,
       a.attname AS column_name,
       format_type(a.atttypid, a.atttypmod) AS data_type,
       a.attnotnull AS not_null
FROM pg_attribute a
JOIN t ON t.relid = a.attrelid
WHERE a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attrelid::regclass::text, a.attnum;
\else
\qecho '(skipped: show_schema is off)'
\endif

\qecho
\qecho '=== 11. Tables read mostly by sequential scans (over 10k rows) ==='
SELECT schemaname || '.' || relname AS table_name,
       seq_scan, seq_tup_read, idx_scan, n_live_tup,
       round(seq_tup_read::numeric / nullif(seq_scan, 0)) AS avg_rows_per_seq_scan
FROM pg_stat_user_tables
WHERE n_live_tup > 10000 AND seq_scan > coalesce(idx_scan, 0)
ORDER BY seq_tup_read DESC
LIMIT 15;

\qecho
\qecho '=== 12. Tables with the most block reads outside shared buffers ==='
SELECT schemaname || '.' || relname AS table_name,
       heap_blks_read, heap_blks_hit,
       round(100.0 * heap_blks_hit / nullif(heap_blks_hit + heap_blks_read, 0), 1) AS heap_hit_pct,
       idx_blks_read, idx_blks_hit,
       toast_blks_read
FROM pg_statio_user_tables
ORDER BY coalesce(heap_blks_read, 0) + coalesce(idx_blks_read, 0) DESC
LIMIT 15;

\qecho
\qecho '=== 13. Foreign keys to check for a supporting B-tree index ==='
SELECT c.conrelid::regclass AS table_name,
       c.conname AS constraint_name,
       pg_get_constraintdef(c.oid) AS definition,
       pg_size_pretty(pg_relation_size(c.conrelid)) AS table_size
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE c.contype = 'f'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    JOIN pg_class ix ON ix.oid = i.indexrelid
    JOIN pg_am am ON am.oid = ix.relam
    WHERE i.indrelid = c.conrelid
      AND am.amname = 'btree'
      AND i.indisvalid AND i.indisready AND i.indislive
      AND i.indpred IS NULL
      AND i.indnkeyatts >= cardinality(c.conkey)
      AND (string_to_array(i.indkey::text, ' ')::int2[])[1:cardinality(c.conkey)] @> c.conkey
  )
ORDER BY pg_relation_size(c.conrelid) DESC
LIMIT 30;

\qecho
\qecho '=== 14. Indexes with zero recorded scans (excluding unique/PK) ==='
SELECT s.schemaname || '.' || s.relname AS table_name,
       s.indexrelname AS index_name,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan
FROM pg_stat_user_indexes s
JOIN pg_index i ON i.indexrelid = s.indexrelid
WHERE s.idx_scan = 0 AND NOT i.indisunique AND NOT i.indisprimary
ORDER BY pg_relation_size(s.indexrelid) DESC
LIMIT 20;

\qecho
\qecho '=== 15. Connections by state and wait type (right now) ==='
SELECT coalesce(state, 'background') AS state,
       coalesce(wait_event_type, '-') AS wait_type,
       coalesce(wait_event, '-') AS wait_event,
       count(*) AS sessions
FROM pg_stat_activity
GROUP BY 1, 2, 3
ORDER BY sessions DESC
LIMIT 25;

\qecho
\qecho '=== 16. Sessions blocked by other sessions (right now; no query text) ==='
SELECT a.pid, b.blocked_by,
       a.wait_event_type, a.wait_event, a.state,
       now() - a.query_start AS query_age
FROM pg_stat_activity a
CROSS JOIN LATERAL (SELECT pg_blocking_pids(a.pid) AS blocked_by OFFSET 0) b
WHERE a.wait_event_type = 'Lock' AND cardinality(b.blocked_by) > 0
ORDER BY a.query_start
LIMIT 20;

\qecho
\qecho '=== 17. Oldest open transactions (no query text) ==='
SELECT pid, usename, application_name, state,
       now() - xact_start AS xact_age,
       now() - state_change AS in_state_for,
       wait_event_type, wait_event
FROM pg_stat_activity
WHERE xact_start IS NOT NULL AND pid <> pg_backend_pid()
ORDER BY xact_start
LIMIT 10;

\qecho
\qecho '=== 18. Transaction ID age (wraparound headroom) ==='
SELECT datname, age(datfrozenxid) AS xid_age,
       round(100.0 * age(datfrozenxid) / 2000000000, 1) AS pct_to_wraparound
FROM pg_database
WHERE datallowconn
ORDER BY xid_age DESC;

\qecho
\qecho '=== 19. Replication (from a primary) ==='
SELECT application_name, state, sync_state,
       write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

\qecho
\qecho '=== 20. Replication slots ==='
SELECT slot_name, slot_type, active,
       pg_size_pretty(pg_wal_lsn_diff(
         CASE WHEN pg_is_in_recovery()
           THEN greatest(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn())
           ELSE pg_current_wal_lsn()
         END,
         restart_lsn
       )) AS wal_retained
FROM pg_replication_slots;

\qecho
\qecho '=== 21. Checkpoints and background writer ==='
\if :pg17
SELECT * FROM pg_stat_checkpointer;
\endif
SELECT * FROM pg_stat_bgwriter;

\qecho
\qecho '=== End of WalStack snapshot. Nothing was changed. ==='
