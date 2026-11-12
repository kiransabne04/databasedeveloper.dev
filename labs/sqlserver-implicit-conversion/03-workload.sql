USE convlab;
SET NOCOUNT ON;
ALTER DATABASE convlab SET QUERY_STORE CLEAR;
GO
-- 300 lookups of different emails through each of the three parameter/column combinations.
DECLARE @i int = 0, @e nvarchar(4000), @v varchar(100);
WHILE @i < 300
BEGIN
  SET @e = CONCAT(N'user', 1 + (@i * 3271) % 1000000, N'@example.com'); SET @v = CAST(@e AS varchar(100));
  EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_sqlcoll WHERE email = @e', N'@e nvarchar(4000)', @e = @e;
  EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_sqlcoll WHERE email = @e', N'@e varchar(100)', @e = @v;
  EXEC sp_executesql N'SELECT id, plan_code FROM dbo.accounts_wincoll WHERE email = @e', N'@e nvarchar(4000)', @e = @e;
  SET @i += 1;
END;
GO
EXEC sp_query_store_flush_db;
GO
