
CREATE VIEW [Audit].[DatabaseUserPermissions]
	( UserName
	,UserType
	,DatabaseUserName
	,Role
	,PermissionType
	,PermissionState
	,ObjectType
	,ObjectName
	,ColumnName )
AS
--List all access provisioned to a sql user or windows user/group directly 
SELECT
	[UserName] = CASE princ.[type]
				   WHEN 'S' THEN princ.[name]
				   WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
				 END
   ,[UserType] = CASE princ.[type]
				   WHEN 'S' THEN 'SQL User'
				   WHEN 'U' THEN 'Windows User'
				   WHEN 'G' THEN 'Windows Group'
				 END
   ,[DatabaseUserName] = princ.[name]
   ,[Role] = NULL
   ,[PermissionType] = perm.[permission_name]
   ,[PermissionState] = perm.[state_desc]
   ,[ObjectType] = CASE perm.class
					 WHEN 3 THEN perm.[class_desc]
					 WHEN 0 THEN perm.[class_desc]
					 ELSE obj.type_desc
				   END
   ,[ObjectName] = CASE perm.class
					 WHEN 3 THEN SCHEMA_NAME(perm.major_id)
					 ELSE OBJECT_NAME(perm.major_id)
				   END
   ,[ColumnName] = col.[name]
FROM
	sys.database_principals princ
LEFT JOIN sys.login_token ulogin
ON	princ.[sid] = ulogin.[sid]
LEFT JOIN sys.database_permissions perm
ON	perm.[grantee_principal_id] = princ.[principal_id]
LEFT JOIN sys.columns col
ON	col.[object_id] = perm.major_id AND
	col.[column_id] = perm.[minor_id]
LEFT JOIN sys.objects obj
ON	perm.[major_id] = obj.[object_id]
LEFT JOIN sys.schemas AS S
ON	s.schema_id = perm.[major_id] AND
	perm.minor_id = 0 AND
	perm.class = 3
WHERE
	princ.[type] IN ( 'S', 'U', 'G' ) --and charindex('_admin',princ.name)>0
UNION
--List all access provisioned to a sql user or windows user/group through a database or application role
SELECT
	[UserName] = CASE memberprinc.[type]
				   WHEN 'S' THEN memberprinc.[name]
				   WHEN 'U' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
				 END
   ,[UserType] = CASE memberprinc.[type]
				   WHEN 'S' THEN 'SQL User'
				   WHEN 'U' THEN 'Windows User'
				   WHEN 'G' THEN 'Windows Group'
				 END
   ,[DatabaseUserName] = memberprinc.[name]
   ,[Role] = roleprinc.[name]
   ,[PermissionType] = perm.[permission_name]
   ,[PermissionState] = perm.[state_desc]
   ,[ObjectType] = CASE perm.class
					 WHEN 3 THEN perm.[class_desc]
					 WHEN 0 THEN perm.[class_desc]
					 ELSE obj.type_desc
				   END
   ,[ObjectName] = CASE perm.class
					 WHEN 3 THEN SCHEMA_NAME(perm.major_id)
					 WHEN 0 THEN perm.[class_desc]
					 ELSE OBJECT_NAME(perm.major_id)
				   END
   ,[ColumnName] = col.[name]
FROM
	sys.database_role_members members
JOIN sys.database_principals roleprinc
ON	roleprinc.[principal_id] = members.[role_principal_id]
JOIN sys.database_principals memberprinc
ON	memberprinc.[principal_id] = members.[member_principal_id]
LEFT JOIN sys.login_token ulogin
ON	memberprinc.[sid] = ulogin.[sid]
LEFT JOIN sys.database_permissions perm
ON	perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN sys.columns col
ON	col.[object_id] = perm.major_id AND
	col.[column_id] = perm.[minor_id]
LEFT JOIN sys.objects obj
ON	perm.[major_id] = obj.[object_id]
--where  charindex('_admin',memberprinc.[name])>0 and roleprinc.[name] like 'db[_]%'
UNION
--List all access provisioned to the public role, which everyone gets by default
SELECT
	[UserName] = '{All Users}'
   ,[UserType] = '{All Users}'
   ,[DatabaseUserName] = '{All Users}'
   ,[Role] = roleprinc.[name]
   ,[PermissionType] = perm.[permission_name]
   ,[PermissionState] = perm.[state_desc]
   ,[ObjectType] = CASE perm.class
					 WHEN 3 THEN perm.[class_desc]
					 ELSE obj.type_desc
				   END
   ,[ObjectName] = CASE perm.class
					 WHEN 3 THEN SCHEMA_NAME(perm.major_id)
					 ELSE OBJECT_NAME(perm.major_id)
				   END
   ,[ColumnName] = col.[name]
FROM
	sys.database_principals roleprinc
LEFT JOIN sys.database_permissions perm
ON	perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN sys.columns col
ON	col.[object_id] = perm.major_id AND
	col.[column_id] = perm.[minor_id]
JOIN sys.objects obj
ON	obj.[object_id] = perm.[major_id]
WHERE
	--Only roles
	roleprinc.[type] = 'R' AND
	--Only public role
    roleprinc.[name] = 'public' AND
	--Only objects of ours, not the MS objects
    obj.is_ms_shipped = 0

GO
EXEC sp_addextendedproperty N'MS_Description', N'Security Audit Report
1) List all access provisioned to a sql user or windows user/group directly 
2) List all access provisioned to a sql user or windows user/group through a database or application role
3) List all access provisioned to the public role', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Name of the column of the object that the user/role is assigned permissions on. This value is only populated if the object is a table, view or a table value function.  ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'ColumnName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Name of the associated user as defined in the database user account.  The database user may not be the same as the server user. ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'DatabaseUserName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Name of the object that the user/role is assigned permissions on. This value may not be populated for all roles.  Some built in roles have implicit permission definitions. ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'ObjectName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Type of object the user/role is assigned permissions on.  Examples could include USER_TABLE,  SQL_SCALAR_FUNCTION, SQL_INLINE_TABLE_VALUED_FUNCTION, SQL_STORED_PROCEDURE, VIEW, etc. This value may not be populated for all roles.  Some built in roles have implicit permission definitions.           ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'ObjectType'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Reflects the state of the permission type, examples could include GRANT, DENY, etc. This value may not be populated for all roles.  Some built in roles have implicit permission definitions. ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'PermissionState'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Type of permissions the user/role has on an object. Examples could include CONNECT, EXECUTE, SELECT DELETE, INSERT, ALTER, CONTROL, TAKE OWNERSHIP, VIEW DEFINITION, etc. This value may not be populated for all roles.  Some built in roles have implicit permission definitions. ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'PermissionType'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The role name.  This will be null if the associated permissions to the object are defined at directly on the user account, otherwise this will be the name of the role that the user is a member of. ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'Role'
GO
EXEC sp_addextendedproperty N'MS_Description', N'SQL or Windows/Active Directory user cccount.  This could also be an Active Directory group. ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'UserName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Value will be either "SQL User" or "Windows User".  This reflects the type of user defined for the SQL Server user account. ', 'SCHEMA', N'Audit', 'VIEW', N'DatabaseUserPermissions', 'COLUMN', N'UserType'
GO
