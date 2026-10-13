#!/bin/sh
# Usage: ./run-workload.sh [container]
# Resets pg_stat_statements, runs 30s of prepared-statement load as role "app", prints statement stats.
C=${1:-dd-lab-plan}
docker exec "$C" psql -U postgres -qAtc "SELECT pg_stat_statements_reset()" >/dev/null
docker exec "$C" pgbench -U app -n -M prepared -c 4 -j 4 -T 30 -f /tmp/workload.pgbench postgres 2>&1 | grep -E "^(latency average|tps|number of transactions actually)"
docker exec "$C" psql -U postgres -f /tmp/03-stats.sql
