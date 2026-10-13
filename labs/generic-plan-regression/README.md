# Lab: forced generic plan on a multi-tenant query

Synthetic reproduction behind `/sample-report` and `/case-studies/lab-generic-plan-regression`.
Every number on those pages comes from the `out-*.txt` files in this folder.

Run on 13 Oct 2026: PostgreSQL 17.11 (`postgres:17` Docker image, `shared_buffers=512MB`), laptop, warm cache.

## Data

- `orders`: 2,001,200 rows (130 MB heap)
- 50 established tenants (ids 1–50), 40,000 orders each
- 20 small tenants (ids 1001–1020), 60 orders each
- Indexes at the start: `(tenant_id)` and `(created_at)`
- Workload: 98% of calls from established tenants, 2% from small tenants, sent as prepared statements by role `app`

## Reproduce

```sh
docker run -d --name dd-lab-plan -e POSTGRES_PASSWORD=lab postgres:17 \
  -c shared_preload_libraries=pg_stat_statements -c shared_buffers=512MB
for f in 01-setup.sql 02-plans.sql 03-stats.sql workload.pgbench; do docker cp $f dd-lab-plan:/tmp/; done
docker exec dd-lab-plan psql -U postgres -f /tmp/01-setup.sql
docker exec dd-lab-plan psql -U postgres -f /tmp/02-plans.sql          # out-02-plans.txt
docker exec dd-lab-plan psql -U postgres \
  -c "ALTER SYSTEM SET session_preload_libraries = 'auto_explain'" \
  -c "ALTER SYSTEM SET auto_explain.log_min_duration = '100ms'" \
  -c "SELECT pg_reload_conf()"
./run-workload.sh                                                      # run A
```

Then repeat `./run-workload.sh` for each scenario (`out-03-runs.txt`):

- **B:** `ALTER ROLE app SET plan_cache_mode = force_generic_plan;`
- **C:** B plus `CREATE INDEX orders_tenant_created_idx ON orders (tenant_id, created_at); ANALYZE orders;`
- **D:** `ALTER ROLE app RESET plan_cache_mode;` and drop the new index

`out-04-auto-explain-sample.txt` holds the auto_explain log from run B.
`out-05-after-index.txt` holds the index build time, the index size and the plans once the index exists.

## Findings worth knowing

- Under the default `plan_cache_mode = auto`, PostgreSQL 17 kept custom plans for this query, and small tenants stayed fast (run A). Two other data shapes tried during the lab didn't regress under `auto` either. The regression shows up when generic plans are forced.
- With generic plans forced, every auto_explain entry over 100 ms came from a small tenant (ids 1001–1020).
- These are absolute timings from a laptop. Use the relative change and the plan shapes, not the absolute numbers.
