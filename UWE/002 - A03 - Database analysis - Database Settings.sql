/*============================================================================
	File:		002 - A03 - Database analysis - Database Settings.sql

	Summary:	This script gives you an overview of all settings of 
				your user databases.

	Date:		June 2015
	Session:	Analysis of a Microsoft SQL Server

	SQL Server Version: 2008 / 2012 / 2014
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

SELECT	name					AS	database_name,
		SUSER_SNAME(owner_sid)	AS	owner_name,
		is_trustworthy_on,
		compatibility_level,
		collation_name,
		state_desc,
		recovery_model_desc,
		page_verify_option_desc,
		log_reuse_wait_desc					AS	log_reuse_type,
		CASE WHEN is_auto_close_on = 1
			 THEN 'Yes'
			 ELSE 'No'
		END						AS	auto_close,
		CASE WHEN is_auto_shrink_on = 1
			 THEN 'Yes'
			 ELSE 'No'
		END						AS auto_shrink,
		snapshot_isolation_state_desc,
		CASE WHEN is_read_committed_snapshot_on = 1
			 THEN 'Yes'
			 ELSE 'No'
		END						AS	RCSI_enabled,
		CASE WHEN is_auto_update_stats_on = 1
			 THEN 'Yes'
			 ELSE 'No'
		END									AS	auto_update_stats,
		CASE WHEN is_auto_create_stats_on = 1
			 THEN 'Yes'
			 ELSE 'No'
		END									AS	auto_create_stats,
		CASE WHEN is_auto_update_stats_async_on = 1
			 THEN 'YES'
			 ELSE 'No'
		END									AS	auto_update_stats_async,
		CASE WHEN is_parameterization_forced = 1
			 THEN 'Yes'
			 ELSE 'No'
		END									AS	forced_parameterization
FROM	sys.databases;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO