




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_sub_accounts_balance](@accounts_id int,@sub_accounts_id int,@opening_bal money,@dteFromDate datetime,@dteToDate datetime,@strUserId varchar(300))
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @RunningTotal money,
@trans_date_temp datetime,
@trans_amt money,
@sub_acc_bal_id int,
@TempId int

SET @trans_amt =0
SET @RunningTotal=@opening_bal
SET @sub_acc_bal_id=0

DELETE FROM sub_accounts_balance WHERE trans_by=@strUserId
--Declare cursor
DECLARE rt_cursor CURSOR FOR 
SELECT distinct(transaction_head.trans_date) FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  
      WHERE transaction_details.sub_accounts_id =  @sub_accounts_id AND  transaction_head.trans_date >=@dteFromDate  AND transaction_head.trans_date <=@dteToDate  order by transaction_head.trans_date
OPEN rt_cursor
FETCH NEXT FROM rt_cursor INTO @trans_date_temp

WHILE @@FETCH_STATUS=0
BEGIN
 SET @trans_amt=(SELECT sum(transaction_details.trans_amount) FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  
         WHERE transaction_details.accounts_id = @accounts_id  AND transaction_details.sub_accounts_id =  @sub_accounts_id  AND transaction_head.trans_date =@trans_date_temp)
if @trans_amt is NULL 
    BEGIN
	   SET @trans_amt=0
    END
else 
    BEGIN
       SET @trans_amt=@trans_amt
     END 
SET @RunningTotal=@RunningTotal + @trans_amt
--This for getting Max of Sub_accounts_balance_id
   if (SELECT MAX(sub_accounts_balance_id) FROM sub_accounts_balance ) is null
     begin
       SET @TempId=0
     end
   else
	begin
	  SET @TempId= (SELECT MAX(sub_accounts_balance_id) FROM sub_accounts_balance ) 
	end
	set @sub_acc_bal_id=(@TempId+1)
-- Insert statements for procedure here

INSERT sub_accounts_balance VALUES(@sub_acc_bal_id,@accounts_id,@sub_accounts_id,@RunningTotal,@trans_date_temp,@strUserId,-1)

FETCH NEXT FROM rt_cursor INTO @trans_date_temp

End

CLOSE rt_cursor
DEALLOCATE rt_cursor	
--SELECT * FROM [sub_accounts_balance]
END
























