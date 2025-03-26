/*============================================================================
	File:		002 - A04 - Database analysis - Bufferpool usage.sql

	Summary:	This script gives you an overview of all settings of 
				your user databases.

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

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

-- Get total buffer usage by database for current instance
WITH	BPU
AS
(
	SELECT	DB_NAME(DOBP.database_id)	AS database_name,
			COUNT(*) / 128.0			AS CachedSize
	FROM	sys.dm_os_buffer_descriptors  DOBP
	WHERE	DOBP.database_id NOT IN (1, 3, 4, 32767)
	GROUP BY
			database_id
)
SELECT	ROW_NUMBER() OVER(ORDER BY CachedSize DESC)							AS [Buffer Pool Rank],
		BPU.database_name,
		CAST(CachedSize AS NUMERIC(18, 2))									AS [Cached Size (MB)],
		CAST(CachedSize / SUM(CachedSize) OVER() * 100.0 AS DECIMAL(5,2))	AS [Buffer Pool Percent]
FROM	BPU
ORDER BY
		[Buffer Pool Rank] OPTION (RECOMPILE);
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO