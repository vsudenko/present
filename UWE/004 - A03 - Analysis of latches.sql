/*============================================================================
	File:		004 - A03 - Analysis of latches.sql

	Summary:	This script is part of the blog post from PAUL RANDAL
				http://www.sqlskills.com/blogs/paul/most-common-latch-classes-and-what-they-mean/

	Date:		May 2015
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014
------------------------------------------------------------------------------
	Written by Paul Randal, SQL Skills

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
WITH [Latches]
AS
(
	SELECT	[latch_class],
			[wait_time_ms] / 1000.0 AS [WaitS],
			[waiting_requests_count] AS [WaitCount],
			100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER()	AS [Percentage],
			ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC)			AS [RowNum]
	FROM	sys.dm_os_latch_stats
	WHERE	[latch_class] NOT IN
			(N'BUFFER') AND
			[wait_time_ms] > 0
)
SELECT	[W1].[latch_class]											AS [LatchClass], 
		CAST ([W1].[WaitS] AS DECIMAL(14, 2))						AS [Wait_S],
		[W1].[WaitCount]											AS [WaitCount],
		CAST ([W1].[Percentage] AS DECIMAL(14, 2))					AS [Percentage],
		CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (14, 4))	AS [AvgWait_S]
FROM	[Latches] AS [W1] INNER JOIN [Latches] AS [W2]
		ON [W2].[RowNum] <= [W1].[RowNum]
WHERE	[W1].[WaitCount] > 0
GROUP BY
		[W1].[RowNum],
		[W1].[latch_class],
		[W1].[WaitS],
		[W1].[WaitCount],
		[W1].[Percentage]
HAVING
		SUM ([W2].[Percentage]) - [W1].[Percentage] < 99;
GO