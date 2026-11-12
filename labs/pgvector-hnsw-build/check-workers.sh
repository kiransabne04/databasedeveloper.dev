#!/usr/bin/env bash
# Do parallel HNSW builds launch workers, and how much CPU do they use?
# Usage: ./check-workers.sh > out-workers.txt 2>&1
set -uo pipefail
IMG=${IMG:-pgvector/pgvector:0.8.7-pg18}
ROWS=${ROWS:-100000}; DIM=${DIM:-768}
for SHM in 64m 4g; do
  C=pgv-chk-$SHM
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
  for W in 0 4; do
    echo "=== shm=$SHM maintenance_work_mem=1GB workers=$W"
    ( docker exec $C psql -U postgres -X -c "set maintenance_work_mem='1GB'" -c "set max_parallel_maintenance_workers=$W" -c '\timing on' -c "create index i on items using hnsw (embedding vector_cosine_ops)" -c "drop index i" 2>&1 | grep -E "Time|ERROR|NOTICE|DETAIL" ) &
    BG=$!
    sleep 20
    for s in 1 2 3; do
      echo "sample $s: workers=$(docker exec $C psql -U postgres -Atc "select count(*) from pg_stat_activity where backend_type='parallel worker'") cpu=$(docker stats --no-stream --format '{{.CPUPerc}}' $C)"
      sleep 10
    done
    wait $BG
  done
  docker exec $C df -h /dev/shm | tail -1
  docker logs $C 2>&1 | grep -iE "shared memory|could not" | tail -3
  docker rm -f $C >/dev/null
done
