-- =============================================
-- Member Management Views for PostgreSQL
-- Author: Converted from SQL Server views
-- Create date: 2024
-- Description: Member management and analysis views for microfinance operations
-- =============================================

-- View: Members without loans
CREATE OR REPLACE VIEW view_member_without_loan AS
SELECT DISTINCT
    m.members_id,
    m.full_name,
    m.gender,
    m.age,
    m.status AS member_status,
    m.appli_date,
    m.ledger_folio_no
FROM members m
LEFT OUTER JOIN loan_accounts la ON m.members_id = la.members_id
WHERE m.members_id NOT IN (
    SELECT members_id 
    FROM loan_accounts 
    WHERE status IN ('1', '2', '3') -- Active, Disbursed, or Pending
    AND members_id IS NOT NULL
)
OR la.members_id IS NULL;

-- Comment on view
COMMENT ON VIEW view_member_without_loan IS 'Members who do not have any active, disbursed, or pending loans';

-- View: Members not received (for recovery/collection purposes)
CREATE OR REPLACE VIEW view_not_received_member_list AS
SELECT 
    dh.members_id,
    dh.demand_list_id,
    rl.recovery_list_id
FROM recovery_list rl
INNER JOIN recovery_head rh ON rl.recovery_list_id = rh.recovery_list_id
RIGHT OUTER JOIN demand_head dh ON rl.demand_list_id = dh.demand_list_id 
    AND rh.members_id = dh.members_id;

-- Comment on view
COMMENT ON VIEW view_not_received_member_list IS 'Members with outstanding demands but no recovery records';

-- Enhanced View: Member profile with contact details
CREATE OR REPLACE VIEW view_member_profile AS
SELECT 
    m.members_id,
    m.full_name,
    m.gender,
    m.age,
    m.birth_date,
    m.pan_no,
    m.adhar_id,
    m.status AS member_status,
    m.appli_date,
    m.ledger_folio_no,
    
    -- Contact address
    mac.address AS contact_address,
    mac.pin AS contact_pin,
    mac.telephone,
    c_contact.name AS contact_city,
    
    -- Permanent address  
    map.address AS permanent_address,
    map.pin AS permanent_pin,
    c_perm.name AS permanent_city,
    
    -- Occupation
    o.name AS occupation,
    
    -- Office
    off.name AS office_name
    
FROM members m
LEFT JOIN member_address_contact mac ON m.members_id = mac.members_id
LEFT JOIN city c_contact ON mac.city_id = c_contact.city_id
LEFT JOIN member_address_permanent map ON m.members_id = map.members_id
LEFT JOIN city c_perm ON map.city_id = c_perm.city_id
LEFT JOIN occupation o ON m.occupation_id = o.occupation_id
LEFT JOIN offices off ON m.offices_id = off.offices_id
WHERE m.status = '1'; -- Active members

-- Comment on view
COMMENT ON VIEW view_member_profile IS 'Complete member profile with contact, permanent address, occupation and office details';

-- View: Members eligible for loans (business rules)
CREATE OR REPLACE VIEW view_loan_eligible_members AS
SELECT 
    m.members_id,
    m.full_name,
    m.age,
    m.status,
    m.appli_date,
    
    -- Savings balance
    COALESCE(savings.total_balance, 0) AS savings_balance,
    
    -- Share balance
    COALESCE(shares.total_balance, 0) AS share_balance,
    
    -- Existing loans
    COALESCE(loans.active_loans, 0) AS active_loan_count,
    COALESCE(ABS(loans.total_outstanding), 0) AS total_loan_outstanding,
    
    -- Eligibility criteria
    CASE 
        WHEN m.age::INTEGER >= 18 AND m.age::INTEGER <= 70 THEN 'Y'
        ELSE 'N'
    END AS age_eligible,
    
    CASE 
        WHEN COALESCE(savings.total_balance, 0) >= 500 THEN 'Y'  -- Minimum savings required
        ELSE 'N'
    END AS savings_eligible,
    
    CASE 
        WHEN COALESCE(loans.active_loans, 0) < 3 THEN 'Y'  -- Max 3 active loans
        ELSE 'N'
    END AS loan_count_eligible,
    
    -- Overall eligibility
    CASE 
        WHEN m.age::INTEGER >= 18 AND m.age::INTEGER <= 70
             AND COALESCE(savings.total_balance, 0) >= 500
             AND COALESCE(loans.active_loans, 0) < 3
             AND m.status = '1'
        THEN 'ELIGIBLE'
        ELSE 'NOT_ELIGIBLE'
    END AS overall_eligibility

FROM members m

-- Savings summary
LEFT JOIN (
    SELECT 
        sa.members_id,
        SUM(COALESCE(bal.balance, 0)) AS total_balance
    FROM sub_accounts sa
    INNER JOIN saving_accounts sac ON sa.sub_accounts_id = sac.sub_accounts_id
    LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
        AND sa.accounts_id = bal.accounts_id
    WHERE sac.status = '1' -- Active
    GROUP BY sa.members_id
) savings ON m.members_id = savings.members_id

-- Shares summary
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

-- Loan summary
LEFT JOIN (
    SELECT 
        la.members_id,
        COUNT(DISTINCT la.loan_accounts_id) AS active_loans,
        SUM(COALESCE(bal.balance, 0)) AS total_outstanding
    FROM loan_accounts la
    INNER JOIN sub_accounts sa ON la.sub_accounts_id = sa.sub_accounts_id
    LEFT JOIN view_sub_account_balance bal ON sa.sub_accounts_id = bal.sub_accounts_id 
        AND sa.accounts_id = bal.accounts_id
    WHERE la.status IN ('1', '2') -- Active/Disbursed
    GROUP BY la.members_id
) loans ON m.members_id = loans.members_id

ORDER BY m.members_id;

-- Comment on view
COMMENT ON VIEW view_loan_eligible_members IS 'Members with loan eligibility assessment based on business rules';

-- View: Member transaction summary
CREATE OR REPLACE VIEW view_member_transaction_summary AS
SELECT 
    m.members_id,
    m.full_name,
    
    -- Transaction counts by type
    COUNT(CASE WHEN a.account_name LIKE '%Saving%' THEN 1 END) AS savings_transactions,
    COUNT(CASE WHEN a.account_name LIKE '%Loan%' OR a.account_name LIKE '%Lone%' THEN 1 END) AS loan_transactions,
    COUNT(CASE WHEN a.account_name LIKE '%Fixed%' OR a.account_name LIKE '%FD%' THEN 1 END) AS fd_transactions,
    COUNT(CASE WHEN a.account_name LIKE '%Share%' THEN 1 END) AS share_transactions,
    
    -- Transaction amounts by type
    SUM(CASE 
        WHEN a.account_name LIKE '%Saving%' AND td.trans_amount > 0 
        THEN td.trans_amount ELSE 0 
    END) AS savings_deposits,
    
    SUM(CASE 
        WHEN a.account_name LIKE '%Saving%' AND td.trans_amount < 0 
        THEN ABS(td.trans_amount) ELSE 0 
    END) AS savings_withdrawals,
    
    SUM(CASE 
        WHEN (a.account_name LIKE '%Loan%' OR a.account_name LIKE '%Lone%') AND td.trans_amount > 0 
        THEN td.trans_amount ELSE 0 
    END) AS loan_repayments,
    
    -- Overall transaction summary
    COUNT(td.transaction_details_id) AS total_transactions,
    MAX(th.trans_date) AS last_transaction_date,
    MIN(th.trans_date) AS first_transaction_date

FROM members m
INNER JOIN sub_accounts sa ON m.members_id = sa.members_id
INNER JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
    AND sa.accounts_id = td.accounts_id
INNER JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
INNER JOIN accounts a ON td.accounts_id = a.accounts_id

WHERE m.status = '1' -- Active members
    AND th.trans_date >= CURRENT_DATE - INTERVAL '1 year' -- Last 1 year

GROUP BY m.members_id, m.full_name
ORDER BY total_transactions DESC;

-- Comment on view
COMMENT ON VIEW view_member_transaction_summary IS 'Member transaction activity summary for the last year';

-- View: Inactive members (no transactions in last 6 months)
CREATE OR REPLACE VIEW view_inactive_members AS
SELECT 
    m.members_id,
    m.full_name,
    m.status,
    m.appli_date,
    MAX(th.trans_date) AS last_transaction_date,
    CURRENT_DATE - MAX(th.trans_date) AS days_since_last_transaction,
    
    -- Current balances
    COALESCE(portfolio.total_savings_balance, 0) AS savings_balance,
    COALESCE(portfolio.total_loan_balance, 0) AS loan_balance,
    COALESCE(portfolio.total_fd_balance, 0) AS fd_balance,
    COALESCE(portfolio.total_share_balance, 0) AS share_balance

FROM members m
LEFT JOIN sub_accounts sa ON m.members_id = sa.members_id
LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
    AND sa.accounts_id = td.accounts_id
LEFT JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
LEFT JOIN view_member_portfolio_summary portfolio ON m.members_id = portfolio.members_id

WHERE m.status = '1' -- Active members

GROUP BY 
    m.members_id, m.full_name, m.status, m.appli_date,
    portfolio.total_savings_balance, portfolio.total_loan_balance,
    portfolio.total_fd_balance, portfolio.total_share_balance

HAVING 
    MAX(th.trans_date) < CURRENT_DATE - INTERVAL '6 months'
    OR MAX(th.trans_date) IS NULL

ORDER BY last_transaction_date DESC NULLS LAST;

-- Comment on view
COMMENT ON VIEW view_inactive_members IS 'Members with no transactions in the last 6 months';

-- View: Member KYC compliance status
CREATE OR REPLACE VIEW view_member_kyc_status AS
SELECT 
    m.members_id,
    m.full_name,
    m.pan_no,
    m.adhar_id,
    
    -- KYC document checks
    COUNT(mkd.member_kyc_document_id) AS total_documents,
    COUNT(CASE WHEN mkd.document_type = 'PAN' THEN 1 END) AS pan_documents,
    COUNT(CASE WHEN mkd.document_type = 'AADHAR' THEN 1 END) AS aadhar_documents,
    COUNT(CASE WHEN mkd.document_type = 'ADDRESS_PROOF' THEN 1 END) AS address_proof_documents,
    COUNT(CASE WHEN mkd.document_type = 'INCOME_PROOF' THEN 1 END) AS income_proof_documents,
    
    -- Address information
    CASE 
        WHEN mac.address IS NOT NULL AND mac.pin IS NOT NULL THEN 'Y' 
        ELSE 'N' 
    END AS contact_address_complete,
    
    CASE 
        WHEN map.address IS NOT NULL AND map.pin IS NOT NULL THEN 'Y' 
        ELSE 'N' 
    END AS permanent_address_complete,
    
    -- Overall KYC status
    CASE 
        WHEN m.pan_no IS NOT NULL 
             AND m.adhar_id IS NOT NULL
             AND mac.address IS NOT NULL 
             AND mac.pin IS NOT NULL
             AND COUNT(mkd.member_kyc_document_id) >= 2
        THEN 'COMPLETE'
        WHEN m.adhar_id IS NOT NULL OR m.pan_no IS NOT NULL
        THEN 'PARTIAL'
        ELSE 'INCOMPLETE'
    END AS kyc_status

FROM members m
LEFT JOIN member_kyc_document mkd ON m.members_id = mkd.members_id
LEFT JOIN member_address_contact mac ON m.members_id = mac.members_id
LEFT JOIN member_address_permanent map ON m.members_id = map.members_id

WHERE m.status = '1' -- Active members

GROUP BY 
    m.members_id, m.full_name, m.pan_no, m.adhar_id,
    mac.address, mac.pin, map.address, map.pin

ORDER BY m.members_id;

-- Comment on view
COMMENT ON VIEW view_member_kyc_status IS 'Member KYC compliance and document verification status';

-- Performance indexes for member views
CREATE INDEX IF NOT EXISTS idx_members_status ON members(status);
CREATE INDEX IF NOT EXISTS idx_loan_accounts_members_status ON loan_accounts(members_id, status);
CREATE INDEX IF NOT EXISTS idx_saving_accounts_members_status ON saving_accounts(members_id, status);
CREATE INDEX IF NOT EXISTS idx_member_address_contact_members ON member_address_contact(members_id);
CREATE INDEX IF NOT EXISTS idx_transaction_head_date ON transaction_head(trans_date);
