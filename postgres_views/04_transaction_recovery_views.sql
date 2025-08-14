-- =============================================
-- Transaction and Recovery Views for PostgreSQL
-- Author: Converted from SQL Server views
-- Create date: 2024
-- Description: Transaction processing and recovery management views
-- =============================================

-- View: Recovery details with product-wise breakdown
CREATE OR REPLACE VIEW view_recovery_details AS
SELECT 
    dh.members_id,
    dh.demand_list_id,
    rl.recovery_list_id,
    
    -- Product-wise recovery amounts
    SUM(CASE WHEN rd.accounts_id = 1 THEN rd.amount::DECIMAL ELSE 0 END) AS shares,
    SUM(CASE WHEN rd.accounts_id = 4 THEN rd.amount::DECIMAL ELSE 0 END) AS loan,
    SUM(CASE WHEN rd.accounts_id = 5 THEN rd.amount::DECIMAL ELSE 0 END) AS loan_interest,
    SUM(CASE WHEN rd.accounts_id = 64 THEN rd.amount::DECIMAL ELSE 0 END) AS saving,
    SUM(CASE WHEN rd.accounts_id = 67 THEN rd.amount::DECIMAL ELSE 0 END) AS grtr,
    SUM(CASE WHEN rd.accounts_id = 104 THEN rd.amount::DECIMAL ELSE 0 END) AS advance,
    SUM(CASE WHEN rd.accounts_id = 211 THEN rd.amount::DECIMAL ELSE 0 END) AS death_and_insurance,
    SUM(CASE WHEN rd.accounts_id = 329 THEN rd.amount::DECIMAL ELSE 0 END) AS cash_deposit,
    
    -- Total recovery amount
    SUM(rd.amount::DECIMAL) AS total_recovery_amount,
    
    -- Recovery date and details
    MAX(rl.recovery_date) AS recovery_date,
    COUNT(rd.recovery_details_id) AS recovery_line_items

FROM demand_head dh
LEFT OUTER JOIN demand_details dd ON dh.demand_head_id = dd.demand_head_id
LEFT OUTER JOIN recovery_list rl ON dh.demand_list_id = rl.demand_list_id
RIGHT OUTER JOIN recovery_head rh ON rl.recovery_list_id = rh.recovery_list_id
RIGHT OUTER JOIN recovery_details rd ON rh.recovery_head_id = rd.recovery_head_id

GROUP BY 
    dh.members_id, 
    dh.demand_list_id, 
    rl.recovery_list_id
    
ORDER BY dh.members_id, rl.recovery_list_id;

-- Comment on view
COMMENT ON VIEW view_recovery_details IS 'Recovery details with product-wise breakdown for demand management';

-- View: Incomplete debit cash transactions
CREATE OR REPLACE VIEW view_incomp_dr_cash_trans AS
SELECT 
    th.transaction_head_id,
    th.mode_of_operation,
    th.trans_date::DATE
FROM transaction_head th
INNER JOIN transaction_passing tp ON th.transaction_head_id = tp.transaction_head_id
INNER JOIN scroll_transactions st ON th.transaction_head_id = st.transaction_head_id
INNER JOIN scroll s ON st.scroll_id = s.scroll_id
WHERE s.scroll_no::INTEGER <= 0 
    AND s.trans_amount::DECIMAL > 0 
    AND s.trans_date::DATE = (
        SELECT c.yearly_trans_dates::DATE
        FROM calender c
        WHERE c.current_day = 'TRUE'
        LIMIT 1
    );

-- Comment on view
COMMENT ON VIEW view_incomp_dr_cash_trans IS 'Incomplete debit cash transactions based on scroll processing';

-- View: Incomplete debit transactions with details
CREATE OR REPLACE VIEW view_incomp_dr_trans AS
SELECT 
    td.accounts_id,
    td.sub_accounts_id,
    td.trans_amount,
    vidt.mode_of_operation,
    sa.name AS sub_account_name,
    vidt.trans_date,
    a.account_name,
    vidt.transaction_head_id
FROM view_incomp_dr_cash_trans vidt
INNER JOIN transaction_details td ON vidt.transaction_head_id = td.transaction_head_id
INNER JOIN accounts a ON td.accounts_id = a.accounts_id
INNER JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
WHERE a.account_type::TEXT <> '6'; -- Exclude specific account type

-- Comment on view
COMMENT ON VIEW view_incomp_dr_trans IS 'Detailed view of incomplete debit transactions with account information';

-- Enhanced View: Transaction summary by member and period
CREATE OR REPLACE VIEW view_member_transaction_summary_detailed AS
SELECT 
    m.members_id,
    m.full_name AS member_name,
    
    -- Time period (current month)
    DATE_TRUNC('month', CURRENT_DATE) AS period_start,
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day' AS period_end,
    
    -- Transaction counts by type
    COUNT(CASE WHEN td.trans_amount > 0 THEN 1 END) AS credit_transactions,
    COUNT(CASE WHEN td.trans_amount < 0 THEN 1 END) AS debit_transactions,
    COUNT(td.transaction_details_id) AS total_transactions,
    
    -- Transaction amounts by type
    SUM(CASE WHEN td.trans_amount > 0 THEN td.trans_amount ELSE 0 END) AS total_credits,
    SUM(CASE WHEN td.trans_amount < 0 THEN ABS(td.trans_amount) ELSE 0 END) AS total_debits,
    SUM(td.trans_amount) AS net_amount,
    
    -- Product-wise transaction summary
    COUNT(CASE WHEN a.account_name ILIKE '%saving%' THEN 1 END) AS savings_transactions,
    COUNT(CASE WHEN a.account_name ILIKE '%loan%' OR a.account_name ILIKE '%lone%' THEN 1 END) AS loan_transactions,
    COUNT(CASE WHEN a.account_name ILIKE '%fd%' OR a.account_name ILIKE '%fixed%' THEN 1 END) AS fd_transactions,
    COUNT(CASE WHEN a.account_name ILIKE '%share%' THEN 1 END) AS share_transactions,
    
    -- First and last transaction in period
    MIN(th.trans_date::DATE) AS first_transaction_date,
    MAX(th.trans_date::DATE) AS last_transaction_date

FROM members m
INNER JOIN sub_accounts sa ON m.members_id = sa.members_id
INNER JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
    AND sa.accounts_id = td.accounts_id
INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
INNER JOIN accounts a ON td.accounts_id = a.accounts_id

WHERE th.trans_date::DATE >= DATE_TRUNC('month', CURRENT_DATE)
    AND th.trans_date::DATE < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    AND m.status = '1' -- Active members

GROUP BY m.members_id, m.full_name
ORDER BY total_transactions DESC;

-- Comment on view
COMMENT ON VIEW view_member_transaction_summary_detailed IS 'Detailed member transaction summary for current month';

-- View: Daily transaction summary
CREATE OR REPLACE VIEW view_daily_transaction_summary AS
SELECT 
    th.trans_date::DATE AS transaction_date,
    
    -- Transaction counts
    COUNT(DISTINCT th.transaction_head_id) AS total_transactions,
    COUNT(DISTINCT td.transaction_details_id) AS total_transaction_lines,
    COUNT(DISTINCT sa.members_id) AS unique_members_transacted,
    
    -- Transaction amounts
    SUM(CASE WHEN td.trans_amount > 0 THEN td.trans_amount ELSE 0 END) AS total_debits,
    SUM(CASE WHEN td.trans_amount < 0 THEN ABS(td.trans_amount) ELSE 0 END) AS total_credits,
    SUM(ABS(td.trans_amount)) AS total_transaction_volume,
    
    -- Mode of operation breakdown
    COUNT(CASE WHEN th.mode_of_operation = '0' THEN 1 END) AS system_transactions,
    COUNT(CASE WHEN th.mode_of_operation = '1' THEN 1 END) AS manual_transactions,
    
    -- Product-wise transaction counts
    COUNT(CASE WHEN a.account_name ILIKE '%saving%' THEN 1 END) AS savings_transactions,
    COUNT(CASE WHEN a.account_name ILIKE '%loan%' OR a.account_name ILIKE '%lone%' THEN 1 END) AS loan_transactions,
    COUNT(CASE WHEN a.account_name ILIKE '%fd%' OR a.account_name ILIKE '%fixed%' THEN 1 END) AS fd_transactions,
    COUNT(CASE WHEN a.account_name ILIKE '%share%' THEN 1 END) AS share_transactions

FROM transaction_head th
INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
INNER JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
INNER JOIN accounts a ON td.accounts_id = a.accounts_id

WHERE th.trans_date::DATE >= CURRENT_DATE - INTERVAL '30 days'

GROUP BY th.trans_date::DATE
ORDER BY th.trans_date::DATE DESC;

-- Comment on view
COMMENT ON VIEW view_daily_transaction_summary IS 'Daily transaction volume and breakdown summary for last 30 days';

-- View: Failed/Pending transactions
CREATE OR REPLACE VIEW view_failed_pending_transactions AS
SELECT 
    th.transaction_head_id,
    th.voucher_no,
    th.trans_date::DATE,
    th.trans_time,
    th.trans_amount::DECIMAL,
    th.trans_narration,
    th.mode_of_operation,
    th.users_id,
    
    -- Transaction status based on passing table
    CASE 
        WHEN tp.transaction_head_id IS NULL THEN 'PENDING'
        ELSE 'PASSED'
    END AS transaction_status,
    
    -- Count of transaction details
    COUNT(td.transaction_details_id) AS detail_line_count,
    
    -- Balance check (debits should equal credits)
    SUM(td.trans_amount) AS balance_check,
    
    CASE 
        WHEN ABS(SUM(td.trans_amount)) < 0.01 THEN 'BALANCED'
        ELSE 'UNBALANCED'
    END AS balance_status

FROM transaction_head th
LEFT JOIN transaction_passing tp ON th.transaction_head_id = tp.transaction_head_id
LEFT JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id

WHERE th.trans_date::DATE >= CURRENT_DATE - INTERVAL '7 days'

GROUP BY 
    th.transaction_head_id, th.voucher_no, th.trans_date, th.trans_time,
    th.trans_amount, th.trans_narration, th.mode_of_operation, th.users_id,
    tp.transaction_head_id

HAVING 
    tp.transaction_head_id IS NULL  -- Only pending transactions
    OR ABS(SUM(td.trans_amount)) >= 0.01  -- Or unbalanced transactions

ORDER BY th.trans_date DESC, th.transaction_head_id DESC;

-- Comment on view
COMMENT ON VIEW view_failed_pending_transactions IS 'Failed or pending transactions that need attention';

-- Enhanced View: Recovery performance analysis
CREATE OR REPLACE VIEW view_recovery_performance_analysis AS
SELECT 
    rl.recovery_date::DATE,
    rl.recovery_list_id,
    
    -- Demand vs Recovery analysis
    COUNT(DISTINCT dh.demand_head_id) AS total_demands,
    COUNT(DISTINCT rh.recovery_head_id) AS total_recoveries,
    COUNT(DISTINCT dh.members_id) AS unique_members_demanded,
    COUNT(DISTINCT rh.members_id) AS unique_members_recovered,
    
    -- Amount analysis
    COALESCE(SUM(dd.amount::DECIMAL), 0) AS total_demand_amount,
    COALESCE(SUM(rd.amount::DECIMAL), 0) AS total_recovery_amount,
    
    -- Recovery efficiency
    CASE 
        WHEN COALESCE(SUM(dd.amount::DECIMAL), 0) > 0
        THEN ROUND((COALESCE(SUM(rd.amount::DECIMAL), 0) / SUM(dd.amount::DECIMAL) * 100), 2)
        ELSE 0
    END AS recovery_percentage,
    
    -- Outstanding amounts
    COALESCE(SUM(dd.amount::DECIMAL), 0) - COALESCE(SUM(rd.amount::DECIMAL), 0) AS outstanding_amount

FROM recovery_list rl
LEFT JOIN demand_head dh ON rl.demand_list_id = dh.demand_list_id
LEFT JOIN demand_details dd ON dh.demand_head_id = dd.demand_head_id
LEFT JOIN recovery_head rh ON rl.recovery_list_id = rh.recovery_list_id
LEFT JOIN recovery_details rd ON rh.recovery_head_id = rd.recovery_head_id

WHERE rl.recovery_date::DATE >= CURRENT_DATE - INTERVAL '90 days'

GROUP BY rl.recovery_date::DATE, rl.recovery_list_id
ORDER BY rl.recovery_date DESC;

-- Comment on view
COMMENT ON VIEW view_recovery_performance_analysis IS 'Recovery performance analysis with demand vs collection comparison';

-- View: Transaction audit trail
CREATE OR REPLACE VIEW view_transaction_audit_trail AS
SELECT 
    th.transaction_head_id,
    th.voucher_no,
    th.trans_date::DATE AS transaction_date,
    th.trans_time,
    th.users_id AS created_by,
    th.trans_narration,
    
    -- Transaction details
    td.accounts_id,
    a.account_name,
    td.sub_accounts_id,
    sa.name AS sub_account_name,
    sa.members_id,
    m.full_name AS member_name,
    td.trans_amount,
    
    -- Transaction type classification
    CASE 
        WHEN td.trans_amount > 0 THEN 'DEBIT'
        WHEN td.trans_amount < 0 THEN 'CREDIT'
        ELSE 'ZERO'
    END AS entry_type,
    
    -- Product classification
    CASE 
        WHEN a.account_name ILIKE '%saving%' THEN 'SAVINGS'
        WHEN a.account_name ILIKE '%loan%' OR a.account_name ILIKE '%lone%' THEN 'LOAN'
        WHEN a.account_name ILIKE '%fd%' OR a.account_name ILIKE '%fixed%' THEN 'FIXED_DEPOSIT'
        WHEN a.account_name ILIKE '%share%' THEN 'SHARES'
        WHEN a.account_name ILIKE '%cash%' THEN 'CASH'
        ELSE 'OTHER'
    END AS product_category,
    
    -- Approval status
    CASE 
        WHEN tp.transaction_head_id IS NOT NULL THEN 'APPROVED'
        ELSE 'PENDING'
    END AS approval_status

FROM transaction_head th
INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
INNER JOIN accounts a ON td.accounts_id = a.accounts_id
INNER JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
LEFT JOIN members m ON sa.members_id = m.members_id
LEFT JOIN transaction_passing tp ON th.transaction_head_id = tp.transaction_head_id

WHERE th.trans_date::DATE >= CURRENT_DATE - INTERVAL '30 days'

ORDER BY th.trans_date DESC, th.transaction_head_id DESC, td.transaction_details_id;

-- Comment on view
COMMENT ON VIEW view_transaction_audit_trail IS 'Complete transaction audit trail for the last 30 days';

-- Performance indexes for transaction and recovery views
CREATE INDEX IF NOT EXISTS idx_recovery_details_accounts ON recovery_details(accounts_id);
CREATE INDEX IF NOT EXISTS idx_recovery_list_date ON recovery_list(recovery_date);
CREATE INDEX IF NOT EXISTS idx_demand_head_members ON demand_head(members_id);
CREATE INDEX IF NOT EXISTS idx_transaction_passing_head ON transaction_passing(transaction_head_id);
CREATE INDEX IF NOT EXISTS idx_scroll_transactions_head ON scroll_transactions(transaction_head_id);
CREATE INDEX IF NOT EXISTS idx_transaction_head_date_mode ON transaction_head(trans_date, mode_of_operation);
