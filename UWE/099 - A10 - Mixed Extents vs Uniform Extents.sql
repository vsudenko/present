/*============================================================================
	File:		099 - A10 - Mixed Extents vs Uniform Extents.sql

	Summary:	This script demonstrates the problem of plan cache bloating.
				The database CustomerOrders is required for this demo!

				This demo shall describe the option
				[optimize for ad hoc workloads] in sys.configurations
				(see 001 - A04!)

				THIS SCRIPT IS PART OF THE TRACK: "Analysis of SQL Server"

	Date:		January 2017

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

IF DB_ID(N'demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE [demo_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [demo_db];
END
GO

CREATE DATABASE [demo_db];
ALTER AUTHORIZATION ON DATABASE::demo_db TO sa;
ALTER DATABASE [demo_db] SET RECOVERY SIMPLE;
ALTER DATABASE [demo_db] SET MIXED_PAGE_ALLOCATIONON OFF;
GO

-- when the new database has been created a demo table can be created
USE [demo_db];
GO

CREATE TABLE dbo.Family (C1 CHAR(8000));
GO

-- the first record will be stored in the table and we check the allocation
INSERT INTO dbo.Family VALUES ('Uwe Ricken');
GO

SELECT	page_type_desc,
		extent_page_id,
		allocated_page_page_id,
		is_iam_page,
		is_mixed_page_allocation,
		page_free_space_percent
FROM	sys.dm_db_database_page_allocations
		(
			DB_ID(),
			OBJECT_ID(N'dbo.Family', N'U'),
			0,
			NULL,
			N'DETAILED'
		)
ORDER BY
		page_type DESC;
GO

DBCC TRACEON (3604);
DBCC PAGE (0, 1, 189, 3);
GO

-- we insert 4 more family members into the table
INSERT INTO dbo.Family VALUES ('Beate Ricken');
INSERT INTO dbo.Family VALUES ('Katharina Ricken');
INSERT INTO dbo.Family VALUES ('Alicia Ricken');
INSERT INTO dbo.Family VALUES ('Maria K.');
GO

SELECT	page_type_desc,
		extent_page_id,
		allocated_page_page_id,
		is_iam_page,
		is_mixed_page_allocation,
		page_free_space_percent
FROM	sys.dm_db_database_page_allocations
		(
			DB_ID(),
			OBJECT_ID(N'dbo.Family', N'U'),
			0,
			NULL,
			N'DETAILED'
		)
ORDER BY
		page_type DESC;
GO

-- and another 4 family members (cats)
INSERT INTO dbo.Family VALUES ('Emma Ricken');
INSERT INTO dbo.Family VALUES ('Josy Ricken');
INSERT INTO dbo.Family VALUES ('Balou Ricken');
INSERT INTO dbo.Family VALUES ('Any other cat');
GO

SELECT	page_type_desc,
		extent_page_id,
		allocated_page_page_id,
		is_iam_page,
		is_mixed_page_allocation,
		page_free_space_percent
FROM	sys.dm_db_database_page_allocations
		(
			DB_ID(),
			OBJECT_ID(N'dbo.Family', N'U'),
			0,
			NULL,
			N'DETAILED'
		)
ORDER BY
		page_type DESC;
GO

-- look into the management page of the table (IAM)
DBCC TRACEON (3604);
DBCC PAGE (demo_db, 1, 189, 3);
GO

INSERT INTO dbo.Family
        ( C1 )
VALUES  ( 'Test'
          );
		  GO 1000

ALTER TABLE dbo.Family REBUILD;
GO

-- look into the management page of the table (IAM)
DBCC TRACEON (3604);
DBCC PAGE (demo_db, 1, 189, 3);
GO