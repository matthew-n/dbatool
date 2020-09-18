CREATE TABLE [ServerSettings].[PermissionHistory]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[principal_id] [int] NOT NULL,
[major_id] [int] NOT NULL CONSTRAINT [DF_PermissionHisotryMajorID] DEFAULT ((0)),
[minor_id] [int] NOT NULL CONSTRAINT [DF_PermissionHisotryMinorID] DEFAULT ((0)),
[permissions_name] [nvarchar] (128) NOT NULL,
[state_desc] [nvarchar] (60) NOT NULL,
[jiraItem] [varchar] (10) NULL,
[Reason] [varchar] (8000) NOT NULL,
[author] [sys].[sysname] NOT NULL CONSTRAINT [DF_PermissionHistoryAuthor] DEFAULT (suser_sname()),
[effectiveDate] [datetime2] NOT NULL CONSTRAINT [DF_PermissionsHistoryDate] DEFAULT (getdate()),
[expiredDate] [datetime2] NULL
)
GO
ALTER TABLE [ServerSettings].[PermissionHistory] ADD CONSTRAINT [PK_PermissionHistory] PRIMARY KEY CLUSTERED  ([id])
GO
