-- =============================================
-- Additional Microfinance Views for PostgreSQL
-- Author: Created for enhanced microfinance operations
-- Create date: 2024
-- Description: Advanced microfinance reporting and analysis views
-- =============================================

-- View: Loan overdue analysis
CREATE OR REPLACE VIEW view_loan_overdue_analysis AS
SELECT 
    la.loan_accounts_id,
    la.members_id,
    m.full_name AS member_name,
    la.loan_amount::DECIMAL,
    la.interest_rate::DECIMAL,
    la.installment_amt::DECIMAL,
    la.end_date::DATE AS maturity_date,
    la.status,
    
    -- Current outstanding balance
    COALESCE(ABS(bal.balance), 0) AS outstanding_balance,
    
    -- Overdue calculation
    CASE 
        WHEN la.end_date::DATE < CURRENT_DATE AND COALESCE(ABS(bal.balance), 0) > 0
        THEN CURRENT_DATE - la.end_date::DATE
        ELSE 0
    END AS overdue_days,
    
    -- Overdue classification
    CASE 
        WHEN la.end_date::DATE >= CURRENT_DATE OR COALESCE(ABS(bal.balance), 0) = 0
        THEN 'CURRENT'
        WHEN CURRENT_DATE - la.end_date::DATE <= 30
        THEN 'OVERDUE_1_30'
        WHEN CURRENT_DATE - la.end_date::DATE <= 90
        THEN 'OVERDUE_31_90'
        WHEN CURRENT_DATE - la.end_date::DATE <= 180
        THEN 'OVERDUE_91_180'
        ELSE 'OVERDUE_180_PLUS'
    END AS overdue_bucket,
    
    -- Risk classification
    CASE 
        WHEN la.end_date::DATE >= CURRENT_DATE OR COALESCE(ABS(bal.balance), 0) = 0
        THEN 'PERFORMING'
        WHEN CURRENT_DATE - la.end_date::DATE <= 30
        THEN 'WATCH'
        WHEN CURRENT_DATE - la.end_date::DATE <= 90
        THEN 'SUBSTANDARD'
        WHEN CURRENT_DATE - la.end_date::DATE <= 180
        THEN 'DOUBTFUL'
        ELSE 'LOSS'
    END AS risk_category,
    
    -- Last payment information
    last_payment.last_payment_date,
    last_payment.last_payment_amount,
    COALESCE(CURRENT_DATE - last_payment.last_payment_date, 9999) AS days_since_last_payment,
    
    -- Contact information for follow-up
    mac.telephone,
    mac.address,
    c.name AS city_name

FROM loan_accounts la
INNER JOIN members m ON la.members_id = m.members_id
INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id
-- Calculate balance inline instead of depending on view_sub_account_balance
LEFT JOIN (
    SELECT 
        SUM(td.trans_amount) AS balance,
        td.accounts_id,
        td.sub_accounts_id
    FROM transaction_details td
    INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
    INNER JOIN accounts a ON td.accounts_id = a.accounts_id
    INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
    WHERE ag.account_primary_group::INTEGER IN (3, 4) -- Assets and Liabilities
    GROUP BY td.accounts_id, td.sub_accounts_id
) bal ON sa.sub_accounts_id = bal.sub_accounts_id AND sa.accounts_id = bal.accounts_id
LEFT JOIN (
    SELECT 
        lrep.loan_accounts_id,
        MAX(lrep.repayment_date::DATE) AS last_payment_date,
        SUM(lrep.repayment_amount::DECIMAL) AS last_payment_amount
    FROM loan_repayment lrep
    GROUP BY lrep.loan_accounts_id
) last_payment ON la.loan_accounts_id = last_payment.loan_accounts_id
LEFT JOIN member_address_contact mac ON m.members_id = mac.members_id
LEFT JOIN city c ON mac.city_id = c.city_id

WHERE la.status IN ('1', '2', '3') -- Active, Disbursed, Partially Paid
    AND COALESCE(ABS(bal.balance), 0) > 0 -- Has outstanding balance

ORDER BY overdue_days DESC, outstanding_balance DESC;

-- Comment on view
COMMENT ON VIEW view_loan_overdue_analysis IS 'Comprehensive loan overdue analysis with risk classification and contact details';

-- View: Interest accrual summary
CREATE OR REPLACE VIEW view_interest_accrual_summary AS
SELECT 
    DATE_TRUNC('month', CURRENT_DATE) AS accrual_month,
    
    -- Savings interest summary
    'SAVINGS' AS product_type,
    COUNT(DISTINCT sip.saving_accounts_id) AS accounts_processed,
    SUM(sip.interest_amount::DECIMAL) AS total_interest_accrued,
    AVG(sip.interest_amount::DECIMAL) AS avg_interest_per_account,
    MIN(sip.interest_amount::DECIMAL) AS min_interest,
    MAX(sip.interest_amount::DECIMAL) AS max_interest
    
FROM saving_interest_post sip
WHERE sip.interest_date::DATE >= DATE_TRUNC('month', CURRENT_DATE)
    AND sip.interest_date::DATE < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'

UNION ALL

SELECT 
    DATE_TRUNC('month', CURRENT_DATE) AS accrual_month,
    
    -- Loan interest summary
    'LOANS' AS product_type,
    COUNT(DISTINCT lip.loan_accounts_id) AS accounts_processed,
    SUM(lip.interest_amount::DECIMAL) AS total_interest_accrued,
    AVG(lip.interest_amount::DECIMAL) AS avg_interest_per_account,
    MIN(lip.interest_amount::DECIMAL) AS min_interest,
    MAX(lip.interest_amount::DECIMAL) AS max_interest
    
FROM loan_interest_post lip
WHERE lip.interest_date::DATE >= DATE_TRUNC('month', CURRENT_DATE)
    AND lip.interest_date::DATE < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'

UNION ALL

SELECT 
    DATE_TRUNC('month', CURRENT_DATE) AS accrual_month,
    
    -- FD interest summary
    'FIXED_DEPOSITS' AS product_type,
    COUNT(DISTINCT fip.fd_accounts_id) AS accounts_processed,
    SUM(fip.interest_amount::DECIMAL) AS total_interest_accrued,
    AVG(fip.interest_amount::DECIMAL) AS avg_interest_per_account,
    MIN(fip.interest_amount::DECIMAL) AS min_interest,
    MAX(fip.interest_amount::DECIMAL) AS max_interest
    
FROM fd_interest_post fip
WHERE fip.interest_date::DATE >= DATE_TRUNC('month', CURRENT_DATE)
    AND fip.interest_date::DATE < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';

-- Comment on view
COMMENT ON VIEW view_interest_accrual_summary IS 'Monthly interest accrual summary across all product types';

-- View: Member growth and retention analysis
CREATE OR REPLACE VIEW view_member_growth_analysis AS
WITH monthly_stats AS (
    SELECT 
        DATE_TRUNC('month', m.appli_date::DATE) AS join_month,
        COUNT(*) AS new_members,
        COUNT(CASE WHEN m.gender = '1' THEN 1 END) AS male_members,
        COUNT(CASE WHEN m.gender = '2' THEN 1 END) AS female_members
    FROM members m
    WHERE m.appli_date::DATE >= CURRENT_DATE - INTERVAL '12 months'
        AND m.status = '1'
    GROUP BY DATE_TRUNC('month', m.appli_date::DATE)
),
retention_stats AS (
    SELECT 
        DATE_TRUNC('month', CURRENT_DATE) AS analysis_month,
        COUNT(CASE WHEN last_activity.last_transaction_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) AS active_last_30_days,
        COUNT(CASE WHEN last_activity.last_transaction_date >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) AS active_last_90_days,
        COUNT(CASE WHEN last_activity.last_transaction_date >= CURRENT_DATE - INTERVAL '180 days' THEN 1 END) AS active_last_180_days,
        COUNT(*) AS total_members
    FROM members m
    LEFT JOIN (
        SELECT 
            sa.members_id,
            MAX(th.trans_date::DATE) AS last_transaction_date
        FROM sub_accounts sa
        INNER JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id
        INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
        GROUP BY sa.members_id
    ) last_activity ON m.members_id = last_activity.members_id
    WHERE m.status = '1'
)
SELECT 
    COALESCE(ms.join_month, rs.analysis_month) AS period,
    ms.new_members,
    ms.male_members,
    ms.female_members,
    rs.active_last_30_days,
    rs.active_last_90_days,
    rs.active_last_180_days,
    rs.total_members,
    
    -- Retention percentages
    CASE 
        WHEN rs.total_members > 0 
        THEN ROUND((rs.active_last_30_days::DECIMAL / rs.total_members * 100), 2)
        ELSE 0 
    END AS retention_30_day_pct,
    
    CASE 
        WHEN rs.total_members > 0 
        THEN ROUND((rs.active_last_90_days::DECIMAL / rs.total_members * 100), 2)
        ELSE 0 
    END AS retention_90_day_pct

FROM monthly_stats ms
FULL OUTER JOIN retention_stats rs ON ms.join_month = rs.analysis_month
ORDER BY COALESCE(ms.join_month, rs.analysis_month) DESC;

-- Comment on view
COMMENT ON VIEW view_member_growth_analysis IS 'Member growth and retention analysis with activity-based metrics';

-- View: Product penetration analysis
CREATE OR REPLACE VIEW view_product_penetration_analysis AS
WITH member_products AS (
    SELECT 
        m.members_id,
        m.full_name,
        
        -- Product ownership flags
        CASE WHEN sac.saving_accounts_id IS NOT NULL THEN 1 ELSE 0 END AS has_savings,
        CASE WHEN la.loan_accounts_id IS NOT NULL THEN 1 ELSE 0 END AS has_loan,
        CASE WHEN fa.fd_accounts_id IS NOT NULL THEN 1 ELSE 0 END AS has_fd,
        CASE WHEN s.shares_id IS NOT NULL THEN 1 ELSE 0 END AS has_shares,
        
        -- Product counts
        COUNT(DISTINCT sac.saving_accounts_id) AS savings_count,
        COUNT(DISTINCT la.loan_accounts_id) AS loan_count,
        COUNT(DISTINCT fa.fd_accounts_id) AS fd_count,
        COUNT(DISTINCT s.shares_id) AS share_count
        
    FROM members m
    LEFT JOIN saving_accounts sac ON m.members_id = sac.members_id AND sac.status = '1'
    LEFT JOIN loan_accounts la ON m.members_id = la.members_id AND la.status IN ('1', '2')
    LEFT JOIN fd_accounts fa ON m.members_id = fa.members_id AND fa.status = '1'
    LEFT JOIN shares s ON m.members_id = s.members_id AND s.status = '1'
    
    WHERE m.status = '1'
    
    GROUP BY 
        m.members_id, m.full_name, 
        sac.saving_accounts_id, la.loan_accounts_id, fa.fd_accounts_id, s.shares_id
)
SELECT 
    -- Overall penetration stats
    COUNT(*) AS total_active_members,
    
    -- Single product penetration
    SUM(has_savings) AS members_with_savings,
    SUM(has_loan) AS members_with_loans,
    SUM(has_fd) AS members_with_fd,
    SUM(has_shares) AS members_with_shares,
    
    -- Single product penetration percentages
    ROUND((SUM(has_savings)::DECIMAL / COUNT(*) * 100), 2) AS savings_penetration_pct,
    ROUND((SUM(has_loan)::DECIMAL / COUNT(*) * 100), 2) AS loan_penetration_pct,
    ROUND((SUM(has_fd)::DECIMAL / COUNT(*) * 100), 2) AS fd_penetration_pct,
    ROUND((SUM(has_shares)::DECIMAL / COUNT(*) * 100), 2) AS shares_penetration_pct,
    
    -- Cross-sell analysis
    SUM(CASE WHEN (has_savings + has_loan + has_fd + has_shares) = 1 THEN 1 ELSE 0 END) AS single_product_members,
    SUM(CASE WHEN (has_savings + has_loan + has_fd + has_shares) = 2 THEN 1 ELSE 0 END) AS two_product_members,
    SUM(CASE WHEN (has_savings + has_loan + has_fd + has_shares) = 3 THEN 1 ELSE 0 END) AS three_product_members,
    SUM(CASE WHEN (has_savings + has_loan + has_fd + has_shares) = 4 THEN 1 ELSE 0 END) AS four_product_members,
    
    -- Average products per member
    ROUND(AVG(has_savings + has_loan + has_fd + has_shares), 2) AS avg_products_per_member

FROM member_products;

-- Comment on view
COMMENT ON VIEW view_product_penetration_analysis IS 'Product penetration and cross-sell analysis across member base';

-- View: Branch performance comparison
CREATE OR REPLACE VIEW view_branch_performance_comparison AS
SELECT 
    b.branch_id,
    b.name AS branch_name,
    
    -- Member statistics
    COUNT(DISTINCT m.members_id) AS total_members,
    COUNT(DISTINCT CASE WHEN m.status = '1' THEN m.members_id END) AS active_members,
    
    -- Product statistics
    COUNT(DISTINCT sac.saving_accounts_id) AS savings_accounts,
    COUNT(DISTINCT la.loan_accounts_id) AS loan_accounts,
    COUNT(DISTINCT fa.fd_accounts_id) AS fd_accounts,
    
    -- Portfolio balances (using latest transaction date as proxy for branch association)
    COALESCE(SUM(CASE WHEN sac.saving_accounts_id IS NOT NULL THEN COALESCE(sab.balance, 0) END), 0) AS total_savings_balance,
    COALESCE(SUM(CASE WHEN la.loan_accounts_id IS NOT NULL THEN ABS(COALESCE(lab.balance, 0)) END), 0) AS total_loan_balance,
    COALESCE(SUM(CASE WHEN fa.fd_accounts_id IS NOT NULL THEN COALESCE(fab.balance, 0) END), 0) AS total_fd_balance,
    
    -- Transaction activity (last 30 days)
    COUNT(DISTINCT CASE WHEN th.trans_date::DATE >= CURRENT_DATE - INTERVAL '30 days' THEN th.transaction_head_id END) AS transactions_last_30_days,
    COALESCE(SUM(CASE WHEN th.trans_date::DATE >= CURRENT_DATE - INTERVAL '30 days' THEN ABS(th.trans_amount::DECIMAL) END), 0) AS transaction_volume_last_30_days,
    
    -- Performance ratios
    CASE 
        WHEN COUNT(DISTINCT m.members_id) > 0 
        THEN ROUND((COALESCE(SUM(CASE WHEN sac.saving_accounts_id IS NOT NULL THEN COALESCE(sab.balance, 0) END), 0) / COUNT(DISTINCT m.members_id)), 2)
        ELSE 0 
    END AS avg_savings_per_member,
    
    CASE 
        WHEN COUNT(DISTINCT m.members_id) > 0 
        THEN ROUND((COALESCE(SUM(CASE WHEN la.loan_accounts_id IS NOT NULL THEN ABS(COALESCE(lab.balance, 0)) END), 0) / COUNT(DISTINCT m.members_id)), 2)
        ELSE 0 
    END AS avg_loan_per_member

FROM branch b
LEFT JOIN transaction_head th ON b.branch_id = th.branch_id
LEFT JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
LEFT JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
LEFT JOIN members m ON sa.members_id = m.members_id
LEFT JOIN saving_accounts sac ON m.members_id = sac.members_id AND sac.status = '1'
LEFT JOIN loan_accounts la ON m.members_id = la.members_id AND la.status IN ('1', '2')
LEFT JOIN fd_accounts fa ON m.members_id = fa.members_id AND fa.status = '1'
-- Calculate balances inline instead of depending on view_sub_account_balance
LEFT JOIN (
    SELECT 
        SUM(td.trans_amount) AS balance,
        td.accounts_id,
        td.sub_accounts_id
    FROM transaction_details td
    INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
    INNER JOIN accounts a ON td.accounts_id = a.accounts_id
    INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
    WHERE ag.account_primary_group::INTEGER IN (3, 4) -- Assets and Liabilities
    GROUP BY td.accounts_id, td.sub_accounts_id
) sab ON sac.sub_accounts_id = sab.sub_accounts_id
LEFT JOIN (
    SELECT 
        SUM(td.trans_amount) AS balance,
        td.accounts_id,
        td.sub_accounts_id
    FROM transaction_details td
    INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
    INNER JOIN accounts a ON td.accounts_id = a.accounts_id
    INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
    WHERE ag.account_primary_group::INTEGER IN (3, 4) -- Assets and Liabilities
    GROUP BY td.accounts_id, td.sub_accounts_id
) lab ON la.sub_accounts_id = lab.sub_accounts_id
LEFT JOIN (
    SELECT 
        SUM(td.trans_amount) AS balance,
        td.accounts_id,
        td.sub_accounts_id
    FROM transaction_details td
    INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
    INNER JOIN accounts a ON td.accounts_id = a.accounts_id
    INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
    WHERE ag.account_primary_group::INTEGER IN (3, 4) -- Assets and Liabilities
    GROUP BY td.accounts_id, td.sub_accounts_id
) fab ON fa.sub_accounts_id = fab.sub_accounts_id

GROUP BY b.branch_id, b.name
ORDER BY total_members DESC;

-- Comment on view
COMMENT ON VIEW view_branch_performance_comparison IS 'Branch-wise performance comparison with key metrics and ratios';

-- View: Financial health indicators
CREATE OR REPLACE VIEW view_financial_health_indicators AS
WITH portfolio_summary AS (
    SELECT 
        -- Asset quality indicators
        COUNT(DISTINCT CASE WHEN la.status IN ('1', '2') THEN la.loan_accounts_id END) AS total_active_loans,
        COUNT(DISTINCT CASE WHEN overdue.overdue_days > 0 THEN overdue.loan_accounts_id END) AS overdue_loans,
        COUNT(DISTINCT CASE WHEN overdue.overdue_days > 90 THEN overdue.loan_accounts_id END) AS npa_loans,
        
        COALESCE(SUM(CASE WHEN la.status IN ('1', '2') THEN ABS(COALESCE(bal.balance, 0)) END), 0) AS total_loan_portfolio,
        COALESCE(SUM(CASE WHEN overdue.overdue_days > 0 THEN ABS(COALESCE(bal.balance, 0)) END), 0) AS overdue_amount,
        COALESCE(SUM(CASE WHEN overdue.overdue_days > 90 THEN ABS(COALESCE(bal.balance, 0)) END), 0) AS npa_amount,
        
        -- Savings indicators
        COUNT(DISTINCT CASE WHEN sac.status = '1' THEN sac.saving_accounts_id END) AS total_savings_accounts,
        COALESCE(SUM(CASE WHEN sac.status = '1' THEN COALESCE(sbal.balance, 0) END), 0) AS total_savings_balance
        
    FROM loan_accounts la
    INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id
    -- Calculate balance inline instead of depending on view_sub_account_balance
    LEFT JOIN (
        SELECT 
            SUM(td.trans_amount) AS balance,
            td.accounts_id,
            td.sub_accounts_id
        FROM transaction_details td
        INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
        INNER JOIN accounts a ON td.accounts_id = a.accounts_id
        INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
        WHERE ag.account_primary_group::INTEGER IN (3, 4) -- Assets and Liabilities
        GROUP BY td.accounts_id, td.sub_accounts_id
    ) bal ON sa.sub_accounts_id = bal.sub_accounts_id
    LEFT JOIN view_loan_overdue_analysis overdue ON la.loan_accounts_id = overdue.loan_accounts_id
    FULL OUTER JOIN saving_accounts sac ON sac.status = '1'
    LEFT JOIN sub_accounts ssa ON sac.sub_accounts_id = ssa.sub_accounts_id
    -- Calculate savings balance inline instead of depending on view_sub_account_balance
    LEFT JOIN (
        SELECT 
            SUM(td.trans_amount) AS balance,
            td.accounts_id,
            td.sub_accounts_id
        FROM transaction_details td
        INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
        INNER JOIN accounts a ON td.accounts_id = a.accounts_id
        INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
        WHERE ag.account_primary_group::INTEGER IN (3, 4) -- Assets and Liabilities
        GROUP BY td.accounts_id, td.sub_accounts_id
    ) sbal ON ssa.sub_accounts_id = sbal.sub_accounts_id
)
SELECT 
    CURRENT_DATE AS report_date,
    
    -- Portfolio composition
    total_active_loans,
    total_loan_portfolio,
    total_savings_accounts,
    total_savings_balance,
    
    -- Asset quality ratios
    overdue_loans,
    npa_loans,
    overdue_amount,
    npa_amount,
    
    -- Key ratios
    CASE 
        WHEN total_active_loans > 0 
        THEN ROUND((overdue_loans::DECIMAL / total_active_loans * 100), 2)
        ELSE 0 
    END AS overdue_loan_ratio_pct,
    
    CASE 
        WHEN total_active_loans > 0 
        THEN ROUND((npa_loans::DECIMAL / total_active_loans * 100), 2)
        ELSE 0 
    END AS npa_loan_ratio_pct,
    
    CASE 
        WHEN total_loan_portfolio > 0 
        THEN ROUND((overdue_amount / total_loan_portfolio * 100), 2)
        ELSE 0 
    END AS overdue_amount_ratio_pct,
    
    CASE 
        WHEN total_loan_portfolio > 0 
        THEN ROUND((npa_amount / total_loan_portfolio * 100), 2)
        ELSE 0 
    END AS npa_amount_ratio_pct,
    
    -- Liquidity indicator
    CASE 
        WHEN total_loan_portfolio > 0 
        THEN ROUND((total_savings_balance / total_loan_portfolio * 100), 2)
        ELSE 0 
    END AS savings_to_loans_ratio_pct,
    
    -- Health status
    CASE 
        WHEN total_loan_portfolio = 0 THEN 'NO_PORTFOLIO'
        WHEN (overdue_amount / NULLIF(total_loan_portfolio, 0) * 100) <= 5 THEN 'HEALTHY'
        WHEN (overdue_amount / NULLIF(total_loan_portfolio, 0) * 100) <= 10 THEN 'WATCH'
        WHEN (overdue_amount / NULLIF(total_loan_portfolio, 0) * 100) <= 20 THEN 'CAUTION'
        ELSE 'CRITICAL'
    END AS portfolio_health_status

FROM portfolio_summary;

-- Comment on view
COMMENT ON VIEW view_financial_health_indicators IS 'Key financial health indicators and portfolio quality metrics';

-- View: Monthly business dashboard
CREATE OR REPLACE VIEW view_monthly_business_dashboard AS
SELECT 
    DATE_TRUNC('month', CURRENT_DATE) AS dashboard_month,
    
    -- Member metrics
    (SELECT COUNT(*) FROM members WHERE status = '1') AS total_active_members,
    (SELECT COUNT(*) FROM members WHERE appli_date::DATE >= DATE_TRUNC('month', CURRENT_DATE) AND status = '1') AS new_members_this_month,
    
    -- Portfolio metrics
    (SELECT COUNT(*) FROM loan_accounts WHERE status IN ('1', '2')) AS active_loans,
    (SELECT COUNT(*) FROM saving_accounts WHERE status = '1') AS active_savings,
    (SELECT COUNT(*) FROM fd_accounts WHERE status = '1') AS active_fds,
    
    -- Financial metrics
    (SELECT COALESCE(SUM(ABS(bal.balance)), 0) FROM loan_accounts la 
     INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id
     LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id
     WHERE la.status IN ('1', '2')) AS total_loan_outstanding,
     
    (SELECT COALESCE(SUM(bal.balance), 0) FROM saving_accounts sac 
     INNER JOIN sub_accounts sa ON sac.sub_accounts_id = sa.sub_accounts_id
     LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id
     WHERE sac.status = '1') AS total_savings_balance,
     
    (SELECT COALESCE(SUM(bal.balance), 0) FROM fd_accounts fa 
     INNER JOIN sub_accounts sa ON fa.sub_accounts_id = sa.sub_accounts_id
     LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id
     WHERE fa.status = '1') AS total_fd_balance,
    
    -- Transaction activity
    (SELECT COUNT(*) FROM transaction_head 
     WHERE trans_date::DATE >= DATE_TRUNC('month', CURRENT_DATE)) AS transactions_this_month,
     
    (SELECT COALESCE(SUM(ABS(trans_amount::DECIMAL)), 0) FROM transaction_head 
     WHERE trans_date::DATE >= DATE_TRUNC('month', CURRENT_DATE)) AS transaction_volume_this_month,
    
    -- Asset quality
    (SELECT recovery_percentage FROM view_recovery_performance_analysis 
     WHERE recovery_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' 
     ORDER BY recovery_date DESC LIMIT 1) AS last_month_recovery_rate,
     
    (SELECT npa_amount_ratio_pct FROM view_financial_health_indicators) AS current_npa_ratio;

-- Comment on view
COMMENT ON VIEW view_monthly_business_dashboard IS 'Monthly business dashboard with key performance indicators';

-- Performance indexes for additional views
CREATE INDEX IF NOT EXISTS idx_loan_accounts_end_date_status ON loan_accounts(end_date, status);
CREATE INDEX IF NOT EXISTS idx_saving_interest_post_date ON saving_interest_post(interest_date);
CREATE INDEX IF NOT EXISTS idx_loan_interest_post_date ON loan_interest_post(interest_date);
CREATE INDEX IF NOT EXISTS idx_fd_interest_post_date ON fd_interest_post(interest_date);
CREATE INDEX IF NOT EXISTS idx_members_appli_date_status ON members(appli_date, status);
CREATE INDEX IF NOT EXISTS idx_loan_repayment_loan_date ON loan_repayment(loan_accounts_id, repayment_date);
