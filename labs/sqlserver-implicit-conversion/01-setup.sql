SET NOCOUNT ON;
IF DB_ID('convlab') IS NOT NULL BEGIN ALTER DATABASE convlab SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE convlab; END;
CREATE DATABASE convlab;
GO
ALTER DATABASE convlab SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE convlab;
GO
-- Same data, three column definitions.
CREATE TABLE dbo.accounts_sqlcoll (id int IDENTITY PRIMARY KEY, email varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL, plan_code char(4) NOT NULL);
CREATE TABLE dbo.accounts_wincoll (id int IDENTITY PRIMARY KEY, email varchar(100) COLLATE Latin1_General_CI_AS NOT NULL, plan_code char(4) NOT NULL);
CREATE TABLE dbo.accounts_nvarchar (id int IDENTITY PRIMARY KEY, email nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL, plan_code char(4) NOT NULL);
GO
WITH n AS (SELECT TOP (1000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c)
INSERT dbo.accounts_sqlcoll (email, plan_code) SELECT CONCAT('user', i, '@example.com'), CASE i % 3 WHEN 0 THEN 'FREE' WHEN 1 THEN 'TEAM' ELSE 'ENTR' END FROM n;
INSERT dbo.accounts_wincoll (email, plan_code) SELECT email, plan_code FROM dbo.accounts_sqlcoll ORDER BY id;
INSERT dbo.accounts_nvarchar (email, plan_code) SELECT email, plan_code FROM dbo.accounts_sqlcoll ORDER BY id;
CREATE INDEX ix_accounts_sqlcoll_email ON dbo.accounts_sqlcoll (email);
CREATE INDEX ix_accounts_wincoll_email ON dbo.accounts_wincoll (email);
CREATE INDEX ix_accounts_nvarchar_email ON dbo.accounts_nvarchar (email);
GO
SELECT @@VERSION AS version, DATABASEPROPERTYEX('convlab','Collation') AS db_collation, compatibility_level FROM sys.databases WHERE name = 'convlab';
SELECT t.name AS table_name, SUM(a.used_pages)*8/1024 AS used_mb FROM sys.tables t JOIN sys.partitions p ON p.object_id=t.object_id JOIN sys.allocation_units a ON a.container_id=p.partition_id GROUP BY t.name;
GO
