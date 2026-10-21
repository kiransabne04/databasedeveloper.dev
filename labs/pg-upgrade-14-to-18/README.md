# Lab: pg_upgrade from PostgreSQL 14 to 18

Synthetic reproduction behind `/insights/pg-upgrade-check-failures` and
`/insights/postgresql-upgrade-logical-replication-slots`.
Every message and number on those pages comes from `out-lab.txt` in this folder.

Run on 21 Oct 2026: PostgreSQL 14.24 and 18.6 from the `postgres:18` Docker image
(PGDG Debian packages), laptop. Self-managed `pg_upgrade --link`, not RDS or Aurora.

## What the PG14 cluster contains

- `orders`: 500,000 rows, analyzed, with one extended statistics object
- `wal_level = logical`, publication `cdc_pub`, logical slot `debezium_orders` (`pgoutput`)
- Two upgrade blockers: a `regproc` column in `job_hooks`, and an open prepared transaction
- PG14 initdb defaults, so data checksums are off

## Steps the script runs

1. `pg_upgrade --check` against a PG18 cluster created with initdb defaults (checksums on)
2. Same check against a cluster created with `--no-data-checksums`
3. Roll back the prepared transaction, check again
4. Convert the `regproc` column to `text`, check again (passes with the slot still present)
5. `pg_upgrade --link`, start PG18, inspect slots, publications and statistics
6. `vacuumdb --all --analyze-in-stages --missing-stats-only`

## Reproduce

```sh
docker run -d --name dd-lab-upgrade --entrypoint sleep postgres:18 infinity
docker cp run-lab.sh dd-lab-upgrade:/run-lab.sh
docker exec dd-lab-upgrade bash /run-lab.sh > out-lab.txt 2>&1
docker rm -f dd-lab-upgrade
```

The script installs `postgresql-14` from the PGDG repository already configured in the image.
