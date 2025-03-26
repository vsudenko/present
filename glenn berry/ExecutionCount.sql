SELECT TOP(20) DB_NAME(t.[dbid]) AS [Database Name], replace(replace(replace(LEFT(t.[text], 350), char(10), ''), char(13), ''), char(9), ''), 
qs.execution_count AS [Execution Count],
qs.total_worker_time AS [Total Worker Time], qs.min_worker_time AS [Min Worker Time],

qs.total_worker_time/qs.execution_count AS [Avg Worker Time],

qs.max_worker_time AS [Max Worker Time],

qs.min_elapsed_time AS [Min Elapsed Time],

qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time],

qs.max_elapsed_time AS [Max Elapsed Time],

qs.min_logical_reads AS [Min Logical Reads],

qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads],

qs.max_logical_reads AS [Max Logical Reads],

 qs.creation_time AS [Creation Time]

-- ,t.[text] AS [Query Text], qp.query_plan AS [Query Plan] -- uncomment out these columns if not copying results to Excel

FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)

CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t

CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp

ORDER BY qs.execution_count DESC OPTION (RECOMPILE);

