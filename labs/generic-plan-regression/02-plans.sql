PREPARE recent_open(int) AS
SELECT id, status, created_at, amount
FROM orders
WHERE tenant_id = $1 AND status = 'open'
ORDER BY created_at DESC
LIMIT 20;

\echo '=== custom plan, small tenant 1007'
SET plan_cache_mode = force_custom_plan;
EXPLAIN (ANALYZE, BUFFERS, COSTS) EXECUTE recent_open(1007);
\echo '=== custom plan, established tenant 17'
EXPLAIN (ANALYZE, BUFFERS, COSTS) EXECUTE recent_open(17);
\echo '=== generic plan, small tenant 1007'
SET plan_cache_mode = force_generic_plan;
EXPLAIN (ANALYZE, BUFFERS, COSTS) EXECUTE recent_open(1007);
\echo '=== generic plan, established tenant 17'
EXPLAIN (ANALYZE, BUFFERS, COSTS) EXECUTE recent_open(17);
