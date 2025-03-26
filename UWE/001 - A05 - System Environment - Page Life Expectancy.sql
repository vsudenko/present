/*============================================================================
	File:		001 - A05 - System Environment - Page Life Expectancy.sql

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

-- Page Life Expectancy (PLE) value for each NUMA node in current instance!
SELECT	@@SERVERNAME											AS	[Server Name],
		[object_name],
		[instance_name],
		[cntr_value]											AS	[Page Life Expectancy],
		CAST(cntr_value AS INT) / 60							AS	[Page Life Expectancy_Minutes],
		CASE WHEN [cntr_value] < 1000
			 THEN 'Check memory and queries'
			 ELSE NULL
		END														AS	[Hint],
		GETDATE()												AS	[Measure_Date_Time],
		(SELECT sqlserver_start_time FROM sys.dm_os_sys_info)	AS	Server_Start_Date_Time
FROM	sys.dm_os_performance_counters WITH (NOLOCK)
WHERE	[object_name] LIKE N'%Buffer Node%' AND
		[counter_name] = N'Page life expectancy' OPTION (RECOMPILE);
GO