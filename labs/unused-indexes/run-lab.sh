#!/usr/bin/env bash
# Unused-index lab: primary + streaming replica on PostgreSQL 18.
# Usage: ./run-lab.sh > out-lab.txt 2>&1
set -euo pipefail
IMG=${IMG:-postgres:18}
NET=uidx-net
docker rm -f uidx-primary uidx-replica >/dev/null 2>&1 || true
docker network rm $NET >/dev/null 2>&1 || true
docker network create $NET >/dev/null

docker run -d --name uidx-primary --network $NET -e POSTGRES_PASSWORD=lab \
  -e POSTGRES_HOST_AUTH_METHOD=trust "$IMG" \
  -c wal_level=replica -c max_wal_senders=5 -c shared_buffers=512MB \
  -c max_parallel_workers_per_gather=0 -c autovacuum=off >/dev/null
until docker exec uidx-primary pg_isready -U postgres -q; do sleep 1; done
sleep 2
docker exec uidx-primary bash -c 'echo "host replication all all trust" >> "$PGDATA/pg_hba.conf"'
docker exec uidx-primary psql -U postgres -qAtc "select pg_reload_conf()" >/dev/null
P() { docker exec -i uidx-primary psql -U postgres -X -v ON_ERROR_STOP=1 "$@"; }
R() { docker exec -i uidx-replica psql -U postgres -X -v ON_ERROR_STOP=1 "$@"; }

echo "== version"; P -Atc "select version()"
P -q <<'SQL'
CREATE TABLE orders (
  id          bigint PRIMARY KEY,
  customer_id int NOT NULL,
  status      text NOT NULL,
  external_ref text NOT NULL,
  created_at  timestamptz NOT NULL,
  updated_at  timestamptz NOT NULL,
  note        text
) WITH (fillfactor = 90);
INSERT INTO orders
SELECT g, g % 50000,
       (ARRAY['new','paid','shipped','refunded'])[1 + g % 4],
       'ref-' || g,
       now() - (g || ' seconds')::interval,
       now() - (g || ' seconds')::interval,
       NULL
FROM generate_series(1, 2000000) g;
CREATE INDEX orders_customer_idx      ON orders (customer_id);           -- used on primary
CREATE INDEX orders_customer_dup_idx  ON orders (customer_id);           -- exact duplicate
CREATE INDEX orders_status_created_idx ON orders (status, created_at);   -- replica-only reporting
CREATE UNIQUE INDEX orders_external_ref_uq ON orders (external_ref);     -- constraint, never scanned
CREATE INDEX orders_updated_at_idx    ON orders (updated_at);            -- unused, on a hot-updated column
VACUUM ANALYZE orders;
CREATE EXTENSION pg_stat_statements;
SQL
echo "== sizes"; P -c "select indexrelid::regclass as index, pg_size_pretty(pg_relation_size(indexrelid)) size from pg_index where indrelid='orders'::regclass order by 1"

echo "== create replica"
docker run -d --name uidx-replica --network $NET -e POSTGRES_PASSWORD=lab --entrypoint bash "$IMG" \
  -c 'rm -rf /var/lib/postgresql/18/docker/* && gosu postgres pg_basebackup -h uidx-primary -U postgres -D /var/lib/postgresql/18/docker -R -X stream --checkpoint=fast && exec gosu postgres postgres -D /var/lib/postgresql/18/docker -c max_parallel_workers_per_gather=0 -c hot_standby=on' >/dev/null
for i in $(seq 1 300); do docker exec uidx-replica pg_isready -U postgres -q 2>/dev/null && break; sleep 1; done
R -Atc "select 'in_recovery=' || pg_is_in_recovery()"

echo "== workload: primary point lookups by customer_id (500x)"
for i in $(seq 1 500); do echo "select count(*) from orders where customer_id = $((i*37 % 50000));"; done | P -q >/dev/null
echo "== workload: replica reporting query (200x)"
for i in $(seq 1 200); do echo "select count(*) from orders where status = 'refunded' and created_at > now() - interval '$((i % 7 + 1)) hours';"; done | R -q >/dev/null
echo "== replica plan"; R -c "explain (costs off) select count(*) from orders where status='refunded' and created_at > now() - interval '3 hours'"

STATQ="select s.indexrelname as index, s.idx_scan, s.last_idx_scan is not null as has_last_scan, i.indisunique as uniq, pg_size_pretty(pg_relation_size(s.indexrelid)) as size from pg_stat_user_indexes s join pg_index i using (indexrelid) where s.relname='orders' order by s.indexrelname"
echo "== pg_stat_user_indexes on PRIMARY"; P -c "$STATQ"
echo "== pg_stat_user_indexes on REPLICA"; R -c "$STATQ"

echo "== candidate query on primary"
P <<'SQL'
SELECT s.schemaname, s.relname AS table_name, s.indexrelname AS index_name,
       s.idx_scan, s.last_idx_scan,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       i.indisunique, i.indisprimary,
       (SELECT string_agg(c.conname, ', ') FROM pg_constraint c WHERE c.conindid = s.indexrelid) AS backs_constraint,
       (SELECT stats_reset FROM pg_stat_database WHERE datname = current_database()) AS db_stats_reset
FROM pg_stat_user_indexes s
JOIN pg_index i USING (indexrelid)
WHERE s.idx_scan = 0
ORDER BY pg_relation_size(s.indexrelid) DESC;
SQL

echo "== filtered candidates (article query) on primary"
P <<'SQL'
SELECT s.schemaname, s.relname AS table_name, s.indexrelname AS index_name,
       s.idx_scan, s.last_idx_scan,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size
FROM pg_stat_user_indexes AS s
JOIN pg_index AS i USING (indexrelid)
WHERE s.idx_scan = 0
  AND i.indisvalid
  AND NOT i.indisunique
  AND NOT i.indisprimary
  AND NOT i.indisexclusion
  AND NOT EXISTS (SELECT 1 FROM pg_constraint AS c WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;
SQL
echo "== how old are these counters"
P -c "SELECT pg_postmaster_start_time() AS server_started, d.stats_reset AS db_stats_reset FROM pg_stat_database d WHERE d.datname = current_database()"
echo "== duplicate index check"
P <<'SQL'
SELECT indrelid::regclass AS table_name,
       array_agg(indexrelid::regclass ORDER BY indexrelid) AS same_definition,
       pg_size_pretty(sum(pg_relation_size(indexrelid))) AS combined_size
FROM pg_index
GROUP BY indrelid, indkey::text, indclass::text, indcollation::text,
         indoption::text, coalesce(pg_get_expr(indexprs, indrelid), ''),
         coalesce(pg_get_expr(indpred, indrelid), '')
HAVING count(*) > 1;
SQL

echo "== write cost: pgbench updates of updated_at WITH orders_updated_at_idx"
cat > /tmp/uidx-upd.sql <<'EOF2'
\set id random(1, 2000000)
UPDATE orders SET updated_at = now() WHERE id = :id;
EOF2
docker cp /tmp/uidx-upd.sql uidx-primary:/tmp/upd.sql
bench() {
  # Diff counters instead of resetting them: pg_stat_reset() would also zero the index counters.
  P -qc "checkpoint" >/dev/null
  read U0 H0 <<<"$(P -Atc "select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname='orders'" | tr '|' ' ')"
  W0=$(P -Atc "select wal_bytes from pg_stat_wal")
  docker exec uidx-primary pgbench -U postgres -n -c 4 -j 4 -t 5000 -f /tmp/upd.sql postgres | grep -E 'latency average'
  sleep 2
  read U1 H1 <<<"$(P -Atc "select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname='orders'" | tr '|' ' ')"
  W1=$(P -Atc "select wal_bytes from pg_stat_wal")
  echo "updates=$((U1-U0)) hot_updates=$((H1-H0)) hot_pct=$(( 100*(H1-H0)/(U1-U0) )) wal_bytes=$((W1-W0)) wal_bytes_per_update=$(( (W1-W0)/(U1-U0) ))"
  P -Atc "select 'orders heap size=' || pg_size_pretty(pg_relation_size('orders'))"
}
bench
echo "== DROP INDEX CONCURRENTLY orders_updated_at_idx (definition saved first)"
P -Atc "select pg_get_indexdef('orders_updated_at_idx'::regclass)"
P -c "drop index concurrently orders_updated_at_idx"
P -qc "vacuum orders" >/dev/null
echo "== write cost WITHOUT orders_updated_at_idx"
bench

echo "== DROP INDEX CONCURRENTLY inside transaction"
P -c "begin; drop index concurrently orders_customer_dup_idx; commit;" || true
echo "== dropping the unique index that backs nothing vs a constraint"
P -c "alter table orders add constraint orders_ref_key unique using index orders_external_ref_uq" 
P -c "drop index concurrently orders_ref_key" || true

echo "== stats after immediate shutdown (crash-like)"
P -Atc "select 'before: orders_customer_dup_idx idx_scan=' || idx_scan from pg_stat_user_indexes where indexrelname='orders_customer_dup_idx'"
docker exec uidx-primary gosu postgres pg_ctl -D /var/lib/postgresql/18/docker -m immediate stop >/dev/null 2>&1 || true
sleep 3; docker start uidx-primary >/dev/null 2>&1 || true
until docker exec uidx-primary pg_isready -U postgres -q 2>/dev/null; do sleep 1; done; sleep 1
P -Atc "select 'after immediate stop: orders_customer_dup_idx idx_scan=' || coalesce(idx_scan::text,'null') from pg_stat_user_indexes where indexrelname='orders_customer_dup_idx'"
P -Atc "select 'db stats_reset=' || coalesce(stats_reset::text,'null') || ' postmaster_start=' || pg_postmaster_start_time() from pg_stat_database where datname=current_database()"
echo "== clean restart"
for i in 1 2 3; do echo "select count(*) from orders where customer_id = $i;"; done | P -q >/dev/null
sleep 2
P -Atc "select 'before clean restart: orders_customer_dup_idx idx_scan=' || idx_scan from pg_stat_user_indexes where indexrelname='orders_customer_dup_idx'"
docker restart uidx-primary >/dev/null; until docker exec uidx-primary pg_isready -U postgres -q 2>/dev/null; do sleep 1; done; sleep 1
P -Atc "select 'after clean restart: orders_customer_dup_idx idx_scan=' || idx_scan from pg_stat_user_indexes where indexrelname='orders_customer_dup_idx'"
echo "== done"
