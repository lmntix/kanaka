-- =============================================
-- Product-Specific Views for PostgreSQL
-- Author: Converted from SQL Server views
-- Create date: 2024
-- Description: Savings, Loan, FD, and RD product views for microfinance operations
-- =============================================

-- View: Savings joint accounts with member and address details
CREATE OR REPLACE VIEW view_saving_joint_acc AS
SELECT 
    m.members_id,
    m.full_name,
    sa.sub_accounts_id,
    sa.accounts_id,
    sa.sub_accounts_no,
    smo.mode_of_operation,
    mac.address,
    c.name AS city_name,
    mac.pin,
    mac.telephone
FROM saving_joint_accounts sja
INNER JOIN saving_accounts sac ON sja.saving_accounts_id = sac.saving_accounts_id
INNER JOIN members m ON sja.members_id = m.members_id
INNER JOIN sub_accounts sa ON sac.sub_accounts_id = sa.sub_accounts_id
INNER JOIN saving_mode_op smo ON sac.saving_accounts_id = smo.saving_accounts_id
INNER JOIN member_address_contact mac ON m.members_id = mac.members_id
INNER JOIN city c ON mac.city_id = c.city_id;

-- Comment on view
COMMENT ON VIEW view_saving_joint_acc IS 'Savings joint account holders with member and contact details';

-- View: Fixed Deposit joint accounts with member and address details
CREATE OR REPLACE VIEW view_fd_joint_acc AS
SELECT 
    m.members_id,
    m.full_name,
    sa.sub_accounts_id,
    sa.accounts_id,
    sa.sub_accounts_no,
    fmo.mode_of_operation,
    mac.address,
    c.name AS city_name,
    mac.pin,
    mac.telephone
FROM fd_joint_accounts fja
INNER JOIN fd_accounts fa ON fja.fd_accounts_id = fa.fd_accounts_id
INNER JOIN members m ON fja.members_id = m.members_id
INNER JOIN sub_accounts sa ON fa.sub_accounts_id = sa.sub_accounts_id
INNER JOIN fd_mode_op fmo ON fa.fd_accounts_id = fmo.fd_accounts_id
INNER JOIN member_address_contact mac ON m.members_id = mac.members_id
INNER JOIN city c ON mac.city_id = c.city_id;

-- Comment on view
COMMENT ON VIEW view_fd_joint_acc IS 'FD joint account holders with member and contact details';

-- View: Recurring Deposit joint accounts with member and address details
CREATE OR REPLACE VIEW view_recurring_joint_acc AS
SELECT 
    m.members_id,
    m.full_name,
    sa.sub_accounts_id,
    sa.accounts_id,
    sa.sub_accounts_no,
    rmo.mode_of_operation,
    mac.address,
    c.name AS city_name,
    mac.pin,
    mac.telephone
FROM recurring_joint_accounts rja
INNER JOIN recurring_accounts ra ON rja.recurring_accounts_id = ra.recurring_accounts_id
INNER JOIN members m ON rja.members_id = m.members_id
INNER JOIN sub_accounts sa ON ra.sub_accounts_id = sa.sub_accounts_id
INNER JOIN recurring_mode_op rmo ON ra.recurring_accounts_id = rmo.recurring_accounts_id
INNER JOIN member_address_contact mac ON m.members_id = mac.members_id
INNER JOIN city c ON mac.city_id = c.city_id;

-- Comment on view
COMMENT ON VIEW view_recurring_joint_acc IS 'RD joint account holders with member and contact details';

-- View: Loan co-applicant accounts with member and address details
CREATE OR REPLACE VIEW view_loan_co_app_acc AS
SELECT 
    m.members_id,
    m.full_name,
    sa.sub_accounts_id,
    sa.accounts_id,
    sa.sub_accounts_no,
    mac.address,
    c.name AS city_name,
    c.pin,
    mac.telephone
FROM members m
INNER JOIN member_address_contact mac ON m.members_id = mac.members_id
INNER JOIN city c ON mac.city_id = c.city_id
INNER JOIN loan_co_applicant lca ON m.members_id = lca.members_id
INNER JOIN loan_accounts la ON m.members_id = la.members_id 
    AND lca.loan_accounts_id = la.loan_accounts_id
INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id;

-- Comment on view
COMMENT ON VIEW view_loan_co_app_acc IS 'Loan co-applicants with member and contact details';

-- Enhanced View: Comprehensive savings account details
CREATE OR REPLACE VIEW view_savings_account_details AS
SELECT 
    sac.saving_accounts_id,
    sac.sub_accounts_id,
    sa.sub_accounts_no,
    sac.members_id,
    m.full_name AS member_name,
    sac.open_date::DATE,
    sac.interest_rate::DECIMAL AS interest_rate,
    sac.status,
    ss.scheme_name,
    ss.min_balance::DECIMAL AS min_balance_required,
    ss.max_balance::DECIMAL AS max_balance_allowed,
    
    -- Current balance
    COALESCE(bal.balance, 0) AS current_balance,
    
    -- Account status description
    CASE sac.status
        WHEN '1' THEN 'Active'
        WHEN '2' THEN 'Inactive'
        WHEN '3' THEN 'Closed'
        WHEN '4' THEN 'Suspended'
        ELSE 'Unknown'
    END AS status_description,
    
    -- Interest eligibility
    CASE 
        WHEN COALESCE(bal.balance, 0) >= COALESCE(ss.min_balance::DECIMAL, 0) 
        THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS interest_eligible,
    
    -- Account age in days
    CURRENT_DATE - sac.open_date::DATE AS account_age_days,
    
    -- Last transaction date
    last_trans.last_transaction_date

FROM saving_accounts sac
INNER JOIN sub_accounts sa ON sac.sub_accounts_id = sa.sub_accounts_id
INNER JOIN members m ON sac.members_id = m.members_id
LEFT JOIN saving_schemes ss ON sac.saving_schemes_id = ss.saving_schemes_id
LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
    AND sa.accounts_id = bal.accounts_id
LEFT JOIN (
    SELECT 
        td.sub_accounts_id,
        MAX(th.trans_date::DATE) AS last_transaction_date
    FROM transaction_details td
    INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
    GROUP BY td.sub_accounts_id
) last_trans ON sa.sub_accounts_id = last_trans.sub_accounts_id

ORDER BY sac.saving_accounts_id;

-- Comment on view
COMMENT ON VIEW view_savings_account_details IS 'Comprehensive savings account information with balances and status';

-- Enhanced View: Comprehensive loan account details
CREATE OR REPLACE VIEW view_loan_account_details AS
SELECT 
    la.loan_accounts_id,
    la.sub_accounts_id,
    sa.sub_accounts_no,
    la.members_id,
    m.full_name AS member_name,
    la.loan_amount::DECIMAL,
    la.interest_rate::DECIMAL,
    la.open_date::DATE,
    la.first_installment_date::DATE,
    la.end_date::DATE,
    la.tenure::INTEGER,
    la.installment_amt::DECIMAL,
    la.total_installments::INTEGER,
    la.status,
    ls.scheme_name,
    lr.reason_name,
    
    -- Current outstanding balance (negative value indicates debt)
    COALESCE(ABS(bal.balance), 0) AS outstanding_balance,
    
    -- Account status description
    CASE la.status
        WHEN '1' THEN 'Applied'
        WHEN '2' THEN 'Approved/Disbursed'
        WHEN '3' THEN 'Partially Paid'
        WHEN '4' THEN 'Fully Paid'
        WHEN '5' THEN 'Closed'
        ELSE 'Unknown'
    END AS status_description,
    
    -- Loan maturity status
    CASE 
        WHEN la.end_date::DATE < CURRENT_DATE AND COALESCE(ABS(bal.balance), 0) > 0
        THEN 'Overdue'
        WHEN la.end_date::DATE < CURRENT_DATE AND COALESCE(ABS(bal.balance), 0) = 0
        THEN 'Matured & Paid'
        WHEN la.end_date::DATE >= CURRENT_DATE
        THEN 'Active'
        ELSE 'Unknown'
    END AS maturity_status,
    
    -- Days to/past maturity
    la.end_date::DATE - CURRENT_DATE AS days_to_maturity,
    
    -- Loan age in days
    CURRENT_DATE - la.open_date::DATE AS loan_age_days,
    
    -- EMI calculations
    CASE 
        WHEN la.tenure::INTEGER > 0 
        THEN ROUND((la.loan_amount::DECIMAL / la.tenure::INTEGER), 2)
        ELSE 0
    END AS calculated_principal_emi,
    
    -- Last payment date
    last_payment.last_payment_date,
    last_payment.last_payment_amount

FROM loan_accounts la
INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id
INNER JOIN members m ON la.members_id = m.members_id
LEFT JOIN loan_schemes ls ON la.loan_schemes_id = ls.loan_schemes_id
LEFT JOIN loan_reason lr ON la.loan_reason_id = lr.loan_reason_id
LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
    AND sa.accounts_id = bal.accounts_id
LEFT JOIN (
    SELECT 
        lrep.loan_accounts_id,
        MAX(lrep.repayment_date::DATE) AS last_payment_date,
        MAX(lrep.repayment_amount::DECIMAL) AS last_payment_amount
    FROM loan_repayment lrep
    GROUP BY lrep.loan_accounts_id
) last_payment ON la.loan_accounts_id = last_payment.loan_accounts_id

ORDER BY la.loan_accounts_id;

-- Comment on view
COMMENT ON VIEW view_loan_account_details IS 'Comprehensive loan account information with outstanding balances and payment status';

-- Enhanced View: FD account details with maturity information
CREATE OR REPLACE VIEW view_fd_account_details AS
SELECT 
    fa.fd_accounts_id,
    fa.sub_accounts_id,
    sa.sub_accounts_no,
    fa.members_id,
    m.full_name AS member_name,
    fa.fd_amount::DECIMAL,
    fa.interest_rate::DECIMAL,
    fa.open_date::DATE,
    fa.maturity_date::DATE,
    fa.maturity_amount::DECIMAL,
    fa.tenure_months::INTEGER,
    fa.tenure_days::INTEGER,
    fa.status,
    fs.scheme_name,
    
    -- Current balance
    COALESCE(bal.balance, 0) AS current_balance,
    
    -- Account status description
    CASE fa.status
        WHEN '1' THEN 'Active'
        WHEN '2' THEN 'Matured'
        WHEN '3' THEN 'Closed'
        WHEN '4' THEN 'Premature Closure'
        ELSE 'Unknown'
    END AS status_description,
    
    -- Maturity status
    CASE 
        WHEN fa.maturity_date::DATE <= CURRENT_DATE AND fa.status = '1'
        THEN 'Due for Maturity'
        WHEN fa.maturity_date::DATE <= CURRENT_DATE AND fa.status = '2'
        THEN 'Matured'
        WHEN fa.maturity_date::DATE > CURRENT_DATE
        THEN 'Active'
        ELSE 'Closed'
    END AS maturity_status,
    
    -- Days to/past maturity
    fa.maturity_date::DATE - CURRENT_DATE AS days_to_maturity,
    
    -- FD duration
    CURRENT_DATE - fa.open_date::DATE AS fd_age_days,
    fa.maturity_date::DATE - fa.open_date::DATE AS total_fd_duration_days,
    
    -- Interest calculations
    ROUND((fa.maturity_amount::DECIMAL - fa.fd_amount::DECIMAL), 2) AS total_interest_amount,
    
    CASE 
        WHEN fa.tenure_days::INTEGER > 0
        THEN ROUND(((fa.maturity_amount::DECIMAL - fa.fd_amount::DECIMAL) * 365.0 / fa.tenure_days::INTEGER / fa.fd_amount::DECIMAL * 100), 2)
        ELSE fa.interest_rate::DECIMAL
    END AS effective_annual_rate

FROM fd_accounts fa
INNER JOIN sub_accounts sa ON fa.sub_accounts_id = sa.sub_accounts_id
INNER JOIN members m ON fa.members_id = m.members_id
LEFT JOIN fd_schemes fs ON fa.fd_schemes_id = fs.fd_schemes_id
LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
    AND sa.accounts_id = bal.accounts_id

ORDER BY fa.fd_accounts_id;

-- Comment on view
COMMENT ON VIEW view_fd_account_details IS 'Comprehensive FD account information with maturity status and interest calculations';

-- View: RD transactions summary
CREATE OR REPLACE VIEW view_rd_trans AS
SELECT 
    td.transaction_details_id,
    td.transaction_head_id,
    td.accounts_id,
    td.sub_accounts_id,
    td.trans_amount,
    sa.members_id,
    th.trans_date,
    th.trans_narration
FROM transaction_details td
INNER JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
WHERE td.accounts_id = 76 -- RD account ID (adjust as per your schema)
ORDER BY sa.members_id, td.sub_accounts_id, th.trans_date;

-- Comment on view
COMMENT ON VIEW view_rd_trans IS 'RD transaction details ordered by member and date';

-- Enhanced View: Product performance summary
CREATE OR REPLACE VIEW view_product_performance_summary AS
SELECT 
    'Savings' AS product_type,
    COUNT(DISTINCT sac.saving_accounts_id) AS total_accounts,
    COUNT(DISTINCT sac.members_id) AS unique_members,
    SUM(CASE WHEN sac.status = '1' THEN 1 ELSE 0 END) AS active_accounts,
    COALESCE(SUM(CASE WHEN sac.status = '1' THEN COALESCE(bal.balance, 0) ELSE 0 END), 0) AS total_active_balance,
    COALESCE(AVG(CASE WHEN sac.status = '1' THEN COALESCE(bal.balance, 0) ELSE NULL END), 0) AS avg_active_balance

FROM saving_accounts sac
INNER JOIN sub_accounts sa ON sac.sub_accounts_id = sa.sub_accounts_id
LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
    AND sa.accounts_id = bal.accounts_id

UNION ALL

SELECT 
    'Loans' AS product_type,
    COUNT(DISTINCT la.loan_accounts_id) AS total_accounts,
    COUNT(DISTINCT la.members_id) AS unique_members,
    SUM(CASE WHEN la.status IN ('1', '2') THEN 1 ELSE 0 END) AS active_accounts,
    COALESCE(SUM(CASE WHEN la.status IN ('1', '2') THEN ABS(COALESCE(bal.balance, 0)) ELSE 0 END), 0) AS total_active_balance,
    COALESCE(AVG(CASE WHEN la.status IN ('1', '2') THEN ABS(COALESCE(bal.balance, 0)) ELSE NULL END), 0) AS avg_active_balance

FROM loan_accounts la
INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id
LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
    AND sa.accounts_id = bal.accounts_id

UNION ALL

SELECT 
    'Fixed Deposits' AS product_type,
    COUNT(DISTINCT fa.fd_accounts_id) AS total_accounts,
    COUNT(DISTINCT fa.members_id) AS unique_members,
    SUM(CASE WHEN fa.status = '1' THEN 1 ELSE 0 END) AS active_accounts,
    COALESCE(SUM(CASE WHEN fa.status = '1' THEN COALESCE(bal.balance, 0) ELSE 0 END), 0) AS total_active_balance,
    COALESCE(AVG(CASE WHEN fa.status = '1' THEN COALESCE(bal.balance, 0) ELSE NULL END), 0) AS avg_active_balance

FROM fd_accounts fa
INNER JOIN sub_accounts sa ON fa.sub_accounts_id = sa.sub_accounts_id
LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
    AND sa.accounts_id = bal.accounts_id;

-- Comment on view
COMMENT ON VIEW view_product_performance_summary IS 'Performance summary across all product types';

-- Performance indexes for product views
CREATE INDEX IF NOT EXISTS idx_saving_accounts_status_members ON saving_accounts(status, members_id);
CREATE INDEX IF NOT EXISTS idx_loan_accounts_status_members ON loan_accounts(status, members_id);
CREATE INDEX IF NOT EXISTS idx_fd_accounts_status_members ON fd_accounts(status, members_id);
CREATE INDEX IF NOT EXISTS idx_saving_joint_accounts ON saving_joint_accounts(saving_accounts_id, members_id);
CREATE INDEX IF NOT EXISTS idx_loan_co_applicant ON loan_co_applicant(loan_accounts_id, members_id);
