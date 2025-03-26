/*============================================================================
	File:		004 - A01 - What tasks are CURRENTLY waiting.sql

	Summary:	Dieses Script zeigt Beispiele für die momentanen Verbindungen,
				die zum Server aufgebaut sind.

				PS: Für einen Test mit mehreren Sessions müssen folgende Bedingungen
					erfüllt sein:

				osstress ist auf dem Computer vorhanden
				http://support.microsoft.com/kb/944837/en-us

				Sowohl die Datenbank demo_db als auch die Prozedur für den Stresstest
				sind implementiert:

				0001 - create database and relations.sql
				0002 - Stored Procedure for execution with ostress.exe.sql

	Date:		Mai 2015
	Historie:	Januar 2016	- Anzeigen von Blocking Prozessen, die NICHT warten!

	SQL Server Version: 2016 / 2017 / 2019
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

	WITH Session_List
	AS
	(
		SELECT	dowt.session_id,
				dowt.blocking_session_id
		FROM	sys.dm_os_waiting_tasks AS dowt
				INNER JOIN sys.dm_exec_sessions AS des
				ON (dowt.session_id = des.session_id)
		WHERE	des.is_user_process = 1
				AND des.session_id <> @@SPID

		UNION ALL

		SELECT	session_id, blocking_session_id
		FROM
		(
			SELECT	des.session_id,
					0		AS	blocking_session_id
			FROM	sys.dm_exec_sessions AS des
			WHERE	des.is_user_process = 1

			EXCEPT

			SELECT	dowt.session_id,
					0
			FROM	sys.dm_os_waiting_tasks AS dowt
		) AS running_sessions
	),
	Session_hierarchy
	AS
	(
		SELECT	1				AS	Level,
				sl.session_id,
				sl.blocking_session_id
		FROM	Session_List AS sl
		WHERE	sl.blocking_session_id = 0

		UNION ALL

		SELECT	Level + 1,
				sl.session_id,
				sl.blocking_session_id
		FROM	Session_hierarchy AS sh
				INNER JOIN Session_List AS sl
				ON (sh.session_id = sl.blocking_session_id)
		WHERE	sl.session_id <> sl.blocking_session_id
	)
	SELECT	sh.Level,
			sh.session_id,
			sh.blocking_session_id,
			x.login_time,
			x.host_name,
			x.program_name,
			x.login_name,
			x.status,
			x.cpu_time,
			x.memory_usage,
			x.total_scheduled_time,
			x.total_elapsed_time,
			x.last_request_start_time,
			x.last_request_end_time,
			x.database_name,
			x.open_transaction_count,
			x.SQLCommand,
			CAST(sw.SessionWaits AS XML) AS SessionWaits,
			CAST(L.Locks AS XML) AS Locks
	FROM	Session_hierarchy AS sh
			CROSS APPLY
			(
				SELECT	des.login_time,
						des.host_name,
						des.program_name,
						des.login_name,
						des.status,
						des.cpu_time,
						des.memory_usage,
						des.total_scheduled_time,
						des.total_elapsed_time,
						des.last_request_start_time,
						des.last_request_end_time,
						DB_NAME(des.database_id)	AS	database_name,
						des.open_transaction_count,
						dest.text	AS	SQLCommand
				FROM	sys.dm_exec_connections AS dec
						INNER JOIN sys.dm_exec_sessions AS des
						ON (dec.session_id = des.session_id)
						LEFT JOIN sys.dm_exec_requests AS der
						ON (des.session_id = der.session_id)

						OUTER APPLY sys.dm_exec_sql_text
						(
							ISNULL(der.sql_handle, dec.most_recent_sql_handle)
						) AS dest
				WHERE	des.session_id = sh.session_id
			) AS x
			OUTER APPLY
			(
				SELECT	session_id,
						wait_type,
						waiting_tasks_count,
						wait_time_ms,
						max_wait_time_ms,
						signal_wait_time_ms
				FROM	sys.dm_exec_session_wait_stats
				WHERE	session_id = sh.session_id
				FOR XML PATH ('wait_type')
			) AS sw (SessionWaits)
			OUTER APPLY
			(
				SELECT	resource_type,
						resource_description,
						request_mode,
						request_type,
						request_status
				FROM	sys.dm_tran_locks
				WHERE	resource_type <> N'DATABASE'
				AND request_session_id = sh.session_id
				FOR XML PATH ('Locking')
			) AS L (Locks)

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO
