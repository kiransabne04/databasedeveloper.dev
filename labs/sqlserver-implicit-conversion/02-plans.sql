USE convlab;
SET NOCOUNT ON;
GO
PRINT '=== A. varchar column, SQL collation, nvarchar parameter (ORM default)';
SET STATISTICS IO ON; SET STATISTICS PROFILE ON;
EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_sqlcoll WHERE email = @e', N'@e nvarchar(4000)', @e = N'user777777@example.com';
SET STATISTICS PROFILE OFF; SET STATISTICS IO OFF;
GO
PRINT '=== B. varchar column, SQL collation, varchar parameter';
SET STATISTICS IO ON; SET STATISTICS PROFILE ON;
EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_sqlcoll WHERE email = @e', N'@e varchar(100)', @e = 'user777777@example.com';
SET STATISTICS PROFILE OFF; SET STATISTICS IO OFF;
GO
PRINT '=== C. varchar column, Windows collation, nvarchar parameter';
SET STATISTICS IO ON; SET STATISTICS PROFILE ON;
EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_wincoll WHERE email = @e', N'@e nvarchar(4000)', @e = N'user777777@example.com';
SET STATISTICS PROFILE OFF; SET STATISTICS IO OFF;
GO
PRINT '=== D. nvarchar column, varchar parameter';
SET STATISTICS IO ON; SET STATISTICS PROFILE ON;
EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_nvarchar WHERE email = @e', N'@e varchar(100)', @e = 'user777777@example.com';
SET STATISTICS PROFILE OFF; SET STATISTICS IO OFF;
GO
PRINT '=== E. nvarchar parameter cast back to varchar in the query text';
SET STATISTICS IO ON; SET STATISTICS PROFILE ON;
EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_sqlcoll WHERE email = CAST(@e AS varchar(100))', N'@e nvarchar(4000)', @e = N'user777777@example.com';
SET STATISTICS PROFILE OFF; SET STATISTICS IO OFF;
GO
PRINT '=== F. what CAST does to a character outside the code page';
SELECT CAST(N'zoë.ł@example.com' AS varchar(100)) AS cast_result, CAST(N'用户@example.com' AS varchar(100)) AS cast_result2;
GO
