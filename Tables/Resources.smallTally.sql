CREATE TABLE [Resources].[smallTally]
(
[N] [int] NOT NULL IDENTITY(1, 1)
)
GO
ALTER TABLE [Resources].[smallTally] ADD CONSTRAINT [smallTallyPK] PRIMARY KEY CLUSTERED  ([N])
GO
EXEC sp_addextendedproperty N'MS_Description', N'tally of 1K', 'SCHEMA', N'Resources', 'TABLE', N'smallTally', NULL, NULL
GO
