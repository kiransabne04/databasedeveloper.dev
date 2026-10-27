# Lab: upgrading pgvector 0.8.6 to 0.8.7

Reproduction behind `/insights/pgvector-087-cve-upgrade`. Every output line on that
page comes from `out-lab.txt` in this folder. The lab does not reproduce the
CVE-2026-103484 buffer overflow; it shows how to check versions, what the upgrade
does to existing indexes, and which roles could build an index.

Run on 27 Oct 2026: PostgreSQL 18.6 from the `pgvector/pgvector:0.8.6-pg18` and
`pgvector/pgvector:0.8.7-pg18` Docker images, sharing one data directory on a Docker
volume, the same as upgrading the package on a self-managed server.

## Steps the script runs

1. `before` (0.8.6 image): create `items` (100,000 rows, 64 dimensions) with IVFFlat
   and HNSW indexes; list installed and available versions
2. `after` (0.8.7 image, same data directory): the package is new but the extension
   in the database is still 0.8.6; query through the IVFFlat index
3. `ALTER EXTENSION vector UPDATE TO '0.8.7'`, index validity, the same query, and
   the exact answer without vector indexes
4. List login roles that can create tables, and the tables with vector columns they own
5. The `public` schema ACL on a new PostgreSQL 18 cluster

## Reproduce

```sh
for phase in before after; do
  image=pgvector/pgvector:0.8.6-pg18
  [ $phase = after ] && image=pgvector/pgvector:0.8.7-pg18
  docker run -d --name dd-lab-pgv -v dd-pgv-work:/work --entrypoint sleep $image infinity
  docker cp run-lab.sh dd-lab-pgv:/run-lab.sh
  docker exec dd-lab-pgv bash /run-lab.sh $phase
  docker rm -f dd-lab-pgv
done > out-lab.txt 2>&1
docker volume rm dd-pgv-work
```
