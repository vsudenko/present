/*============================================================================
	File:		099 - A01 - Demodatabase for workload demos.sql

	Summary:	This script creates a demo database which will be used for
				the future demonstration scripts


	Date:		December 2020

	SQL Server Version: 2008 / 2012 / 2014 / 2017 / 2019
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

IF DB_ID(N'CustomerOrders') IS NOT NULL
BEGIN
	ALTER DATABASE CustomerOrders SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE CustomerOrders;
END
GO

-- read the default pathes for database files from the registry (>= SQL 2012)
DECLARE	@DataPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(256)) + N'CustomerOrders.mdf';
DECLARE @LogPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(256)) + N'CustomerOrders.ldf';

RESTORE DATABASE CustomerOrders
FROM DISK = N'S:\Backup\CustomerOrders.bak'
WITH
	MOVE N'CustomerOrders_Data' TO @DataPath,
	MOVE N'CustomerOrders_Log' TO @LogPath,
	STATS = 10,
	REPLACE,
	RECOVERY;
GO

ALTER AUTHORIZATION ON DATABASE::[CustomerOrders] TO sa;
ALTER DATABASE [CustomerOrders] SET RECOVERY SIMPLE;
ALTER DATABASE [CustomerOrders] SET COMPATIBILITY_LEVEL = 130;
GO

-- Cross check for created database files
SELECT	type,
		type_desc,
		MF.physical_name,
		size / 128.0	AS	size_MB
FROM	sys.master_files AS MF
WHERE	MF.database_id = DB_ID(N'CustomerOrders');
GO