-- Synthetic table for the DDL lock-queue lab (PostgreSQL 17).
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  tenant_id   int           NOT NULL,
  status      text          NOT NULL,
  created_at  timestamptz   NOT NULL,
  amount      numeric(12,2) NOT NULL
);
INSERT INTO orders (tenant_id, status, created_at, amount)
SELECT (random()*100)::int, 'paid',
       timestamptz '2025-10-01' + random() * interval '365 days',
       round((random()*500)::numeric, 2)
FROM generate_series(1, 200000);
VACUUM ANALYZE orders;
