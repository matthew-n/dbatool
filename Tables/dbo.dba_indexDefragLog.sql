CREATE TABLE [dbo].[dba_indexDefragLog]
(
[indexDefrag_id] [int] NOT NULL IDENTITY(1, 1),
[databaseID] [int] NOT NULL,
[databaseName] [nvarchar] (128) NOT NULL,
[objectID] [int] NOT NULL,
[objectName] [nvarchar] (128) NULL,
[indexID] [int] NOT NULL,
[indexName] [nvarchar] (128) NULL,
[partitionNumber] [smallint] NOT NULL,
[fragmentation] [float] NOT NULL,
[page_count] [int] NOT NULL,
[dateTimeStart] [datetime] NOT NULL,
[dateTimeEnd] [datetime] NULL,
[durationSeconds] [int] NULL,
[sqlStatement] [varchar] (4000) NULL,
[errorMessage] [varchar] (1000) NULL
)
GO
ALTER TABLE [dbo].[dba_indexDefragLog] ADD CONSTRAINT [PK_indexDefragLog_v40] PRIMARY KEY CLUSTERED  ([indexDefrag_id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'History log only contains the information from the last execution', 'SCHEMA', N'dbo', 'TABLE', N'dba_indexDefragLog', NULL, NULL
GO
