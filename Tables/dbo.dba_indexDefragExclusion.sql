CREATE TABLE [dbo].[dba_indexDefragExclusion]
(
[databaseID] [int] NOT NULL,
[databaseName] [nvarchar] (128) NOT NULL,
[objectID] [int] NOT NULL,
[objectName] [nvarchar] (128) NOT NULL,
[indexID] [int] NOT NULL,
[indexName] [nvarchar] (128) NOT NULL,
[exclusionMask] [int] NOT NULL
)
GO
ALTER TABLE [dbo].[dba_indexDefragExclusion] ADD CONSTRAINT [PK_indexDefragExclusion_v40] PRIMARY KEY CLUSTERED  ([databaseID], [objectID], [indexID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'List of exclusion rules for automated index defrag utility', 'SCHEMA', N'dbo', 'TABLE', N'dba_indexDefragExclusion', NULL, NULL
GO
