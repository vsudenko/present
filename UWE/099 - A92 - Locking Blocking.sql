EXEC sp_create_demo_db;

USE demo_db;
GO

SELECT * INTO dbo.messages FROM sys.messages;
GO

CREATE NONCLUSTERED INDEX x1 ON dbo.messages (severity);
GO

/* Verteilung von Severity*/
DBCC SHOW_STATISTICS (N'dbo.messages', N'x1') WITH HISTOGRAM;

SELECT	*
FROM	dbo.messages
WHERE	severity = 12
ORDER BY
		language_id,
		message_id;
GO

SELECT	*
FROM	dbo.messages
WHERE	severity = 16
ORDER BY
		language_id,
		message_id;
GO


EXEC sp_executesql
N'SELECT	*
FROM	dbo.messages
WHERE	severity = @severity
ORDER BY
		language_id,
		message_id;
',
N'@severity SMALLINT',
16;
GO


BEGIN TRANSACTION;
GO

	UPDATE	dbo.messages
	SET		Text = 'Ich will ein Bier'
	WHERE	Language_id = 1033;
	GO

	SELECT * FROM sys.dm_tran_locks
	WHERE	resource_database_id = DB_ID();
	GO
ROLLBACK;
GO

ALTER DATABASE demo_db SET READ_COMMITTED_SNAPSHOT ON
WITH ROLLBACK IMMEDIATE;
GO
