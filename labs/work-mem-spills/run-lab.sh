#!/bin/bash
# Runs inside the postgres:18 container as root. Shows sorts, hash aggregates and
# hash joins spilling to temp files at the default work_mem, where the spills show
# up (EXPLAIN, server log, pg_stat_statements, pg_stat_database), and the fixes.
set -u
BIN=/usr/lib/postgresql/18/bin
W=/work
step() { printf '\n==== %s ====\n' "$1"; }

mkdir -p $W && chown postgres $W
cd $W
as_pg() { su postgres -c "cd $W && $*"; }
PSQL="$BIN/psql -h $W -p 5432 -U postgres -X -q"

as_pg "$BIN/initdb -D $W/data -U postgres >/dev/null"
cat >> $W/data/postgresql.conf <<'EOF'
unix_socket_directories = '/work'
listen_addresses = ''
shared_preload_libraries = 'pg_stat_statements'
log_temp_files = 0
max_parallel_workers_per_gather = 0
EOF
as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"

step "Version and memory settings"
as_pg "$PSQL" <<'EOF'
SELECT version();
SELECT name, setting, unit FROM pg_settings
WHERE name IN ('work_mem', 'hash_mem_multiplier', 'log_temp_files', 'max_parallel_workers_per_gather')
ORDER BY name;
EOF

step "Build orders (2,000,000 rows) and customers (500,000 rows)"
as_pg "$PSQL" <<'EOF'
CREATE EXTENSION pg_stat_statements;
CREATE TABLE customers (id int PRIMARY KEY, region text NOT NULL, name text NOT NULL);
INSERT INTO customers SELECT g, 'region-' || (g % 20), 'customer-' || g FROM generate_series(1, 500000) g;
CREATE TABLE orders (id bigint PRIMARY KEY, customer_id int NOT NULL, created_at timestamptz NOT NULL, amount numeric(10,2) NOT NULL);
INSERT INTO orders
SELECT g, 1 + (g::bigint * 7919) % 500000, timestamptz '2026-01-01' + (g % 25000000) * interval '1 second', (g::bigint * 37 % 100000) / 100.0
FROM generate_series(1, 2000000) g;
VACUUM ANALYZE customers, orders;
SELECT relname, pg_size_pretty(pg_table_size(oid)) FROM pg_class WHERE relname IN ('orders', 'customers');
SELECT pg_stat_statements_reset() IS NOT NULL AS reset;
SELECT pg_stat_reset() IS NOT NULL AS reset;
EOF

cat > $W/queries.sql <<'EOF'
\echo '--- Q1 sort'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT id, customer_id, amount FROM orders ORDER BY amount DESC, created_at;
\echo '--- Q2 hash aggregate'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT customer_id, count(*), sum(amount) FROM orders GROUP BY customer_id;
\echo '--- Q3 hash join'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT c.region, o.amount FROM orders o JOIN customers c ON c.id = o.customer_id WHERE o.amount > 10;
EOF

LOGSTART=$(wc -l < $W/server.log)
step "Default work_mem (4MB)"
as_pg "$PSQL -f $W/queries.sql"

step "Server log with log_temp_files = 0"
tail -n +$((LOGSTART+1)) $W/server.log | grep -E 'temporary file|STATEMENT' | head -8
echo "..."
echo "temp file log lines: $(tail -n +$((LOGSTART+1)) $W/server.log | grep -c 'temporary file')"

step "pg_stat_statements and pg_stat_database"
as_pg "$PSQL" <<'EOF'
SELECT left(regexp_replace(query, '\s+', ' ', 'g'), 60) AS query, calls,
       temp_blks_written, pg_size_pretty(temp_blks_written * 8192) AS temp_written,
       round(mean_exec_time::numeric, 0) AS mean_ms
FROM pg_stat_statements WHERE query LIKE 'EXPLAIN%' ORDER BY temp_blks_written DESC;
SELECT datname, temp_files, pg_size_pretty(temp_bytes) AS temp_bytes
FROM pg_stat_database WHERE datname = current_database();
EOF

step "Same queries with SET LOCAL work_mem = '256MB'"
as_pg "$PSQL" <<'EOF'
BEGIN;
SET LOCAL work_mem = '256MB';
\i /work/queries.sql
COMMIT;
EOF

step "Smallest work_mem that keeps the hash aggregate in memory"
for m in 16MB 32MB 64MB; do
  echo "--- work_mem = $m"
  as_pg "$PSQL" <<EOF | grep -E 'Batches|Memory Usage|Disk Usage|Execution Time'
SET work_mem = '$m';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT customer_id, count(*), sum(amount) FROM orders GROUP BY customer_id;
EOF
done

step "Per-role setting instead of a global change"
as_pg "$PSQL" <<'EOF'
CREATE ROLE reporting LOGIN;
ALTER ROLE reporting SET work_mem = '64MB';
SELECT rolname, rolconfig FROM pg_roles WHERE rolname = 'reporting';
EOF
as_pg "$BIN/psql -h $W -p 5432 -U reporting -d postgres -X -q -c 'SHOW work_mem'"

step "Index that removes the sort instead of feeding it more memory"
as_pg "$PSQL" <<'EOF'
CREATE INDEX orders_amount_created_idx ON orders (amount DESC, created_at);
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT id, customer_id, amount FROM orders ORDER BY amount DESC, created_at LIMIT 50;
EOF

step "Repeat timing: 5 runs each at 4MB and 256MB (Execution Time, ms)"
for q in "SELECT id, customer_id, amount FROM orders ORDER BY amount DESC, created_at" \
         "SELECT customer_id, count(*), sum(amount) FROM orders GROUP BY customer_id" \
         "SELECT c.region, o.amount FROM orders o JOIN customers c ON c.id = o.customer_id WHERE o.amount > 10"; do
  echo "--- $q"
  for m in 4MB 256MB; do
    t=""
    for i in 1 2 3 4 5; do
      t="$t $(as_pg "$PSQL -At -c \"SET work_mem = '$m'\" -c \"EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) $q\"" | grep 'Execution Time' | awk '{printf "%.0f", $3}')"
    done
    echo "work_mem $m:$t"
  done
done
