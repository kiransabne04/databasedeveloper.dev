#!/usr/bin/env bash
# Why no parallel workers: heap vs TOAST size, then force workers with the parallel_workers reloption.
# Usage: ./check-toast.sh > out-toast.txt 2>&1
set -uo pipefail
IMG=${IMG:-pgvector/pgvector:0.8.7-pg18}
ROWS=${ROWS:-100000}; DIM=${DIM:-768}
for SHM in 4g 64m; do
  C=pgv-toast-$SHM
  docker rm -f $C >/dev/null 2>&1
  docker run -d --name $C --shm-size=$SHM -e POSTGRES_PASSWORD=lab "$IMG" -c shared_buffers=1GB -c max_worker_processes=16 -c max_parallel_workers=16 >/dev/null
  until docker exec $C pg_isready -U postgres -q; do sleep 1; done; sleep 2
  docker exec -i $C psql -U postgres -X -q <<SQL
CREATE EXTENSION vector;
CREATE TABLE items (id bigint PRIMARY KEY, embedding vector($DIM) NOT NULL);
SELECT setseed(0.42);
INSERT INTO items SELECT g, (SELECT array_agg(random()::real - 0.5) FROM generate_series(1, $DIM) WHERE g > 0)::vector FROM generate_series(1, $ROWS) g;
VACUUM ANALYZE items;
SQL
  echo "##### shm=$SHM"
  docker exec $C psql -U postgres -X -c "
SELECT pg_size_pretty(pg_relation_size('items')) AS heap,
       pg_relation_size('items') / current_setting('block_size')::int AS heap_pages,
       pg_size_pretty(pg_relation_size(reltoastrelid)) AS toast,
       current_setting('min_parallel_table_scan_size') AS min_parallel_table_scan_size
FROM pg_class WHERE oid = 'items'::regclass;"
  docker exec $C psql -U postgres -X -Atc "select 'vector typstorage=' || typstorage::text from pg_type where typname='vector'"
  for W in 2 4 8; do
    echo "=== shm=$SHM maintenance_work_mem=1GB parallel_workers reloption=$W max_parallel_maintenance_workers=$W"
    ( docker exec $C psql -U postgres -X -c "alter table items set (parallel_workers = $W)" -c "set maintenance_work_mem='1GB'" -c "set max_parallel_maintenance_workers=$W" -c '\timing on' -c "create index i on items using hnsw (embedding vector_cosine_ops)" -c "drop index if exists i" 2>&1 | grep -E "^Time|ERROR|DETAIL|HINT|NOTICE" ) &
    BG=$!
    sleep 15
    echo "sample: parallel workers=$(docker exec $C psql -U postgres -Atc "select count(*) from pg_stat_activity where backend_type='parallel worker'") cpu=$(docker stats --no-stream --format '{{.CPUPerc}}' $C)"
    wait $BG
    [ "$SHM" = 64m ] && break
  done
  docker logs $C 2>&1 | grep -iE "could not|shared memory segment" | tail -3
  docker rm -f $C >/dev/null
done
