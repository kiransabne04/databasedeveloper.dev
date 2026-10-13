-- Who is waiting on whom. Run during the incident.
SELECT pid,
       pg_blocking_pids(pid)                         AS blocked_by,
       state,
       wait_event_type || ':' || wait_event          AS wait,
       round(extract(epoch FROM now() - xact_start)::numeric, 1)  AS xact_age_s,
       round(extract(epoch FROM now() - state_change)::numeric, 1) AS in_state_s,
       left(regexp_replace(query, '\s+', ' ', 'g'), 60) AS query
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid()
  AND (state <> 'idle' OR wait_event_type = 'Lock')
ORDER BY xact_start NULLS LAST
LIMIT 12;

SELECT count(*) FILTER (WHERE wait_event_type = 'Lock') AS sessions_waiting_on_lock,
       max(extract(epoch FROM now() - query_start))::numeric(6,1) AS longest_wait_s
FROM pg_stat_activity
WHERE datname = current_database() AND pid <> pg_backend_pid() AND wait_event_type = 'Lock';

-- Lock modes on the table: held vs waiting.
SELECT l.pid, l.mode, l.granted, count(*) OVER (PARTITION BY l.mode, l.granted) AS sessions_in_same_state
FROM pg_locks l
WHERE l.relation = 'orders'::regclass
ORDER BY l.granted DESC, l.mode
LIMIT 5;
