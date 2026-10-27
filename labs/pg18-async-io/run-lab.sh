#!/bin/bash
# Runs inside a --privileged postgres:18.6 container as root. Compares io_method
# sync, worker and io_uring on cold-cache sequential and bitmap heap scans.
# --privileged is needed to drop the OS page cache between runs and to allow
# io_uring, which Docker's default seccomp profile blocks.
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
shared_buffers = '256MB'
max_parallel_workers_per_gather = 0
track_io_timing = on
jit = off
EOF
as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"

step "Version and I/O settings"
as_pg "$PSQL" <<'EOF'
SELECT version();
SELECT name, setting, unit FROM pg_settings
WHERE name IN ('io_method', 'io_workers', 'effective_io_concurrency', 'maintenance_io_concurrency', 'io_combine_limit', 'shared_buffers')
ORDER BY name;
EOF

step "Build events (8,000,000 rows) with an index on account_id"
as_pg "$PSQL" <<'EOF'
CREATE TABLE events (id bigint PRIMARY KEY, account_id int NOT NULL, created_at timestamptz NOT NULL, payload text NOT NULL);
INSERT INTO events
SELECT g, (g::bigint * 7919) % 20000, timestamptz '2026-01-01' + g * interval '1 second', repeat(md5(g::text), 3)
FROM generate_series(1, 8000000) g;
CREATE INDEX events_account_idx ON events (account_id);
VACUUM ANALYZE events;
SELECT pg_size_pretty(pg_table_size('events')) AS table_size, pg_size_pretty(pg_relation_size('events_account_idx')) AS index_size;
EOF

cat > $W/q_seq.sql <<'EOF'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT count(*) FROM events WHERE payload LIKE 'zzz%';
EOF
cat > $W/q_bitmap.sql <<'EOF'
SET enable_indexscan = off;
SET work_mem = '64MB';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT count(*), max(created_at) FROM events WHERE account_id BETWEEN 1000 AND 1400;
EOF

cold() {
  as_pg "$BIN/pg_ctl -D $W/data -w stop >/dev/null"
  sync; echo 3 > /proc/sys/vm/drop_caches
  as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"
}

for method in sync worker io_uring sync_again; do
  m=${method%_again}
  as_pg "$BIN/pg_ctl -D $W/data -w stop >/dev/null"
  sed -i '/^io_method/d' $W/data/postgresql.conf
  echo "io_method = '$m'" >> $W/data/postgresql.conf
  as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null" || { echo "io_method=$m failed to start"; tail -5 $W/server.log; continue; }
  step "io_method = $method: one full plan per query (cold cache)"
  as_pg "$PSQL -c 'SHOW io_method'"
  # one discarded cold run of each query first
  cold; as_pg "$PSQL -f $W/q_seq.sql" >/dev/null; cold; as_pg "$PSQL -f $W/q_bitmap.sql" >/dev/null
  cold; as_pg "$PSQL -f $W/q_seq.sql"
  cold; as_pg "$PSQL -f $W/q_bitmap.sql"
  step "io_method = $method: five cold runs, execution time in ms"
  for q in seq bitmap; do
    printf '%s:' "$q"
    for i in 1 2 3 4 5; do
      cold
      t=$(as_pg "$PSQL -f $W/q_$q.sql" | grep 'Execution Time' | awk '{print $3}')
      printf ' %s' "$t"
    done
    echo
  done
done

step "effective_io_concurrency on the bitmap scan, io_method = io_uring, cold"
for eic in 1 16 64 256; do
  printf 'eic=%s:' "$eic"
  for i in 1 2 3; do
    cold
    t=$(as_pg "$PSQL -c 'SET effective_io_concurrency = $eic' -f $W/q_bitmap.sql" | grep 'Execution Time' | awk '{print $3}')
    printf ' %s' "$t"
  done
  echo
done

step "pg_aios while a cold scan runs (io_method = worker)"
as_pg "$BIN/pg_ctl -D $W/data -w stop >/dev/null"
sed -i '/^io_method/d' $W/data/postgresql.conf
echo "io_method = 'worker'" >> $W/data/postgresql.conf
as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"
cold
as_pg "$PSQL -c 'SELECT count(*) FROM events WHERE payload LIKE \$\$zzz%\$\$'" >/dev/null &
for i in 1 2 3 4 5 6; do
  sleep 0.03
  as_pg "$PSQL -At -c 'SELECT count(*), string_agg(DISTINCT operation || \$\$/\$\$ || state, \$\$, \$\$) FROM pg_aios'"
done
wait
as_pg "$PSQL -c 'SELECT backend_type, count(*) FROM pg_stat_activity GROUP BY 1 ORDER BY 1'"
