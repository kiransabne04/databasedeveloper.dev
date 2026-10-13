# Lab: DDL lock queue behind an idle transaction

Synthetic reproduction behind `/case-studies/lab-lock-queue`.
Every number on that page comes from the `out-*.txt` files in this folder.

Run on 13 Oct 2026: PostgreSQL 17.11 (`postgres:17` Docker image, default settings), laptop.

## Setup

- `orders`: 200,000 rows
- 8 pgbench clients run primary-key reads for 40 s
- `run-scenario.sh` drives this timeline:

| t (s) | Event |
|---|---|
| 0 | Readers start |
| 5 | A session runs `BEGIN; SELECT … FROM orders` and then sits idle in transaction (holds `AccessShareLock`) |
| 10 | `ALTER TABLE orders ADD COLUMN note text` is issued |
| 14 | Blocking-chain and `pg_locks` snapshot (`02-blocking-chain.sql`) |
| 25 | The idle transaction commits |
| 40 | Readers stop |

## Reproduce

```sh
docker run -d --name dd-lab-lock -e POSTGRES_PASSWORD=lab postgres:17
for f in 01-setup.sql readers.pgbench 02-blocking-chain.sql; do docker cp $f dd-lab-lock:/tmp/; done
docker exec dd-lab-lock psql -U postgres -f /tmp/01-setup.sql
./run-scenario.sh dd-lab-lock "" out-A-no-timeout.txt
./run-scenario.sh dd-lab-lock "SET lock_timeout = '2s';" out-B-lock-timeout.txt
```

## Results

- **A, no `lock_timeout`:** the DDL waited 14.96 s. Reader throughput was 0 tps from t=11 to t=24. All 8 readers were blocked by the DDL's queued `AccessExclusiveLock` request, not by the idle transaction directly. The run processed 3.91M reads.
- **B, `lock_timeout = '2s'`:** the DDL failed after 2.01 s with `canceling statement due to lock timeout`. Readers recovered by t=13. The run processed 5.51M reads.

These are absolute timings from a laptop. Use the shape of the timeline, not the absolute numbers.
