-- Synthetic multi-tenant dataset (PostgreSQL 17).
-- 50 established tenants (ids 1..50):   40,000 orders each = 2,000,000 rows.
-- 20 small/new tenants   (ids 1001..1020):  60 orders each.
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  tenant_id   int           NOT NULL,
  status      text          NOT NULL,
  created_at  timestamptz   NOT NULL,
  amount      numeric(12,2) NOT NULL
);

SELECT setseed(0.42);

INSERT INTO orders (tenant_id, status, created_at, amount)
SELECT t,
       (ARRAY['open','paid','paid','paid','shipped'])[1 + floor(random()*5)::int],
       timestamptz '2025-10-01' + random() * interval '365 days',
       round((random()*500)::numeric, 2)
FROM generate_series(1, 50) t, generate_series(1, 40000);

INSERT INTO orders (tenant_id, status, created_at, amount)
SELECT t,
       (ARRAY['open','paid','paid','paid','shipped'])[1 + floor(random()*5)::int],
       timestamptz '2025-10-01' + random() * interval '365 days',
       round((random()*500)::numeric, 2)
FROM generate_series(1001, 1020) t, generate_series(1, 60);

-- Indexes in the "before" state.
CREATE INDEX orders_tenant_idx  ON orders (tenant_id);
CREATE INDEX orders_created_idx ON orders (created_at);
VACUUM ANALYZE orders;

-- Application role. The regression trigger in this lab: generic plans forced
-- for the app role (a setting sometimes applied to reduce planning CPU).
DROP ROLE IF EXISTS app;
CREATE ROLE app LOGIN;
GRANT SELECT ON orders TO app;
GRANT EXECUTE ON FUNCTION pg_stat_statements_reset(oid, oid, bigint, boolean) TO app;
