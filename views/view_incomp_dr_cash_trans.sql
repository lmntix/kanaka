-- dbo.view_incomp_dr_cash_trans source

ALTER VIEW dbo.view_incomp_dr_cash_trans
AS
SELECT     dbo.transaction_head.transaction_head_id, dbo.transaction_head.mode_of_operation, dbo.transaction_head.trans_date
FROM         dbo.transaction_head INNER JOIN
                      dbo.transaction_passing ON dbo.transaction_head.transaction_head_id = dbo.transaction_passing.transaction_head_id INNER JOIN
                      dbo.scroll_transactions ON dbo.transaction_head.transaction_head_id = dbo.scroll_transactions.transaction_head_id INNER JOIN
                      dbo.[scroll] ON dbo.scroll_transactions.scroll_id = dbo.[scroll].scroll_id
WHERE     (dbo.[scroll].scroll_no <= 0) AND (dbo.[scroll].trans_amount > 0) AND (dbo.[scroll].trans_date =
                          (SELECT     yearly_trans_dates
                            FROM          dbo.calender
                            WHERE      (current_day = 'TRUE')));