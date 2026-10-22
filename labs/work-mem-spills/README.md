# Lab: work_mem and temp file spills

Synthetic reproduction behind `/insights/postgresql-work-mem-temp-file-spills`.
Every plan line and number on that page comes from `out-lab.txt` in this folder.

Run on 22 Oct 2026: PostgreSQL 18.6 from the `postgres:18` Docker image, on a laptop
(10 cores, 16 GB RAM, Docker Desktop). `max_parallel_workers_per_gather = 0` to keep
plans simple, `log_temp_files = 0` to log every temp file.

Timings are from one machine with temp files likely served from the OS page cache.
They show how to measure, not what spills cost on RDS, Aurora or any other storage.

## Steps the script runs

1. Create `orders` (2,000,000 rows) and `customers` (500,000 rows)
2. A full sort, a hash aggregate and a hash join at the default `work_mem` (4 MB)
3. Read the server log, `pg_stat_statements` and `pg_stat_database` for the spills
4. The same queries with `SET LOCAL work_mem = '256MB'`
5. The hash aggregate at 16, 32 and 64 MB
6. `ALTER ROLE ... SET work_mem` for a reporting role
7. An index that removes the sort for `ORDER BY ... LIMIT 50`
8. Five timed runs of each query at 4 MB and 256 MB

## Reproduce

```sh
docker run -d --name dd-lab-wm --entrypoint sleep postgres:18 infinity
docker cp run-lab.sh dd-lab-wm:/run-lab.sh
docker exec dd-lab-wm bash /run-lab.sh > out-lab.txt 2>&1
docker rm -f dd-lab-wm
```
