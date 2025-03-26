/*============================================================================
	File:		005 - A06 - find cxpacket queries in the plan cache.sql

	Summary:	This script analyzes the current situation in the plan cache
				of the connected SQL Server instance

				Author: Jonathan Kehaysias (SQLSkills.com)

	Date:		Juni 2015

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
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

WITH XMLNAMESPACES   
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')  
SELECT  
     query_plan AS CompleteQueryPlan, 
     n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS StatementText, 
     n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS StatementOptimizationLevel, 
     n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS StatementSubTreeCost, 
     n.query('.') AS ParallelSubTreeXML,  
     ecp.usecounts, 
     ecp.size_in_bytes 
FROM sys.dm_exec_cached_plans AS ecp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS eqp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n) 
WHERE  n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1 
