/*============================================================================
	File:		002 - A06 - Database analysis - CPU analysis.sql

	Summary:	This script gives you an overview of all settings of 
				your user databases.

				The basic script idea has been developed by Glen Berry
				https://sqlserverperformance.wordpress.com/2014/09/17/sql-server-diagnostic-information-queries-for-september-2014/

	Date:		February 2016
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014 /2016 / 2017 / 2019
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

WITH DB_CPU_Stats
AS
(
	SELECT	DatabaseID,
			DB_NAME(DatabaseID)		AS [Database Name],
			SUM(total_worker_time)	AS [CPU_Time_Ms]
	FROM	sys.dm_exec_query_stats AS qs
			CROSS APPLY
			(
				SELECT	CAST(value AS INT) AS [DatabaseID] 
				FROM	sys.dm_exec_plan_attributes(qs.plan_handle)
				WHERE	attribute = N'dbid'
			) AS F_DB
	GROUP BY
			DatabaseID
)
SELECT	ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC)	AS [CPU Rank],
		[Database Name],
		[CPU_Time_Ms], 
		CAST
		(
			[CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0
			AS DECIMAL(5, 2)
		) AS [CPU Percent]
FROM	DB_CPU_Stats
WHERE	DatabaseID <> 32767 -- ResourceDB
ORDER BY
		[CPU Rank] OPTION (RECOMPILE);
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO