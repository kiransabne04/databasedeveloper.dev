# Lab: PostgreSQL 14 end-of-life inventory

Behind `/postgresql-14-eol`. Every output quoted on that page comes from `out-lab.txt` in this folder.

Run on 11 Nov 2026 on a laptop (Docker, arm64):

- PostgreSQL 14.24 (`postgres:14` image)
- PostgreSQL 18.6 (`postgres:18` image)

## What it does

1. Starts PostgreSQL 14 with `wal_level=logical` and `vacuum_defer_cleanup_age=1000`.
2. Seeds one finding for each check: `pg_stat_statements` and `pgcrypto`, a role with an MD5 password, a `pgoutput` logical slot named `debezium`, and a SQL function that calls `pg_start_backup`.
3. Runs `inventory.sql`, the read-only script published in the article.
4. On PostgreSQL 18, creates the same function with `check_function_bodies = off` (the setting pg_dump output uses), calls it, and sets an MD5 password.

## Reproduce

```sh
./run-lab.sh > out-lab.txt 2>&1
```

## Results

| Check | PostgreSQL 14.24 result |
|---|---|
| Logical slots | `debezium`, `pgoutput`, inactive |
| Removed settings | `vacuum_defer_cleanup_age = 1000`, source `command line` |
| Removed functions | `public.nightly_backup_start` (sql) |
| MD5 roles | `legacy_app` |

On PostgreSQL 18.6, `CREATE FUNCTION` succeeded and the first call failed with
`ERROR: function pg_start_backup(unknown) does not exist`. Setting an MD5 password printed
`WARNING: setting an MD5-encrypted password` with a deprecation `DETAIL`, and the role was created.

Check 6 reads `pg_authid`, which needs a superuser. It does not work on RDS, Aurora or Azure.
