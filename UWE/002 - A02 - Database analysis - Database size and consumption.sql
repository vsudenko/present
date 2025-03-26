/*============================================================================
	File:		002 - A02 - Database analysis - Database size and consumption.sql

	Summary:	Ths script returns properties of all databases in the current
				instance of Microsoft SQL Server for performance perspectives!

	Date:		May 2015

	SQL Server Version: 2008 / 2012
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

-- define a table variable to store information about all databases
DECLARE	@Result TABLE
(
	database_name		sysname			NOT NULL,
	database_owner		sysname			NULL,
	is_trustworthy_on	BIT				NOT NULL,
	compatibility_level	VARCHAR(10)		NOT NULL,
	collation_Name		sysname			NOT NULL,
	state_mode			VARCHAR(30)		NOT NULL,
	recovery_mode		VARCHAR(30)		NOT NULL,
	snapshot_isolation	VARCHAR(5)		NOT NULL	DEFAULT ('OFF'),
	read_committed_SI	TINYINT			NOT NULL	DEFAULT (0),				
	logical_name		sysname			NOT NULL,
	type_desc			VARCHAR(10)		NOT NULL,
	physical_name		VARCHAR(255)	NOT NULL,
	size_MB				DECIMAL(18, 2)	NULL		DEFAULT (0),
	growth_MB			DECIMAL(18, 2)	NULL		DEFAULT (0),
	used_MB				DECIMAL(18, 2)	NULL		DEFAULT (0),
	max_size			DECIMAL(18, 2)	NULL		DEFAULT (0),
	is_percent_growth	TINYINT			NULL		DEFAULT (0),
	percent_growth		TINYINT			NULL		DEFAULT (0),
	
	PRIMARY KEY CLUSTERED
	(
		database_name,
		logical_name
	),
	
	UNIQUE (physical_name)	
);

INSERT INTO @Result
EXEC	sys.sp_MSforeachdb @command1 = N'USE [?];
SELECT	DB_NAME(D.database_id)							AS [Database Name],
		SP.name											AS	[Database_Owner],
		D.is_trustworthy_on								AS	[is_trustworthy_on],
		D.compatibility_level,
		D.collation_name,
		D.state_desc,
		D.recovery_model_desc,
		D.snapshot_isolation_state_desc,
		D.is_read_committed_snapshot_on,
		MF.name,
		MF.type_desc,
		MF.physical_name,
		MF.size / 128.0									AS	[size_MB],
		CASE WHEN MF.[is_percent_growth] = 1
			THEN MF.[size] * (MF.[growth] / 100.0)
			ELSE MF.[growth]
		END	/ 128.0										AS	[growth_MB],
		FILEPROPERTY(MF.name, ''spaceused'') / 128.0	AS	[used_MB],
		CASE WHEN MF.max_size = -1
			 THEN 0
			 ELSE MF.max_size / 128.0
		END												AS	[max_size],
		MF.[is_percent_growth],
		CASE WHEN MF.[is_percent_growth] = 1
			 THEN MF.[growth]
			 ELSE 0
		END												AS	[percent_growth]
FROM	sys.databases AS D INNER JOIN sys.master_files AS MF
		ON	(D.database_id = MF.database_id) LEFT JOIN sys.server_principals AS SP
		ON	(D.owner_sid = SP.sid)
WHERE	D.database_id = DB_ID();';

SELECT	*
FROM	@Result AS R;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO