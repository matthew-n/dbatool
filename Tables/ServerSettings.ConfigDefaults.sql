CREATE TABLE [ServerSettings].[ConfigDefaults]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[dbVersion] [int] NOT NULL,
[property] [nvarchar] (35) NULL,
[default_value] [sql_variant] NULL
)
GO
ALTER TABLE [ServerSettings].[ConfigDefaults] ADD CONSTRAINT [PK_ConfigDefaults] PRIMARY KEY CLUSTERED  ([ID])
GO
ALTER TABLE [ServerSettings].[ConfigDefaults] ADD CONSTRAINT [NK_ConfigDefaults] UNIQUE NONCLUSTERED  ([dbVersion], [property])
GO
EXEC sp_addextendedproperty N'MS_Description', N'reference table with the defaults from BOL', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigDefaults', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Just a reminder about the product version this default belongs to', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigDefaults', 'COLUMN', N'dbVersion'
GO
EXEC sp_addextendedproperty N'MS_Description', N'default value as found on BOL', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigDefaults', 'COLUMN', N'default_value'
GO
EXEC sp_addextendedproperty N'MS_Description', N'this is the same value as the name field in the sys.configurations view', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigDefaults', 'COLUMN', N'property'
GO
EXEC sp_addextendedproperty N'MS_Description', N'(not used) used a longer natural key in case a go add historical values.', 'SCHEMA', N'ServerSettings', 'TABLE', N'ConfigDefaults', 'CONSTRAINT', N'NK_ConfigDefaults'
GO
