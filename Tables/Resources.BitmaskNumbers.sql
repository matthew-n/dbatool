CREATE TABLE [Resources].[BitmaskNumbers]
(
[Number] [smallint] NOT NULL,
[Byte] [int] NULL,
[BitValue] [int] NULL
)
GO
ALTER TABLE [Resources].[BitmaskNumbers] ADD CONSTRAINT [PK_BitmaskNumbers] PRIMARY KEY CLUSTERED  ([Number])
GO
