
CREATE PROCEDURE [ServerCache].[FindPhysicalOperators]

(@op VARCHAR(30))

AS

	SET QUOTED_IDENTIFIER ON
	SET ANSI_NULLS ON
	SET ANSI_PADDING ON
	SET ANSI_WARNINGS ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	SET NOCOUNT ON;

	SELECT
		DB_NAME (st.[dbid]) AS [DBName],
		CAST(REPLACE(st.[text], CHAR(13), ' ') AS VARCHAR(8000)) AS text,
		qs.Execution_Count,
		qs.last_execution_time,
		qs.total_worker_time,
		qs.total_elapsed_time,
		qs.total_logical_reads,
		qs.total_logical_writes,
		CAST(REPLACE(CAST(p.query_plan AS VARCHAR(MAX)), CHAR(13), ' ') AS VARCHAR(8000)) AS query_plan
		--,qs.*, p.*  -- add these back in if you want a lot more data
	FROM sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_sql_text (sql_handle) AS st
	CROSS APPLY sys.dm_exec_query_plan (plan_handle) AS p
	WHERE query_plan.exist ('
		  declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";
		  /ShowPlanXML/BatchSequence/Batch/Statements//RelOp/@PhysicalOp[. = sql:variable("@op")]') = 1
	AND st.[dbid] != 4
	ORDER BY qs.Execution_Count DESC
	OPTION(RECOMPILE, MAXDOP 1);

RETURN;

GO
