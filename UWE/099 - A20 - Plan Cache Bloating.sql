/*============================================================================
	File:		099 - A20 - Plan Cache Bloating.sql

	Summary:	This script demonstrates the problem of plan cache bloating.
				The database CustomerOrders is required for this demo!

				This demo shall describe the option
				[optimize for ad hoc workloads] in sys.configurations
				(see 001 - A04!)

				THIS SCRIPT IS PART OF THE TRACK: "Analysis of SQL Server"

	Date:		January 2017

	SQL Server Version: 2008 / 2012 / 2014 / 2016
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE [CustomerOrders];
GO


-- Clear the plan cache of the server (NOT FOR PRODUCTION!)
DBCC FREEPROCCACHE;
GO

-- what is now in the plan cache?
SELECT	DEST.text,
        DECP.usecounts,
        DECP.size_in_bytes,
        DECP.objtype,
        DECP.cacheobjtype
FROM	sys.dm_exec_cached_plans AS DECP
		CROSS APPLY sys.dm_exec_sql_text(DECP.plan_handle) AS DEST
WHERE	DECP.objtype = N'Adhoc' AND
		DEST.text LIKE '%Customers%' AND
		DEST.text NOT LIKE '%dm_exec_sql_text%';
GO

-- Now run 100 queries with different customer ids
DECLARE @I INT = 1;
DECLARE @STMT NVARCHAR(1000);
WHILE @I <= 100
BEGIN
	SET @STMT = N'SELECT * FROM dbo.Customers WHERE Id = ' + CAST(@I AS NVARCHAR(5)) + ';'
	EXEC (@STMT);

	SET @I += 1;
END
GO

-- what is now in the plan cache?
SELECT	DEST.text,
		DECP.usecounts,
		DECP.size_in_bytes,
		DECP.objtype,
		DECP.cacheobjtype
FROM	sys.dm_exec_cached_plans AS DECP
		CROSS APPLY sys.dm_exec_sql_text(DECP.plan_handle) AS DEST
WHERE	DECP.objtype = N'Adhoc' AND
		DEST.text LIKE '%Customers%' AND
		DEST.text NOT LIKE '%dm_exec_sql_text%';
GO

-- Activate "Optimize for Ad Hoc"
EXEC sp_configure N'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sp_configure N'optimize for ad hoc workloads', 1
GO
RECONFIGURE WITH OVERRIDE
GO

DBCC FREEPROCCACHE;
GO

-- Now run 100 queries with different customer ids
DECLARE @I INT = 1;
DECLARE @STMT NVARCHAR(1000);
WHILE @I <= 100
BEGIN
	SET @STMT = N'SELECT * FROM dbo.Customers WHERE Id = ' + CAST(@I AS NVARCHAR(5)) + ';'
	EXEC (@STMT);

	SET @I += 1;
END
GO

-- what is now in the plan cache?
SELECT	DEST.text,
		DECP.usecounts,
		DECP.size_in_bytes,
		DECP.objtype,
		DECP.cacheobjtype
FROM	sys.dm_exec_cached_plans AS DECP
		CROSS APPLY sys.dm_exec_sql_text(DECP.plan_handle) AS DEST
WHERE	DECP.objtype = N'Adhoc' AND
		DEST.text LIKE '%Customers%' AND
		DEST.text NOT LIKE '%dm_exec_sql_text%';
GO

-- Now run 100 queries with different customer ids
-- step in between = 2
DECLARE @I INT = 1;
DECLARE @STMT NVARCHAR(1000);
WHILE @I <= 100
BEGIN
	SET @STMT = N'SELECT * FROM dbo.Customers WHERE Id = ' + CAST(@I AS NVARCHAR(5)) + ';'
	EXEC (@STMT);

	SET @I += 10;
END
GO

-- what is now in the plan cache?
SELECT	DEST.text,
		DECP.usecounts,
		DECP.size_in_bytes,
		DECP.objtype,
		DECP.cacheobjtype
FROM	sys.dm_exec_cached_plans AS DECP
		CROSS APPLY sys.dm_exec_sql_text(DECP.plan_handle) AS DEST
WHERE	DECP.objtype = N'Adhoc' AND
		DEST.text LIKE '%Customers%' AND
		DEST.text NOT LIKE '%dm_exec_sql_text%';
GO

EXEC sp_configure N'optimize for ad hoc workloads', 0
GO
RECONFIGURE WITH OVERRIDE
GO

DBCC FREEPROCCACHE;
GO

-- Now run 100 queries with different customer ids
DECLARE @I INT = 1;
DECLARE @STMT NVARCHAR(1000) = N'SELECT * FROM dbo.Customers WHERE Id = @ID;';
WHILE @I <= 100
BEGIN
	EXEC sp_executesql @STMT, N'@ID INT', @I;
	SET @I += 1;
END
GO

-- what is now in the plan cache?
SELECT	DEST.text,
		DECP.usecounts,
		DECP.size_in_bytes,
		DECP.objtype,
		DECP.cacheobjtype
FROM	sys.dm_exec_cached_plans AS DECP
		CROSS APPLY sys.dm_exec_sql_text(DECP.plan_handle) AS DEST
WHERE	DEST.text LIKE '%Customers%' AND
		DEST.text NOT LIKE '%dm_exec_sql_text%';
GO

SELECT * INTO dbo.messages FROM sys.messages;
GO

CREATE NONCLUSTERED INDEX x1 ON dbo.messages (severity);
GO
SET STATISTICS IO, TIME ON;
GO

SELECT * FROM dbo.messages WHERE severity = 12 ORDER BY text;
GO
SELECT * FROM dbo.messages WHERE severity = 16 ORDER BY text;
GO

CREATE OR ALTER PROC dbo.GetMessages
	@severity TINYINT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	message_id,
            language_id,
            severity,
            is_event_logged,
            text
	FROM	dbo.messages
	WHERE	severity = @severity
	ORDER BY
			Text;
END
GO

DBCC FREEPROCCACHE;
GO

EXEC dbo.GetMessages 
    @severity = 12 -- tinyint

EXEC dbo.GetMessages 
    @severity = 16 -- tinyint
GO

