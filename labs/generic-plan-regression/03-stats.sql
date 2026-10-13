SELECT calls,
       round(mean_exec_time::numeric, 2)   AS mean_ms,
       round(stddev_exec_time::numeric, 2) AS stddev_ms,
       round(min_exec_time::numeric, 2)    AS min_ms,
       round(max_exec_time::numeric, 2)    AS max_ms,
       round(total_exec_time::numeric, 0)  AS total_ms
FROM pg_stat_statements
WHERE query LIKE '%FROM orders%ORDER BY created_at DESC%'
  AND query NOT LIKE '%pg_stat_statements%';
