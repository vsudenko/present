/*============================================================================
	File:		002 - A05 - Database analysis - IO analysis.sql

	Summary:	This script gives you an overview of all settings of 
				your user databases.

	Date:		June 2015
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014
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

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

-- Calculates average stalls per read, per write, and per total input/output
-- This script only covers database which are ONLINE.
IF CAST(SERVERPROPERTY('ProductVersion') AS CHAR(2)) <= '10'
EXEC sp_executesql N'
SELECT	DB_NAME(FS.database_id) AS [Database Name],
		MF.physical_name,
		MF.type_desc,
		FS.io_stall_read_ms,
		FS.num_of_reads, 
		FS.io_stall_write_ms,
		FS.num_of_writes,
		CASE WHEN FS.num_of_reads = 0
			 THEN 0
			 ELSE CAST(FS.io_stall_read_ms / (1.0 * FS.num_of_reads) AS NUMERIC(10, 1))
		END		AS [avg_read_stall_ms],
		CASE WHEN FS.num_of_writes = 0
			 THEN 0
			 ELSE CAST(FS.io_stall_write_ms / (1.0 * FS.num_of_writes) AS NUMERIC(10, 1))
		END		AS [avg_write_stall_ms],
		CASE WHEN FS.num_of_reads + FS.num_of_writes = 0
			 THEN 0
			 ELSE CAST((FS.io_stall_read_ms + FS.io_stall_write_ms) / (1.0 * (FS.num_of_reads + FS.num_of_writes)) AS NUMERIC(10, 1))
		END	AS [avg_io_stall_ms]
FROM	sys.master_files AS MF INNER JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS FS
		ON (
			 MF.database_id = FS.database_id AND
			 MF.file_id = FS.file_id
			)
WHERE	DATABASEPROPERTYEX(DB_NAME(FS.database_id), ''Status'') = ''ONLINE''
ORDER BY
		FS.database_id,
		FS.file_id,
		avg_io_stall_ms DESC OPTION (RECOMPILE);';
ELSE
EXEC sp_executesql N'
SELECT	DB_NAME(FS.database_id) AS [Database Name],
		MF.physical_name,
		MF.type_desc,
		FS.io_stall_read_ms,
		FS.num_of_reads, 
		FS.io_stall_write_ms,
		FS.num_of_writes,
		CASE WHEN FS.num_of_reads = 0
			 THEN 0
			 ELSE CAST(FS.io_stall_read_ms / (1.0 * FS.num_of_reads) AS NUMERIC(10, 1))
		END		AS [avg_read_stall_ms],
		CASE WHEN FS.num_of_writes = 0
			 THEN 0
			 ELSE CAST(FS.io_stall_write_ms / (1.0 * FS.num_of_writes) AS NUMERIC(10, 1))
		END		AS [avg_write_stall_ms],
		CASE WHEN FS.num_of_reads + FS.num_of_writes = 0
			 THEN 0
			 ELSE CAST((FS.io_stall_read_ms + FS.io_stall_write_ms) / (1.0 * (FS.num_of_reads + FS.num_of_writes)) AS NUMERIC(10, 1))
		END	AS [avg_io_stall_ms]
FROM	sys.master_files AS MF
		CROSS APPLY sys.dm_io_virtual_file_stats(MF.database_id, MF.file_id) AS FS
WHERE	DATABASEPROPERTYEX(DB_NAME(FS.database_id), ''Status'') = ''ONLINE''
ORDER BY
		FS.database_id,
		FS.file_id,
		avg_io_stall_ms DESC OPTION (RECOMPILE);';
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO
