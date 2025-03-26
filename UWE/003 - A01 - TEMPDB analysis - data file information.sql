/*============================================================================
	File:		003 - A01 - TEMPDB analysis - data file information.sql

	Summary:	This script gives you an overview of all settings of 
				your user databases.

	Optimize:	add column for growth

	Date:		June 2015
	Session:	Analysis of a Microsoft SQL Server

	Information:
				For test purposes the script
				099 - A01 - RCSI and side effects to TEMPDB.sql
				can be used to demonstrate the side effects of RCSI

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
USE master;
GO

-- this view gives an overview of eventually missing tempdb files!
WITH CPU
AS
(
	SELECT	CASE WHEN CAST(value_in_use AS BIGINT) = 0
				 THEN (SELECT cpu_count FROM sys.dm_os_sys_info AS DOSI)
				 ELSE CAST(value_in_use AS BIGINT) % 2
			END										AS	IsActive,
			CASE WHEN CAST(value_in_use AS BIGINT) = 0
				 THEN CAST(0 AS BIGINT)
				 ELSE CAST(value_in_use AS BIGINT) / 2
			END										AS	next_value
	FROM	sys.configurations
	WHERE	name = 'affinity mask'

	UNION ALL

	SELECT	CPU.next_value % 2						AS	IsActive,
			CPU.next_value / 2						AS	next_value
	FROM	CPU
	WHERE	next_value > 0
)
SELECT	@@SERVERNAME				AS	ServerName,
		COUNT_BIG(*)				AS	NumDatabaseFiles,
		C.CPUS						AS	NumCPU,
		CASE WHEN C.CPUS <= 8
			 THEN C.CPUS - COUNT_BIG(*)
			 ELSE CASE WHEN C.CPUS > 8
					   THEN 8 - COUNT_BIG(*)
					   ELSE 0
				  END
		END							AS	RequiredFiles
FROM	tempdb.sys.database_files AS MF,
		(SELECT	SUM(IsActive) AS CPUS FROM	CPU) AS C 
WHERE	MF.type_desc != 'LOG'
GROUP BY
		C.CPUS;
GO

-- is TEMPDB sharing it's storage with other databases
USE tempdb;
GO

WITH tdb
AS
(
	SELECT	DISTINCT
			LEFT(physical_name, 2)	AS	Drive
	FROM	tempdb.sys.database_files AS MF
)
SELECT	D.name,
		D.create_date,
		physical_name,
		type_desc,
		size / 128.0							AS	initial_size_mb,
		FV.BytesOnDisk / POWER(1024, 2)	* 1.0	AS	disk_size_mb,
		FILEPROPERTY(MF.name, 'SpaceUsed')	/ 128.0	AS	used_mb,
		FV.BytesRead / POWER(1024, 2) * 1.0		AS	mb_read,
		FV.BytesWritten / POWER(1024, 2) * 1.0	AS	mb_written
FROM	sys.databases AS D, sys.database_files AS MF
		CROSS APPLY sys.fn_virtualfilestats(DB_ID(), MF.file_id) AS FV
WHERE	D.database_id = DB_ID();
GO

USE master;
GO
