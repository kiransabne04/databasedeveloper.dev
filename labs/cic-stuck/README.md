# Lab: CREATE INDEX CONCURRENTLY waits, failures and recovery

Synthetic reproduction for the draft article "CREATE INDEX CONCURRENTLY Stuck? Diagnose, Recover, and Deploy Safely in PostgreSQL".
Every claim in this README comes from `out-pg17.txt` or `out-pg18.txt` in this folder.

Run on 9 Nov 2026, on a laptop (Docker, arm64, default settings, `maintenance_work_mem = 64MB`):

- PostgreSQL 17.11 (`postgres:17` image)
- PostgreSQL 18.6 (`postgres:18` image)

The two versions behaved the same in every scenario. The outputs differ only in PIDs, timings and how often the sampler caught short phases.

## Setup

`01-setup.sql` creates these tables:

| Table | Size | Contents |
|---|---|---|
| `orders` | 3,000,000 rows, 449 MB | Columns `payload` (64-char text) and `external_ref` (`'ref-' \|\| id`), with `tenant_id = id % 1000` |
| `t2` | 3,000,000 rows, 377 MB | |
| `unrelated_table` | 1,000 rows | |
| `orders_p` | 3 range partitions of 1,000,000 rows each | |

`writer.pgbench` runs single-row updates on `orders` during every scenario, from 2 clients at a combined 100 transactions/s.

`run-lab.sh` drives each scenario using background `psql` sessions, tagged by `application_name`. It polls `pg_stat_progress_create_index` every ~0.1 s. Each build of `orders(payload)` took 4–10 s, and up to 25 s when it was held up by a waiting session.

## Reproduce

```sh
docker run -d --name cic-lab-18 -e POSTGRES_PASSWORD=lab postgres:18
docker cp 01-setup.sql cic-lab-18:/tmp/ && docker cp writer.pgbench cic-lab-18:/tmp/
docker exec cic-lab-18 psql -U postgres -f /tmp/01-setup.sql
./run-lab.sh cic-lab-18 out-pg18.txt
```

Repeat the same steps with `postgres:17`.

## Results

| ID | Scenario | Result (PG 17 and 18) |
|---|---|---|
| L1 | Baseline build | Phases logged in order: `building index: scanning table`, `sorting live tuples`, `loading tuples in tree`, then `index validation: scanning index`, `scanning table`. The waiting phases passed too quickly to sample, apart from one brief wait on a pgbench writer in the PG 17 run. The index finished valid. |
| L2a | Writer left `idle in transaction` before the build | Phase `waiting for writers before build`, `lockers 0/1`, with `current_locker_pid` = the idle session. `pg_stat_activity.wait_event` = `Lock:virtualxid`. `pg_locks` shows an ungranted `virtualxid` `ShareLock` alongside the granted `ShareUpdateExclusiveLock` on `orders`. `pg_blocking_pids(build)` returns the idle session. |
| L2b | `REPEATABLE READ` transaction that read only `unrelated_table`, opened after the build started, then left idle | The build waited in `waiting for old snapshots` with `current_locker_pid` = that session, until it ended. The build took 25.0 s, against 5 s with no blocker. |
| L2b-rc | The same, but in `READ COMMITTED` | `backend_xmin` was null, and the build was not held up by that session. |
| L2c | Two expression-index builds started together, on `orders` and `t2` | Neither waited on the other in this run. Both took 9.6 s and neither showed a locker. The documented cross-table wait was **not** reproduced. |
| L3a | Cancel during `waiting for writers before build` | `ERROR: canceling statement due to user request`. Index left with `indisvalid = f`, `indisready = f`, 0 bytes. |
| L3b | Cancel during `building index` | Same as L3a: invalid, not ready, 0 bytes. |
| L3c | Cancel during `waiting for old snapshots` | Invalid, **`indisready = t`, 273 MB**. |
| L3d | `statement_timeout = 2s` during the writer wait | `ERROR: canceling statement due to statement timeout` after 2.0 s. Invalid, not ready. |
| L4a | `lock_timeout = 2s` during the writer wait | `ERROR: canceling statement due to lock timeout` after 2.0 s. Invalid, not ready. |
| L4b | `lock_timeout = 2s` during the old-snapshot wait | `ERROR: canceling statement due to lock timeout`. Invalid, **ready, 273 MB**. |
| L5 | Build waiting for its own `SHARE UPDATE EXCLUSIVE` lock, held by another session | **No row in `pg_stat_progress_create_index`** while it waited. `pg_stat_activity` showed `active`, `Lock:relation`. `pg_locks` showed an ungranted `ShareUpdateExclusiveLock`, and `pg_blocking_pids` returned the lock holder. |
| L6 | `CREATE INDEX CONCURRENTLY IF NOT EXISTS` where an invalid index with that name already exists | `NOTICE: relation "orders_ext_idx" already exists, skipping`, then `CREATE INDEX`, with psql exit code 0 under `ON_ERROR_STOP=1`. The index stayed invalid. `REINDEX INDEX CONCURRENTLY` then made it valid. |
| L7a | Unique build with a duplicate already in the table (fails in the first scan) | `ERROR: could not create unique index … Key … is duplicated.` Index invalid, **not ready**, 0 bytes. A later duplicate insert **succeeded**, so this failed index did not enforce uniqueness. |
| L7b | Unique build with a duplicate inserted during the first scan (fails in validation) | `ERROR: duplicate key value violates unique constraint "orders_tenant_ref_uq"`. Index invalid, **ready**, 90 MB. After the failure it **rejected** a duplicate of an existing key and a newly inserted duplicate pair. The planner did not use it (Seq Scan, even with `enable_seqscan = off`). `DROP INDEX CONCURRENTLY` succeeded. |
| L7c | `ALTER TABLE … ADD CONSTRAINT … UNIQUE USING INDEX` | Took **`AccessExclusiveLock` on `orders`**. NOTICE: the index is renamed to the constraint name. `DROP INDEX CONCURRENTLY` on the constraint's index fails with `cannot drop index … because constraint … requires it`. |
| L8 | `CREATE INDEX CONCURRENTLY` inside `BEGIN` | `ERROR: CREATE INDEX CONCURRENTLY cannot run inside a transaction block` |
| L9 | Partitioned parent | `ERROR: cannot create index on partitioned table "orders_p" concurrently`. With concurrent builds on each partition first (about 1.0–1.2 s each), the parent `CREATE INDEX` took about 2 ms and attached all three, with no duplicate indexes. `DROP INDEX CONCURRENTLY` on the parent index fails: `cannot drop partitioned index … concurrently`. |
| L11a | `REINDEX INDEX CONCURRENTLY` cancelled during `building index` | Left `orders_payload_idx_ccnew`: invalid, not ready, 0 bytes. The original index stayed valid. |
| L11b | `REINDEX INDEX CONCURRENTLY` held in `waiting for readers before marking dead` by an idle reader, then cancelled | Left `orders_payload_idx_ccold`: invalid, **ready, 273 MB**. The rebuilt index was valid under the original name. `DROP INDEX CONCURRENTLY … _ccold` succeeded once the reader had ended. |
| L10 | RDS master user terminating another role's session | **Not run**: no RDS instance was used. |

## What the results add to the documentation

- **Not every invalid index costs write overhead.** In these runs, a build that failed before its first scan finished left an invalid index with `indisready = f` and no data. A build that failed after that point left `indisready = t`, a full-size index, and, for a unique index, uniqueness enforcement. The documentation says a failed build "will still consume update overhead" and that a unique build is enforced from the second scan onward. Check `indisready` to tell which case you have.
- **The progress view can be empty while the build is blocked.** A build waiting for its own table lock had no progress row. Look in `pg_stat_activity` and `pg_blocking_pids` instead.
- **The transaction waits are lock-manager waits.** They show as `Lock:virtualxid`. They appear in `pg_blocking_pids`, and `lock_timeout` cancels them.

These are laptop timings. Use the order of events, not the absolute numbers.
