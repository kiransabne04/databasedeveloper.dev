#!/usr/bin/env bash
# CREATE INDEX CONCURRENTLY lab driver.
# Usage: ./run-lab.sh <container> <output-file>
# Requires: 01-setup.sql and writer.pgbench already loaded (see README).
set -u
C=$1
OUT=$2
WORK=$(mktemp -d)
: >"$OUT"
export T0=$(perl -MTime::HiRes=time -e 'printf "%.3f", time')

P()   { docker exec -i "$C" psql -X -U postgres -d lab -v ON_ERROR_STOP=0 "$@"; }
qa()  { P -At -c "$1" 2>&1; }
ts()  { perl -MTime::HiRes=time -e 'printf "%6.1f", time-$ENV{T0}'; }
log() { echo "[t=$(ts)s] $*" >>"$OUT"; }
q()   { echo "[t=$(ts)s] SQL> $1" >>"$OUT"; P -c "$1" >>"$OUT" 2>&1; }
nap() { perl -e "select undef,undef,undef,$1"; }
hdr() { T0=$(perl -MTime::HiRes=time -e 'printf "%.3f", time'); export T0; printf '\n==================== %s ====================\n' "$*" >>"$OUT"; }

pid_of() { qa "SELECT pid FROM pg_stat_activity WHERE application_name = '$1' LIMIT 1"; }

# hold <app_name> <seconds> <sql...>: open a session, run SQL, stay idle, then COMMIT.
hold() {
  local app=$1 secs=$2; shift 2
  ( { echo "SET application_name = '$app';"; printf '%s\n' "$@"; sleep "$secs"; echo "COMMIT;"; } \
      | P >"$WORK/$app.log" 2>&1 ) &
  eval "HOLD_$app=$!"
}

# run_bg <app_name> <sql-lines...>: run SQL in a background session with \timing.
run_bg() {
  local app=$1; shift
  ( { echo '\timing on'; echo "SET application_name = '$app';"; printf '%s\n' "$@"; } \
      | P >"$WORK/$app.log" 2>&1; echo "psql exit=$?" >>"$WORK/$app.log" ) &
  eval "BG_$app=$!"
}
bg_wait() { local v="BG_$1"; wait "${!v}" 2>/dev/null; log "session $1 output:"; sed 's/^/    /' "$WORK/$1.log" >>"$OUT"; }

progress_line() {
  qa "SELECT p.phase || ' | lockers ' || coalesce(p.lockers_done,0) || '/' || coalesce(p.lockers_total,0)
          || ' current_locker_pid=' || coalesce(p.current_locker_pid,0)
          || ' (' || coalesce((SELECT application_name FROM pg_stat_activity WHERE pid = p.current_locker_pid),'-') || ')'
          || ' | blocks ' || p.blocks_done || '/' || p.blocks_total
          || ' | wait ' || coalesce(a.wait_event_type,'-') || ':' || coalesce(a.wait_event,'-')
      FROM pg_stat_progress_create_index p JOIN pg_stat_activity a USING (pid)
      WHERE a.application_name = '$1'"
}
phase_of() { qa "SELECT p.phase FROM pg_stat_progress_create_index p JOIN pg_stat_activity a USING (pid) WHERE a.application_name = '$1'"; }

# wait_phase <app> <pattern> <timeout_s>: poll until phase LIKE pattern; logs transitions.
wait_phase() {
  local app=$1 pat=$2 to=$3 last="" cur ph
  local end=$(( $(date +%s) + to ))
  while [ "$(date +%s)" -lt "$end" ]; do
    ph=$(phase_of "$app")
    if [ "$ph" != "$last" ]; then log "phase[$app]: ${ph:-(no progress row)}"; last=$ph; fi
    case "$ph" in $pat) return 0;; esac
    nap 0.1
  done
  log "TIMEOUT waiting for phase '$pat' on $app"; return 1
}

# trace <app> <seconds>: log every phase transition until the session's progress row disappears.
trace() {
  local app=$1 to=$2 last="__" cur ph seen=0
  local end=$(( $(date +%s) + to ))
  while [ "$(date +%s)" -lt "$end" ]; do
    cur=$(progress_line "$app"); ph=${cur%% |*}
    [ -n "$cur" ] && seen=1
    if [ "$ph" != "$last" ]; then log "phase[$app]: ${cur:-(no progress row)}"; last=$ph; fi
    [ -z "$cur" ] && [ "$seen" = 1 ] && return 0
    [ -z "$(pid_of "$app")" ] && [ "$seen" = 0 ] && { log "session $app ended before a progress row was seen"; return 0; }
    nap 0.1
  done
}

istate() {
  q "SELECT t.relname AS tbl, c.relname AS index_name, i.indisvalid, i.indisready, i.indislive, i.indisunique,
            pg_size_pretty(pg_relation_size(c.oid)) AS size
     FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_class t ON t.oid = i.indrelid
     WHERE t.relname IN ('orders','t2','orders_p','orders_p1','orders_p2','orders_p3') AND NOT i.indisprimary
     ORDER BY 1, 2;"
}

locks_for() {
  local pid; pid=$(pid_of "$1")
  q "SELECT locktype, coalesce(relation::regclass::text,'') AS relation, virtualxid, transactionid, mode, granted
     FROM pg_locks WHERE pid = $pid AND (NOT granted OR locktype = 'relation') ORDER BY granted, locktype;"
  q "SELECT $pid AS build_pid, pg_blocking_pids($pid) AS blocking_pids,
            (SELECT array_agg(application_name || ':' || pid) FROM pg_stat_activity WHERE pid = ANY(pg_blocking_pids($pid))) AS blockers;"
}

reset() {
  P -q >/dev/null 2>&1 <<'SQL'
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
 WHERE datname = 'lab' AND pid <> pg_backend_pid() AND application_name NOT IN ('pgbench','');
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_tenant_ref_key;
DELETE FROM orders WHERE payload = 'lab-dup';
DROP INDEX IF EXISTS orders_p_payload_idx;
DO $$DECLARE r record; BEGIN
  FOR r IN SELECT c.relname FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
           JOIN pg_class t ON t.oid = i.indrelid
           WHERE t.relname IN ('orders','t2','orders_p1','orders_p2','orders_p3') AND NOT i.indisprimary
  LOOP EXECUTE 'DROP INDEX ' || quote_ident(r.relname); END LOOP; END$$;
SQL
  nap 0.5
}

# ---------------------------------------------------------------- start
{ echo "# CIC lab output"; echo "container: $C"; date -u '+run at %Y-%m-%dT%H:%M:%SZ'; } >>"$OUT"
q "SELECT version();"
q "SHOW maintenance_work_mem;"
reset
# Light background write load: 2 clients, ~100 single-row updates/s in total.
docker exec "$C" sh -c 'pgbench -n -U postgres -c 2 -R 100 -T 3600 -f /tmp/writer.pgbench lab >/tmp/pgbench.log 2>&1 &'
log "pgbench writer started (2 clients, -R 100)"
nap 2

# ---------------------------------------------------------------- L1
hdr "L1 baseline: CREATE INDEX CONCURRENTLY, no blocker"
reset
run_bg b1 "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
trace b1 60; bg_wait b1; istate

# ---------------------------------------------------------------- L2a
hdr "L2a writer left idle in transaction before the build"
reset
hold w_idle 12 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 1;"
nap 1
run_bg b2a "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
wait_phase b2a "waiting for writers before build" 10
nap 1
log "progress: $(progress_line b2a)"
q "SELECT pid, application_name, state, now() - xact_start AS xact_age, backend_xmin FROM pg_stat_activity WHERE application_name = 'w_idle';"
locks_for b2a
trace b2a 60; bg_wait b2a; istate

# ---------------------------------------------------------------- L2b
hdr "L2b REPEATABLE READ snapshot on an UNRELATED table, opened after the build started"
reset
hold w_gate 6 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 2;"
nap 1
run_bg b2b "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
wait_phase b2b "waiting for writers before build" 10
hold rr_unrelated 25 "BEGIN ISOLATION LEVEL REPEATABLE READ;" "SELECT count(*) FROM unrelated_table;"
nap 1
q "SELECT application_name, state, backend_xmin, backend_xid FROM pg_stat_activity WHERE application_name IN ('rr_unrelated','w_gate');"
log "w_gate commits at ~6s; build then proceeds; rr_unrelated stays idle until ~31s"
wait_phase b2b "waiting for old snapshots" 30 && { log "progress: $(progress_line b2b)"; locks_for b2b; }
trace b2b 60; bg_wait b2b; istate

# ---------------------------------------------------------------- L2b-rc
hdr "L2b-rc same, but READ COMMITTED idle transaction (no snapshot held between statements)"
reset
hold w_gate2 6 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 2;"
nap 1
run_bg b2r "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
wait_phase b2r "waiting for writers before build" 10
hold rc_unrelated 25 "BEGIN;" "SELECT count(*) FROM unrelated_table;"
nap 1
q "SELECT application_name, state, backend_xmin, backend_xid FROM pg_stat_activity WHERE application_name IN ('rc_unrelated');"
trace b2r 40; bg_wait b2r; istate

# ---------------------------------------------------------------- L2c
hdr "L2c two expression-index builds on different tables at the same time"
reset
run_bg b2c_o "SET statement_timeout = '120s';" "CREATE INDEX CONCURRENTLY orders_lower_payload_idx ON orders (lower(payload));"
run_bg b2c_t "SET statement_timeout = '120s';" "CREATE INDEX CONCURRENTLY t2_lower_x_idx ON t2 (lower(x));"
( trace b2c_t 90 ) &
TR=$!
trace b2c_o 90; wait $TR; bg_wait b2c_o; bg_wait b2c_t; istate

hdr "L2c-plain two plain-column builds on different tables at the same time (control)"
reset
run_bg b2p_o "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
run_bg b2p_t "CREATE INDEX CONCURRENTLY t2_x_idx ON t2 (x);"
( trace b2p_t 90 ) &
TR=$!
trace b2p_o 90; wait $TR; bg_wait b2p_o; bg_wait b2p_t; istate

# ---------------------------------------------------------------- L3
hdr "L3a cancel during 'waiting for writers before build'"
reset
hold w3 10 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 3;"
nap 1
run_bg b3a "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
wait_phase b3a "waiting for writers before build" 10
q "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name = 'b3a';"
bg_wait b3a; istate

hdr "L3b cancel during 'building index'"
reset
run_bg b3b "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
wait_phase b3b "building index*" 10
nap 0.5
log "progress: $(progress_line b3b)"
q "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name = 'b3b';"
bg_wait b3b; istate

hdr "L3c cancel during 'waiting for old snapshots'"
reset
hold w3c 5 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 4;"
nap 1
run_bg b3c "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
wait_phase b3c "waiting for writers before build" 10
hold rr3c 40 "BEGIN ISOLATION LEVEL REPEATABLE READ;" "SELECT 1 FROM unrelated_table LIMIT 1;"
wait_phase b3c "waiting for old snapshots" 30
q "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name = 'b3c';"
bg_wait b3c; istate

hdr "L3d statement_timeout during 'waiting for writers before build'"
reset
hold w3d 10 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 5;"
nap 1
run_bg b3d "SET statement_timeout = '2s';" "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
bg_wait b3d; istate

# ---------------------------------------------------------------- L4
hdr "L4a lock_timeout = 2s while waiting for a writer (waiting for writers before build)"
reset
hold w4 10 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 6;"
nap 1
run_bg b4a "SET lock_timeout = '2s';" "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
bg_wait b4a; istate

hdr "L4b lock_timeout = 2s while waiting for an old snapshot"
reset
run_bg b4b "SET lock_timeout = '2s';" "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
wait_phase b4b "building index*" 10
hold rr4 30 "BEGIN ISOLATION LEVEL REPEATABLE READ;" "SELECT 1 FROM unrelated_table LIMIT 1;"
trace b4b 30; bg_wait b4b; istate

# ---------------------------------------------------------------- L5
hdr "L5 build waiting for its own SHARE UPDATE EXCLUSIVE table lock"
reset
hold suelock 8 "BEGIN;" "LOCK TABLE orders IN SHARE UPDATE EXCLUSIVE MODE;"
nap 1
run_bg b5 "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
nap 2
log "progress row: '$(progress_line b5)'"
q "SELECT pid, state, wait_event_type, wait_event FROM pg_stat_activity WHERE application_name = 'b5';"
locks_for b5
trace b5 40; bg_wait b5; istate

# ---------------------------------------------------------------- L6
hdr "L6 CREATE INDEX CONCURRENTLY IF NOT EXISTS over an existing INVALID index"
reset
hold w6 10 "BEGIN;" "UPDATE orders SET created_at = created_at WHERE id = 7;"
nap 1
run_bg b6 "SET lock_timeout = '1s';" "CREATE INDEX CONCURRENTLY orders_ext_idx ON orders (external_ref);"
bg_wait b6; istate
log "now re-run with IF NOT EXISTS under ON_ERROR_STOP=1"
docker exec -i "$C" psql -X -U postgres -d lab -v ON_ERROR_STOP=1 \
  -c "CREATE INDEX CONCURRENTLY IF NOT EXISTS orders_ext_idx ON orders (external_ref);" >>"$OUT" 2>&1
log "psql exit code: $?"
istate
q "SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;"
log "recovery: REINDEX INDEX CONCURRENTLY on the invalid index"
q "REINDEX INDEX CONCURRENTLY orders_ext_idx;"
istate

# ---------------------------------------------------------------- L7
hdr "L7a UNIQUE build with a pre-existing duplicate (fails in first scan)"
reset
q "INSERT INTO orders (tenant_id, external_ref, payload) VALUES (1, 'ref-1001', 'lab-dup');"
run_bg b7a "CREATE UNIQUE INDEX CONCURRENTLY orders_tenant_ref_uq ON orders (tenant_id, external_ref);"
trace b7a 40; bg_wait b7a; istate
log "after failed first-scan unique build: insert another duplicate of an existing key"
q "INSERT INTO orders (tenant_id, external_ref, payload) VALUES (2, 'ref-2002', 'lab-dup');"

hdr "L7b UNIQUE build; duplicate inserted during first scan (fails in validation / second scan)"
reset
run_bg b7b "CREATE UNIQUE INDEX CONCURRENTLY orders_tenant_ref_uq ON orders (tenant_id, external_ref);"
wait_phase b7b "building index*" 15
q "INSERT INTO orders (tenant_id, external_ref, payload) VALUES (3, 'ref-3003', 'lab-dup');"
trace b7b 60; bg_wait b7b; istate
log "after failed second-scan unique build: insert a NEW duplicate of a different existing key"
q "INSERT INTO orders (tenant_id, external_ref, payload) VALUES (4, 'ref-4004', 'lab-dup');"
q "INSERT INTO orders (tenant_id, external_ref, payload) VALUES (9, 'brand-new-ref', 'lab-dup'), (9, 'brand-new-ref', 'lab-dup');"
q "SET enable_seqscan = off; EXPLAIN (COSTS OFF) SELECT * FROM orders WHERE tenant_id = 4 AND external_ref = 'ref-4004';"
log "can the invalid unique index be dropped concurrently?"
q "DROP INDEX CONCURRENTLY orders_tenant_ref_uq;"
istate

hdr "L7c successful UNIQUE build, then ADD CONSTRAINT ... USING INDEX: locks taken"
reset
q "CREATE UNIQUE INDEX CONCURRENTLY orders_tenant_ref_uq ON orders (tenant_id, external_ref);"
P >>"$OUT" 2>&1 <<'SQL'
BEGIN;
ALTER TABLE orders ADD CONSTRAINT orders_tenant_ref_key UNIQUE USING INDEX orders_tenant_ref_uq;
SELECT coalesce(relation::regclass::text, locktype) AS object, mode, granted
FROM pg_locks WHERE pid = pg_backend_pid() AND locktype = 'relation'
ORDER BY 1, 2;
COMMIT;
SQL
q "DROP INDEX CONCURRENTLY orders_tenant_ref_key;"
q "ALTER TABLE orders DROP CONSTRAINT orders_tenant_ref_key;"

# ---------------------------------------------------------------- L8
hdr "L8 CREATE INDEX CONCURRENTLY inside a transaction block"
reset
P >>"$OUT" 2>&1 <<'SQL'
BEGIN;
CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);
ROLLBACK;
SQL

# ---------------------------------------------------------------- L9
hdr "L9 partitioned table"
reset
q "CREATE INDEX CONCURRENTLY orders_p_payload_idx ON orders_p (payload);"
P >>"$OUT" 2>&1 <<'SQL'
\timing on
CREATE INDEX CONCURRENTLY orders_p1_payload_idx ON orders_p1 (payload);
CREATE INDEX CONCURRENTLY orders_p2_payload_idx ON orders_p2 (payload);
CREATE INDEX CONCURRENTLY orders_p3_payload_idx ON orders_p3 (payload);
CREATE INDEX orders_p_payload_idx ON orders_p (payload);
\timing off
SELECT c.relname AS partition_index, p.relname AS attached_to
FROM pg_inherits h JOIN pg_class c ON c.oid = h.inhrelid JOIN pg_class p ON p.oid = h.inhparent
WHERE p.relname = 'orders_p_payload_idx' ORDER BY 1;
SELECT t.relname AS tbl, count(*) AS indexes FROM pg_index i JOIN pg_class t ON t.oid = i.indrelid
WHERE t.relname LIKE 'orders_p%' GROUP BY 1 ORDER BY 1;
SQL
q "DROP INDEX CONCURRENTLY orders_p_payload_idx;"
q "DROP INDEX orders_p_payload_idx;"

# ---------------------------------------------------------------- L11
hdr "L11 REINDEX CONCURRENTLY cancelled: leftover _ccnew / _ccold"
reset
q "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
run_bg b11 "REINDEX INDEX CONCURRENTLY orders_payload_idx;"
wait_phase b11 "building index*" 15
q "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name = 'b11';"
bg_wait b11; istate
q "DROP INDEX CONCURRENTLY orders_payload_idx_ccnew;"
istate
log "L11b REINDEX CONCURRENTLY blocked by an idle reader that opened first, cancelled in the reader-wait phase"
reset
q "CREATE INDEX CONCURRENTLY orders_payload_idx ON orders (payload);"
hold reader11 25 "BEGIN;" "SELECT 1 FROM orders WHERE id = 1;"
nap 1
run_bg b11b "REINDEX INDEX CONCURRENTLY orders_payload_idx;"
wait_phase b11b "waiting for readers*" 30
nap 1
log "progress: $(progress_line b11b)"
q "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name = 'b11b';"
bg_wait b11b; istate
q "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'reader11';"
nap 0.5
q "DROP INDEX CONCURRENTLY orders_payload_idx_ccold;"
istate

# ---------------------------------------------------------------- done
reset
docker exec "$C" pkill pgbench >/dev/null 2>&1
log "pgbench stopped"
rm -rf "$WORK"
log "DONE"
