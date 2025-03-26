/*============================================================================
	File:		099 - A70 - Monitoring Wait Stats daily.sql

	Summary:	This script creates a database for the storage of the
				daily different wait stats for a daily analysis!

				THIS SCRIPT IS PART OF THE TRACK: "Analysis of SQL Server"

	Date:		March 2018

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

IF DB_ID(N'MaintenanceDB') IS NULL
BEGIN
	CREATE DATABASE MaintenanceDB;
	ALTER DATABASE MaintenanceDB SET RECOVERY SIMPLE;
	ALTER AUTHORIZATION ON DATABASE::MaintenanceDB TO sa;
END
GO

USE MaintenanceDB;
GO

-- Create a table for the storage of the daily wait stats analysis
IF OBJECT_ID(N'dbo.WaitStatsAnalysis', N'U') IS NULL
BEGIN
	WITH [Waits] AS
	(
		SELECT	[wait_type],
				[wait_time_ms] / 1000.0 AS [WaitS],
				([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
				[signal_wait_time_ms] / 1000.0 AS [SignalS],
				[waiting_tasks_count] AS [WaitCount],
				100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
				ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
		FROM	sys.dm_os_wait_stats
		WHERE	[wait_type] NOT IN
		(
			N'BROKER_EVENTHANDLER',         N'BROKER_RECEIVE_WAITFOR',
			N'BROKER_TASK_STOP',            N'BROKER_TO_FLUSH',
			N'BROKER_TRANSMITTER',          N'CHECKPOINT_QUEUE',
			N'CHKPT',                       N'CLR_AUTO_EVENT',
			N'CLR_MANUAL_EVENT',            N'CLR_SEMAPHORE',
			N'DBMIRROR_DBM_EVENT',          N'DBMIRROR_EVENTS_QUEUE',
			N'DBMIRROR_WORKER_QUEUE',       N'DBMIRRORING_CMD',
			N'DIRTY_PAGE_POLL',             N'DISPATCHER_QUEUE_SEMAPHORE',
			N'EXECSYNC',                    N'FSAGENT',
			N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
			N'HADR_CLUSAPI_CALL',           N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
			N'HADR_LOGCAPTURE_WAIT',        N'HADR_NOTIFICATION_DEQUEUE',
			N'HADR_TIMER_TASK',             N'HADR_WORK_QUEUE',
			N'KSOURCE_WAKEUP',              N'LAZYWRITER_SLEEP',
			N'LOGMGR_QUEUE',                N'ONDEMAND_TASK_QUEUE',
			N'PWAIT_ALL_COMPONENTS_INITIALIZED',
			N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
			N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
			N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
			N'SERVER_IDLE_CHECK',           N'SLEEP_BPOOL_FLUSH',
			N'SLEEP_DBSTARTUP',             N'SLEEP_DCOMSTARTUP',
			N'SLEEP_MASTERDBREADY',         N'SLEEP_MASTERMDREADY',
			N'SLEEP_MASTERUPGRADED',        N'SLEEP_MSDBSTARTUP',
			N'SLEEP_SYSTEMTASK',            N'SLEEP_TASK',
			N'SLEEP_TEMPDBSTARTUP',         N'SNI_HTTP_ACCEPT',
			N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
			N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
			N'SQLTRACE_WAIT_ENTRIES',       N'WAIT_FOR_RESULTS',
			N'WAITFOR',                     N'WAITFOR_TASKSHUTDOWN',
			N'WAIT_XTP_HOST_WAIT',          N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
			N'WAIT_XTP_CKPT_CLOSE',         N'XE_DISPATCHER_JOIN',
			N'XE_DISPATCHER_WAIT',          N'XE_TIMER_EVENT',
			N'QDS_SHUTDOWN_QUEUE',			N'QDS_ASYNC_QUEUE')
		AND	waiting_tasks_count > 0
		)
	SELECT	CAST(NULL AS DATETIME2(0)) AS [MeasureTime],
			MAX ([W1].[wait_type]) AS [WaitType],
			CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
			CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
			CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
			MAX ([W1].[WaitCount]) AS [WaitCount],
			CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
			CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
			CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
			CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S]
	INTO	dbo.WaitStatsAnalysis
	FROM	[Waits] AS [W1] INNER JOIN [Waits] AS [W2]
			ON ([W2].[RowNum] <= [W1].[RowNum])
	WHERE	1 = 0
	GROUP BY
			[W1].[RowNum],
			W1.wait_type
	HAVING	SUM ([W2].[Percentage]) - MAX ([W1].[Percentage]) < 99;

	CREATE UNIQUE CLUSTERED INDEX cuix_WaitStatsAnalysis_DateTime_WaitType
	ON dbo.WaitStatsAnalysis
	(
		[MeasureTime],
		[WaitType]
	);
END
GO

SELECT * FROM dbo.WaitStatsAnalysis;