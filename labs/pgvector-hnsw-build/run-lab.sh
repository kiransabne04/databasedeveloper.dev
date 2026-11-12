#!/usr/bin/env bash
# HNSW build time vs maintenance_work_mem, parallel workers and /dev/shm size.
# Usage: ./run-lab.sh > out-lab.txt 2>&1
set -uo pipefail
IMG=${IMG:-pgvector/pgvector:0.8.7-pg18}
ROWS=${ROWS:-100000}
DIM=${DIM:-768}

start() { # name shm-size
  docker rm -f "$1" >/dev/null 2>&1
  docker run -d --name "$1" --shm-size="$2" -e POSTGRES_PASSWORD=lab "$IMG" \
    -c shared_buffers=1GB -c max_worker_processes=16 -c max_parallel_workers=16 >/dev/null
  until docker exec "$1" pg_isready -U postgres -q; do sleep 1; done; sleep 2
}
P() { local c=$1; shift; docker exec -i "$c" psql -U postgres -X "$@"; }
load() {
  P "$1" -q <<SQL
CREATE EXTENSION vector;
CREATE TABLE items (id bigint PRIMARY KEY, embedding vector($DIM) NOT NULL);
SELECT setseed(0.42);
INSERT INTO items
SELECT g, (SELECT array_agg(random()::real - 0.5) FROM generate_series(1, $DIM) WHERE g > 0)::vector
FROM generate_series(1, $ROWS) g;
VACUUM ANALYZE items;
SQL
}
build() { # container mwm workers
  echo "--- maintenance_work_mem=$2 max_parallel_maintenance_workers=$3"
  P "$1" -v ON_ERROR_STOP=0 <<SQL 2>&1 | grep -vE '^(SET|DROP INDEX)$'
DROP INDEX IF EXISTS items_embedding_hnsw;
SET maintenance_work_mem = '$2';
SET max_parallel_maintenance_workers = $3;
\timing on
CREATE INDEX items_embedding_hnsw ON items USING hnsw (embedding vector_cosine_ops);
\timing off
SELECT pg_size_pretty(pg_relation_size('items_embedding_hnsw')) AS index_size;
SQL
}

echo "== container A: default /dev/shm (64MB)"
start pgv-shm64 64m
P pgv-shm64 -Atc "select version()"; P pgv-shm64 -Atc "select 'vector ' || extversion from pg_extension where extname='vector'" 2>/dev/null
docker exec pgv-shm64 df -h /dev/shm | tail -1
load pgv-shm64
P pgv-shm64 -c "select pg_size_pretty(pg_total_relation_size('items')) table_size, count(*) from items"
P pgv-shm64 -Atc "show maintenance_work_mem; show max_parallel_maintenance_workers"
build pgv-shm64 64MB 0
build pgv-shm64 1GB 0
build pgv-shm64 1GB 2

echo "== container B: /dev/shm 4GB"
start pgv-shm4g 4g
docker exec pgv-shm4g df -h /dev/shm | tail -1
load pgv-shm4g
build pgv-shm4g 64MB 2
build pgv-shm4g 1GB 2
build pgv-shm4g 1GB 4
build pgv-shm4g 1GB 8

echo "== progress phases during a build (sampled every 0.5s)"
P pgv-shm4g -q -c "drop index if exists items_embedding_hnsw" >/dev/null
( P pgv-shm4g -q -c "set maintenance_work_mem='64MB'; set max_parallel_maintenance_workers=0; create index items_embedding_hnsw on items using hnsw (embedding vector_cosine_ops)" >/dev/null 2>&1 ) &
BG=$!
while kill -0 $BG 2>/dev/null; do
  P pgv-shm4g -Atc "select to_char(clock_timestamp(),'HH24:MI:SS') || ' ' || phase || ' tuples ' || tuples_done || '/' || tuples_total || ' blocks ' || blocks_done || '/' || blocks_total from pg_stat_progress_create_index" 2>/dev/null
  sleep 0.5
done | awk '{k=$2" "$3" "$4; if (k!=last) print; last=k}' | head -20
echo "== done"
