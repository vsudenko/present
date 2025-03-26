/*============================================================================
	File:		001 - A04 - System Environment - Configuration.sql

	Summary:	Ths script returns the privileges of the system account
				which will be used by the SQL Server Database Engine
				
	Date:		May 2015
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017 / 2019
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

SELECT	name,
		description,
		value_in_use,
		is_dynamic,
		C.is_advanced,
		CASE C.name
			WHEN 'optimize for ad hoc workloads' THEN '099 - A01 - Plan Cache Bloating.sql'
			ELSE NULL
		END		AS	DemoScript
FROM	sys.configurations AS C
WHERE	name IN
(
	N'Ad Hoc Distributed Queries',
	N'recovery interval (min)',
	N'locks',
	N'fill factor (%)',
	N'cross db ownership chaining',
	N'max worker threads',
	N'cost threshold for parallelism',
	N'max degree of parallelism',
	N'min server memory (MB)',
	N'max server memory (MB)',
	N'clr enabled',
	N'optimize for ad hoc workloads',
	N'Database Mail XPs',
	N'xp_cmdshell',
	N'TARGET_RECOVERY_TIME'
)
ORDER BY name;
GO