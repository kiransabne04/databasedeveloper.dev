#!/usr/bin/env bash
# Runs inventory.sql against PostgreSQL 14 with a few seeded findings.
# Usage: ./run-lab.sh > out-lab.txt 2>&1
set -euo pipefail
docker rm -f pg14-inv >/dev/null 2>&1 || true
docker run -d --name pg14-inv -e POSTGRES_PASSWORD=lab postgres:14 \
  -c wal_level=logical -c vacuum_defer_cleanup_age=1000 >/dev/null
until docker exec pg14-inv pg_isready -U postgres -q; do sleep 1; done; sleep 2
docker exec -i pg14-inv psql -U postgres -X -q -v ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION pg_stat_statements; CREATE EXTENSION pgcrypto;
SET password_encryption = 'md5'; CREATE ROLE legacy_app LOGIN PASSWORD 'x';
SELECT pg_create_logical_replication_slot('debezium', 'pgoutput') \gset
CREATE FUNCTION nightly_backup_start() RETURNS void LANGUAGE sql AS $$ SELECT pg_start_backup('nightly') $$;
SQL
docker cp inventory.sql pg14-inv:/tmp/inventory.sql
docker exec pg14-inv psql -U postgres -X -f /tmp/inventory.sql
docker rm -f pg14-inv >/dev/null

echo "== PostgreSQL 18: the flagged function restores but fails when called; MD5 warns"
docker rm -f pg18-inv >/dev/null 2>&1 || true
docker run -d --name pg18-inv -e POSTGRES_PASSWORD=lab postgres:18 >/dev/null
until docker exec pg18-inv pg_isready -U postgres -q; do sleep 1; done; sleep 2
docker exec -i pg18-inv psql -U postgres -X <<'SQL' 2>&1
SELECT version();
SET check_function_bodies = off;  -- what pg_dump/pg_upgrade restores use
CREATE FUNCTION nightly_backup_start() RETURNS void LANGUAGE sql AS $$ SELECT pg_start_backup('nightly') $$;
SELECT nightly_backup_start();
SET password_encryption = 'md5';
CREATE ROLE legacy_app LOGIN PASSWORD 'x';
SQL
docker rm -f pg18-inv >/dev/null
