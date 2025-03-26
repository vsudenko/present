/*============================================================================
	File:		099 - A90 - Demonstration of CXPACKET.sql

	Summary:	This script monitors / forces the 
				CXPACKET wait stats stat

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Wait Stats Analysis"

	Date:		April 2019

	SQL Server Version: 2012 / 2014 / 2016 / 2017^/ 2019
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

EXEC dbo.sp_restore_Customers;
GO

USE CustomerOrders;
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

-- reconfigure the threshold for parallelism to default value!
EXEC sys.sp_configure N'cost threshold for parallelism', 5;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sys.sp_configure N'max degree of parallelism', 0;
RECONFIGURE WITH OVERRIDE;
GO

SET STATISTICS IO, TIME ON;
GO

-- the most important query in the system because the CKM
-- (Chief Kitchen Manager)
-- needs the data every morning
SELECT	C.Name,
		YEAR(CO.OrderDate)				AS	YearOfOrder,
		COUNT_BIG(*)					AS	NumOfOrders,
		SUM(COD.Quantity * COD.Price)	AS	TotalAmount
FROM	CustomerOrders.dbo.Customers AS C
		INNER JOIN CustomerOrders.dbo.CustomerOrders AS CO
		ON (C.Id = CO.Customer_Id)
		INNER JOIN CustomerOrders.dbo.CustomerOrderDetails AS COD
		ON (CO.Id = COD.Order_Id)
WHERE	C.Id <= 10
GROUP BY
		C.Name,
		YEAR(CO.OrderDate)
ORDER BY
		C.Name
OPTION (RECOMPILE, QUERYTRACEON 9130);
GO


-- Resolve parallelism in a professional way like Microsoft is doing it
-- with Sharepoint :)
EXEC sp_configure N'max degree of parallelism', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- needs the data every morning
SELECT	C.Name,
		YEAR(CO.OrderDate)				AS	YearOfOrder,
		COUNT_BIG(*)					AS	NumOfOrders,
		SUM(COD.Quantity * COD.Price)	AS	TotalAmount
FROM	CustomerOrders.dbo.Customers AS C
		INNER JOIN CustomerOrders.dbo.CustomerOrders AS CO
		ON (C.Id = CO.Customer_Id)
		INNER JOIN CustomerOrders.dbo.CustomerOrderDetails AS COD
		ON (CO.Id = COD.Order_Id)
WHERE	C.Id <= 10
GROUP BY
		C.Name,
		YEAR(CO.OrderDate)
ORDER BY
		C.Name
OPTION (MAXDOP 4)
GO

-- or we increase the cost threshold for parallelism way to high
-- the query has an estimated cost value of 19.7632
EXEC sp_configure N'max degree of parallelism', 4;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sp_configure N'cost threshold for parallelism', 150;
RECONFIGURE WITH OVERRIDE;
GO

SET STATISTICS IO, TIME ON;
GO

-- needs the data every morning
SELECT	C.Name,
		YEAR(CO.OrderDate)				AS	YearOfOrder,
		COUNT_BIG(*)					AS	NumOfOrders,
		SUM(COD.Quantity * COD.Price)	AS	TotalAmount
FROM	CustomerOrders.dbo.Customers AS C
		INNER JOIN CustomerOrders.dbo.CustomerOrders AS CO
		ON (C.Id = CO.Customer_Id)
		INNER JOIN CustomerOrders.dbo.CustomerOrderDetails AS COD
		ON (CO.Id = COD.Order_Id)
WHERE	C.Id <= 10
GROUP BY
		C.Name,
		YEAR(CO.OrderDate)
ORDER BY
		C.Name
OPTION (MAXDOP 4);
GO

EXEC sp_configure N'max degree of parallelism', 0;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sp_configure N'cost threshold for parallelism', 5;
RECONFIGURE WITH OVERRIDE;
GO

-- How to resolve CXPACKET waits with indexing...
-- Create an index on dbo.Customers
CREATE UNIQUE CLUSTERED INDEX cuix_Customers_Id
ON dbo.Customers (ID);
GO

CREATE INDEX ix_CustomerOrders_Customer_Id
ON dbo.CustomerOrders (Customer_Id, Id)
INCLUDE (OrderDate)
GO

CREATE UNIQUE CLUSTERED INDEX ix1
ON dbo.CustomerOrderDetails (Order_Id, Position)
GO

SET STATISTICS IO ON;
GO

SELECT	C.Name,
		YEAR(CO.OrderDate)				AS	YearOfOrder,
		COUNT_BIG(*)					AS	NumOfOrders,
		SUM(COD.Quantity * COD.Price)	AS	TotalAmount
FROM	CustomerOrders.dbo.Customers AS C
		INNER JOIN CustomerOrders.dbo.CustomerOrders AS CO
		ON (C.Id = CO.Customer_Id)
		INNER JOIN CustomerOrders.dbo.CustomerOrderDetails AS COD
		ON (CO.Id = COD.Order_Id)
WHERE	C.Id <= 10
GROUP BY
		C.Name,
		YEAR(CO.OrderDate)
ORDER BY
		C.Name
OPTION (RECOMPILE) --, QUERYTRACEON 9130);
GO