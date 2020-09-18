CREATE PROCEDURE [Audit].[ServerLoginPermissions_raw]
AS
SET NOCOUNT ON;
DECLARE @SQLMember TABLE (
    PrincipalID INT NOT NULL,
    MemberName SYSNAME NOT NULL
);

DECLARE @WindowsGroup TABLE (
    PrincipalID INT NOT NULL,
    DomainGroup SYSNAME NOT NULL
);

DECLARE @WindowUsersInGroup TABLE (
    AccountName SYSNAME NOT NULL,
    AccountType VARCHAR(8) NOT NULL,
    Privilege VARCHAR(9) NOT NULL,
    WindowsAccount SYSNAME NOT NULL,
    DomainGroup SYSNAME NOT NULL,
    PrincipalID INT NULL
);

/* First, insert all SQL logins (S) and Window logins (U) */
INSERT INTO @SQLMember (PrincipalID, MemberName)
SELECT SP.principal_id, SP.name
FROM sys.server_principals AS SP
WHERE SP.TYPE IN ('S', 'U', 'G', 'C') /* S = SQL Login, U = Windows Login */

/* Now, for all domain groups, obtain the member accounts that belong to each one */
INSERT INTO @WindowsGroup (PrincipalID, DomainGroup)
SELECT SP.principal_id, SP.name
FROM sys.server_principals AS SP
WHERE SP.TYPE IN ('G') /* G = Windows Group */

/* Iterate through all domain groups retrieving each domain account that belongs to that group */
DECLARE @CurrentDomainGroup SYSNAME;
DECLARE @CurrentPrincipalID INT;

SELECT TOP 1 @CurrentDomainGroup = DomainGroup, @CurrentPrincipalID = PrincipalID FROM @WindowsGroup

WHILE (@CurrentDomainGroup IS NOT NULL)
    BEGIN
        /* Grab all members in this group */
        INSERT INTO @WindowUsersInGroup (AccountName, AccountType, Privilege, WindowsAccount, DomainGroup)
            EXEC xp_logininfo @acctname=@CurrentDomainGroup, @option='members';

        /* Remove this group from our list that controls the loop */
        DELETE @WindowsGroup WHERE DomainGroup = @CurrentDomainGroup;

        /* Stamp all the new users with this principal ID for later use */
        UPDATE @WindowUsersInGroup
        SET PrincipalID = @CurrentPrincipalID
        WHERE PrincipalID IS NULL;

        /* Get the next group - all without a cursor */
        SET @CurrentDomainGroup = NULL;
        SET @CurrentPrincipalID = NULL;
        SELECT TOP 1 @CurrentDomainGroup = DomainGroup, @CurrentPrincipalID = PrincipalID FROM @WindowsGroup
    END

SELECT
	SERVERPROPERTY('SERVERNAME') AS ServerName,
	l.name AS LoginName,
	wg.WindowsAccount,
	sp.class_desc AS PermissionClass,
	IIF(state_desc='GRANT',1,0) AS IsGrant,
	SP.permission_name AS PermissionName,
	CASE SP.class_desc 
		WHEN 'SERVER_PRINCIPAL' THEN (SELECT name FROM sys.server_principals WHERE principal_id = sp.major_id)
		ELSE NULL 
	END AS PermissionTarget,
	SP.major_id,
	NULL AS RoleName
FROM @SQLMember AS SM
JOIN sys.server_principals AS l ON SM.PrincipalID = l.principal_id
JOIN sys.server_permissions AS SP ON l.principal_id = sp.grantee_principal_id
LEFT JOIN @WindowUsersInGroup AS WG ON SM.PrincipalID = WG.PrincipalID
UNION
SELECT
	SERVERPROPERTY('SERVERNAME') AS ServerName,
	l.name AS LoginName,
	wg.WindowsAccount,
	sp.class_desc AS PermissionClass,
	IIF(state_desc='GRANT',1,0) AS IsGrant,
	SP.permission_name AS PermissionName,
	CASE SP.class_desc 
		WHEN 'SERVER_PRINCIPAL' THEN (SELECT name FROM sys.server_principals WHERE principal_id = sp.major_id)
		ELSE NULL 
	END AS PermissionTarget,
	SP.major_id,
	RP.name AS RoleName
FROM (SELECT * FROM sys.server_principals WHERE type='R') AS RP
JOIN sys.server_role_members AS SRM  ON RP.principal_id = SRM.role_principal_id
JOIN sys.server_principals AS l ON SRM.member_principal_id= l.principal_id
JOIN sys.server_permissions AS SP ON RP.principal_id = sp.grantee_principal_id
LEFT JOIN @WindowUsersInGroup AS WG ON l.principal_id = WG.PrincipalID
UNION ALL
SELECT
	SERVERPROPERTY('SERVERNAME') AS ServerName,
	lgn.name AS LoginName,
	wg.WindowsAccount,
	--NULL AS WindowsAccount,
	'FIXED ROLE' AS PermissionClass,
	1 AS IsGrant,
	SUSER_NAME(rm.role_principal_id) AS PermissionName,
	NULL AS PermissionTarget,
	0,
	SUSER_NAME(rm.role_principal_id) AS RoleName
FROM sys.server_role_members rm
JOIN sys.server_principals lgn ON rm.member_principal_id = lgn.principal_id
LEFT JOIN @WindowUsersInGroup AS WG ON lgn.principal_id = WG.PrincipalID
WHERE
	rm.role_principal_id >= 3 AND
	rm.role_principal_id <= 10
GO
