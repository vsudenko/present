/*============================================================================
	File:		099 - A05 - Startup Procedure for SQL Server.sql

	Summary:	Ths script returns default system information about the sql server
				you wish to check.

	Date:		May 2016
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014 /2016
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

DECLARE	@show		INT;
DECLARE	@Startup	INT;

-- Get information about the safety settings of SQL Server
SELECT	@show = CAST(C.value_in_use AS INT)
FROM	sys.configurations AS C
WHERE	name = N'show advanced options';

IF @show = 0
BEGIN
	EXEC	sp_configure N'show advanced options', 1;
	RECONFIGURE WITH OVERRIDE;
END;

SELECT	@Startup = CAST(C.value_in_use AS INT)
FROM	sys.configurations AS C
WHERE	name = N'scan for startup procs';

IF @Startup = 0
BEGIN
	RAISERROR ('Option for startup procs will be opened!', 0, 1) WITH NOWAIT;
	EXEC	sys.sp_configure N'scan for startup procs', 1;
	RECONFIGURE WITH OVERRIDE;
END

EXEC sp_configure N'show advanced options', @show;
RECONFIGURE WITH OVERRIDE;
GO

USE master;
GO

IF OBJECT_ID(N'dbo.sp_SQLServer_Startup', N'P') IS NOT NULL
	DROP PROC dbo.sp_SQLServer_Startup;
	GO

CREATE PROC dbo.sp_SQLServer_Startup
AS
	SET NOCOUNT ON;

	DECLARE	@ProductVersion VARCHAR(20) = CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20));
	SET		@ProductVersion = LEFT(@ProductVersion, CHARINDEX('.', @ProductVersion) - 1);

	IF CAST(@ProductVersion AS SMALLINT) < 13
	BEGIN
		-- all files will grow at the same time
		-- https://msdn.microsoft.com/de-de/library/ms188396.aspx
		DBCC TRACEON (1117, -1);

		-- SQL Server will use uniform extents only
		-- https://msdn.microsoft.com/de-de/library/ms188396.aspx
		DBCC TRACEON (1118, -1);

		-- Changes the automatic update statistics in SQL Server
		-- https://blogs.msdn.microsoft.com/saponsqlserver/2011/09/07/changes-to-automatic-update-statistics-in-sql-server-traceflag-2371/
		DBCC TRACEON (2371, -1);
	END

	-- OPTIONAL: avoid messages about successfull backups in error log
	DBCC TRACEON (3226, -1);

	SET NOCOUNT OFF;
GO

EXEC sys.sp_procoption
	@ProcName = N'dbo.sp_SQLServer_Startup',
    @OptionName = 'startup',
    @OptionValue = 'true';
GO

-- Execute the proc
EXEC dbo.sp_SQLServer_Startup;
GO

-- check the open TF
DBCC TRACESTATUS(-1);
GO

