/*============================================================================
	File:		003 - A02 - TEMPDB analysis - Allocation by object types.sql

	Summary:	This script gives you an overview of all settings of 
				your user databases.

	Date:		June 2015
	Session:	Analysis of a Microsoft SQL Server

	Information:
				For test purposes the script
				099 - A01 - RCSI and side effects to TEMPDB.sql
				can be used to demonstrate sideeffects of RCSI

	SQL Server Version: 2008 / 2012 / 2014 / 2017 / 2019
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

SELECT	FreePages			=	SUM(unallocated_extent_page_count),
		FreeSpaceMB			=	SUM(unallocated_extent_page_count) / 128.0,
		VersionStorePages	=	SUM(version_store_reserved_page_count),
		VersionStoreMB		=	SUM(version_store_reserved_page_count) / 128.0,
		InternalObjectPages =	SUM(internal_object_reserved_page_count),
		InternalObjectsMB	=	SUM(internal_object_reserved_page_count) / 128.0,
		UserObjectPages		=	SUM(user_object_reserved_page_count),
		UserObjectsMB		=	SUM(user_object_reserved_page_count) / 128.0
FROM	tempdb.sys.dm_db_file_space_usage;
GO

-- get a list of items in TEMPDB for each session!
SELECT	es.session_id AS [SESSION ID],
		DB_NAME(es.database_id) AS [DATABASE Name],
		HOST_NAME AS [System Name],
		program_name AS [Program Name],
		es.login_name AS [USER Name],
		es.status,
		es.cpu_time AS [CPU TIME (in milisec)],
		es.total_scheduled_time AS [Total Scheduled TIME (in milisec)],
		es.total_elapsed_time AS    [Elapsed TIME (in milisec)],
		(es.memory_usage * 8)      AS [Memory USAGE (in KB)],
		(spu.user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
		(spu.user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
		(spu.internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
		(spu.internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
		CASE es.is_user_process
			WHEN 1      THEN 'user session'
			WHEN 0      THEN 'system session'
		END         AS [SESSION Type], 
		es.row_count AS [ROW COUNT],
		st.text
FROM	sys.dm_db_session_space_usage spu INNER join sys.dm_exec_sessions es
		ON spu.session_id = es.session_id INNER JOIN sys.dm_exec_requests er
		ON es.session_id = er.session_id
		CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE	is_user_process = 1

