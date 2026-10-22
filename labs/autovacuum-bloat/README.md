# Lab: autovacuum blocked by an idle-in-transaction session

Synthetic reproduction behind `/insights/postgresql-autovacuum-not-removing-dead-tuples`.
Every message and number on that page comes from `out-lab.txt` in this folder.

Run on 22 Oct 2026: PostgreSQL 18.6 from the `postgres:18` Docker image, laptop.
`autovacuum_naptime = 5s` and `log_autovacuum_min_duration = 0` so the lab runs in seconds.

## Steps the script runs

1. Create `accounts` (200,000 rows, 27 MB) and compute its autovacuum trigger point
2. Open a `REPEATABLE READ` session that runs one `SELECT` and stays idle in transaction
3. Update every row three times; read `pg_stat_user_tables` and the autovacuum log
4. Find the session through `pg_stat_activity`, `pg_prepared_xacts` and `pg_replication_slots`
5. Terminate it; read the next autovacuum log entry, table size and `pgstattuple`
6. Three more full updates with vacuum (space reuse), then `VACUUM FULL`
7. Per-table autovacuum settings

## Reproduce

```sh
docker run -d --name dd-lab-av --entrypoint sleep postgres:18 infinity
docker cp run-lab.sh dd-lab-av:/run-lab.sh
docker exec dd-lab-av bash /run-lab.sh > out-lab.txt 2>&1
docker rm -f dd-lab-av
```
