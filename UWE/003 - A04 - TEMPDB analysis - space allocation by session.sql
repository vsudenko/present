/*============================================================================
	File:		003 - A04 - TEMPDB analysis - space allocation by session.sql

	Summary:	This script evaluates the usage of each space type in tempdb
				by session.

	Date:		January 2016
	Session:	Analysis of a Microsoft SQL Server

	Information:

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
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

WITH TaskAllocation
AS
(
	SELECT	session_id,
			CAST(SUM(user_objects_alloc_page_count ) / 128.0 AS NUMERIC ( 18, 2 )) AS User_Pages_MB,
			CAST(SUM(internal_objects_alloc_page_count ) / 128.0 AS NUMERIC ( 18, 2 )) AS Internal_Pages_MB
	FROM	sys.dm_db_task_space_usage
	GROUP BY
		session_id
)
SELECT	S.session_id,
		S.login_time,
		S.host_name,
		S.program_name,
		S.status						AS SessionStatus,
		S.cpu_time,
		S.memory_usage,
		S.last_request_start_time,
		S.logical_reads,
		DER.status						AS RequestStatus,
		DER.command,
		DEST.text,
		CAST(DEQP.query_plan AS XML)	AS query_plan,
		DB_NAME(DER.database_id)		AS Database_Name,
		TA.User_Pages_MB,
		TA.Internal_Pages_MB
FROM	sys.dm_exec_sessions AS S INNER JOIN TaskAllocation AS TA
		ON (S.session_id = TA.session_id) LEFT JOIN sys.dm_exec_requests AS DER
		ON (S.session_id = DER.session_id )
		CROSS APPLY sys.dm_exec_sql_text ( DER.sql_handle ) AS DEST
		CROSS APPLY sys.dm_exec_query_plan ( DER.plan_handle ) AS DEQP
WHERE	s.is_user_process = 1
		AND s.status <> N'SLEEPING'
		AND s.session_id <> @@SPID;