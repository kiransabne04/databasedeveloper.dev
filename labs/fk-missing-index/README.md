# Lab: unindexed foreign keys and slow parent deletes

Synthetic reproduction behind `/insights/postgresql-foreign-key-index-slow-delete`.
Every plan line and number on that page comes from `out-lab.txt` in this folder.

Run on 4 Nov 2026: PostgreSQL 18.6 from the `postgres:18` Docker image, on a laptop
(10 cores, 16 GB RAM, Docker Desktop). `max_parallel_workers_per_gather = 0` to keep
plans simple. Warm cache: the tables fit in memory, so every sequential scan is a
memory scan. On larger tables or network storage each scan costs more.

## Data

- `customers`: 100,000 rows
- `orders`: 2,000,000 rows (115 MB), `customer_id` references `customers ON DELETE CASCADE`, 20 orders per customer
- `order_items`: 4,000,000 rows (230 MB), `order_id` references `orders ON DELETE CASCADE`, 2 items per order
- `audit_notes`: 500,000 rows (25 MB), `customer_id` references `customers` (NO ACTION), only for customers 90001–100000; it has an index on `(created_at, customer_id)`, which does not serve the foreign key
- No index on any referencing column at the start

## Steps the script runs

1. List foreign keys with no index whose leading columns are the key columns
2. `EXPLAIN ANALYZE` deletes of 1 and 10 customers, rolled back
3. A delete of a customer with no orders and no notes
4. `pg_stat_user_tables` sequential scan counters
5. `pg_stat_statements` with `track = top` (default) and `track = all`
6. `auto_explain` with `log_nested_statements = on`
7. Locks held by a delete in progress
8. `CREATE INDEX CONCURRENTLY` on the three referencing columns, then the same deletes
9. Five timed single-customer deletes with and without the indexes

## Reproduce

```sh
docker run -d --name dd-lab-fk --entrypoint sleep postgres:18 infinity
docker cp run-lab.sh dd-lab-fk:/run-lab.sh
docker exec dd-lab-fk bash /run-lab.sh > out-lab.txt 2>&1
docker rm -f dd-lab-fk
```

The full run took about 70 seconds.
