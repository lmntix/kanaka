-- dbo.view_recovery_details source

ALTER VIEW dbo.view_recovery_details
AS
SELECT     dbo.demand_head.members_id, dbo.demand_head.demand_list_id, dbo.recovery_list.recovery_list_id, 
                      SUM(CASE recovery_details.accounts_id WHEN 1 THEN recovery_details.amount ELSE 0 END) AS Shares, 
                      SUM(CASE recovery_details.accounts_id WHEN 4 THEN recovery_details.amount ELSE 0 END) AS Loan, 
                      SUM(CASE recovery_details.accounts_id WHEN 5 THEN recovery_details.amount ELSE 0 END) AS LoanInterest, 
                      SUM(CASE recovery_details.accounts_id WHEN 64 THEN recovery_details.amount ELSE 0 END) AS Saving, 
                      SUM(CASE recovery_details.accounts_id WHEN 67 THEN recovery_details.amount ELSE 0 END) AS GRTR, 
                      SUM(CASE recovery_details.accounts_id WHEN 104 THEN recovery_details.amount ELSE 0 END) AS Advance, 
                      SUM(CASE recovery_details.accounts_id WHEN 211 THEN recovery_details.amount ELSE 0 END) AS DeathandInsurance, 
                      SUM(CASE recovery_details.accounts_id WHEN 329 THEN recovery_details.amount ELSE 0 END) AS CashDeposit
FROM         dbo.demand_head LEFT OUTER JOIN
                      dbo.demand_details ON dbo.demand_head.demand_head_id = dbo.demand_details.demand_head_id LEFT OUTER JOIN
                      dbo.recovery_list RIGHT OUTER JOIN
                      dbo.recovery_head ON dbo.recovery_list.recovery_list_id = dbo.recovery_head.recovery_list_id RIGHT OUTER JOIN
                      dbo.recovery_details ON dbo.recovery_head.recovery_head_id = dbo.recovery_details.recovery_head_id ON 
                      dbo.demand_details.demand_details_id = dbo.recovery_details.demand_details_id
GROUP BY dbo.recovery_list.recovery_list_id, dbo.recovery_list.transaction_head_id, dbo.demand_head.demand_list_id, dbo.demand_head.members_id;