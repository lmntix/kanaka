--Modified By CHETAN on 25.11.2009 Added optional Parameter
-- =============================================
-- Author:		Mukund L. Netnaskar
-- Create date: 01/04/2008
-- Description:	To calculate Balance as per sub_accounts_id
-- =============================================
CREATE PROCEDURE [dbo].[sp_Balance](@strAccountList varchar(8000),@dteToDate datetime,@strUserId varchar(300),@Delimiter char(1) = ',',@intFinYearId int=null )
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @sub_accounts_id int,
        @sub_accounts_balance_id int,
        @trans_amt money,
        @Item Varchar(8000),
        @TempId int,
        @TempAccId int,
		@PrimGroupType int
--@strAccountList varchar(8000), -- List of delimited items
--@Delimiter char(1) = ',' -- delimiter that separates items

--SET @RunningTotal=@opening_bal

DELETE FROM sub_accounts_balance WHERE trans_by = @strUserId
set @sub_accounts_balance_id=0
--SET @sub_accounts_balance_id=10 --SELECT MAX(sub_accounts_balance_id) FROM sub_accounts_balance 

--Declare cursor
WHILE CHARINDEX(@Delimiter,@strAccountList,0) <> 0
BEGIN
SELECT
@Item=RTRIM(LTRIM(SUBSTRING(@strAccountList,1,CHARINDEX(@Delimiter,@strAccountList,0)-1))),
@strAccountList=RTRIM(LTRIM(SUBSTRING(@strAccountList,CHARINDEX(@Delimiter,@strAccountList,0)+1,LEN(@strAccountList))))

if(SELECT Max(sub_accounts_id) FROM sub_accounts WHERE accounts_id = @Item AND sub_accounts_no <>0 ) is null
begin
 SET @TempAccId= (SELECT accounts_id FROM accounts_family WHERE related_accounts_id=@Item)
 DECLARE rt_cursor CURSOR FOR 
 SELECT sub_accounts_id FROM sub_accounts WHERE accounts_id = @TempAccId
end
Else
 begin
      DECLARE rt_cursor CURSOR FOR 
     (SELECT sub_accounts_id FROM sub_accounts  WHERE accounts_id = @Item )
 end

SET @PrimGroupType=(SELECT account_groups.account_primary_group FROM accounts INNER JOIN 
               account_groups ON accounts.account_groups_id = account_groups.account_groups_id WHERE accounts.accounts_id=@Item)                                                                                                                                    

OPEN rt_cursor
FETCH NEXT FROM rt_cursor INTO @sub_accounts_id   
WHILE ((@@FETCH_STATUS=0))
BEGIN
IF LEN(@Item) > 0
--SELECT sub_accounts_balance_id FROM sub_accounts_balance
--       WHERE accounts_id = @Item 
 --SET @trans_amt=(SELECT sum(transaction_details.trans_amount) FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  
  -- WHERE (transaction_details.accounts_id = @Item AND transaction_details.sub_accounts_id=@sub_accounts_id  AND transaction_head.trans_date <=@dteToDate)
   -- GROUP BY sub_accounts_id )
IF (SELECT sum(transaction_details.trans_amount) FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  
   WHERE (transaction_details.accounts_id = @Item AND transaction_details.sub_accounts_id=@sub_accounts_id  AND transaction_head.trans_date <=@dteToDate)
   GROUP BY sub_accounts_id ) is null
 BEGIN
  SET @trans_amt=0
 END  
ELSE 
  BEGIN
     --Check For Income and Expense Type Account
	if (@intFinYearId>0) and (@PrimGroupType=1 OR @PrimGroupType=2)
      SET @trans_amt=(SELECT sum(transaction_details.trans_amount) FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  
       WHERE (transaction_details.accounts_id = @Item AND transaction_details.sub_accounts_id=@sub_accounts_id  AND transaction_head.financial_years_id =@intFinYearId AND transaction_head.trans_date <=@dteToDate)
       GROUP BY sub_accounts_id )
	else
      SET @trans_amt=(SELECT sum(transaction_details.trans_amount) FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  
       WHERE (transaction_details.accounts_id = @Item AND transaction_details.sub_accounts_id=@sub_accounts_id  AND transaction_head.trans_date <=@dteToDate)
       GROUP BY sub_accounts_id )
  END

--set	@trans_amt=100
--if @trans_amt=NULL 
-- BEGIN
-- set @trans_amt=0
-- END 
--END

 if (SELECT MAX(sub_accounts_balance_id) FROM sub_accounts_balance ) is null
begin
  SET @TempId=0
end
else
	begin
	  SET @TempId= (SELECT MAX(sub_accounts_balance_id) FROM sub_accounts_balance ) 
	end
	set @sub_accounts_balance_id=(@TempId+1)
	-- SET @RunningTotal=@RunningTotal + @trans_amt
	-- Insert statements for procedure here
	-- Modified by Rupa on 19.01.2010 to check null
    if not @trans_amt is null
	begin 
		INSERT sub_accounts_balance VALUES(@sub_accounts_balance_id,@Item,@sub_accounts_id,@trans_amt,@dteToDate,@strUserId,-1)
	end
	FETCH NEXT FROM rt_cursor INTO @sub_accounts_id
END

CLOSE rt_cursor
DEALLOCATE rt_cursor
End

--SELECT * FROM [sub_accounts_balance]
END