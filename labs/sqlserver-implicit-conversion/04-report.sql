USE convlab;
SET NOCOUNT ON;
GO
PRINT '=== Query Store runtime stats, 300 executions each';
SELECT LEFT(qt.query_sql_text, 90) AS query_text,
       SUM(rs.count_executions) AS execs,
       CAST(SUM(rs.avg_logical_io_reads*rs.count_executions)/SUM(rs.count_executions) AS decimal(12,1)) AS avg_logical_reads,
       CAST(SUM(rs.avg_cpu_time*rs.count_executions)/SUM(rs.count_executions)/1000.0 AS decimal(12,3)) AS avg_cpu_ms,
       CAST(SUM(rs.avg_duration*rs.count_executions)/SUM(rs.count_executions)/1000.0 AS decimal(12,3)) AS avg_duration_ms
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
WHERE qt.query_sql_text LIKE '%FROM dbo.accounts_%'
GROUP BY qt.query_sql_text
ORDER BY avg_logical_reads DESC;
GO
PRINT '=== Find plans with a PlanAffectingConvert warning in Query Store';
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
plans AS (
  SELECT p.plan_id, q.query_id, qt.query_sql_text, TRY_CONVERT(xml, p.query_plan) AS plan_xml
  FROM sys.query_store_plan p
  JOIN sys.query_store_query q ON q.query_id = p.query_id
  JOIN sys.query_store_query_text qt ON qt.query_text_id = q.query_text_id
),
warnings AS (
  SELECT pl.query_id, pl.plan_id, pl.query_sql_text,
         w.n.value('@ConvertIssue', 'varchar(40)') AS convert_issue,
         w.n.value('@Expression', 'nvarchar(400)') AS expression
  FROM plans pl
  CROSS APPLY pl.plan_xml.nodes('//Warnings/PlanAffectingConvert') AS w(n)
)
SELECT w.query_id, w.plan_id, LEFT(w.query_sql_text, 90) AS query_text,
       w.convert_issue, LEFT(w.expression, 90) AS expression,
       SUM(rs.count_executions) AS execs,
       CAST(MAX(rs.avg_logical_io_reads) AS bigint) AS avg_logical_reads
FROM warnings w
JOIN sys.query_store_runtime_stats rs ON rs.plan_id = w.plan_id
GROUP BY w.query_id, w.plan_id, w.query_sql_text, w.convert_issue, w.expression
ORDER BY avg_logical_reads DESC;
GO
