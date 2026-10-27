#!/bin/bash
# Runs as root in two containers that share the data directory on a volume:
# `run-lab.sh before` in pgvector/pgvector:0.8.6-pg18, then `run-lab.sh after`
# in pgvector/pgvector:0.8.7-pg18, the same as upgrading the package on a server.
# Shows how to find the installed and available pgvector versions, who can build
# an IVFFlat index, and what ALTER EXTENSION ... UPDATE does to existing indexes.
# It does not reproduce CVE-2026-103484.
set -u
PHASE=${1:-before}
BIN=/usr/lib/postgresql/18/bin
W=/work
step() { printf '\n==== %s ====\n' "$1"; }

mkdir -p $W && chown postgres $W
cd $W
as_pg() { su postgres -c "cd $W && $*"; }
PSQL="$BIN/psql -h $W -p 5432 -U postgres -X -q"
start() { as_pg "$BIN/pg_ctl -D $W/data -l $W/server.log -w start >/dev/null"; }
stop() { as_pg "$BIN/pg_ctl -D $W/data -w stop >/dev/null"; }

if [ "$PHASE" = before ]; then
as_pg "$BIN/initdb -D $W/data -U postgres >/dev/null"
cat >> $W/data/postgresql.conf <<'EOF'
unix_socket_directories = '/work'
listen_addresses = ''
EOF
start

step "pgvector 0.8.6 installed: build a table with IVFFlat and HNSW indexes"
as_pg "$PSQL" <<'EOF'
SELECT version();
CREATE EXTENSION vector;
CREATE TABLE items (id bigint PRIMARY KEY, tenant_id int NOT NULL, embedding vector(64) NOT NULL);
INSERT INTO items
SELECT g, g % 50, (SELECT array_agg(sin(g * 0.001 * d + d)::real)::vector FROM generate_series(1, 64) d)
FROM generate_series(1, 100000) g;
CREATE INDEX items_ivf ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
CREATE INDEX items_hnsw ON items USING hnsw (embedding vector_cosine_ops);
ANALYZE items;
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
EOF

step "Which pgvector versions this server can install"
as_pg "$PSQL" <<'EOF'
SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';
EOF

stop
exit 0
fi

step "Same data directory, server now has the pgvector 0.8.7 package"
start
as_pg "$PSQL" <<'EOF'
SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';
SELECT version FROM pg_available_extension_versions WHERE name = 'vector' AND version LIKE '0.8.%' ORDER BY version;
EOF

step "Index checks before ALTER EXTENSION (new library, old catalog version)"
as_pg "$PSQL" <<'EOF'
SET enable_seqscan = off;
EXPLAIN (COSTS OFF) SELECT id FROM items ORDER BY embedding <-> (SELECT embedding FROM items WHERE id = 42) LIMIT 5;
SELECT id FROM items ORDER BY embedding <-> (SELECT embedding FROM items WHERE id = 42) LIMIT 5;
EOF

step "ALTER EXTENSION vector UPDATE"
as_pg "$PSQL" <<'EOF'
\timing on
ALTER EXTENSION vector UPDATE TO '0.8.7';
\timing off
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
SELECT indexrelid::regclass AS index, indisvalid, indisready FROM pg_index WHERE indrelid = 'items'::regclass;
SET enable_seqscan = off;
SELECT id FROM items ORDER BY embedding <-> (SELECT embedding FROM items WHERE id = 42) LIMIT 5;
-- Exact answer without the vector indexes, to compare
SET enable_indexscan = off; SET enable_seqscan = on;
SELECT id FROM items ORDER BY embedding <-> (SELECT embedding FROM items WHERE id = 42) LIMIT 5;
EOF

step "Who could build an IVFFlat index: roles that can create tables somewhere"
as_pg "$PSQL" <<'EOF'
CREATE ROLE app_rw LOGIN;
CREATE ROLE analyst LOGIN;
GRANT USAGE ON SCHEMA public TO analyst;
GRANT SELECT, INSERT, UPDATE, DELETE ON items TO app_rw;
GRANT USAGE ON SCHEMA public TO app_rw;
-- Roles that own a table with a vector column, or can create a table in any schema
SELECT r.rolname,
       r.rolsuper,
       (SELECT string_agg(n.nspname, ', ') FROM pg_namespace n
         WHERE n.nspname NOT LIKE 'pg\_%' AND n.nspname <> 'information_schema'
           AND has_schema_privilege(r.oid, n.oid, 'CREATE')) AS can_create_in,
       (SELECT string_agg(DISTINCT c.relname, ', ') FROM pg_class c JOIN pg_attribute a ON a.attrelid = c.oid
         JOIN pg_type t ON t.oid = a.atttypid
         WHERE c.relowner = r.oid AND c.relkind IN ('r', 'p') AND t.typname IN ('vector', 'halfvec', 'sparsevec')) AS owns_vector_tables
FROM pg_roles r
WHERE r.rolcanlogin
ORDER BY 1;
EOF

step "public schema ACL on a new PostgreSQL 18 cluster: no CREATE for PUBLIC"
as_pg "$PSQL" <<'EOF'
SELECT nspname, nspacl FROM pg_namespace WHERE nspname = 'public';
EOF
