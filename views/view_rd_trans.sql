-- dbo.view_rd_trans source

ALTER VIEW dbo.view_rd_trans
AS
SELECT     TOP (100) PERCENT dbo.transaction_details.transaction_details_id, dbo.transaction_details.transaction_head_id, dbo.transaction_details.accounts_id, 
                      dbo.transaction_details.sub_accounts_id, dbo.transaction_details.trans_amount, dbo.sub_accounts.members_id
FROM         dbo.transaction_details INNER JOIN
                      dbo.sub_accounts ON dbo.transaction_details.sub_accounts_id = dbo.sub_accounts.sub_accounts_id
WHERE     (dbo.transaction_details.accounts_id = 76)
ORDER BY dbo.sub_accounts.members_id, dbo.transaction_details.sub_accounts_id;