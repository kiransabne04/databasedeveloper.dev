export const capabilities = [
  {
    name: 'PostgreSQL',
    eyebrow: 'Primary',
    href: '/postgresql-performance-investigation',
    description: 'Workload-level performance investigations across plans, locks, connections, indexing, vacuum/statistics and production regressions.'
  },
  {
    name: 'SQL Server',
    eyebrow: 'Secondary',
    href: '/sql-server-performance',
    description: 'Query Store, plan regressions, blocking, parameter sensitivity, indexing and ORM-sensitive workload reviews.'
  },
  {
    name: 'pgvector',
    eyebrow: 'AI + database',
    href: '/pgvector-performance',
    description: 'HNSW/IVFFlat trade-offs, filtering, latency/recall, memory, index builds and hybrid vector + relational workloads.'
  },
  {
    name: 'Snowflake',
    eyebrow: 'Analytical',
    href: '/snowflake-performance',
    description: 'Query history, warehouse sizing, pruning/spills, clustering, concurrency and cost/performance investigations.'
  },
  {
    name: 'OLAP / Big Data',
    eyebrow: 'Analytical',
    href: '/olap-analytical-performance',
    description: 'Large analytical SQL, partitioning, skew, scan amplification, distributed joins and workload-isolation trade-offs.'
  }
] as const;
