# Lab: transaction ID wraparound warning, stop and recovery

Synthetic reproduction behind `/insights/postgresql-transaction-id-wraparound`.
Every message and number on that page comes from `out-lab.txt` in this folder.

Run on 22 Oct 2026: PostgreSQL 18.6 from the `postgres:18` Docker image, laptop.

**Lab shortcut:** the script uses `pg_resetwal -x` to move the next transaction ID
to 2,120,000,000 and then 2,145,000,000 instead of consuming 2 billion transactions.
It writes a zeroed `pg_xact` segment for each new ID. Never run `pg_resetwal` on a
database you care about. Everything after the jump is normal server behavior.

## Steps the script runs

1. Create two small tables and leave a prepared transaction (`xa-ledger-42`) open
2. Jump to 2,120,000,000: read ages and the warning on the next write
3. Let anti-wraparound autovacuum run; try `VACUUM (FREEZE, VERBOSE)`
4. List every blocker type with one query
5. Jump to 2,145,000,000: a write fails, a read works
6. `ROLLBACK PREPARED`, `VACUUM`, `vacuumdb --all`; ages and a write afterwards

## Reproduce

```sh
docker run -d --name dd-lab-xid --entrypoint sleep postgres:18 infinity
docker cp run-lab.sh dd-lab-xid:/run-lab.sh
docker exec dd-lab-xid bash /run-lab.sh > out-lab.txt 2>&1
docker rm -f dd-lab-xid
```
