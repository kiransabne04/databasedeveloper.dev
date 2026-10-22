#!/bin/bash
# Runs inside the postgres:18 container as root. Uses pg_resetwal to move the next
# transaction ID close to the wraparound limit (lab only; never do this to a real
# cluster), with a prepared transaction holding back freezing. Shows the warnings,
# what does not fix them, how to find the blocker and how age drops afterwards.
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
max_prepared_transactions = 5
log_autovacuum_min_duration = 0
autovacuum_naptime = 5s
EOF
as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"

step "Version and freeze settings"
as_pg "$PSQL" <<'EOF'
SELECT version();
SELECT name, setting FROM pg_settings
WHERE name IN ('autovacuum_freeze_max_age', 'vacuum_freeze_min_age', 'vacuum_freeze_table_age',
               'vacuum_failsafe_age', 'autovacuum_multixact_freeze_max_age')
ORDER BY name;
EOF

step "Data, and a prepared transaction that nobody resolves"
as_pg "$PSQL" <<'EOF'
CREATE TABLE events (id bigint PRIMARY KEY, payload text);
INSERT INTO events SELECT g, md5(g::text) FROM generate_series(1, 100000) g;
CREATE TABLE ledger (id int PRIMARY KEY, amount int);
INSERT INTO ledger VALUES (1, 100);
BEGIN; UPDATE ledger SET amount = amount + 1 WHERE id = 1; PREPARE TRANSACTION 'xa-ledger-42';
SELECT gid, transaction, prepared FROM pg_prepared_xacts;
SELECT datname, datfrozenxid, age(datfrozenxid) FROM pg_database ORDER BY datname;
EOF

# Lab only: set the next XID with pg_resetwal. pg_xact needs a segment covering
# the new XID (1,048,576 XIDs per segment).
jump() {
  as_pg "$BIN/pg_ctl -D $W/data -w stop >/dev/null"
  SEG=$(printf '%04X' $(($1 / 1048576)))
  as_pg "dd if=/dev/zero of=$W/data/pg_xact/$SEG bs=8192 count=32 status=none"
  as_pg "$BIN/pg_resetwal -x $1 -D $W/data"
  as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"
  sleep 2
}
step "Lab only: pg_resetwal moves the next XID to 2,120,000,000"
jump 2120000000

step "Ages now"
as_pg "$PSQL" <<'EOF'
SELECT datname, age(datfrozenxid) AS xid_age,
       round(100.0 * age(datfrozenxid) / 2147483648, 1) AS pct_to_wraparound
FROM pg_database ORDER BY 2 DESC;
EOF

step "Any write now warns"
sql "INSERT INTO events VALUES (100001, 'x')" 2>&1

step "Wait for anti-wraparound autovacuum, then check again"
sleep 20
grep -E 'to prevent wraparound|failsafe|removable cutoff|new relfrozenxid' $W/server.log | head -8
as_pg "$PSQL" <<'EOF'
SELECT datname, age(datfrozenxid) AS xid_age FROM pg_database ORDER BY 2 DESC;
SELECT relname, age(relfrozenxid) AS xid_age FROM pg_class
WHERE relkind IN ('r', 't', 'm') AND relnamespace = 'public'::regnamespace ORDER BY 2 DESC;
EOF

step "Manual VACUUM (FREEZE, VERBOSE) does not help either"
sql "VACUUM (FREEZE, VERBOSE) events" 2>&1 | grep -E 'WARNING|removable cutoff|new relfrozenxid|failsafe|HINT' | head -6

step "Find what holds the horizon"
as_pg "$PSQL" <<'EOF'
SELECT 'prepared xact' AS kind, gid AS name, age(transaction) AS xid_age FROM pg_prepared_xacts
UNION ALL
SELECT 'backend', pid::text || ' ' || coalesce(application_name, ''), greatest(age(backend_xid), age(backend_xmin))
FROM pg_stat_activity WHERE (backend_xid IS NOT NULL OR backend_xmin IS NOT NULL) AND pid <> pg_backend_pid()
UNION ALL
SELECT 'replication slot', slot_name, greatest(age(xmin), age(catalog_xmin)) FROM pg_replication_slots
ORDER BY xid_age DESC NULLS LAST;
EOF

step "Lab only: let it get to the stop limit (next XID 2,145,000,000)"
jump 2145000000
sql "INSERT INTO events VALUES (100002, 'y')" 2>&1
sql "SELECT count(*) FROM events" 2>&1

step "Recovery in normal mode: resolve the prepared transaction, then VACUUM"
sql "ROLLBACK PREPARED 'xa-ledger-42'" 2>&1
as_pg "$PSQL" <<'EOF' 2>&1 | grep -E 'removable cutoff|new relfrozenxid|^Time'
\timing on
VACUUM (VERBOSE) events;
EOF
as_pg "$BIN/vacuumdb -h $W -U postgres --all" > $W/vacuumdb.log 2>&1
echo "vacuumdb --all exit code: $?, warnings: $(grep -c WARNING $W/vacuumdb.log)"
sleep 12
as_pg "$PSQL" <<'EOF'
SELECT datname, age(datfrozenxid) AS xid_age FROM pg_database ORDER BY 2 DESC;
EOF
sql "INSERT INTO events VALUES (100003, 'z')" 2>&1 && echo "insert ok"
