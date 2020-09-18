CREATE TABLE [Performance].[ExpensiveQueryHistory]
(
[ID] [int] NOT NULL IDENTITY(-2147483648, 1),
[SampleTime] [datetime] NOT NULL,
[sql_handle] [varbinary] (64) NOT NULL,
[query_hash] [binary] (8) NOT NULL,
[plan_handle] [varbinary] (64) NOT NULL,
[query_plan_hash] [binary] (8) NOT NULL,
[Database] [nvarchar] (128) NULL,
[Object] [nvarchar] (128) NULL,
[PlanCountByStmtHash] [bigint] NULL,
[LogicalReadTotal] [bigint] NOT NULL,
[LogicalReadRank] [bigint] NULL,
[LogicalReadPct] [numeric] (38, 15) NULL,
[CPUTimeTotal] [numeric] (26, 6) NULL,
[CPUTimeRank] [bigint] NULL,
[CPUTimePct] [numeric] (38, 15) NULL,
[RunTimeTotal] [bigint] NOT NULL,
[RunTimeRank] [bigint] NULL,
[RunTimePct] [numeric] (38, 15) NULL,
[StatementText] [nvarchar] (max) NULL
)
GO
