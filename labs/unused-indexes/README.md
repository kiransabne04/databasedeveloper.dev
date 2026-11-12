# Lab: unused indexes on a primary and a streaming replica

Behind `/insights/postgresql-find-unused-indexes`. Every number on that page comes from `out-lab.txt` in this folder.

Run on 11 Nov 2026: PostgreSQL 18.6 (`postgres:18` image) on a laptop (Docker Desktop, arm64, 10 cores).
A primary and a streaming replica built with `pg_basebackup --checkpoint=fast`. `autovacuum = off`,
`max_parallel_workers_per_gather = 0`, `shared_buffers = 512MB`. Warm cache: the table fits in memory.

## Data

`orders`: 2,000,000 rows, `fillfactor = 90`, heap 164 MB. Indexes:

| Index | Definition | Size | Purpose in the test |
|---|---|---|---|
| `orders_pkey` | `(id)` | 43 MB | primary key |
| `orders_customer_idx` | `(customer_id)` | 14 MB | lookups on the primary |
| `orders_customer_dup_idx` | `(customer_id)` | 14 MB | exact duplicate |
| `orders_status_created_idx` | `(status, created_at)` | 65 MB | reporting, replica only |
| `orders_external_ref_uq` | unique `(external_ref)` | 60 MB | never read |
| `orders_updated_at_idx` | `(updated_at)` | 43 MB | never read; column changed by every update |

## Reproduce

```sh
./run-lab.sh > out-lab.txt 2>&1
```

## Results

| Check | Result |
|---|---|
| `idx_scan` for `orders_status_created_idx` | 0 on the primary, 200 on the replica (index-only scan) |
| Duplicates | Planner used `orders_customer_dup_idx` for all 500 lookups; its twin showed 0 |
| Filtered candidate query on the primary | 3 rows: `orders_status_created_idx`, `orders_updated_at_idx`, `orders_customer_idx` |
| 20,000 pgbench updates of `updated_at`, with `orders_updated_at_idx` | 0% HOT, 13,997 WAL bytes per update, 280 MB WAL, 1.386 ms average latency |
| Same, after `DROP INDEX CONCURRENTLY` | 100% HOT, 4,933 WAL bytes per update, 99 MB WAL, 0.584 ms |
| `DROP INDEX CONCURRENTLY` in `BEGIN` | `ERROR: DROP INDEX CONCURRENTLY cannot run inside a transaction block` |
| `DROP INDEX CONCURRENTLY` on a constraint's index | `ERROR: cannot drop index orders_ref_key because constraint orders_ref_key on table orders requires it` |
| Immediate shutdown (`pg_ctl -m immediate`) | `idx_scan` 500 to 0; `pg_stat_database.stats_reset` stayed null |
| Clean restart | `idx_scan` kept (3 before, 3 after) |

Each pgbench run started right after a `CHECKPOINT`. The counters were diffed, not reset, because `pg_stat_reset()`
also zeroes index counters. These are laptop numbers: use the ratios, not the absolute values.
