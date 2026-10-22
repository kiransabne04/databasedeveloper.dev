#!/bin/bash
# Runs inside the postgres:18 container as root. Shows an idle-in-transaction
# session stopping autovacuum from removing dead rows, how to find it, and what
# VACUUM does and does not give back afterwards.
set -u
BIN=/usr/lib/postgresql/18/bin
W=/work
step() { printf '\n==== %s ====\n' "$1"; }

mkdir -p $W && chown postgres $W
cd $W
as_pg() { su postgres -c "cd $W && $*"; }
PSQL="$BIN/psql -h $W -p 5432 -U postgres -X -q"
sql() { as_pg "$PSQL -c \"$1\""; }

as_pg "$BIN/initdb -D $W/data -U postgres >/dev/null"
cat >> $W/data/postgresql.conf <<'EOF'
unix_socket_directories = '/work'
listen_addresses = ''
autovacuum_naptime = 5s
log_autovacuum_min_duration = 0
shared_preload_libraries = 'pg_stat_statements'
EOF
as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"

step "Version and autovacuum settings"
as_pg "$PSQL -c 'SELECT version()'" | head -3
as_pg "$PSQL" <<'EOF'
SELECT name, setting FROM pg_settings
WHERE name IN ('autovacuum_vacuum_threshold', 'autovacuum_vacuum_scale_factor',
               'autovacuum_vacuum_max_threshold', 'autovacuum_naptime', 'autovacuum_vacuum_cost_limit')
ORDER BY name;
EOF

step "Build accounts: 200,000 rows"
as_pg "$PSQL" <<'EOF'
CREATE EXTENSION pgstattuple;
CREATE TABLE accounts (id int PRIMARY KEY, balance int NOT NULL, note text NOT NULL);
INSERT INTO accounts SELECT g, 0, repeat('x', 100) FROM generate_series(1, 200000) g;
VACUUM ANALYZE accounts;
SELECT pg_size_pretty(pg_table_size('accounts')) AS table_size;
EOF

step "Autovacuum trigger point for this table"
as_pg "$PSQL" <<'EOF'
SELECT c.relname, c.reltuples::bigint,
       least(current_setting('autovacuum_vacuum_threshold')::int
             + current_setting('autovacuum_vacuum_scale_factor')::float8 * c.reltuples,
             current_setting('autovacuum_vacuum_max_threshold')::float8)::bigint AS dead_rows_to_trigger
FROM pg_class c WHERE c.relname = 'accounts';
EOF

step "Open a session that reads, then sits idle in transaction"
( echo "SET application_name = 'report-export'; BEGIN ISOLATION LEVEL REPEATABLE READ; SELECT count(*) FROM accounts;"; sleep 600 ) \
  | su postgres -c "$PSQL" >/dev/null 2>&1 &
sleep 2

step "Update every row three times"
for i in 1 2 3; do sql "UPDATE accounts SET balance = balance + 1"; done
sleep 20

step "pg_stat_user_tables after autovacuum has run"
as_pg "$PSQL" <<'EOF'
SELECT relname, n_live_tup, n_dead_tup, autovacuum_count, last_autovacuum IS NOT NULL AS autovacuumed,
       pg_size_pretty(pg_table_size(relid)) AS table_size
FROM pg_stat_user_tables WHERE relname = 'accounts';
EOF

step "Autovacuum log lines for accounts"
grep -A12 'automatic vacuum of table "postgres.public.accounts"' $W/server.log | tail -13

step "Manual VACUUM VERBOSE while the session is still open"
sql "VACUUM (VERBOSE) accounts" 2>&1 | grep -E 'tuples:|removable cutoff|pages:' | head -3

step "Find what holds the xmin horizon"
as_pg "$PSQL" <<'EOF'
SELECT pid, application_name, state, age(backend_xmin) AS xmin_age,
       now() - xact_start AS xact_open_for, left(query, 40) AS last_query
FROM pg_stat_activity
WHERE backend_xmin IS NOT NULL
ORDER BY age(backend_xmin) DESC;

SELECT gid, age(transaction) AS xmin_age FROM pg_prepared_xacts;
SELECT slot_name, slot_type, age(xmin) AS xmin_age, age(catalog_xmin) AS catalog_xmin_age
FROM pg_replication_slots;
EOF

step "End the blocking session"
sql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'report-export'" >/dev/null
sleep 12
echo "--- next autovacuum of accounts"
grep -A4 'automatic vacuum of table "postgres.public.accounts"' $W/server.log | tail -4
as_pg "$PSQL" <<'EOF'
SELECT n_live_tup, n_dead_tup, pg_size_pretty(pg_table_size('accounts')) AS table_size
FROM pg_stat_user_tables WHERE relname = 'accounts';
SELECT tuple_count, dead_tuple_count, round(free_percent::numeric, 1) AS free_percent
FROM pgstattuple('accounts');
EOF

step "Three more full updates now reuse the free space"
for i in 1 2 3; do sql "UPDATE accounts SET balance = balance + 1"; sql "VACUUM accounts"; done
sql "SELECT pg_size_pretty(pg_table_size('accounts')) AS table_size"

step "VACUUM FULL returns the space (ACCESS EXCLUSIVE lock for the duration)"
as_pg "$PSQL" <<'EOF'
\timing on
VACUUM FULL accounts;
\timing off
SELECT pg_size_pretty(pg_table_size('accounts')) AS table_size;
EOF

step "Per-table autovacuum settings for a large table"
as_pg "$PSQL" <<'EOF'
ALTER TABLE accounts SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
SELECT relname, reloptions FROM pg_class WHERE relname = 'accounts';
EOF
