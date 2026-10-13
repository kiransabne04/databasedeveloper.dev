-- DatabaseDeveloper PostgreSQL evidence collector, v1
-- https://databasedeveloper.dev/evidence-collection
--
-- Read-only. Runs catalog and statistics queries only; it changes no data or settings
-- outside this session. Supports PostgreSQL 13 and later, including Amazon RDS and Aurora.
--
-- Run as a role with pg_monitor (on RDS/Aurora, the master user can GRANT pg_monitor),
-- connected to the application database:
--
--   psql "host=... dbname=... user=..." -X -f pg-evidence-collector.sql -o evidence.txt
--
-- Review evidence.txt before sending it. Statement text from pg_stat_statements is
-- normalized (literal values replaced by $1, $2, ...), but table and column names remain.
-- Section 9 includes truncated text of currently running queries; delete it if needed.

\set ON_ERROR_STOP off
\set QUIET on
\pset pager off
\pset footer on
SET default_transaction_read_only = on;
SET statement_timeout = '30s';
SET lock_timeout = '1s';
SET application_name = 'dd-evidence-collector';

SELECT current_setting('server_version_num')::int >= 140000 AS pg14,
       current_setting('server_version_num')::int >= 170000 AS pg17,
       EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') AS has_pgss
\gset

\qecho '== 1. Server'
SELECT version(),
       now()                               AS collected_at,
       pg_postmaster_start_time()          AS started_at,
       current_database()                  AS database,
       pg_size_pretty(pg_database_size(current_database())) AS database_size,
       (SELECT stats_reset FROM pg_stat_database WHERE datname = current_database()) AS db_stats_reset;

\qecho '== 2. Non-default settings'
SELECT name, setting, unit, source
FROM pg_settings
WHERE source NOT IN ('default', 'override', 'client')
ORDER BY name;

\qecho '== 3. Extensions'
SELECT extname, extversion FROM pg_extension ORDER BY extname;

\qecho '== 4. Database activity'
SELECT numbackends, xact_commit, xact_rollback,
       blks_hit, blks_read,
       round(100.0 * blks_hit / nullif(blks_hit + blks_read, 0), 2) AS cache_hit_pct,
       temp_files, pg_size_pretty(temp_bytes) AS temp_bytes,
       deadlocks, conflicts
FROM pg_stat_database
WHERE datname = current_database();

\qecho '== 5. Top statements by total execution time (pg_stat_statements)'
\if :has_pgss
SELECT queryid,
       calls,
       round(total_exec_time::numeric / 1000, 1)                         AS total_s,
       round(mean_exec_time::numeric, 2)                                 AS mean_ms,
       round(stddev_exec_time::numeric, 2)                               AS stddev_ms,
       round(max_exec_time::numeric, 2)                                  AS max_ms,
       round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 1) AS pct_total,
       rows,
       shared_blks_hit, shared_blks_read, temp_blks_written,
       left(regexp_replace(query, '\s+', ' ', 'g'), 300)                 AS query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY total_exec_time DESC
LIMIT 50;
\if :pg14
SELECT * FROM pg_stat_statements_info;
\endif
\else
\qecho 'pg_stat_statements is not installed in this database. That is useful to know; no action needed for this collection.'
\endif

\qecho '== 6. Largest tables: size, scans, vacuum and analyze'
SELECT s.relname,
       pg_size_pretty(pg_total_relation_size(s.relid)) AS total_size,
       pg_size_pretty(pg_relation_size(s.relid))       AS heap_size,
       s.n_live_tup, s.n_dead_tup, s.n_mod_since_analyze,
       s.seq_scan, s.seq_tup_read, s.idx_scan,
       s.n_tup_ins, s.n_tup_upd, s.n_tup_hot_upd, s.n_tup_del,
       s.last_autovacuum, s.last_autoanalyze, s.last_vacuum, s.last_analyze,
       c.reloptions
FROM pg_stat_user_tables s
JOIN pg_class c ON c.oid = s.relid
ORDER BY pg_total_relation_size(s.relid) DESC
LIMIT 40;

\qecho '== 7. Indexes: size and usage'
SELECT s.relname AS table_name,
       s.indexrelname AS index_name,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan,
       i.indisunique, i.indisprimary, i.indisvalid,
       pg_get_indexdef(s.indexrelid) AS definition
FROM pg_stat_user_indexes s
JOIN pg_index i ON i.indexrelid = s.indexrelid
ORDER BY pg_relation_size(s.indexrelid) DESC
LIMIT 80;

\qecho '== 8. Connections by user, application and state'
SELECT usename, application_name, state,
       count(*) AS sessions,
       max(now() - state_change) AS longest_in_state,
       max(now() - xact_start)   AS oldest_xact
FROM pg_stat_activity
WHERE backend_type = 'client backend'
GROUP BY 1, 2, 3
ORDER BY sessions DESC;

\qecho '== 9. Current waits and blocking (snapshot)'
SELECT pid,
       pg_blocking_pids(pid) AS blocked_by,
       usename, application_name, state,
       wait_event_type, wait_event,
       now() - xact_start  AS xact_age,
       now() - query_start AS query_age,
       left(regexp_replace(query, '\s+', ' ', 'g'), 120) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend'
  AND pid <> pg_backend_pid()
  AND (state <> 'idle' OR wait_event_type = 'Lock')
ORDER BY xact_start NULLS LAST
LIMIT 50;

\qecho '== 10. Transaction ID age (wraparound headroom)'
SELECT datname, age(datfrozenxid) AS xid_age,
       round(100.0 * age(datfrozenxid) / 2147483647, 1) AS pct_of_limit
FROM pg_database
ORDER BY xid_age DESC;

\qecho '== 11. Checkpoints and background writer'
\if :pg17
SELECT * FROM pg_stat_checkpointer;
SELECT * FROM pg_stat_bgwriter;
\else
SELECT * FROM pg_stat_bgwriter;
\endif

\qecho '== 12. Replication and slots'
SELECT application_name, state, sync_state,
       write_lag, flush_lag, replay_lag
FROM pg_stat_replication;
SELECT slot_name, slot_type, active,
       CASE WHEN pg_is_in_recovery() THEN NULL
            ELSE pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) END AS retained_wal
FROM pg_replication_slots;

\qecho '== 13. Vacuum in progress'
SELECT p.pid, p.relid::regclass AS table_name, p.phase,
       p.heap_blks_total, p.heap_blks_scanned,
       now() - a.xact_start AS running_for
FROM pg_stat_progress_vacuum p
JOIN pg_stat_activity a USING (pid);

\qecho '== Done. Review this file before sending it.'
