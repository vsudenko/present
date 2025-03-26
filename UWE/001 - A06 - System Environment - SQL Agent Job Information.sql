/*============================================================================
	File:		001 - A06 - System Environment - SQL Agent Job Information.sql

	Summary:	This script gives you an overview of the current value of the
				PLE

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

-- Get SQL Server Agent jobs and Category information
SELECT  sj.name						AS [JobName],
        sj.[description]			AS [JobDescription],
        SUSER_SNAME(sj.owner_sid)	AS [JobOwner],
        sj.date_created,
        sj.[enabled],
        sj.notify_email_operator_id,
        sc.name AS [CategoryName]
FROM    msdb.dbo.sysjobs AS sj INNER JOIN msdb.dbo.syscategories AS sc
		ON (sj.category_id = sc.category_id)
ORDER BY
		sj.name
OPTION	(RECOMPILE);
GO

/* When did the jobs run the last time */
SELECT	SJ.name												AS [Job Name],
		run_status											AS [Run Status],
		MAX(msdb.dbo.agent_datetime(run_date, run_time))	AS [Last Time Job Ran On]
FROM	msdb.dbo.sysjobs AS SJ LEFT JOIN msdb.dbo.SYSJOBHISTORY SJH
		ON	(SJ.job_id = SJH.job_id)
WHERE	SJH.step_id = 0 AND
		SJH.run_status = 1
GROUP BY
		SJ.name,
		SJH.run_status
ORDER BY
		[Last Time Job Ran On] DESC
OPTION	(RECOMPILE);
GO