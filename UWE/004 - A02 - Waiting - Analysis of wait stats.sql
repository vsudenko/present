/*============================================================================
	File:		004 - A02 - Analysis of wait stats.sql

	Summary:	This script is part of the collection from Glen Berry and shows
				the wait stats of a system!
				http://www.sqlskills.com/blogs/glenn/category/dmv-queries/

	Info:		The original script has been modified by Uwe Ricken.
				There is an additional column with a link to the library 
				of prominent wait stats description to RED GATE library!

	Date:		May 2019
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017 / 2019
------------------------------------------------------------------------------
	Written by Paul Randal, SQL Skills

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE master;
GO
--DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR)

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

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
    WHERE	[wait_type]
			NOT LIKE N'PREEMPTIVE%'
			AND [wait_type] NOT IN
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
		N'QDS_ASYNC_QUEUE',				N'XE_LIVE_TARGET_TVF',
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
		N'QDS_SHUTDOWN_QUEUE',			N'CXCONSUMER',
		N'SOS_WORK_DISPATCHER',			N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
		N'XTP_PREEMPTIVE_TASK',			N'MSQL_DQ', N'OLEDB',
		N'PVS_PREALLOCATE',				N'VDI_CLIENT_OTHER',
		N'PARALLEL_REDO_WORKER_WAIT_WORK',	N'REDO_THREAD_PENDING_WORK',
		N'DBMIRROR_DBM_MUTEX', N'DBMIRROR_SEND')
	AND	waiting_tasks_count > 0
	)
SELECT	MAX ([W1].[wait_type]) AS [WaitType],
		CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
		CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Suspended_S],
		CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Runnable_S],
		MAX ([W1].[WaitCount]) AS [WaitCount],
		CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
		CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
		CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
		CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
		'https://documentation.red-gate.com/sm8/analyzing-performance/overview-pages/using-performance-diagnostics/list-of-common-wait-types/' + LOWER(W1.wait_type) AS [DocumentLink]
FROM	[Waits] AS [W1] INNER JOIN [Waits] AS [W2]
		ON ([W2].[RowNum] <= [W1].[RowNum])
GROUP BY
		[W1].[RowNum],
		W1.wait_type
HAVING	SUM ([W2].[Percentage]) - MAX ([W1].[Percentage]) < 99.9;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO
