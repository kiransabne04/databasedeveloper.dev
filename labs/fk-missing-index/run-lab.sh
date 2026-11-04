#!/bin/bash
# Runs inside the postgres:18 container as root. Shows a DELETE on a parent table
# that is slow because the referencing column on the child table has no index:
# where the time shows up (EXPLAIN trigger lines, pg_stat_user_tables,
# pg_stat_statements with track = top and all, auto_explain), a catalog query that
# finds unindexed foreign keys, and the fix.
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
shared_preload_libraries = 'pg_stat_statements,auto_explain'
max_parallel_workers_per_gather = 0
auto_explain.log_min_duration = '50ms'
auto_explain.log_nested_statements = off
EOF
as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"

step "Version"
as_pg "$PSQL -At -c 'SELECT version()'"

step "Build customers (100,000), orders (2,000,000), order_items (4,000,000)"
as_pg "$PSQL" <<'EOF'
CREATE EXTENSION pg_stat_statements;
CREATE TABLE customers (id int PRIMARY KEY, name text NOT NULL);
INSERT INTO customers SELECT g, 'customer-' || g FROM generate_series(1, 100000) g;
CREATE TABLE orders (
  id bigint PRIMARY KEY,
  customer_id int NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL,
  amount numeric(10,2) NOT NULL);
INSERT INTO orders
SELECT g, 1 + (g::bigint * 7919) % 100000, timestamptz '2026-01-01' + g * interval '10 seconds', (g % 10000) / 100.0
FROM generate_series(1, 2000000) g;
CREATE TABLE order_items (
  id bigint PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  sku text NOT NULL, qty int NOT NULL);
INSERT INTO order_items SELECT g, 1 + (g - 1) / 2, 'sku-' || (g % 500), 1 + g % 3 FROM generate_series(1, 4000000) g;
CREATE TABLE audit_notes (
  id bigint PRIMARY KEY,
  created_at timestamptz NOT NULL,
  customer_id int NOT NULL REFERENCES customers (id),
  note text);
INSERT INTO audit_notes SELECT g, timestamptz '2026-01-01' + g * interval '1 minute', 90001 + g % 10000, 'n' FROM generate_series(1, 500000) g;
CREATE INDEX audit_notes_created_customer_idx ON audit_notes (created_at, customer_id);
VACUUM ANALYZE;
SELECT relname, pg_size_pretty(pg_table_size(oid)) AS size FROM pg_class
WHERE relname IN ('customers','orders','order_items','audit_notes') ORDER BY relname;
EOF

step "Find foreign keys with no index whose leading columns match"
cat > $W/unindexed.sql <<'EOF'
SELECT c.conrelid::regclass AS child_table,
       c.conname AS constraint_name,
       c.confrelid::regclass AS parent_table,
       array_agg(a.attname ORDER BY k.n) AS fk_columns,
       pg_size_pretty(pg_relation_size(c.conrelid)) AS child_size
FROM pg_constraint c
CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS k(attnum, n)
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = k.attnum
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid
      AND i.indpred IS NULL
      AND (i.indkey::int2[])[0:cardinality(c.conkey) - 1] @> c.conkey
      AND (i.indkey::int2[])[0:cardinality(c.conkey) - 1] <@ c.conkey)
GROUP BY c.conrelid, c.conname, c.confrelid
ORDER BY pg_relation_size(c.conrelid) DESC;
EOF
as_pg "$PSQL -f $W/unindexed.sql"

as_pg "$PSQL -c 'SELECT pg_stat_statements_reset() IS NOT NULL AS r' -c 'SELECT pg_stat_reset() IS NOT NULL AS r'" >/dev/null

step "Delete one customer with no index on orders.customer_id or order_items.order_id"
as_pg "$PSQL" <<'EOF'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM customers WHERE id = 42;
ROLLBACK;
EOF

step "Delete 10 customers (one batch of offboarding)"
as_pg "$PSQL" <<'EOF'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM customers WHERE id BETWEEN 1001 AND 1010;
ROLLBACK;
EOF

step "Delete one customer that has no orders and no audit notes"
as_pg "$PSQL" <<'EOF'
INSERT INTO customers VALUES (100001, 'no-orders');
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM customers WHERE id = 100001;
ROLLBACK;
EOF

step "Sequential scan counters on the child tables"
as_pg "$PSQL" <<'EOF'
SELECT pg_stat_force_next_flush();
SELECT relname, seq_scan, seq_tup_read, idx_scan FROM pg_stat_user_tables
WHERE relname IN ('orders','order_items','audit_notes') ORDER BY relname;
EOF

step "pg_stat_statements with default track = top"
as_pg "$PSQL" <<'EOF'
SELECT left(regexp_replace(query, '\s+', ' ', 'g'), 70) AS query, calls, round(total_exec_time::numeric) AS total_ms
FROM pg_stat_statements WHERE query ILIKE '%delete%' OR query ILIKE '%FOR KEY SHARE%' ORDER BY total_exec_time DESC LIMIT 6;
EOF

step "Same delete with pg_stat_statements.track = all"
as_pg "$PSQL" <<'EOF'
SELECT pg_stat_statements_reset() IS NOT NULL AS r \gset
SET pg_stat_statements.track = 'all';
BEGIN;
DELETE FROM customers WHERE id = 43;
ROLLBACK;
SELECT left(regexp_replace(query, '\s+', ' ', 'g'), 90) AS query, calls, round(total_exec_time::numeric) AS total_ms
FROM pg_stat_statements WHERE query NOT ILIKE '%pg_stat_statements%' ORDER BY total_exec_time DESC LIMIT 6;
EOF

step "auto_explain with log_nested_statements = on"
LOGSTART=$(wc -l < $W/server.log)
as_pg "$PSQL" <<'EOF'
SET auto_explain.log_nested_statements = on;
SET auto_explain.log_analyze = on;
BEGIN;
DELETE FROM customers WHERE id = 44;
ROLLBACK;
EOF
sleep 1
tail -n +$((LOGSTART+1)) $W/server.log | grep -vE '^\s*$' | head -40

step "Lock held while the slow delete runs"
as_pg "$PSQL" <<'EOF' &
BEGIN;
DELETE FROM customers WHERE id BETWEEN 2001 AND 2010;
SELECT pg_sleep(3);
ROLLBACK;
EOF
sleep 1.5
as_pg "$PSQL" <<'EOF'
SELECT l.relation::regclass AS rel, l.mode, l.granted
FROM pg_locks l JOIN pg_stat_activity a ON a.pid = l.pid
WHERE l.locktype = 'relation' AND a.query LIKE 'DELETE FROM customers%' AND l.relation::regclass::text NOT LIKE 'pg_%'
ORDER BY 1, 2;
EOF
wait

step "Index the referencing columns"
as_pg "$PSQL" <<'EOF'
\timing on
CREATE INDEX CONCURRENTLY orders_customer_id_idx ON orders (customer_id);
CREATE INDEX CONCURRENTLY order_items_order_id_idx ON order_items (order_id);
CREATE INDEX CONCURRENTLY audit_notes_customer_id_idx ON audit_notes (customer_id);
\timing off
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indexrelid::regclass::text LIKE '%_id_idx' ORDER BY 1;
EOF

step "Unindexed foreign keys after the fix"
as_pg "$PSQL -f $W/unindexed.sql"

step "Delete one customer after the fix"
as_pg "$PSQL" <<'EOF'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM customers WHERE id = 42;
ROLLBACK;
EOF

step "Delete 10 customers after the fix"
as_pg "$PSQL" <<'EOF'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM customers WHERE id BETWEEN 1001 AND 1010;
ROLLBACK;
EOF

step "Delete the customer with no orders and no audit notes after the fix"
as_pg "$PSQL" <<'EOF'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM customers WHERE id = 100001;
ROLLBACK;
EOF

step "Repeat timing: 5 runs of deleting one customer, before and after (ms)"
run5() {
  t=""
  for i in 1 2 3 4 5; do
    id=$((5000 + i))
    t="$t $(as_pg "$PSQL -At" <<EOF | grep 'Execution Time' | awk '{printf "%.1f", $3}'
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF) DELETE FROM customers WHERE id = $id;
ROLLBACK;
EOF
)"
  done
  echo "$1:$t"
}
run5 "with indexes"
as_pg "$PSQL -c 'DROP INDEX orders_customer_id_idx, order_items_order_id_idx, audit_notes_customer_id_idx'"
run5 "without indexes"
