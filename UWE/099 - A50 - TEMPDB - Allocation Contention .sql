/*============================================================================
	File:		099 - A50 - TEMPDB - Allocation Contention.sql

	Summary:	This script demonstrates the different runtimes
				the problem with allocation contention in a wrong
				configured TEMPDB database

				THIS SCRIPT IS PART OF THE TRACK: "Analysis of SQL Server"

	Date:		September 2017

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017 / 2019
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

-- Preparation 2:	Reduce TEMPDB to 1 data file
USE tempdb;
GO

-- Copy the output into a new window and execute it
-- if some files cannot be deleted restart the instance
-- and try it again!
SELECT	N'DBCC SHRINKFILE(' + QUOTENAME(name) + N', EMPTYFILE);
ALTER DATABASE [tempdb] REMOVE FILE ' + QUOTENAME(name) + N';'
FROM	sys.master_files
WHERE	database_id = 2
		AND type = 0
		AND file_id > 1;
GO

-- Check the number of files in TEMPDB after running the above output in a separate window
SELECT	*
FROM	sys.master_files
WHERE	database_id = DB_ID(N'tempdb');
GO

-- Preparation 3:	Create the demo database with a demo table
master.dbo.sp_create_demo_db;
GO

USE demo_db;
GO

-- Preparation 4:	Example proc for workload
IF OBJECT_ID(N'dbo.proc_fill_tempdata', N'P') IS NOT NULL
	DROP PROC dbo.proc_fill_tempdata;
	GO

CREATE OR ALTER PROC dbo.proc_fill_tempdata
	@UseTableVariable BIT
AS
BEGIN
	SET NOCOUNT ON;

	IF @UseTableVariable = 1
	BEGIN
		DECLARE	@T AS TABLE
		(
			message_id	INT	NOT NULL,
			language_id	INT NOT NULL
		);

		INSERT INTO @T
		(message_id, language_id)
		SELECT	TOP (20)
		message_id, language_id
		FROM	sys.messages;
	END
	ELSE
	BEGIN
		CREATE TABLE #T
		(
			message_id	INT,
			language_id	INT
		);

		INSERT INTO #T
		(message_id, language_id)
		SELECT	TOP (20)
		message_id, Language_Id
		FROM	sys.messages;
	END
END
GO

-- Now we create an XEvent which records contention on PFS, GAM, SGAM pages
IF EXISTS
(
	SELECT * 
	FROM sys.server_event_sessions 
	WHERE name = 'db Track TempDB Contention'
)
DROP EVENT SESSION [db Track TempDB Contention] ON SERVER;
GO

CREATE EVENT SESSION [db Track TempDB Contention]
ON SERVER
ADD EVENT sqlserver.latch_suspend_end
(
	ACTION
    (
        sqlserver.plan_handle,
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.username
    )
	WHERE
	(
		database_id = 2			-- only tempdb database
		AND duration >= 100	-- Duration > 1 ms
		AND FILE_ID <> 2		-- not the log file
		AND
		(
			mode = 1
			OR mode = 2
			OR mode = 3
			OR mode = 4			
		)
		AND
		(
			-- only check for PFS, GAM, SGAM
			page_id = 1
			OR page_id = 2
			OR page_id = 3
			OR package0.divides_by_uint64(page_id, 8088)
			OR package0.divides_by_uint64(page_id, 511232)
		)
		-- Since SQL Server 2019 you can use page_type_id instead of page_id!
		--(
		--	page_type_id = 11
		--	OR page_type_id = 9
		--	OR page_type_id = 8
		--)
	)
)
ADD TARGET package0.histogram
(
	SET filtering_event_name=N'sqlserver.latch_suspend_end',
		source=N'page_id',
		source_type = 0
)
WITH
(
	MAX_MEMORY = 4096KB ,
	EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS ,
	MAX_DISPATCH_LATENCY = 5 SECONDS ,
	MAX_EVENT_SIZE = 0KB ,
	MEMORY_PARTITION_MODE = NONE ,
	TRACK_CAUSALITY = OFF ,
	STARTUP_STATE = OFF
);
GO

ALTER EVENT SESSION [db Track TempDB Contention] ON SERVER STATE = START;
GO

-- Now run the stored procedure for 3 minutes each with the following command
-- ostress -SNB-LENOVO-I\SQL_2019 -E -Q"EXEC dbo.proc_fill_tempdata @UseTableVariable = 0;" -ddemo_db -q -n50 -r1000
-- ostress -SNB-LENOVO-I\SQL_2019 -E -Q"EXEC dbo.proc_fill_tempdata @UseTableVariable = 1;" -ddemo_db -q -n50 -r1000

-- After the demo we add as much files as we have cores in the system!
-- Before adding new tempdb files we reduce the size of the first file
-- to 1024 MB
USE tempdb;
GO

DBCC SHRINKFILE ('tempdev', 1024);
GO

DECLARE	@stmt		NVARCHAR(1024);
DECLARE	@FilePath	NVARCHAR(260);
DECLARE	@MaxFiles	TINYINT;
DECLARE	@Counter	TINYINT = 2;

SELECT	@MaxFiles = cpu_count
FROM sys.dm_os_sys_info;

SELECT	@FilePath = REVERSE(RIGHT(REVERSE(filename), LEN(filename) - CHARINDEX('\', REVERSE(filename))))
FROM sys.sysfiles
WHERE	FileId = 1;

IF @MaxFiles > 8
	SET @MaxFiles = 8;

WHILE @Counter <= @MaxFiles
	  OR @Counter <= 8
BEGIN
	SET	@stmt = 'ALTER DATABASE [tempdb]
ADD FILE
(
	Name = ''tempdev_' + RIGHT(N'0' + CAST(@Counter AS NVARCHAR(2)), 2) + ''',
	FILENAME = ''' + @FilePath + N'\tempdev_' +RIGHT(N'0' + CAST(@Counter AS NVARCHAR(2)), 2) + N'.ndf'',
	SIZE = 64,
	MAXSIZE = 2048
);
GO';

	PRINT @stmt;
	SET @Counter += 1;
END

-- Now run the stored procedure for 3 minutes each with the following command
-- C:\Program Files\Microsoft Corporation\RMLUtils\ostress -SNB-LENOVO-I\SQL_2016 -E -Q"EXEC dbo.proc_fill_tempdata @UseTableVariable = 1, @Duration = 3;" -ddemo_db -q -n50
-- C:\Program Files\Microsoft Corporation\RMLUtils\ostress -SNB-LENOVO-I\SQL_2016 -E -Q"EXEC dbo.proc_fill_tempdata @UseTableVariable = 0, @Duration = 3;" -ddemo_db -q -n50
WITH Tasks
AS
(
	SELECT	session_id,
			wait_type,
			wait_duration_ms,
			blocking_session_id,
			resource_description,
			PageID = CAST
			(
				RIGHT
				(
						resource_description,
						LEN(resource_description) - CHARINDEX(':', resource_description, 3)
				) AS INT
			)
	FROM	sys.dm_os_waiting_tasks AS DOWT WITH (NOLOCK)
	WHERE	wait_type LIKE 'PAGE%LATCH_%' AND
			resource_description LIKE '2:%'
)
SELECT	session_id,
		wait_type,
		wait_duration_ms,
		blocking_session_id,
		resource_description,
		ResourceType =	CASE WHEN PageID = 1 Or PageID % 8088 = 0 THEN 'PFS'
							 WHEN PageID = 2 Or PageID % 511232 = 0 THEN 'GAM'
							 WHEN PageID = 3 Or (PageID - 1) % 511232 = 0 THEN 'SGAM'
							 ELSE 'OTHER'
						END
FROM Tasks;
GO
