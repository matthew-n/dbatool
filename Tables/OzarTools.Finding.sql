CREATE TABLE [OzarTools].[Finding]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[CheckID] [smallint] NOT NULL,
[PRIORITY] [tinyint] NOT NULL,
[FindingsGroup] [varchar] (80) NOT NULL,
[Finding] [varchar] (500) NOT NULL,
[URL] [varchar] (500) NULL
)
GO
ALTER TABLE [OzarTools].[Finding] ADD CONSTRAINT [PK__Checks__3214EC271E38E682] PRIMARY KEY CLUSTERED  ([ID])
GO
ALTER TABLE [OzarTools].[Finding] ADD CONSTRAINT [NK_OzarToolsChecks] UNIQUE NONCLUSTERED  ([CheckID], [Finding])
GO
