# Snapshot script lab

Runs `public/snapshot/walstack-snapshot.sql` (v1.2) against disposable `postgres:13` to `postgres:18` Docker containers. The data is generated (20,000 customers, 200,000 orders). No real database is involved.

```bash
./run-lab.sh > out-lab.txt 2>&1          # all versions
VERSIONS="14 18" ./run-lab.sh            # a subset
```

## Scenarios per version

| Scenario | What it checks |
| --- | --- |
| A | Login with `pg_monitor` and default switches. The script exits 0 with no stderr. A credential literal recorded by `pg_stat_statements` is replaced with a placeholder. |
| B | Login without `pg_monitor`. The script still completes, prints a warning at the top, and the affected fields show `<insufficient privilege>`. |
| C | `-v show_query_text=off -v show_schema=off` on the command line. No query text and no column listing. |
| D | Database without the `pg_stat_statements` extension. Sections 6–7 print an "unavailable" line and the rest runs. |
| E | Another session holds `ACCESS EXCLUSIVE` on `orders`. Statements that need a lock on that table are cancelled after the 1-second `lock_timeout`. The script finishes in about 4–5 seconds and does not hang or join the lock queue for long. |
| F | No session from the script is left idle in transaction. |

## Result (22 November 2026, `out-lab.txt`)

- All 30 runs (6 versions × A–E) exited 0.
- On every version from 13 to 18, `pg_stat_statements` stored `ALTER ROLE app_login PASSWORD '…'` with the literal password. The v1.1 script would have printed it if the statement was among the top 50 by total time. v1.2 prints `[omitted by script: text mentions a credential]` instead and keeps the timing row.
- With the table locked, 4 statements per version hit `lock_timeout` and the script finished in 4–5 seconds.

## Not tested here

- Amazon RDS and Aurora PostgreSQL. The script excludes `rdsadmin` from the size query and uses only views and functions that RDS documents for `pg_monitor`. It has not been run on a managed instance as part of this lab. Run it on a non-production RDS or Aurora instance before claiming compatibility from evidence.
- Catalogs with tens of thousands of tables. The size ordering in sections 8 and 9 calls `pg_total_relation_size` for every user table. The 10-second `statement_timeout` bounds this, and a timed-out section is skipped.
- psql clients older than the server. `\if` and `:{?var}` require psql 10 or newer.
