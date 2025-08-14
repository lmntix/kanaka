









-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[sp_sub_accounts_statement](@accounts_id int,@sub_accounts_id int,@opening_bal decimal,@dteFromDate datetime,@dteToDate datetime,@strUserId varchar(300))
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @RunningTotal money,
@trans_date_temp datetime,
@trans_head_id int,
@trans_amt money,
@sub_acc_bal_id int,
@AccId int,
@SubAccId int,
@TempId int,
@DateCursor int,
@TransAmtCursor int

SET @trans_amt =0
SET @RunningTotal=@opening_bal
SET @sub_acc_bal_id=0

DELETE FROM sub_accounts_balance WHERE trans_by=@strUserId
--Declare cursor
DECLARE rt_cursor CURSOR FOR 
SELECT distinct(transaction_head.transaction_head_id) FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  RIGHT OUTER JOIN transaction_passing  ON transaction_head.transaction_head_id = transaction_passing.transaction_head_id
      WHERE transaction_details.sub_accounts_id =  @sub_accounts_id AND  transaction_head.trans_date >=@dteFromDate  AND transaction_head.trans_date <=@dteToDate 

OPEN rt_cursor

FETCH NEXT FROM rt_cursor INTO @trans_head_id
SET @DateCursor=@@FETCH_STATUS
WHILE @DateCursor=0
BEGIN
DECLARE rt_cursor1 CURSOR FOR 
	SELECT transaction_details.accounts_id,transaction_details.sub_accounts_id,transaction_details.trans_amount,transaction_head.trans_date FROM transaction_head INNER JOIN transaction_details ON transaction_head.transaction_head_id = transaction_details.transaction_head_id  
		  WHERE transaction_details.transaction_head_id= @trans_head_id AND (transaction_details.sub_accounts_id <> @sub_accounts_id or transaction_details.accounts_id <> @accounts_id)    order by transaction_head.transaction_head_id
	OPEN rt_cursor1

	FETCH NEXT FROM rt_cursor1 INTO @AccId,@SubAccId,@trans_amt,@trans_date_temp
	SET @TransAmtCursor =@@FETCH_STATUS
	 WHILE @TransAmtCursor=0
		BEGIN
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

		INSERT INTO sub_accounts_balance VALUES(@sub_acc_bal_id,@AccId,@SubAccId,@trans_amt,@trans_date_temp,@strUserId,@trans_head_id)

		FETCH NEXT FROM rt_cursor1 INTO @AccId,@SubAccId,@trans_amt,@trans_date_temp
		SET @TransAmtCursor=@@FETCH_STATUS
      END
	  CLOSE rt_cursor1
      DEALLOCATE rt_cursor1
FETCH NEXT FROM rt_cursor INTO @trans_head_id
SET @DateCursor=@@FETCH_STATUS
End
CLOSE rt_cursor
DEALLOCATE rt_cursor	
--SELECT * FROM [sub_accounts_balance]
END
