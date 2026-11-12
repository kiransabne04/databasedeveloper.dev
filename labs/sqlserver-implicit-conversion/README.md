# Lab: SQL Server implicit conversion, nvarchar parameter against a varchar index

Behind `/insights/sql-server-implicit-conversion-nvarchar-varchar`. Every plan line and number on that page comes from `out-lab.txt` in this folder.

Run on 11 Nov 2026: SQL Server 2022 RTM-CU27 (16.0.4295.3), Developer Edition, `mcr.microsoft.com/mssql/server:2022-latest`,
x86-64 under emulation on an arm64 laptop (Docker Desktop). Server collation `SQL_Latin1_General_CP1_CI_AS`, compatibility level 160.
Because of the emulation, CPU and duration figures are inflated; compare logical reads.

## Data

Three tables with the same 1,000,000 rows (`email = 'user<n>@example.com'`), each with a nonclustered index on `email`:

| Table | `email` column |
|---|---|
| `accounts_sqlcoll` | `varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS` |
| `accounts_wincoll` | `varchar(100) COLLATE Latin1_General_CI_AS` |
| `accounts_nvarchar` | `nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS` |

## Reproduce

```sh
docker run -d --name mssql-lab --platform linux/amd64 -e ACCEPT_EULA=Y \
  -e 'MSSQL_SA_PASSWORD=Lab_Passw0rd!' mcr.microsoft.com/mssql/server:2022-latest
./run-lab.sh > out-lab.txt 2>&1
```

## Results

| Case | Parameter | Plan | Logical reads |
|---|---|---|---|
| A | `nvarchar(4000)` against the SQL-collation `varchar` column | Index Scan, `CONVERT_IMPLICIT(nvarchar(100), email)` | 4,484 |
| B | `varchar(100)`, same column | Index Seek | 6 |
| C | `nvarchar(4000)` against the Windows-collation `varchar` column | `GetRangeThroughConvert` then Index Seek | 6 |
| D | `varchar(100)` against the `nvarchar` column | Index Seek, parameter converted | 6 |
| E | `nvarchar(4000)` with `CAST(@e AS varchar(100))` in the query | Index Seek | 6 |

Query Store, 300 executions each: A averaged 4,484 reads and 86.7 ms CPU, C 6 reads and 0.13 ms, B 6 reads and 0.11 ms.
The `PlanAffectingConvert` query returned only case A, with `ConvertIssue = "Seek Plan"`.

`CAST(N'zoë.ł@example.com' AS varchar(100))` returned `zoë.l@example.com`; `CAST(N'用户@example.com' AS varchar(100))` returned `??@example.com`.

`sqlcmd` runs with `-I` (`QUOTED_IDENTIFIER ON`). Without it, the Query Store XML query fails with Msg 1934.
