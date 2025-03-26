/*============================================================================
	File:		005 - A04 - Missing Indexes and its impact.sql

	Summary:	This script gives you an overview of all statistics
				in a dedicated database.

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
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

-- Missing Indexes for all databases by Index Advantage  (Query 25) (Missing Indexes All Databases)
SELECT	DDMIGS.last_user_seek,
		DDMID.[statement]				AS [Database.Schema.Table],
		DDMID.equality_columns,
		DDMID.inequality_columns,
		DDMID.included_columns,
		DDMIGS.unique_compiles,
		DDMIGS.user_seeks,
		DDMIGS.avg_total_user_cost,
		DDMIGS.avg_user_impact,
		CAST(
				user_seeks * avg_total_user_cost *
				(avg_user_impact * 0.01)
				AS NUMERIC(10, 2)
			 )							AS [index_advantage]
FROM	sys.dm_db_missing_index_group_stats AS DDMIGS
		INNER JOIN sys.dm_db_missing_index_groups AS DDMIG
		ON (DDMIGS.group_handle = DDMIG.index_group_handle)
		INNER JOIN sys.dm_db_missing_index_details AS DDMID
		ON (DDMIG.index_handle = DDMID.index_handle)
ORDER BY
		DDMIGS.unique_compiles DESC
OPTION	(RECOMPILE);
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO