# Lab: pgvector HNSW build time, parallel workers and /dev/shm

Behind `/insights/pgvector-hnsw-index-build-slow`. Every number on that page comes from the output files in this folder.

Run on 11 Nov 2026: `pgvector/pgvector:0.8.7-pg18` (PostgreSQL 18.6, pgvector 0.8.7) on a laptop, Docker Desktop
with 10 CPUs and 8 GB of memory. `shared_buffers = 1GB`, `max_worker_processes = 16`, `max_parallel_workers = 16`.

Data: `items(id bigint, embedding vector(768))`, 100,000 rows of `random() - 0.5` (seeded). Heap 5,888 kB (736 pages),
TOAST 391 MB. Index `USING hnsw (embedding vector_cosine_ops)` with default `m = 16`, `ef_construction = 64`; 391 MB.
The `vector` type has `typstorage = e` (EXTERNAL), checked separately with
`select typname, typstorage::text from pg_type where typname in ('vector','halfvec')` (both `e`).

## Scripts

| Script | Output | What it does |
|---|---|---|
| `run-lab.sh` | `out-lab.txt` | Builds with `maintenance_work_mem` 64MB and 1GB and 0 to 8 requested workers, in a container with the default 64MB `/dev/shm` and one with 4GB |
| `check-workers.sh` | `out-workers.txt` | Samples `pg_stat_activity` for parallel workers and `docker stats` CPU during builds |
| `check-toast.sh` | `out-toast.txt` | Heap vs TOAST size, then builds with the `parallel_workers` reloption set; one attempt with 64MB `/dev/shm`. Its `typstorage` line failed in the recorded run (missing `::text` cast, fixed since) |

## Results

| `maintenance_work_mem` | Workers requested | Workers started | `/dev/shm` | Time |
|---|---|---|---|---|
| 64MB | 0 | 0 | 64MB | 9:04.2 (NOTICE after 17,697 tuples) |
| 64MB | 2 | 0 | 4GB | 11:49.2 (NOTICE after 17,702 tuples) |
| 1GB | 0 | 0 | 64MB / 4GB | 1:58.7, 1:36.5, 1:44.9 |
| 1GB | 2, 4, 8 (no reloption) | 0 | 64MB / 4GB | 2:01.0, 1:45.6, 1:54.7, 1:52.1, 1:32.8, 2:01.9 |
| 1GB | 2 + `parallel_workers = 2` | 2 (302% CPU) | 4GB | 0:53.0 |
| 1GB | 4 + `parallel_workers = 4` | 4 (503% CPU) | 4GB | 1:09.8 |
| 1GB | 8 + `parallel_workers = 8` | 8 (970% CPU) | 4GB | 1:13.7 |
| 1GB | 2 + `parallel_workers = 2` | — | 64MB | `ERROR: could not resize shared memory segment "/PostgreSQL.323454400" to 1070632480 bytes: No space left on device` |

Without the reloption, no workers started because the 736-page heap is below `min_parallel_table_scan_size` (8MB).
Random vectors are a hard case for graph construction; use the ratios, not the absolute times.
