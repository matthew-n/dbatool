CREATE TABLE [OzarTools].[BlitzChecksToSkip]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ServerName] [nvarchar] (128) NULL,
[DatabaseName] [nvarchar] (128) NULL,
[FindingID] [int] NULL,
[BusinessOperation] [varchar] (800) NULL,
[Reason] [varchar] (8000) NULL
)
GO
ALTER TABLE [OzarTools].[BlitzChecksToSkip] ADD CONSTRAINT [PK_SettingsBlitzCheckToSkip] PRIMARY KEY CLUSTERED  ([ID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Document overrides to Brents best practices with business process and reason', 'SCHEMA', N'OzarTools', 'TABLE', N'BlitzChecksToSkip', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Name of the business operation that cases the violation', 'SCHEMA', N'OzarTools', 'TABLE', N'BlitzChecksToSkip', 'COLUMN', N'BusinessOperation'
GO
EXEC sp_addextendedproperty N'MS_Description', N'if the exection needs a database scope', 'SCHEMA', N'OzarTools', 'TABLE', N'BlitzChecksToSkip', 'COLUMN', N'DatabaseName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Joins to findings to get Brent''s CheckID to skip', 'SCHEMA', N'OzarTools', 'TABLE', N'BlitzChecksToSkip', 'COLUMN', N'FindingID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'detailed information about how that process needs this execption.', 'SCHEMA', N'OzarTools', 'TABLE', N'BlitzChecksToSkip', 'COLUMN', N'Reason'
GO
EXEC sp_addextendedproperty N'MS_Description', N'the server the rule applies to incase we centralize this.', 'SCHEMA', N'OzarTools', 'TABLE', N'BlitzChecksToSkip', 'COLUMN', N'ServerName'
GO
