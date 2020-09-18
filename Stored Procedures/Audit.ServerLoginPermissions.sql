
CREATE PROCEDURE [Audit].[ServerLoginPermissions]
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

/* This returns specific server roles */
SELECT
    SERVERPROPERTY('SERVERNAME') AS ServerName,
    R.name AS RoleName,
    R.type_desc AS RoleType,
    SM.MemberName AS MemberName,
    M.type_desc AS MemberType,
    CASE WHEN M.is_disabled = 1 THEN 'Yes' ELSE 'No' END AS Disabled,
    ISNULL(LEFT(AL.AccountList, LEN(AL.AccountList) - 1), '') AS NTAccountList
FROM @SQLMember AS SM
    INNER JOIN sys.server_role_members AS RM
        ON SM.PrincipalID = RM.member_principal_id
    INNER JOIN sys.server_principals AS R
        ON RM.role_principal_id = R.principal_id
    INNER JOIN sys.server_principals AS M
        ON RM.member_principal_id = M.principal_id
    /* For Window groups, pull off a list of network accounts from the above loop */
    OUTER APPLY
        (
            SELECT AccountName + ', '
            FROM @WindowUsersInGroup
            WHERE PrincipalID = SM.PrincipalID
            ORDER BY AccountName
            FOR XML PATH('')
        ) AS AL (AccountList)
ORDER BY 
    R.name, 
    CASE 
        WHEN M.type_desc = 'SQL_LOGIN' THEN 1
        WHEN M.type_desc = 'WINDOWS_LOGIN' THEN 2
        WHEN M.type_desc = 'WINDOWS_GROUP' THEN 3
    END,
    SM.MemberName;

/* This returns specific server permissions */
SELECT
    SERVERPROPERTY('SERVERNAME') AS ServerName,
    P.class_desc AS PermissionClass,
    P.state_desc AS PermissionState,
    ISNULL(LEFT(PL.PermissionList, LEN(PL.PermissionList) - 1), '') AS PermissionList,
    SM.MemberName AS MemberName,
    SP.type_desc AS MemberType,
    CASE WHEN SP.is_disabled = 1 THEN 'Yes' ELSE 'No' END AS Disabled,
    ISNULL(LEFT(AL.AccountList, LEN(AL.AccountList) - 1), '') AS NTAccountList
FROM @SQLMember AS SM
    INNER JOIN sys.server_principals AS SP
        ON SM.PrincipalID = SP.principal_id
    INNER JOIN (SELECT DISTINCT class, class_desc, major_id, minor_id, grantee_principal_id, grantor_principal_id, state, state_desc FROM sys.server_permissions) AS P
        ON SP.principal_id = P.grantee_principal_id
    CROSS APPLY (
        SELECT permission_name + ', '
        FROM sys.server_permissions
        WHERE class = P.class
        AND class_desc = P.class_desc
        AND major_id = P.major_id
        AND minor_id = P.minor_id
        AND grantee_principal_id = P.grantee_principal_id
        AND grantor_principal_id = P.grantor_principal_id
        AND state = P.state
        AND state_desc = P.state_desc
        ORDER BY permission_name
        FOR XML PATH('')
    ) AS PL (PermissionList)
    /* For Window groups, pull off a list of network accounts from the above loop */
    OUTER APPLY
        (
            SELECT AccountName + ', '
            FROM @WindowUsersInGroup
            WHERE PrincipalID = SM.PrincipalID
            ORDER BY AccountName
            FOR XML PATH('')
        ) AS AL (AccountList)
ORDER BY
    SERVERPROPERTY('SERVERNAME'),
    P.class_desc,
    P.state_desc,
    CASE 
        WHEN SP.type_desc = 'SQL_LOGIN' THEN 1
        WHEN SP.type_desc = 'WINDOWS_LOGIN' THEN 2
        WHEN SP.type_desc = 'WINDOWS_GROUP' THEN 3
    END,
    SM.MemberName;
GO
