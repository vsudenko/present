/*============================================================================
	File:		099 - A02 - Latch Contention in tempdb.sql

	Summary:	This script creates two simple stored procedures to 
				create a temporary table for demonstration of LATCH
				contention

	Date:		March 2015

	SQL Server Version: 2017 / 2019 / 2022
============================================================================*/
--ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA=OFF;
--GO

USE demo_db;
GO

CREATE OR ALTER PROCEDURE dbo.SPROC_tempdbMemOptimzedtest_1
AS 
BEGIN
   SET NOCOUNT ON;

	CREATE TABLE #DummyTable ( ID BIGINT NOT NULL );

	INSERT INTO #DummyTable 
	SELECT T.RowNum 
	FROM
	(
		SELECT TOP (1) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum 
		FROM	sys.sysobjects 
	) AS T;
END
GO




SELECT req.session_id,
       req.wait_type,
       req.wait_resource,
       OBJECT_NAME(inf.[object_id], inf.database_id) AS [object_name],
       req.blocking_session_id,
       req.command,
       SUBSTRING(   txt.text,
                    (req.statement_start_offset / 2) + 1,
                    ((CASE req.statement_end_offset
                          WHEN -1 THEN
                              DATALENGTH(txt.text)
                          ELSE
                              req.statement_end_offset
                      END - req.statement_start_offset
                     ) / 2
                    ) + 1
                ) AS statement_text,
       inf.database_id,
       inf.[file_id],
       inf.page_id,
       inf.[object_id],
       inf.index_id,
       inf.page_type_desc
FROM sys.dm_exec_requests AS req
    CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS txt
    CROSS APPLY sys.fn_PageResCracker(req.page_resource) AS pgc
    CROSS APPLY sys.dm_db_page_info(pgc.[db_id], pgc.[file_id], pgc.page_id, 'DETAILED') AS inf
WHERE req.wait_type LIKE '%page%';