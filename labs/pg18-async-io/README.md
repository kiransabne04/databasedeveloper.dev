# Lab: PostgreSQL 18 asynchronous I/O (io_method)

Synthetic reproduction behind `/insights/postgresql-18-async-io-io-method`.
Every plan line and number on that page comes from `out-lab.txt` in this folder.

Run on 27 Oct 2026: PostgreSQL 18.6 from the `postgres:18.6` Docker image, on a laptop
(10 cores, 16 GB RAM, Docker Desktop, local SSD). `shared_buffers = 256MB`,
`max_parallel_workers_per_gather = 0`, `track_io_timing = on`.

The container runs with `--privileged` so the script can drop the Linux page cache
between runs and so `io_uring` is allowed (Docker's default seccomp profile blocks it).
Docker Desktop runs Linux in a VM; dropping the guest page cache does not clear the
macOS host's cache of the VM disk, so "cold" reads here are faster than reads from
EBS or Aurora storage. The numbers show how to compare `io_method` settings, not
what they will do on RDS, Aurora or any other storage.

## Steps the script runs

1. Create `events` (8,000,000 rows, 1.2 GB) with an index on `account_id`
2. For `io_method` = `sync`, `worker`, `io_uring`, then `sync` again: restart,
   drop caches, one discarded run, one full plan, five timed cold runs of a
   sequential scan and a bitmap heap scan
3. `effective_io_concurrency` 1, 16, 64, 256 on the bitmap scan with `io_uring`
4. Sample `pg_aios` while a cold sequential scan runs with `io_method = worker`

## Reproduce

```sh
docker run -d --privileged --name dd-lab-aio --entrypoint sleep postgres:18.6 infinity
docker cp run-lab.sh dd-lab-aio:/run-lab.sh
docker exec dd-lab-aio bash /run-lab.sh > out-lab.txt 2>&1
docker rm -f dd-lab-aio
```
