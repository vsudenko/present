/*============================================================================
	File:		005 - A02 - Index physical stats in dedicated database.sql

	Summary:	This script analyzes the current situation in the plan cache
				of the connected SQL Server instance

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
SELECT	QUOTENAME(S.name) + '.' + QUOTENAME(T.name)	AS	Object_Name,
		QUOTENAME(I.name)							AS	Index_name,
		DDIPS.index_level,
		DDIPS.avg_fragmentation_in_percent,
		DDIPS.fragment_count,
		DDIPS.avg_fragment_size_in_pages,
		DDIPS.avg_page_space_used_in_percent,
		DDIPS.page_count,
		DDIPS.record_count,
		DDIPS.forwarded_record_count,
		DDIPS.version_ghost_record_count
FROM	sys.schemas AS S INNER JOIN sys.tables AS T
		ON	(S.schema_id = T.schema_Id) INNER JOIN sys.indexes AS I
		ON	(T.object_id = I.object_Id)
		CROSS APPLY sys.dm_db_index_physical_stats
		(
			DB_ID(),
			I.object_Id,
			I.index_id,
			NULL,
			'DETAILED'
		) AS DDIPS
WHERE	I.is_disabled = 0
ORDER BY
		S.name,
		T.name,
		I.index_id,
		DDIPS.index_level;