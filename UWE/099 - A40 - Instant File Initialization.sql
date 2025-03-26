/*============================================================================
	File:		099 - A40 - Instant File Initialization.sql

	Summary:	This script demonstrates the different runtimes when creating
				a new datbase with and without IFI

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Wait Stats Analysis"

	Date:		September 2017

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017
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

-- First of all a new database will be created...
IF DB_ID('demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE demo_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE demo_db;
END
GO

--  Check whether TF 1806 is activated
DBCC TRACESTATUS();
GO

-- Disable Instant File Initialization
DBCC TRACEON (1806, -1)
GO

SET STATISTICS TIME ON;
GO

CREATE DATABASE demo_db
ON PRIMARY
(
	NAME		= N'demo_db',
	FILENAME	= N'F:\MSSQL16.SQL_2022\MSSQL\DATA\demo_db.mdf',
	SIZE		= 10240MB,
	FILEGROWTH	= 1024MB
)
LOG ON
(
	NAME		= N'ASYNC_IO_LOG',
	FILENAME	= N'L:\MSSQL16.SQL_2022\MSSQL\DATA\demo_db.ldf',
	SIZE		= 512MB,
	FILEGROWTH	= 1024MB
);
GO

/*
	NOW WE DO THE SAME WORKLOAD WITH INSTANT FILE INITIALIZATION ACTIVATED!
*/
-- Enable Instant File Initialization
DBCC TRACEOFF (1806, -1)
GO

-- First of all a new database will be created...
IF DB_ID('demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE demo_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE demo_db;
END
GO

CREATE DATABASE demo_db
ON PRIMARY
(
	NAME		= N'demo_db',
	FILENAME	= N'F:\MSSQL16.SQL_2022\MSSQL\DATA\demo_db.mdf',
	SIZE		= 10240MB,
	FILEGROWTH	= 1024MB
)
LOG ON
(
	NAME		= N'ASYNC_IO_LOG',
	FILENAME	= N'L:\MSSQL16.SQL_2022\MSSQL\DATA\demo_db.ldf',
	SIZE		= 512MB,
	FILEGROWTH	= 1024MB
);
GO

-- Clean the kitchen!
IF DB_ID('demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE demo_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE demo_db;
END
GO
