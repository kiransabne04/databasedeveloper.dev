#!/usr/bin/env bash
# Snapshot-script lab: runs public/snapshot/walstack-snapshot.sql against
# disposable PostgreSQL containers on generated data only.
# Usage: ./run-lab.sh > out-lab.txt 2>&1   (VERSIONS="13 18" to narrow)
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SCRIPT="$HERE/../../public/snapshot/walstack-snapshot.sql"
VERSIONS=${VERSIONS:-"13 14 15 16 17 18"}
ERR=$(mktemp -d)

for v in $VERSIONS; do
  name=snaplab-pg$v
  docker rm -f $name >/dev/null 2>&1 || true
  docker run -d --name $name -e POSTGRES_HOST_AUTH_METHOD=trust "postgres:$v" \
    -c shared_preload_libraries=pg_stat_statements >/dev/null
  until docker exec $name pg_isready -U postgres -q 2>/dev/null; do sleep 1; done
  sleep 2
  docker cp "$SCRIPT" $name:/tmp/snap.sql
  P() { docker exec -i $name psql -U postgres -X -q -v ON_ERROR_STOP=1 "$@"; }
  P <<'SQL'
CREATE EXTENSION pg_stat_statements;
CREATE TABLE customers (id bigint PRIMARY KEY, email text NOT NULL);
CREATE TABLE orders (id bigint PRIMARY KEY, customer_id bigint REFERENCES customers, total numeric, created_at timestamptz);
INSERT INTO customers SELECT g, 'user' || g || '@example.test' FROM generate_series(1, 20000) g;
INSERT INTO orders SELECT g, 1 + g % 20000, g % 500, now() - g * interval '1 minute' FROM generate_series(1, 200000) g;
CREATE INDEX orders_created_idx ON orders (created_at);
ANALYZE;
SELECT count(*) FROM orders WHERE customer_id = 42;
SELECT count(*) FROM orders WHERE customer_id = 42;
CREATE ROLE app_login LOGIN;
ALTER ROLE app_login PASSWORD 'lab-only-not-a-secret';
CREATE ROLE snap_monitor LOGIN IN ROLE pg_monitor;
CREATE ROLE snap_plain LOGIN;
SQL
  echo "################ PostgreSQL $v"
  P -Atc "select version()"

  echo "== A. pg_monitor login, defaults"
  docker exec $name psql -X -U snap_monitor -d postgres -f /tmp/snap.sql -o /tmp/a.txt 2>"$ERR/a.err"; echo "exit=$?"; echo "stderr lines: $(grep -c . "$ERR/a.err")"; sed -E 's/^psql:[^ ]+ //' "$ERR/a.err" | sort | uniq -c
  docker exec $name sh -c 'grep -c . /tmp/a.txt; grep -E "^=== " /tmp/a.txt | wc -l'
  echo "-- credential literal stored by pg_stat_statements? (raw view as superuser)"; P -Atc "select count(*) from pg_stat_statements where query like '%lab-only-not-a-secret%'"
  echo "-- credential text present in output? (expect 0)"; docker exec $name sh -c 'grep -c "lab-only-not-a-secret" /tmp/a.txt'
  echo "-- placeholder lines"; docker exec $name sh -c 'grep -c "omitted by script" /tmp/a.txt'
  echo "-- privilege line"; docker exec $name sh -c 'grep -A3 "1. Server" /tmp/a.txt | tail -1 | grep -oE "\| [tf] *$"'

  echo "== B. login without pg_monitor"
  docker exec $name psql -X -U snap_plain -d postgres -f /tmp/snap.sql -o /tmp/b.txt 2>"$ERR/b.err"; echo "exit=$?"; echo "stderr lines: $(grep -c . "$ERR/b.err")"; sed -E 's/^psql:[^ ]+ //' "$ERR/b.err" | sort | uniq -c
  docker exec $name sh -c 'grep -c "insufficient privilege" /tmp/b.txt'

  echo "== C. -v show_query_text=off -v show_schema=off"
  docker exec $name psql -X -U snap_monitor -d postgres -v show_query_text=off -v show_schema=off -f /tmp/snap.sql -o /tmp/c.txt 2>"$ERR/c.err"; echo "exit=$?"; echo "stderr lines: $(grep -c . "$ERR/c.err")"; sed -E 's/^psql:[^ ]+ //' "$ERR/c.err" | sort | uniq -c
  docker exec $name sh -c 'grep -m1 "show_query_text" /tmp/c.txt; grep -c "count(\*)" /tmp/c.txt; grep "skipped: show_schema" /tmp/c.txt'

  echo "== D. extension absent (fresh database)"
  P -c "CREATE DATABASE nopgss" >/dev/null
  docker exec $name psql -X -U snap_monitor -d nopgss -f /tmp/snap.sql -o /tmp/d.txt 2>"$ERR/d.err"; echo "exit=$?"; echo "stderr lines: $(grep -c . "$ERR/d.err")"; sed -E 's/^psql:[^ ]+ //' "$ERR/d.err" | sort | uniq -c
  docker exec $name sh -c 'grep "Query timings unavailable" /tmp/d.txt'

  echo "== E. another session holds ACCESS EXCLUSIVE on orders"
  docker exec -d $name psql -U postgres -X -c "BEGIN; LOCK TABLE orders IN ACCESS EXCLUSIVE MODE; SELECT pg_sleep(60);"
  sleep 1
  start=$(date +%s)
  docker exec $name psql -X -U snap_monitor -d postgres -f /tmp/snap.sql -o /tmp/e.txt 2>"$ERR/e.err"; echo "exit=$?"
  echo "elapsed_seconds=$(( $(date +%s) - start ))"
  sed -E 's/^psql:[^ ]+ //' "$ERR/e.err" | sort | uniq -c
  docker exec $name sh -c 'grep -c "End of WalStack snapshot" /tmp/e.txt'

  echo "== F. no writes: pg_stat_database xact_commit unaffected? (session counters only)"
  P -Atc "select count(*) from pg_stat_activity where state = 'idle in transaction' and usename like 'snap%'"
  docker rm -f $name >/dev/null
done
