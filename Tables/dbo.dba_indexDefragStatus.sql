CREATE TABLE [dbo].[dba_indexDefragStatus]
(
[databaseID] [int] NOT NULL,
[databaseName] [nvarchar] (128) NOT NULL,
[objectID] [int] NOT NULL,
[indexID] [int] NOT NULL,
[partitionNumber] [smallint] NOT NULL,
[fragmentation] [float] NOT NULL,
[page_count] [int] NOT NULL,
[range_scan_count] [bigint] NOT NULL,
[schemaName] [nvarchar] (128) NULL,
[objectName] [nvarchar] (128) NULL,
[indexName] [nvarchar] (128) NULL,
[scanDate] [datetime] NOT NULL,
[defragDate] [datetime] NULL,
[printStatus] [bit] NOT NULL CONSTRAINT [DF__dba_index__print__70698DE3] DEFAULT ((0)),
[exclusionMask] [int] NOT NULL CONSTRAINT [DF__dba_index__exclu__715DB21C] DEFAULT ((0))
)
GO
ALTER TABLE [dbo].[dba_indexDefragStatus] ADD CONSTRAINT [PK_indexDefragStatus_v40] PRIMARY KEY CLUSTERED  ([databaseID], [objectID], [indexID], [partitionNumber])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Temporary data for the current execution of the proc is stored here', 'SCHEMA', N'dbo', 'TABLE', N'dba_indexDefragStatus', NULL, NULL
GO
