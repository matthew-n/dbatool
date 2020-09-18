CREATE TABLE [ServerSettings].[ConfigChangeReason]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[property] [nvarchar] (35) NOT NULL,
[new_value] [sql_variant] NOT NULL,
[reason] [varchar] (8000) NULL,
[author] [sys].[sysname] NOT NULL CONSTRAINT [DF_ValueChangeReasonAuthor] DEFAULT (suser_sname()),
[effectiveDate] [datetime2] NOT NULL CONSTRAINT [DF_ValueChangeReasonDate] DEFAULT (getdate()),
[expiredDate] [datetime2] NULL
)
GO
ALTER TABLE [ServerSettings].[ConfigChangeReason] ADD CONSTRAINT [PK_ValueChangeReason] PRIMARY KEY CLUSTERED  ([ID])
GO
ALTER TABLE [ServerSettings].[ConfigChangeReason] ADD CONSTRAINT [NK_ValueChangeReason] UNIQUE NONCLUSTERED  ([effectiveDate], [property])
GO
EXEC sp_addextendedproperty N'MS_Description', N'running log of changes to server cofigurations', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'server login for the user making the change', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', 'COLUMN', N'author'
GO
EXEC sp_addextendedproperty N'MS_Description', N'when have added the new value', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', 'COLUMN', N'effectiveDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'when the value was over ridden', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', 'COLUMN', N'expiredDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'the value you are updating to', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', 'COLUMN', N'new_value'
GO
EXEC sp_addextendedproperty N'MS_Description', N'server setting you are chaning', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', 'COLUMN', N'property'
GO
EXEC sp_addextendedproperty N'MS_Description', N'describe the pourpose of the change', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', 'COLUMN', N'reason'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Natural key for this log', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigChangeReason', 'CONSTRAINT', N'NK_ValueChangeReason'
GO
