/*============================================================================
	File:		005 - A01 - Index usage in dedicated database.sql

	Summary:	This script analyzes the current situation in the plan cache
				of the connected SQL Server instance

	Optimization:	INCLUDE Pagecount

	Date:		November 2019

	SQL Server Version: 2012 / 2014 / 2016 / 2017 / 2019
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
SET NOCOUNT ON
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

SELECT	QUOTENAME(S.name) + N'.' + QUOTENAME(T.name)	AS	Object_Name,
		I.index_id,
		P.partition_id,
		QUOTENAME(I.name)						AS	Index_name,
		DDIUS.user_seeks,
		DDIUS.user_scans,
		DDIUS.user_lookups,
		DDIUS.user_updates,
		P.rows,
		(
			DDIUS.user_seeks +
			DDIUS.user_scans +
			DDIUS.user_lookups -
			DDIUS.user_updates
		)										AS	Index_Performance
		,
		DDIUS.last_user_seek,
		DDIUS.last_user_scan,
		DDIUS.last_user_lookup,
		DDIUS.last_user_update
FROM	sys.schemas AS S INNER JOIN sys.tables AS T
		ON	(S.schema_id = T.schema_id) INNER JOIN sys.indexes AS I
		ON	(T.object_id = I.object_id) LEFT JOIN sys.dm_db_index_usage_stats AS DDIUS
		ON	(
				I.object_id = DDIUS.object_id AND
				I.index_id = DDIUS.index_id
			) INNER JOIN sys.partitions AS P
		ON	(
				I.index_id = P.index_id AND
				I.object_id = P.object_id
			)
WHERE	I.is_disabled = 0
		AND DDIUS.database_id = DB_ID()
		AND P.rows >= 100000
ORDER BY
		QUOTENAME(S.name) + QUOTENAME(T.name),
		I.index_id;
GO

-- unused indexes
;WITH unusedIndexes
AS
(
	SELECT	QUOTENAME(S.name) + N'.' + QUOTENAME(T.name)	AS	Object_Name,
			I.index_id,
			QUOTENAME(I.name)						AS	Index_name,
			ISNULL(DDIUS.user_seeks, 0)				AS	user_seeks,
			ISNULL(DDIUS.user_scans, 0)				AS	user_scans,
			ISNULL(DDIUS.user_lookups, 0)			AS	user_lookups,
			ISNULL(DDIUS.user_updates, 0)			AS	user_updates,
			(
				ISNULL(DDIUS.user_seeks, 0) +
				ISNULL(DDIUS.user_scans, 0) +
				ISNULL(DDIUS.user_lookups, 0) -
				ISNULL(DDIUS.user_updates, 0)
			)										AS	Index_Performance
			,
			DDIUS.last_user_seek,
			DDIUS.last_user_scan,
			DDIUS.last_user_lookup,
			DDIUS.last_user_update
	FROM	sys.schemas AS S INNER JOIN sys.tables AS T
			ON	(S.schema_id = T.schema_id) INNER JOIN sys.indexes AS I
			ON	(T.object_id = I.object_id) LEFT JOIN sys.dm_db_index_usage_stats AS DDIUS
			ON	(
					I.object_id = DDIUS.object_id AND
					I.index_id = DDIUS.index_id
				)
)
SELECT	*
FROM	unusedIndexes AS UI
WHERE	UI.user_seeks +
		UI.user_scans +
		UI.user_lookups = 0
		AND UI.index_id > 1
		AND UI.user_updates > 0
ORDER BY
		UI.Object_Name,
		UI.index_id;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO
