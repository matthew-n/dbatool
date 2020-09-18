CREATE TABLE [Resources].[mediumTally]
(
[N] [int] NOT NULL IDENTITY(1, 1)
)
GO
ALTER TABLE [Resources].[mediumTally] ADD CONSTRAINT [mediumTallyPK] PRIMARY KEY CLUSTERED  ([N])
GO
EXEC sp_addextendedproperty N'MS_Description', N'tally of 10K', 'SCHEMA', N'Resources', 'TABLE', N'mediumTally', NULL, NULL
GO
