-- =============================================
-- Balance and Account Views for PostgreSQL
-- Author: Converted from SQL Server views
-- Create date: 2024
-- Description: Account balance and related views for microfinance operations
-- =============================================

-- View: Sub-account balance for Assets and Liabilities
CREATE OR REPLACE VIEW view_sub_account_balance AS
SELECT 
    SUM(td.trans_amount) AS balance,
    td.accounts_id,
    td.sub_accounts_id
FROM transaction_details td
INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
INNER JOIN accounts a ON td.accounts_id = a.accounts_id
INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
WHERE ag.account_primary_group::INTEGER IN (3, 4) -- Assets and Liabilities
GROUP BY td.accounts_id, td.sub_accounts_id;

-- Comment on view
COMMENT ON VIEW view_sub_account_balance IS 'Sub-account balances for Assets and Liabilities only';

-- View: Member-wise balances (configurable for different accounts)
CREATE OR REPLACE VIEW view_members_bal AS
SELECT 
    td.accounts_id,
    td.sub_accounts_id,
    sa.members_id,
    SUM(td.trans_amount) AS balance
FROM transaction_head th
INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
INNER JOIN accounts a ON td.accounts_id = a.accounts_id
INNER JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
WHERE td.accounts_id = 3 -- Dividend Payable account
    AND th.trans_date <= '2025-03-31'::DATE
GROUP BY td.accounts_id, td.sub_accounts_id, sa.members_id;

-- Comment on view
COMMENT ON VIEW view_members_bal IS 'Member-wise balance view for specific account (currently account_id = 3)';

-- View: Balance brief - simplified version
CREATE OR REPLACE VIEW view_balance_brief AS
SELECT 
    td.accounts_id,
    td.sub_accounts_id,
    SUM(td.trans_amount) AS balance
FROM transaction_head th
INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
WHERE th.trans_date >= '1900-01-01'::DATE  -- Start date filter (was empty string in original)
    AND th.trans_date <= '2025-03-31'::DATE
    AND td.accounts_id = 3
GROUP BY td.accounts_id, td.sub_accounts_id;

-- Comment on view
COMMENT ON VIEW view_balance_brief IS 'Brief balance view with date range filter for specific account';

-- Enhanced View: Current sub-account balances (all accounts)
CREATE OR REPLACE VIEW view_current_sub_account_balances AS
SELECT 
    a.accounts_id,
    a.account_name,
    ag.name AS account_group_name,
    ag.account_primary_group,
    sa.sub_accounts_id,
    sa.sub_accounts_no,
    sa.name AS sub_account_name,
    m.members_id,
    m.full_name AS member_name,
    COALESCE(SUM(td.trans_amount), 0) AS current_balance,
    COUNT(td.transaction_details_id) AS transaction_count,
    MAX(th.trans_date) AS last_transaction_date
FROM accounts a
INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
INNER JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
LEFT JOIN members m ON sa.members_id = m.members_id
LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
    AND sa.accounts_id = td.accounts_id
LEFT JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
GROUP BY 
    a.accounts_id, a.account_name, ag.name, ag.account_primary_group,
    sa.sub_accounts_id, sa.sub_accounts_no, sa.name,
    m.members_id, m.full_name
ORDER BY a.accounts_id, sa.sub_accounts_id;

-- Comment on view
COMMENT ON VIEW view_current_sub_account_balances IS 'Comprehensive current balances for all sub-accounts with member details';

-- Enhanced View: Member portfolio summary
CREATE OR REPLACE VIEW view_member_portfolio_summary AS
SELECT 
    m.members_id,
    m.full_name AS member_name,
    m.status AS member_status,
    
    -- Savings summary
    COALESCE(savings.account_count, 0) AS savings_accounts,
    COALESCE(savings.total_balance, 0) AS total_savings_balance,
    
    -- Loan summary  
    COALESCE(loans.account_count, 0) AS loan_accounts,
    COALESCE(ABS(loans.total_balance), 0) AS total_loan_balance,
    
    -- FD summary
    COALESCE(fd.account_count, 0) AS fd_accounts,
    COALESCE(fd.total_balance, 0) AS total_fd_balance,
    
    -- Share summary
    COALESCE(shares.total_balance, 0) AS total_share_balance,
    
    -- Net position
    COALESCE(savings.total_balance, 0) + COALESCE(fd.total_balance, 0) + 
    COALESCE(shares.total_balance, 0) - COALESCE(ABS(loans.total_balance), 0) AS net_position

FROM members m

-- Savings accounts
LEFT JOIN (
    SELECT 
        sa.members_id,
        COUNT(DISTINCT sac.saving_accounts_id) AS account_count,
        SUM(COALESCE(bal.balance, 0)) AS total_balance
    FROM sub_accounts sa
    INNER JOIN saving_accounts sac ON sa.sub_accounts_id = sac.sub_accounts_id
    LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
        AND sa.accounts_id = bal.accounts_id
    WHERE sac.status = '1' -- Active
    GROUP BY sa.members_id
) savings ON m.members_id = savings.members_id

-- Loan accounts
LEFT JOIN (
    SELECT 
        la.members_id,
        COUNT(DISTINCT la.loan_accounts_id) AS account_count,
        SUM(COALESCE(bal.balance, 0)) AS total_balance
    FROM loan_accounts la
    INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id
    LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
        AND sa.accounts_id = bal.accounts_id
    WHERE la.status IN ('1', '2') -- Active/Disbursed
    GROUP BY la.members_id
) loans ON m.members_id = loans.members_id

-- FD accounts
LEFT JOIN (
    SELECT 
        fa.members_id,
        COUNT(DISTINCT fa.fd_accounts_id) AS account_count,
        SUM(COALESCE(bal.balance, 0)) AS total_balance
    FROM fd_accounts fa
    INNER JOIN sub_accounts sa ON fa.sub_accounts_id = sa.sub_accounts_id
    LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
        AND sa.accounts_id = bal.accounts_id
    WHERE fa.status = '1' -- Active
    GROUP BY fa.members_id
) fd ON m.members_id = fd.members_id

-- Share accounts
LEFT JOIN (
    SELECT 
        s.members_id,
        SUM(COALESCE(bal.balance, 0)) AS total_balance
    FROM shares s
    INNER JOIN sub_accounts sa ON s.sub_accounts_id = sa.sub_accounts_id
    LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
        AND sa.accounts_id = bal.accounts_id
    WHERE s.status = '1' -- Active
    GROUP BY s.members_id
) shares ON m.members_id = shares.members_id

WHERE m.status = '1' -- Active members
ORDER BY m.members_id;

-- Comment on view
COMMENT ON VIEW view_member_portfolio_summary IS 'Complete portfolio summary for each member including all product balances';

-- View: Account-wise balance summary
CREATE OR REPLACE VIEW view_account_balance_summary AS
SELECT 
    a.accounts_id,
    a.account_name,
    ag.name AS account_group_name,
    ag.account_primary_group,
    a.balance_type,
    COUNT(DISTINCT sa.sub_accounts_id) AS total_sub_accounts,
    COUNT(DISTINCT CASE WHEN sa.members_id IS NOT NULL THEN sa.members_id END) AS member_count,
    COALESCE(SUM(bal.balance), 0) AS total_balance,
    COALESCE(SUM(CASE WHEN bal.balance > 0 THEN bal.balance END), 0) AS total_debit_balance,
    COALESCE(SUM(CASE WHEN bal.balance < 0 THEN ABS(bal.balance) END), 0) AS total_credit_balance,
    COUNT(CASE WHEN bal.balance > 0 THEN 1 END) AS accounts_with_debit_balance,
    COUNT(CASE WHEN bal.balance < 0 THEN 1 END) AS accounts_with_credit_balance
FROM accounts a
INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
    AND sa.accounts_id = bal.accounts_id
WHERE a.status = '1' -- Active accounts
GROUP BY 
    a.accounts_id, a.account_name, ag.name, 
    ag.account_primary_group, a.balance_type
ORDER BY a.accounts_id;

-- Comment on view
COMMENT ON VIEW view_account_balance_summary IS 'Summary of balances grouped by account with debit/credit breakdown';

-- Performance indexes for views
CREATE INDEX IF NOT EXISTS idx_transaction_details_account_sub 
ON transaction_details(accounts_id, sub_accounts_id);

CREATE INDEX IF NOT EXISTS idx_sub_accounts_members 
ON sub_accounts(members_id) WHERE members_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_accounts_status 
ON accounts(status);

CREATE INDEX IF NOT EXISTS idx_account_groups_primary 
ON account_groups(account_primary_group);
