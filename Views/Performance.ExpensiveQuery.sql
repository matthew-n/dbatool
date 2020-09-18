CREATE VIEW [Performance].[ExpensiveQuery]
AS
WITH base AS(
	SELECT
		deqs.query_hash,
		deqs.query_plan_hash,
		deqs.plan_handle,
		deqs.sql_handle,
		deqs.statement_start_offset,
		deqs.statement_end_offset,
		deqs.execution_count,
		--Reads
		deqs.total_logical_reads AS LogicalReadTotal,
		ROW_NUMBER()OVER(ORDER BY total_logical_reads DESC, t1.pctOfLogicalReadsRange DESC) AS LogicalReadRank,
		100.0*deqs.total_logical_reads/SUM(deqs.total_logical_reads)OVER() AS LogicalReadPct,
		--CPU
		deqs.total_worker_time/1000.0 AS CPUTimeTotal,
		ROW_NUMBER()OVER(ORDER BY deqs.total_worker_time DESC, t1.pctOfCPUTimeRange DESC) AS CPUTimeRank,
		100.0*deqs.total_worker_time/SUM(deqs.total_worker_time)OVER() AS CPUTimePct,
		--RunTime
		deqs.total_elapsed_time AS RunTimeTotal,
		ROW_NUMBER()OVER(ORDER BY deqs.total_elapsed_time DESC, pctOfElapsedTimeRange DESC) AS RunTimeRank,
		100.0*deqs.total_elapsed_time/SUM(deqs.total_elapsed_time)OVER() RunTimePct
	FROM sys.dm_exec_query_stats AS deqs
	CROSS APPLY(
		SELECT
			((1.0*deqs.total_worker_time/deqs.execution_count)-deqs.min_worker_time)/NULLIF((deqs.max_worker_time-deqs.min_worker_time),0.0) AS pctOfCPUTimeRange,
			((1.0*deqs.total_logical_reads /deqs.execution_count)-deqs.min_logical_reads)/NULLIF((deqs.max_logical_reads-deqs.min_logical_reads),0.0) AS pctOfLogicalReadsRange,
			((1.0*deqs.total_elapsed_time /deqs.execution_count)-deqs.total_elapsed_time)/NULLIF((deqs.max_elapsed_time-deqs.total_elapsed_time),0.0) AS pctOfElapsedTimeRange
	) AS t1
	WHERE 
		deqs.execution_count >1
)
SELECT
	    GETDATE() AS SampleTime
	   ,wt.sql_handle
	   ,WT.query_hash
	   ,WT.plan_handle
	   ,WT.query_plan_hash
	   ,DB_NAME(deqp.dbid) AS [Database]
	   ,OBJECT_NAME(deqp.objectid,deqp.dbid) AS [Object]
	   ,ROW_NUMBER()OVER(PARTITION BY WT.query_hash ORDER BY WT.execution_count DESC) AS PlanCountByStmtHash
	   --Logical Reads Axis
	   ,WT.LogicalReadTotal
	   ,WT.LogicalReadRank
	   ,WT.LogicalReadPct
	   --CPU Time Axis
	   ,WT.CPUTimeTotal
	   ,WT.CPUTimeRank
	   ,WT.CPUTimePct
	   --RunTime Time Axis
	   ,WT.RunTimeTotal
	   ,WT.RunTimeRank
	   ,WT.RunTimePct
	   --Drill down info
	,SUBSTRING(dest.text, ( wt.statement_start_offset / 2 ) + 1, 
	( ( CASE wt.statement_end_offset
			WHEN -1 THEN DATALENGTH(dest.text)
			ELSE wt.statement_end_offset
		END - wt.statement_start_offset ) / 2 ) + 1) AS StatementText
FROM base AS WT
CROSS APPLY sys.dm_exec_sql_text(wt.sql_handle) AS dest
CROSS APPLY sys.dm_exec_query_plan(wt.plan_handle) AS deqp
WHERE
	wt.CPUTimeRank <=10 OR
	wt.LogicalReadRank<=10 OR
	wt.RunTimeRank <= 10

GO
