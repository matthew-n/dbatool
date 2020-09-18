CREATE TABLE [dbo].[CommandLog]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DatabaseName] [sys].[sysname] NULL,
[SchemaName] [sys].[sysname] NULL,
[ObjectName] [sys].[sysname] NULL,
[ObjectType] [char] (2) NULL,
[IndexName] [sys].[sysname] NULL,
[IndexType] [tinyint] NULL,
[StatisticsName] [sys].[sysname] NULL,
[PartitionNumber] [int] NULL,
[ExtendedInfo] [xml] NULL,
[Command] [nvarchar] (max) NOT NULL,
[CommandType] [nvarchar] (60) NOT NULL,
[StartTime] [datetime] NOT NULL,
[EndTime] [datetime] NULL,
[ErrorNumber] [int] NULL,
[ErrorMessage] [nvarchar] (max) NULL
)
GO
ALTER TABLE [dbo].[CommandLog] ADD CONSTRAINT [PK_CommandLog] PRIMARY KEY CLUSTERED  ([ID])
GO
