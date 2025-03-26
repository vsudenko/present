/*============================================================================
	File:		005 - A02 - Statistics in explicit database.sql

	Summary:	This script gives you an overview of all statistics
				in a dedicated database.

	Date:		June 2015
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2012 / 2014 / 2016
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/

-- what statistics do we have and what is the modification counter?
SELECT	S.name,
		SP.object_id,
        SP.stats_id,
        SP.last_updated,
        SP.rows,
        SP.rows_sampled,
        SP.steps,
        SP.unfiltered_rows,
        SP.modification_counter,
        SP.persisted_sample_percent
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS SP