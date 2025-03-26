/*============================================================================
	File:		001 - A02 - System Environment - SQL Server Logins and server roles.sql

	Summary:	Ths script returns the privileges of the system account
				which will be used by the SQL Server Database Engine


	Date:		November 2014

	SQL Server Version: 2008 / 2012 / 2014 / 2016

	Improvement:	Add columnn for deactivated users!
					ORDER BY login_name
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
-- 1. Get all logins and their Serverrole based security
USE master;
GO

SELECT	login_name,
		[is_enabled],
		login_type,
		[public],
		[sysadmin],
		[securityadmin],
		[serveradmin],
		[setupadmin],
		[processadmin],
		[diskadmin],
		[dbcreator],
		[bulkadmin]
FROM
(
	SELECT	SP.name			AS	login_name,
			CASE WHEN is_disabled = 1
				 THEN 0
				 ELSE 1
			END				AS	is_enabled,
			SP.type			AS	login_type,
			'public'		AS	server_role,
			sp.principal_Id
	FROM	sys.server_principals AS SP
	WHERE	type != 'R'

	UNION

	SELECT	SP.name			AS	login_name,
			CASE WHEN SP.is_disabled = 1
				 THEN 0
				 ELSE 1
			END				AS	is_enabled,
			SP.type			AS	login_type,
			role_list.name	AS	server_role,
			SP.principal_Id
	FROM	sys.server_principals AS SP LEFT JOIN
			(
				SELECT	SRM.member_principal_id,
						SR.name
				FROM	sys.server_role_members AS SRM INNER JOIN sys.server_principals AS SR
						ON	(SRM.role_principal_id = SR.principal_id)
			) AS role_list ON
			(SP.principal_id = role_list.member_principal_id)
	WHERE	SP.type != 'R'
) AS SecList
PIVOT
(
	COUNT(principal_id)
	FOR	 server_role
	IN
	(
		[public],
		[sysadmin],
		[securityadmin],
		[serveradmin],
		[setupadmin],
		[processadmin],
		[diskadmin],
		[dbcreator],
		[bulkadmin]	
	)
) AS pvt
ORDER BY
	login_type,
	login_name;
GO

-- Get a list of orphaned users
DECLARE @T TABLE
(
	database_name	VARCHAR(128),
	name			sysname,
	principal_id	SMALLINT,
	type			VARCHAR(2),
	sid				VARBINARY(64),
	create_date		DATETIME,
	modify_date		DATETIME
);

INSERT INTO @T
(database_name, name, principal_id, type, sid, create_date, modify_date)
EXEC sys.sp_MSforeachdb @command1 = N';WITH L
AS
(
	SELECT	sid
	FROM	sys.server_principals
	WHERE	type IN (''S'', N''U'')
			AND name NOT LIKE ''##%''
)
SELECT	''[?]''			AS	Database_name,
		DP.name,
		DP.principal_id,
		DP.type,
		DP.sid,
		DP.create_date,
		DP.modify_date
FROM	[?].sys.database_principals AS DP
		LEFT JOIN L ON (DP.sid = L.sid)
WHERE	DB_ID(''?'') > 4
		AND DP.type IN (''S'', ''U'')
		AND DP.principal_id > 4
		AND L.sid IS NULL;'

SELECT * FROM @T
ORDER BY
		database_name,
		name;
GO

-- 3. Get all database role based security information
DECLARE @T TABLE
(
	database_name			VARCHAR(128),
	member_name				VARCHAR(128),
	[public]				SMALLINT,
	[db_accessadmin]		SMALLINT,
	[db_backupoperator]		SMALLINT,
	[db_datareader]			SMALLINT,
	[db_datawriter]			SMALLINT,
	[db_ddladmin]			SMALLINT,
	[db_denydatareader]		SMALLINT,
	[db_denydatawriter]		SMALLINT,
	[db_owner]				SMALLINT,
	[db_securityadmin]		SMALLINT
)

INSERT INTO @T
EXEC sp_msforeachdb N'USE [?];

SELECT	''[?]''			AS	database_name,
		[member_name],
		[public],
		[db_accessadmin],
		[db_backupoperator],
		[db_datareader],
		[db_datawriter],
		[db_ddladmin],
		[db_denydatareader],
		[db_denydatawriter],
		[db_owner],
		[db_securityadmin]
FROM
(
	SELECT	principal_id,
			name			AS	member_name,
			''public''		AS	role_name
	FROM	sys.database_principals
	WHERE	type != ''R''

	UNION ALL

	SELECT	DP.principal_id,
			DP.name	AS	member_name,
			DR.name	AS	role_name
	FROM	sys.database_principals AS DP
	INNER JOIN sys.database_role_members AS DRM
	ON (DP.principal_id = DRM.member_principal_id)
	INNER JOIN sys.database_principals AS DR
	ON (DRM.role_principal_id = DR.principal_id)
) AS SecList
PIVOT
(
	COUNT(principal_id)
	FOR	 role_name
	IN
	(
		[public],
		[db_accessadmin],
		[db_backupoperator],
		[db_datareader],
		[db_datawriter],
		[db_ddladmin],
		[db_denydatareader],
		[db_denydatawriter],
		[db_owner],
		[db_securityadmin]
	)
) AS pvt
ORDER BY
	pvt.member_name;';

SELECT * FROM @T;
GO
