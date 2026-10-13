#!/bin/sh
# Usage: ./run-scenario.sh <container> <ddl-prefix> <outfile>
#   ddl-prefix: SQL run before the DDL in its session, e.g. "" or "SET lock_timeout = '2s';"
# Timeline (seconds): 0 readers start | 5 long transaction opens, then sits idle | 10 DDL issued
#                     14 blocking-chain snapshot | 25 long transaction commits | 40 readers stop
C=$1; PREFIX=$2; OUT=$3
PSQL="docker exec -i $C psql -U postgres -X -q"
: > "$OUT"
docker exec "$C" pgbench -U postgres -n -M prepared -c 8 -j 4 -T 40 --progress=1 -f /tmp/readers.pgbench postgres > "$OUT.pgbench" 2>&1 &
BENCH=$!
sleep 5
( echo "BEGIN; SELECT count(*) FROM orders WHERE tenant_id = 7;"; sleep 20; echo "COMMIT;" ) | $PSQL > /dev/null &
sleep 5
echo "[t=10] DDL issued: ${PREFIX} ALTER TABLE orders ADD COLUMN note text;" >> "$OUT"
printf '%s\n' '\timing on' "${PREFIX}" "ALTER TABLE orders ADD COLUMN note text;" | $PSQL >> "$OUT" 2>&1 &
DDL=$!
sleep 4
echo "[t=14] blocking-chain snapshot" >> "$OUT"
docker exec "$C" psql -U postgres -X -f /tmp/02-blocking-chain.sql >> "$OUT" 2>&1
wait $DDL
echo "[DDL session finished]" >> "$OUT"
wait $BENCH
cat "$OUT.pgbench" >> "$OUT"; rm "$OUT.pgbench"
docker exec "$C" psql -U postgres -X -qc "ALTER TABLE orders DROP COLUMN IF EXISTS note" > /dev/null
