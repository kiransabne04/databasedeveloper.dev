#!/bin/bash
# Runs inside the postgres:18 container as root. Installs PostgreSQL 14 binaries,
# builds a PG14 cluster with common upgrade blockers, then runs pg_upgrade to 18.
set -u
OLD=/usr/lib/postgresql/14/bin
NEW=/usr/lib/postgresql/18/bin
W=/work
step() { printf '\n==== %s ====\n' "$1"; }

apt-get update -qq >/dev/null && apt-get install -y -qq postgresql-14 >/dev/null 2>&1
mkdir -p $W && chown postgres $W
cd $W
as_pg() { su postgres -c "cd $W && $*"; }

step "Versions"
as_pg "$OLD/postgres --version; $NEW/postgres --version"

step "Build PG14 cluster (initdb defaults)"
as_pg "$OLD/initdb -D $W/old14 -U postgres >/dev/null"
cat >> $W/old14/postgresql.conf <<'EOF'
port = 5414
wal_level = logical
max_prepared_transactions = 5
unix_socket_directories = '/work'
EOF
as_pg "$OLD/pg_ctl -D $W/old14 -l $W/old14.log -w start >/dev/null"
P14="$OLD/psql -h $W -p 5414 -U postgres -X -q"
as_pg "$P14" <<'EOF'
CREATE TABLE orders (id bigint PRIMARY KEY, customer_id int, status text, total numeric);
INSERT INTO orders SELECT g, g % 20000, CASE WHEN g % 10 = 0 THEN 'refunded' ELSE 'paid' END, g % 500
FROM generate_series(1, 500000) g;
CREATE STATISTICS orders_cust_status (dependencies) ON customer_id, status FROM orders;
ANALYZE orders;
CREATE PUBLICATION cdc_pub FOR TABLE orders;
SELECT 'slot created: ' || slot_name FROM pg_create_logical_replication_slot('debezium_orders', 'pgoutput');
-- Blocker: a reg* column in a user table
CREATE TABLE job_hooks (id int, handler regproc);
INSERT INTO job_hooks VALUES (1, 'now');
-- Blocker: an open prepared transaction
BEGIN; INSERT INTO orders VALUES (900001, 1, 'paid', 1); PREPARE TRANSACTION 'stuck_2pc';
EOF
as_pg "$P14 -c \"SELECT slot_name, plugin, slot_type FROM pg_replication_slots\""
as_pg "$P14 -c \"SELECT count(*) AS orders_pg_stats_rows FROM pg_stats WHERE tablename = 'orders'\""
as_pg "$P14 -c \"SHOW data_checksums\""
as_pg "$OLD/pg_ctl -D $W/old14 -w stop >/dev/null"

step "Run 1: pg_upgrade --check against a PG18 initdb with default settings"
as_pg "$NEW/initdb -D $W/new18 -U postgres >/dev/null"
as_pg "$NEW/pg_controldata $W/new18 | grep -i checksum"
as_pg "$NEW/pg_upgrade --check -b $OLD -B $NEW -d $W/old14 -D $W/new18 -U postgres --link" 2>&1 | sed '/^$/d'

step "Run 2: new cluster with --no-data-checksums"
rm -rf $W/new18
as_pg "$NEW/initdb -D $W/new18 -U postgres --no-data-checksums >/dev/null"
as_pg "$NEW/pg_upgrade --check -b $OLD -B $NEW -d $W/old14 -D $W/new18 -U postgres --link" 2>&1 | sed '/^$/d'
for f in $(find $W/new18/pg_upgrade_output.d -name '*.txt' 2>/dev/null); do echo "--- $(basename $f)"; cat $f; done

step "Fix the prepared transaction only, then re-check"
as_pg "$OLD/pg_ctl -D $W/old14 -l $W/old14.log -w start >/dev/null"
as_pg "$P14 -c \"ROLLBACK PREPARED 'stuck_2pc'\""
as_pg "$OLD/pg_ctl -D $W/old14 -w stop >/dev/null"
as_pg "$NEW/pg_upgrade --check -b $OLD -B $NEW -d $W/old14 -D $W/new18 -U postgres --link" 2>&1 | sed '/^$/d'
for f in $(find $W/new18/pg_upgrade_output.d -name '*.txt' 2>/dev/null); do echo "--- $(basename $f)"; cat $f; done

step "Fix the reg* column"
as_pg "$OLD/pg_ctl -D $W/old14 -l $W/old14.log -w start >/dev/null"
as_pg "$P14 -c \"ALTER TABLE job_hooks ALTER COLUMN handler TYPE text\""
as_pg "$P14 -c \"SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal FROM pg_replication_slots\""
as_pg "$OLD/pg_ctl -D $W/old14 -w stop >/dev/null"

step "Run 3: pg_upgrade --check after fixes"
as_pg "$NEW/pg_upgrade --check -b $OLD -B $NEW -d $W/old14 -D $W/new18 -U postgres --link" 2>&1 | sed '/^$/d'

step "Run 4: pg_upgrade --link"
as_pg "$NEW/pg_upgrade -b $OLD -B $NEW -d $W/old14 -D $W/new18 -U postgres --link" 2>&1 | sed '/^$/d' | tail -25

step "On PG18 after upgrade"
cat >> $W/new18/postgresql.conf <<'EOF'
port = 5418
wal_level = logical
unix_socket_directories = '/work'
EOF
as_pg "$NEW/pg_ctl -D $W/new18 -l $W/new18.log -w start >/dev/null"
P18="$NEW/psql -h $W -p 5418 -U postgres -X"
as_pg "$P18 -c 'SELECT version()'"
as_pg "$P18 -c 'SELECT slot_name, plugin, slot_type FROM pg_replication_slots'"
as_pg "$P18 -c 'SELECT pubname FROM pg_publication'"
as_pg "$P18 -c \"SELECT count(*) AS orders_pg_stats_rows FROM pg_stats WHERE tablename = 'orders'\""
as_pg "$P18 -c \"SELECT s.stxname, d.stxdinherit, d.stxddependencies IS NOT NULL AS has_data FROM pg_statistic_ext s LEFT JOIN pg_statistic_ext_data d ON d.stxoid = s.oid\""
as_pg "$P18 -c \"SELECT relname, reltuples::bigint FROM pg_class WHERE relname = 'orders'\""
as_pg "$P18 -c \"SELECT relname, n_live_tup, n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname = 'orders'\""
as_pg "$NEW/vacuumdb -h $W -p 5418 -U postgres --all --analyze-in-stages --missing-stats-only" 2>&1
as_pg "$P18 -c \"SELECT s.stxname, d.stxddependencies IS NOT NULL AS has_data FROM pg_statistic_ext s LEFT JOIN pg_statistic_ext_data d ON d.stxoid = s.oid\""
