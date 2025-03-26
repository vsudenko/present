/*============================================================================
	File:		001 - A07 - System Environment - Backup-Information.sql

	Summary:	This script returns for all databases the information about the
				last taken backup.

	Date:		May 2016
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014 / 2016
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

SELECT	CAST(SERVERPROPERTY('Servername') AS CHAR(100)) AS Server, 
		BS.database_name, 
		BS.backup_start_date, 
		BS.backup_finish_date, 
		BS.expiration_date, 
		CASE BS.type 
			WHEN 'D' THEN 'Database' 
			WHEN 'L' THEN 'Log'
			WHEN 'I' THEN 'Differential'
		END							AS backup_type, 
		BS.backup_size, 
		BMF.logical_device_name, 
		BMF.physical_device_name, 
		BS.name		AS backupset_name, 
		BS.description
FROM	msdb.dbo.backupmediafamily AS BMF
		INNER JOIN msdb.dbo.backupset AS BS ON BMF.media_set_id = BS.media_set_id
WHERE	BS.backup_start_date >= GETDATE() - 7
ORDER BY 
		BS.database_name, 
		BS.backup_finish_date DESC;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO