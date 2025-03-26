/*============================================================================
	File:		099 - A60 - Uneven size of multiple data files.sql

	Summary:	This script demonstrates the weird behavior of Microsoft SQL Server
				when it has to fill a table in multiple files of a filegroup.
				The files have uneven file sizes!

				THIS SCRIPT IS PART OF THE TRACK: "Analysis of SQL Server"

	Date:		November 2017

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE master;
GO

-- Preparation 1:	Drop an existing demo database
IF DB_ID(N'demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE [demo_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [demo_db];
END
GO

DECLARE	@DataPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(256));
DECLARE @LogPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(256));

DECLARE @stmt	NVARCHAR(4000) = N'
CREATE DATABASE demo_db
ON PRIMARY
(
	NAME = N''demo_db_01'',
	FILENAME = ''' + @DataPath + N'demo_db_01.ndf'',
	SIZE = 128MB
),
(
	NAME = N''demo_db_02'',
	FILENAME = ''' + @DataPath + N'demo_db_02.ndf'',
	SIZE = 64MB
),
(
	NAME = N''demo_db_03'',
	FILENAME = ''' + @DataPath + N'demo_db_03.ndf'',
	SIZE = 1024MB
),
(
	NAME = N''demo_db_04'',
	FILENAME = ''' + @DataPath + N'demo_db_04.ndf'',
	SIZE = 128MB
)
LOG ON
(
	NAME = N''demo_db_ldf'',
	FILENAME = ''' + @LogPath + N'demo_db.ldf'',
	SIZE = 128MB
);'

EXEC sp_executesql @stmt;
GO

SELECT	file_id,
		name,
		size / 128	AS	size_mb
FROM	sys.master_files
WHERE	database_id = DB_ID(N'demo_db')
ORDER BY
		type,
		file_id;

ALTER DATABASE demo_db SET RECOVERY SIMPLE;
ALTER AUTHORIZATION ON DATABASE::demo_db TO sa;
GO

-- Now we create a XEvent-Session which monitors the write events
-- to each file of demo_db;
IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'Multiple_File_Load')
	DROP EVENT SESSION [Multiple_File_Load] ON SERVER 
	GO

CREATE EVENT SESSION [Multiple_File_Load]
	ON SERVER
	ADD EVENT sqlserver.physical_page_write
	(WHERE [sqlserver].[database_name] = N'demo_db'),
	ADD EVENT sqlos.wait_info
	(
	    WHERE	duration> 0
				AND 
				(
					wait_type = N'PAGELATCH_EX'
					OR wait_type = 'PAGEIOLATCH_SH'
				)
	)
	ADD TARGET package0.histogram
	(
		SET filtering_event_name = N'sqlserver.physical_page_write',
			source = N'file_id',
			source_type = 0
	),
	ADD TARGET package0.event_file
	(
		SET filename = N'T:\Tracefiles\Multiple_File_Load.xel'
	)
	WITH
	(
		MAX_MEMORY = 4096KB ,
		EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS ,
		MAX_DISPATCH_LATENCY = 30 SECONDS ,
		MAX_EVENT_SIZE = 0KB ,
		MEMORY_PARTITION_MODE = NONE ,
		TRACK_CAUSALITY = OFF ,
		STARTUP_STATE = ON
	);
GO

EXEC sp_configure N'show adv%', 1;
RECONFIGURE WITH OVERRIDE;

EXEC sp_configure N'xp_cmdshell', 1;
RECONFIGURE WITH OVERRIDE;
EXEC xp_cmdshell N'DEL T:\TraceFiles\Multiple*.* /q';
ALTER EVENT SESSION Multiple_File_Load ON SERVER STATE = START;
GO

-- when the extended event session has been created and is up and running we
-- create a demo table and fill it with 100,000 records!
USE demo_db;
GO

IF OBJECT_ID(N'dbo.demo_table', N'U') IS NOT NULL
	DROP TABLE dbo.demo_table;
	GO

CREATE TABLE dbo.demo_table (C1 CHAR(4000));
GO

SET NOCOUNT ON;
GO

DECLARE	@starttime DATETIME2(7) = GETDATE();

DECLARE @I INT = 1;
WHILE @I <= 500000
BEGIN
	INSERT INTO dbo.demo_table VALUES (CAST(@I AS VARCHAR(10)));

	IF @I % 10000 = 0
		RAISERROR (N'%i records have been inserted into demo table', 0, 1, @I) WITH NOWAIT;

	SET @I += 1;
END

SELECT	'Run Time: ' + FORMAT(DATEDIFF (MILLISECOND, @starttime, GETDATE()), N'#,##0', N'de-de');
GO

SELECT	file_id,
		name,
		size / 128.0	AS	size_mb,
		CAST
		(
			FILEPROPERTY(name, 'spaceused')
			AS BIGINT
		) / 128.0		AS	used_mb
FROM	sys.master_files
WHERE	database_id = DB_ID()
		AND file_id <> 2;
GO


USE Master;
GO

-- Preparation 2:	Drop an existing demo database
IF DB_ID(N'demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE [demo_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [demo_db];
END
GO

DECLARE	@DataPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(256));
DECLARE @LogPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(256));

DECLARE @stmt	NVARCHAR(4000) = N'
CREATE DATABASE demo_db
ON PRIMARY
(
	NAME = N''demo_db_01'',
	FILENAME = ''' + @DataPath + N'demo_db_01.ndf'',
	SIZE = 128MB
),
(
	NAME = N''demo_db_02'',
	FILENAME = ''' + @DataPath + N'demo_db_02.ndf'',
	SIZE = 128MB
),
(
	NAME = N''demo_db_03'',
	FILENAME = ''' + @DataPath + N'demo_db_03.ndf'',
	SIZE = 128MB
),
(
	NAME = N''demo_db_04'',
	FILENAME = ''' + @DataPath + N'demo_db_04.ndf'',
	SIZE = 128MB
)
LOG ON
(
	NAME = N''demo_db_ldf'',
	FILENAME = ''' + @LogPath + N'demo_db.ldf'',
	SIZE = 128MB
);'

EXEC sp_executesql @stmt;
GO

ALTER DATABASE demo_db SET RECOVERY SIMPLE;
ALTER AUTHORIZATION ON DATABASE::demo_db TO sa;
ALTER DATABASE demo_db MODIFY FILEGROUP [PRIMARY] AutoGrow_All_Files;
GO

SELECT	file_id,
		name,
		size / 128	AS	size_mb
FROM	sys.master_files
WHERE	database_id = DB_ID(N'demo_db')
ORDER BY
		type,
		file_id;
GO

USE demo_db;
GO

SET NOCOUNT ON;
GO

-- when the extended event session has been created and is up and running we
-- create a demo table and fill it with 100,000 records!
USE demo_db;
GO

IF OBJECT_ID(N'dbo.demo_table', N'U') IS NOT NULL
	DROP TABLE dbo.demo_table;
	GO

CREATE TABLE dbo.demo_table (C1 CHAR(4000));
GO

DECLARE	@starttime DATETIME2(7) = GETDATE();
DECLARE @I INT = 1;
WHILE @I <= 500000
BEGIN
	INSERT INTO dbo.demo_table VALUES (CAST(@I AS VARCHAR(10)));

	IF @I % 10000 = 0
		RAISERROR (N'%i records have been inserted into demo table', 0, 1, @I) WITH NOWAIT;

	SET @I += 1;
END

SELECT	'Run Time: ' + FORMAT(DATEDIFF (MILLISECOND, @starttime, GETDATE()), N'#,##0', N'de-de') + N' ms.';
GO

SELECT	file_id,
		name,
		size / 128.0	AS	size_mb,
		CAST
		(
			FILEPROPERTY(name, 'spaceused')
			AS BIGINT
		) / 128.0		AS	used_mb
FROM	sys.master_files
WHERE	database_id = DB_ID()
		AND file_id <> 2;
GO