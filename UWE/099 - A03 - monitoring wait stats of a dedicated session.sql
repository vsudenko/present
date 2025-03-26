/*============================================================================
	File:		099 - A03 - monitoring wait stats of a dedicated session.sql

	Summary:	This script creates an extended event session and monitors
				only waits from a dedicated session id

				This script is by courtesy of Paul Randall (SQL Skills) from his
				blog article:

				http://www.sqlskills.com/blogs/paul/capturing-wait-stats-for-a-single-operation/

	Date:		March 2015

	SQL Server Version: 2008 / 2012 / 2014
============================================================================*/
USE master;
GO

-- in the first step an existing session will be dropped
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'MonitorWaits')
	DROP EVENT SESSION MonitorWaits ON SERVER
GO 

-- a new extended event session will be created to monitor a dedicated
-- session id. Make sure that you know the session id before you create
-- 
CREATE EVENT SESSION MonitorWaits ON SERVER
ADD EVENT sqlos.wait_info
    (WHERE sqlserver.session_id = 226 /* session_id of connection to monitor */)
ADD TARGET package0.asynchronous_file_target
    (SET FILENAME = N'D:\DATA\EE_WaitStats.xel', 
    METADATAFILE = N'D:\DATA\EE_WaitStats.xem')
WITH (max_dispatch_latency = 1 seconds);
GO 
