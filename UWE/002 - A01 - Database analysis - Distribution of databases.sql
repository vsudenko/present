/*============================================================================
	File:		002 - A01 - Database analysis - Distribution of databases.sql

	Summary:	This script returns all databases and it's physical location of
				data files. Furthermore the result is separated by
				- Database
				- Drive Letter
				- FileType

				It gives a total of files and the complete amount of storage
				which is consumed by the database files.

	Date:		May 2015
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

DECLARE	@ShowSystemDB	TINYINT = 0;

SELECT	D.name									AS	DatabaseName,
		LEFT(MF.physical_name, 2)				AS	Drive,
		REPLACE(MF.type_desc, N'ROWS', N'DATA')	AS	FileType,
		COUNT_BIG(MF.file_id)					AS	Num_Of_Files,
		SUM(size / 128.0)						AS	size_MB
FROM	sys.databases AS D INNER JOIN sys.master_files AS MF
		ON (D.database_id = MF.database_id)
WHERE	@ShowSystemDB = 1
		OR D.database_id > 4
GROUP BY
		D.Database_id,
		D.name,
		LEFT(MF.physical_name, 2),
		MF.type_desc
ORDER BY
		CASE WHEN D.database_id <= 4
			 THEN 0
			 ELSE 1
		END,
		D.Name	ASC,
		LEFT(MF.physical_name, 2) ASC,
		MF.type_desc DESC;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO