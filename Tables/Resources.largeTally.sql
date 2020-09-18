CREATE TABLE [Resources].[largeTally]
(
[N] [int] NOT NULL IDENTITY(1, 1)
)
GO
ALTER TABLE [Resources].[largeTally] ADD CONSTRAINT [largeTallyPK] PRIMARY KEY CLUSTERED  ([N])
GO
EXEC sp_addextendedproperty N'MS_Description', N'tally of 1M ', 'SCHEMA', N'Resources', 'TABLE', N'largeTally', NULL, NULL
GO
