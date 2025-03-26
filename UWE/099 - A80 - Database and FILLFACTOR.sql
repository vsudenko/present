/*============================================================================
	File:		099 - A80 - Database and FILLFACTOR.sql

	Summary:	This script demonstrates the side effects of FILLFACTOR
				for an index

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Wait Stats Analysis"

	Date:		April 2018

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

CREATE DATABASE demo_db;
ALTER AUTHORIZATION ON DATABASE::demo_db TO sa;
ALTER DATABASE demo_db SET RECOVERY SIMPLE;
GO

USE demo_db;
GO

-- Create a demo table for the data
CREATE TABLE dbo.messages
(
	id					UNIQUEIDENTIFIER	NOT NULL	DEFAULT (NEWID()),
	message_id			INT					NOT NULL,
	language_id			INT					NOT NULL,
	severity			SMALLINT			NOT NULL,
	is_event_logged		TINYINT				NOT NULL,
	[text]				NVARCHAR(2000)		NOT NULL
);
GO

INSERT INTO dbo.messages 
(message_id, language_id, severity, is_event_logged, [text])
SELECT	message_id,
		language_id,
		severity,
		is_event_logged,
		[text]
FROM	sys.messages
WHERE	language_id = 1032;
GO

-- Now we create an unique clustered index on id for demo purposes
CREATE UNIQUE CLUSTERED INDEX cuix_messages_id
ON dbo.messages (Id);
GO

-- check the fragmentation of the index
SELECT	index_level,
		avg_fragment_size_in_pages,
		avg_fragmentation_in_percent,
		page_count
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.messages', N'U'),
			1,
			NULL,
			N'DETAILED'
		);
GO

-- now we insert the next data dump
CHECKPOINT;
GO

SELECT * FROM sys.fn_dblog(NULL, NULL);
GO

BEGIN TRANSACTION;
GO
	INSERT INTO dbo.messages 
	(message_id, language_id, severity, is_event_logged, [text])
	SELECT	message_id,
			language_id,
			severity,
			is_event_logged,
			[text]
	FROM	sys.messages
	WHERE	language_id = 1033;
	GO

	SELECT	Operation,
			COUNT_BIG(*)
	FROM	sys.fn_dblog(NULL, NULL)
	WHERE	Operation IN
			(
				N'LOP_DELETE_SPLIT',
				N'LOP_INSERT_ROWS',
				N'LOP_FORMAT_PAGE',
				N'LOP_INSYSACT'
			)
	GROUP BY
			Operation;
	GO
COMMIT TRANSACTION;
GO

-- Now we check the index fragmentation again
SELECT	index_level,
		avg_fragment_size_in_pages,
		avg_fragmentation_in_percent,
		page_count
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.messages', N'U'),
			1,
			NULL,
			N'DETAILED'
		);
GO

-- Now we rebuild the index with a dedicated FILLFACTOR
ALTER INDEX cuix_messages_id ON dbo.messages
REBUILD WITH (FILLFACTOR = 50);
GO

BEGIN TRANSACTION;
GO
	INSERT INTO dbo.messages 
	(message_id, language_id, severity, is_event_logged, [text])
	SELECT	message_id,
			language_id,
			severity,
			is_event_logged,
			[text]
	FROM	sys.messages
	WHERE	language_id = 1033;
	GO

	SELECT	Operation,
			COUNT_BIG(*)
	FROM	sys.fn_dblog(NULL, NULL)
	WHERE	Operation IN
			(
				N'LOP_DELETE_SPLIT',
				N'LOP_INSERT_ROWS',
				N'LOP_FORMAT_PAGE',
				N'LOP_INSYSACT'
			)
	GROUP BY
			Operation;
	GO
COMMIT TRANSACTION;
GO

-- Now we check the index fragmentation again
SELECT	index_level,
		avg_fragment_size_in_pages,
		avg_fragmentation_in_percent,
		page_count
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.messages', N'U'),
			1,
			NULL,
			N'DETAILED'
		);
GO