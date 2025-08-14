-- dbo.view_incomp_dr_trans source

ALTER VIEW dbo.view_incomp_dr_trans
AS
SELECT     dbo.transaction_details.accounts_id, dbo.transaction_details.sub_accounts_id, dbo.transaction_details.trans_amount, 
                      dbo.view_incomp_dr_cash_trans.mode_of_operation, dbo.sub_accounts.name, dbo.view_incomp_dr_cash_trans.trans_date, 
                      dbo.accounts.account_name, dbo.view_incomp_dr_cash_trans.transaction_head_id
FROM         dbo.view_incomp_dr_cash_trans INNER JOIN
                      dbo.transaction_details ON dbo.view_incomp_dr_cash_trans.transaction_head_id = dbo.transaction_details.transaction_head_id INNER JOIN
                      dbo.accounts ON dbo.transaction_details.accounts_id = dbo.accounts.accounts_id INNER JOIN
                      dbo.sub_accounts ON dbo.transaction_details.sub_accounts_id = dbo.sub_accounts.sub_accounts_id
WHERE     (dbo.accounts.account_type <> 6);