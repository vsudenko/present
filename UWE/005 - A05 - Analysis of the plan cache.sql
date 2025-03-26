/*============================================================================
	File:		005 - A05 - Analyze of the plan cache.sql

	Summary:	This script analyzes the current situation in the plan cache
				of the connected SQL Server instance

	Date:		September 2020

	SQL Server Version: 2012 / 2014 / 2016 / 2017 / 2019
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.

	Notice: <2019 does not have spills-columns
============================================================================*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
GO

-- Display options (AND)
:SETVAR	max_rows		20		-- number of displayed executions (avoid high number (>20) if show_plan = 1!)
:SETVAR	show_last		1		-- show last execution values
:SETVAR	show_min		1		-- show min execution values
:SETVAR	show_max		1		-- show max exeuction values
:SETVAR show_plan		1		-- show the execution plan
:SETVAR show_spills		0		-- only available with SQL 2019
:SETVAR parallel_only	0		-- only queries which run in parallel

-- Output options (AND)
:SETVAR show_ms		1			-- Display time values in milliseconds instead of microseconds
:SETVAR print_stmt	0			-- print the statement before it gets executed

-- Sort options (OR)
:SETVAR order_by_exec	0		-- execution count
:SETVAR	order_by_io		1		-- last_logical_read
:SETVAR order_by_cpu	0		-- last_worker_time
:SETVAR order_by_memory	0		-- last_grant_kb

DECLARE @stmt NVARCHAR(4000) = N'
SELECT	TOP ($(max_rows))
	CASE WHEN DEST.dbid IS NULL
			THEN ''--''
			ELSE DB_NAME(DEST.dbid)
	END	AS database_name,
	DEST.text	AS SQL_Batch,
	SUBSTRING
	(
		DEST.text,
		DEQS.statement_start_offset / 2,
		CASE WHEN DEQS.statement_end_offset = -1
				THEN DATALENGTH(DEST.text)
				ELSE (DEQS.statement_end_offset - DEQS.statement_start_offset) / 2 + 2
		END
	)								AS	SQL_Command,'

IF $(show_plan) = 1
SET @stmt = @stmt + N'
	DEQP.query_plan,';

SET @stmt = @stmt + N'
    DEQS.creation_time,
    DEQS.last_execution_time,
    DEQS.execution_count,';

IF $(show_last) = 1
SET @stmt = @stmt + N'
	DEQS.last_worker_time / ($(show_ms) * 1000)	 AS last_worker_time,
    DEQS.last_elapsed_time / ($(show_ms) * 1000) AS last_elapsed_time,
    DEQS.last_rows,
    DEQS.last_logical_writes	/	128.0	AS	last_logical_writes_mb,
    DEQS.last_logical_reads		/	128.0	AS	last_logical_reads_mb,
    DEQS.last_grant_kb,
    DEQS.last_used_grant_kb,
    DEQS.last_ideal_grant_kb,
    DEQS.last_used_threads,
	DEQS.last_dop,';

IF CAST(SERVERPROPERTY('ProductMajorVersion') AS SMALLINT) >= 15
BEGIN
	IF $(show_spills) = 1 AND $(show_last) = 1
	SET @stmt = @stmt + N'DEQS.last_spills,'
END

IF $(show_min) = 1
SET @stmt = @stmt + N'
	DEQS.min_worker_time / ($(show_ms) * 1000)	 AS min_worker_time,
    DEQS.min_elapsed_time / ($(show_ms) * 1000)	 AS min_elapsed_time,
    DEQS.min_rows,
    DEQS.min_logical_writes	/	128.0	AS	min_logical_writes_mb,
    DEQS.min_logical_reads	/	128.0	AS	min_logical_reads_mb,
    DEQS.min_grant_kb,
    DEQS.min_used_grant_kb,
    DEQS.min_ideal_grant_kb,
    DEQS.min_used_threads,
    DEQS.min_dop,';

IF CAST(SERVERPROPERTY('ProductMajorVersion') AS SMALLINT) >= 15
BEGIN
	IF $(show_spills) = 1 AND $(show_min) = 1
	SET @stmt = @stmt + N'DEQS.min_spills,'
END

IF $(show_max) = 1
SET @stmt = @stmt + N'
	DEQS.max_worker_time / ($(show_ms) * 1000)	 AS max_worker_time,
    DEQS.max_elapsed_time / ($(show_ms) * 1000)	 AS max_elapsed_time,
    DEQS.max_rows,
    DEQS.max_logical_writes	/	128.0	AS	max_logical_writes_mb,
    DEQS.max_logical_reads	/	128.0	AS	max_logical_reads_mb,
    DEQS.max_grant_kb,
    DEQS.max_used_grant_kb,
    DEQS.max_ideal_grant_kb,
    DEQS.max_used_threads,
    DEQS.max_dop,';

IF CAST(SERVERPROPERTY('ProductMajorVersion') AS SMALLINT) >= 15
BEGIN
	IF $(show_spills) = 1 AND $(show_max) = 1
	SET @stmt = @stmt + N'DEQS.max_spills,'
END 

SET @stmt = @stmt + N'
	DEQS.sql_handle
FROM	sys.dm_exec_query_stats AS DEQS
	CROSS APPLY sys.dm_exec_sql_text(DEQS.sql_handle) AS DEST'

IF $(show_plan) = 1
SET @stmt = @stmt + N'
CROSS APPLY sys.dm_exec_query_plan(DEQS.plan_handle) AS DEQP';

SET @stmt = @stmt + N'
WHERE	DEST.text NOT LIKE N''%@_msparam%''
	AND DEST.text NOT LIKE N''%obj.schema_id%''';

IF $(parallel_only) = 1
SET @stmt = @stmt + N'
	AND DEQS.max_dop > 1';

IF $(order_by_io) = 1
SET @stmt = @stmt + N'ORDER BY DEQS.last_logical_reads DESC;'

IF $(order_by_cpu) = 1
SET @stmt = @stmt + N'ORDER BY DEQS.last_worker_time DESC;'

IF $(order_by_memory) = 1
SET @stmt = @stmt + N'ORDER BY DEQS.last_grant_kb DESC;'

IF $(order_by_exec) = 1
SET @stmt = @stmt + N'ORDER BY DEQS.execution_count DESC;'


IF $(print_stmt) = 1
	PRINT @stmt;

EXEC sp_executesql @stmt;
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO
