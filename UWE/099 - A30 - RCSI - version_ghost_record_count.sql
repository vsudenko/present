/*============================================================================
	File:		099 - A30 - RCSI - version_ghost_record_count.sql

	Summary:	This demonstrates bad code which leads to a huge
				number of version_ghost_record_count.
				This problem will escalate if another query is running
				against an aggregation (e.g. MAX).

	Date:		March 2017
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
USE master;
GO

RESTORE DATABASE CustomerOrders FROM DISK = N'S:\Backup\CustomerOrders.bak'
WITH REPLACE;
GO

ALTER DATABASE CustomerOrders SET RECOVERY SIMPLE;
ALTER AUTHORIZATION ON DATABASE::CustomerOrders TO sa;
GO

ALTER DATABASE CustomerOrders SET READ_COMMITTED_SNAPSHOT ON;
GO

USE CustomerOrders;
GO

-- Create a unique clustered index on dbo.Customers
CREATE UNIQUE CLUSTERED INDEX cuix_Customers_Id ON dbo.Customers (Id);
GO


SET NOCOUNT ON;
GO

BEGIN TRANSACTION;
GO
	DECLARE	@EndTime DATETIME2(0) = DATEADD(MINUTE, 3, GETDATE());

	-- Insert a new record at the end
	WHILE (GETDATE() <= @EndTime)
	BEGIN
		INSERT INTO dbo.Customers (Name, InsertUser, InsertDate)
		SELECT	Name, InsertUser, InsertDate
		FROM	dbo.Customers WHERE Id = (SELECT MIN(Id) FROM dbo.Customers);

		DELETE	dbo.Customers
		WHERE	Id = (SELECT MIN(Id) FROM dbo.Customers);

		WAITFOR DELAY '00:00:00:010';
	END


-- check in a second window the number of version_ghost_record_count
USE CustomerOrders;
GO
ROLLBACK TRANSACTION;
GO

SELECT	page_count,
		version_ghost_record_count
FROM sys.dm_db_index_physical_stats
(
	DB_ID(),
	OBJECT_ID(N'dbo.Customers'),
	NULL,
	NULL,
	N'DETAILED'
)
WHERE	index_level = 0;
GO

SELECT * FROM sys.dm_tran_locks
WHERE	resource_database_id = DB_ID()
		AND resource_type != N'DATABASE'
GO

SET STATISTICS IO ON;
GO

SELECT * FROM dbo.Customers;
GO
SELECT MAX(Id) FROM dbo.Customers WITH (NOLOCK);
GO
