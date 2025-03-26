/*============================================================================
	File:		003 - A03 - TEMPDB analysis - page latch contention.sql

	Summary:	This script gives you an snapshot information about any
				latch contention in your tempdb.

	Date:		June 2015
	Session:	Analysis of a Microsoft SQL Server

	Information:

	SQL Server Version: 2008 / 2012 / 2014
------------------------------------------------------------------------------
	Written by Robert Davis! (@SQLSoldier)
	http://www.sqlsoldier.com

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
WITH Tasks
AS
(
	SELECT	session_id,
			wait_type,
			wait_duration_ms,
			blocking_session_id,
			resource_description,
			PageID = CAST
			(
				RIGHT
				(
						resource_description,
						LEN(resource_description) - CHARINDEX(':', resource_description, 3)
				) AS INT
			)
	FROM	sys.dm_os_waiting_tasks AS DOWT WITH (NOLOCK)
	WHERE	wait_type LIKE 'PAGE%LATCH_%' AND
			resource_description LIKE '2:%'
)
SELECT	session_id,
		wait_type,
		wait_duration_ms,
		blocking_session_id,
		resource_description,
		ResourceType =	CASE WHEN PageID = 1 Or PageID % 8088 = 0 THEN 'PFS'
							 WHEN PageID = 2 Or PageID % 511232 = 0 THEN 'GAM'
							 WHEN PageID = 3 Or (PageID - 1) % 511232 = 0 THEN 'SGAM'
							 ELSE 'OTHER'
						END
FROM Tasks;