/*============================================================================
	File:		001 - A01 - System Environment Security.sql

	Summary:	Ths script returns the privileges of the system account
				which will be used by the SQL Server Database Engine

	Date:		May 2015
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017 / 2019
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater eGmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE master;
GO

SET NOCOUNT ON;
GO

-- If we are not a sysadmin we are not allowed to activate xp_cmdshell
IF IS_SRVROLEMEMBER('sysadmin') != 1
BEGIN
	RAISERROR ('No sysadmin privilege. Action cancelled', 16, 1) WITH NOWAIT;
	RETURN
END

-- Activate XP_CMDSHELL if isn't!
DECLARE	@advanced_options	BIT;
DECLARE	@xp_cmdshell		BIT;

SELECT	@advanced_options = ISNULL(CAST(value_in_use AS INT), 0)
FROM	sys.configurations AS C
WHERE	name = 'show advanced options';

IF @advanced_options = 0
BEGIN
	RAISERROR ('Activating advanced options', 0, 1) WITH NOWAIT;
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
END

SELECT	@xp_cmdshell = ISNULL(CAST(value_in_use AS INT), 0)
FROM	sys.configurations AS C
WHERE	name = 'xp_cmdshell';

IF @xp_cmdshell = 0
BEGIN
	RAISERROR ('Activating xp_cmdshell', 0, 1) WITH NOWAIT;
	EXEC sp_configure 'xp_cmdshell', 1;
	RECONFIGURE;
END

DECLARE	@Result TABLE (RN INT NOT NULL IDENTITY (1, 1), output VARCHAR(MAX) NULL);

-- what is the name of the service account?
INSERT INTO @Result(output) VALUES ('------------------ whoami.exe /user /FO TABLE /NH ------------------');
INSERT INTO @Result([output])
EXEC xp_cmdshell 'whoami.exe /user /FO TABLE /NH';
INSERT INTO @Result(output) VALUES (' ');

-- what groups does the account belong to?
INSERT INTO @Result(output) VALUES ('------------------ whoami.exe /groups /NH ------------------');
INSERT INTO @Result([output])
EXEC xp_cmdshell 'whoami.exe /groups /NH';
INSERT INTO @Result(output) VALUES (' ');

-- what privileges does the account have?
INSERT INTO @Result(output) VALUES ('------------------ whoami.exe /priv /NH ------------------');
INSERT INTO @Result([output])
EXEC xp_cmdshell 'whoami.exe /priv /NH'
INSERT INTO @Result(output) VALUES (' ');

-- Check the blocksize of each accessible drive
-- this will only work if the account have local admin privileges!
INSERT INTO @Result(output) VALUES ('------------------ Storage block size information ------------------');
DECLARE @stmt	VARCHAR(255);
DECLARE	@drives TABLE (Drive VARCHAR(2), MB BIGINT, Command VARCHAR(255) NULL)
INSERT INTO @drives (Drive, MB)
EXEC sys.xp_fixeddrives;

UPDATE	@drives
SET		Command = 'fsutil fsinfo ntfsinfo ' + Drive + ':';

DECLARE c CURSOR
FOR
	SELECT Command FROM @drives AS D;

OPEN c;

FETCH NEXT FROM c INTO @stmt;
WHILE @@FETCH_STATUS != -1
BEGIN
	INSERT INTO @Result([output]) VALUES (@stmt);
	INSERT INTO @Result([output])
	EXEC xp_cmdshell @stmt;

	FETCH NEXT FROM c INTO @stmt;
END

CLOSE c;
DEALLOCATE c;
INSERT INTO @Result(output) VALUES (' ');

INSERT INTO @Result(output) VALUES ('------------------ Storage information ------------------');

SELECT	DISTINCT
		SERVERPROPERTY('MachineName') AS MachineName,
		ISNULL(SERVERPROPERTY('InstanceName'), 'MSSQLSERVER') AS InstanceName,
		vs.volume_mount_point					AS VolumeName,
		vs.logical_volume_name					AS VolumeLabel,
		vs.total_bytes  / POWER(1024, 3)		AS VolumeCapacityGB,
		vs.available_bytes  / POWER(1024, 3)	AS VolumeFreeSpaceGB,
		CAST(vs.available_bytes * 100.0 / vs.total_bytes AS DECIMAL(5, 2)) AS PercentageFreeSpace
FROM	sys.master_files AS mf
		CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS vs;


IF @xp_cmdshell  = 0
BEGIN
	RAISERROR ('Deactivating xp_cmdshell', 0, 1) WITH NOWAIT;
	EXEC sp_configure 'xp_cmdshell', 0;
	RECONFIGURE;
END

IF @advanced_options = 0
BEGIN
	RAISERROR ('Deactivating advanced options', 0, 1)
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE
END

SELECT	[output]
FROM	@Result AS R
WHERE	output IS NOT NULL
ORDER BY
		RN;