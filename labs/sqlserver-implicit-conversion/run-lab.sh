#!/usr/bin/env bash
# Usage: ./run-lab.sh > out-lab.txt 2>&1
# Needs a container named mssql-lab:
#   docker run -d --name mssql-lab --platform linux/amd64 -e ACCEPT_EULA=Y \
#     -e 'MSSQL_SA_PASSWORD=Lab_Passw0rd!' mcr.microsoft.com/mssql/server:2022-latest
set -euo pipefail
C=${C:-mssql-lab}
SQL() { docker exec -i "$C" /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P 'Lab_Passw0rd!' -I -W -s '|' "$@"; }
for f in 01-setup.sql 02-plans.sql 03-workload.sql 04-report.sql; do
  echo "##### $f"; docker cp "$f" "$C:/tmp/$f"
  if [ "$f" = 03-workload.sql ]; then SQL -i "/tmp/$f" >/dev/null; echo "(workload result sets discarded)"; else SQL -i "/tmp/$f"; fi
done
