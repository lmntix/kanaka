-- ===================================================================
-- MULTI-ORGANIZATION MIGRATION SCRIPT
-- Cooperative Banking System - SaaS Transformation
-- ===================================================================
-- This script transforms a single-org system to multi-org SaaS platform
-- Execute in order and test thoroughly before production deployment
-- ===================================================================

BEGIN;

-- ===================================================================
-- STEP 1: CREATE ORGANIZATION MANAGEMENT TABLES
-- ===================================================================

-- Create organizations master table
CREATE TABLE IF NOT EXISTS organizations (
    organization_id SERIAL PRIMARY KEY,
    organization_name VARCHAR(200) NOT NULL,
    organization_code VARCHAR(50) UNIQUE NOT NULL,
    registration_number VARCHAR(100),
    address TEXT,
    contact_info JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subscription_plan VARCHAR(50) DEFAULT 'BASIC',
    license_valid_until DATE,
    settings JSONB DEFAULT '{}',
    CONSTRAINT chk_org_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'INACTIVE'))
);

-- Add indexes for organizations
CREATE INDEX idx_organizations_code ON organizations(organization_code);
CREATE INDEX idx_organizations_status ON organizations(status);

-- Create user-organization access table
CREATE TABLE IF NOT EXISTS user_organization_access (
    user_org_access_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    organization_id INTEGER NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'USER',
    access_level VARCHAR(20) DEFAULT 'USER',
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_access_date TIMESTAMP,
    UNIQUE(user_id, organization_id),
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id),
    CONSTRAINT chk_access_level CHECK (access_level IN ('SUPER_ADMIN', 'ADMIN', 'USER', 'READ_ONLY'))
);

-- Create organization-specific settings table
CREATE TABLE IF NOT EXISTS organization_settings (
    setting_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'STRING',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, setting_key),
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id),
    CONSTRAINT chk_setting_type CHECK (setting_type IN ('STRING', 'NUMBER', 'BOOLEAN', 'JSON', 'DATE'))
);

-- ===================================================================
-- STEP 2: VOUCHER AND ACCOUNT NUMBER MANAGEMENT
-- ===================================================================

-- Create voucher sequences per organization
CREATE TABLE IF NOT EXISTS voucher_sequences (
    sequence_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    voucher_type VARCHAR(50) NOT NULL,
    financial_year INTEGER NOT NULL,
    current_number INTEGER DEFAULT 0,
    prefix VARCHAR(10) DEFAULT '',
    suffix VARCHAR(10) DEFAULT '',
    number_length INTEGER DEFAULT 6,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, voucher_type, financial_year),
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id)
);

-- Create account number sequences per organization
CREATE TABLE IF NOT EXISTS account_number_sequences (
    sequence_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    current_number INTEGER DEFAULT 0,
    prefix VARCHAR(10) DEFAULT '',
    format_pattern VARCHAR(50) DEFAULT 'PREFIX000000',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, account_type),
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id)
);

-- ===================================================================
-- STEP 3: ADD ORGANIZATION_ID TO EXISTING TABLES
-- ===================================================================

-- Core Transaction Tables
ALTER TABLE transaction_head ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE transaction_details ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Member and Account Tables
ALTER TABLE members ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE sub_accounts ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE sub_accounts_balance ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Product-Specific Tables
ALTER TABLE fd_accounts ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_accounts ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE recurring_accounts ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE saving_accounts ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Financial and Configuration Tables
ALTER TABLE financial_years ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE calender ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Scheme Tables
ALTER TABLE fd_schemes ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_schemes ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE fd_interest_rate ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_interest_rate ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE recurring_interest_rate ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Interest and Charges Tables
ALTER TABLE fd_interest_post ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_interest_post ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE recurring_interest_post ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE fd_charges ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_charges ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE recurring_charges ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Member-related Tables
ALTER TABLE member_address_contact ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE member_address_permanent ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE member_approval ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE member_job_info ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE member_kyc_document ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE nominee ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Loan-related Tables
ALTER TABLE loan_disbursement ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_repayment ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_schedule ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE loan_guarantor ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Cheque-related Tables
ALTER TABLE cheque_register ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE cheque_transactions ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE cheque_in ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE cheque_return ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- Dividend Tables
ALTER TABLE dividend_paid ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE dividend_register ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE dividend_setting ADD COLUMN IF NOT EXISTS organization_id INTEGER;

-- ===================================================================
-- STEP 4: CREATE DEFAULT ORGANIZATION AND UPDATE EXISTING DATA
-- ===================================================================

-- Insert default organization for existing data
INSERT INTO organizations (
    organization_name, 
    organization_code, 
    registration_number,
    status,
    subscription_plan,
    license_valid_until
) VALUES (
    'Default Organization', 
    'DEFAULT001', 
    'DEFAULT-REG-001',
    'ACTIVE',
    'ENTERPRISE',
    '2099-12-31'
) ON CONFLICT (organization_code) DO NOTHING;

-- Get the default organization ID
DO $$
DECLARE
    default_org_id INTEGER;
BEGIN
    SELECT organization_id INTO default_org_id 
    FROM organizations 
    WHERE organization_code = 'DEFAULT001';
    
    -- Update all existing data with default organization ID
    -- Core Transaction Tables
    UPDATE transaction_head SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE transaction_details SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Member and Account Tables
    UPDATE members SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE accounts SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE sub_accounts SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE sub_accounts_balance SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Product-Specific Tables
    UPDATE fd_accounts SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_accounts SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE recurring_accounts SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE saving_accounts SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Financial and Configuration Tables
    UPDATE financial_years SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE calender SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Scheme Tables
    UPDATE fd_schemes SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_schemes SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE fd_interest_rate SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_interest_rate SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE recurring_interest_rate SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Interest and Charges Tables  
    UPDATE fd_interest_post SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_interest_post SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE recurring_interest_post SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE fd_charges SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_charges SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE recurring_charges SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Member-related Tables
    UPDATE member_address_contact SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE member_address_permanent SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE member_approval SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE member_job_info SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE member_kyc_document SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE nominee SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Loan-related Tables
    UPDATE loan_disbursement SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_repayment SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_schedule SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE loan_guarantor SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Cheque-related Tables
    UPDATE cheque_register SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE cheque_transactions SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE cheque_in SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE cheque_return SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    -- Dividend Tables
    UPDATE dividend_paid SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE dividend_register SET organization_id = default_org_id WHERE organization_id IS NULL;
    UPDATE dividend_setting SET organization_id = default_org_id WHERE organization_id IS NULL;
    
    RAISE NOTICE 'Updated all existing data with default organization ID: %', default_org_id;
END $$;

-- ===================================================================
-- STEP 5: MAKE ORGANIZATION_ID NOT NULL AND ADD CONSTRAINTS
-- ===================================================================

-- Make organization_id NOT NULL for core tables
-- Core Transaction Tables
ALTER TABLE transaction_head ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE transaction_details ALTER COLUMN organization_id SET NOT NULL;

-- Member and Account Tables
ALTER TABLE members ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE accounts ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE sub_accounts ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE sub_accounts_balance ALTER COLUMN organization_id SET NOT NULL;

-- Product-Specific Tables
ALTER TABLE fd_accounts ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE loan_accounts ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE recurring_accounts ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE saving_accounts ALTER COLUMN organization_id SET NOT NULL;

-- Financial and Configuration Tables
ALTER TABLE financial_years ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE calender ALTER COLUMN organization_id SET NOT NULL;

-- ===================================================================
-- STEP 6: ADD FOREIGN KEY CONSTRAINTS
-- ===================================================================

-- Core Transaction Tables
ALTER TABLE transaction_head 
ADD CONSTRAINT fk_transaction_head_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE transaction_details 
ADD CONSTRAINT fk_transaction_details_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

-- Member and Account Tables
ALTER TABLE members 
ADD CONSTRAINT fk_members_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE accounts 
ADD CONSTRAINT fk_accounts_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE sub_accounts 
ADD CONSTRAINT fk_sub_accounts_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE sub_accounts_balance 
ADD CONSTRAINT fk_sub_accounts_balance_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

-- Product-Specific Tables
ALTER TABLE fd_accounts 
ADD CONSTRAINT fk_fd_accounts_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE loan_accounts 
ADD CONSTRAINT fk_loan_accounts_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE recurring_accounts 
ADD CONSTRAINT fk_recurring_accounts_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE saving_accounts 
ADD CONSTRAINT fk_saving_accounts_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

-- Financial and Configuration Tables
ALTER TABLE financial_years 
ADD CONSTRAINT fk_financial_years_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

ALTER TABLE calender 
ADD CONSTRAINT fk_calender_org 
FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

-- ===================================================================
-- STEP 7: CREATE ORGANIZATION-SCOPED INDEXES
-- ===================================================================

-- Transaction tables indexes
CREATE INDEX idx_transaction_head_org_date ON transaction_head(organization_id, trans_date);
CREATE INDEX idx_transaction_head_org_voucher ON transaction_head(organization_id, voucher_no);
CREATE INDEX idx_transaction_details_org_sub_acc ON transaction_details(organization_id, sub_accounts_id);
CREATE INDEX idx_transaction_details_org_head ON transaction_details(organization_id, transaction_head_id);

-- Member and account indexes
CREATE INDEX idx_members_org_status ON members(organization_id, status);
CREATE INDEX idx_members_org_name ON members(organization_id, full_name);
CREATE INDEX idx_sub_accounts_org_member ON sub_accounts(organization_id, members_id);
CREATE INDEX idx_sub_accounts_org_account ON sub_accounts(organization_id, accounts_id);
CREATE INDEX idx_accounts_org_type ON accounts(organization_id, account_type);

-- Product-specific indexes
CREATE INDEX idx_fd_accounts_org ON fd_accounts(organization_id);
CREATE INDEX idx_loan_accounts_org ON loan_accounts(organization_id);
CREATE INDEX idx_recurring_accounts_org ON recurring_accounts(organization_id);
CREATE INDEX idx_saving_accounts_org ON saving_accounts(organization_id);

-- Financial and configuration indexes
CREATE INDEX idx_financial_years_org ON financial_years(organization_id);
CREATE INDEX idx_calender_org_date ON calender(organization_id, yearly_trans_dates);
CREATE INDEX idx_calender_org_current ON calender(organization_id, current_day);

-- ===================================================================
-- STEP 8: CREATE UTILITY FUNCTIONS
-- ===================================================================

-- Function to get next voucher number
CREATE OR REPLACE FUNCTION get_next_voucher_number(
    p_org_id INTEGER,
    p_voucher_type VARCHAR,
    p_financial_year INTEGER
) RETURNS VARCHAR AS $$
DECLARE
    next_num INTEGER;
    voucher_no VARCHAR;
    prefix_val VARCHAR;
    suffix_val VARCHAR;
    num_length INTEGER;
BEGIN
    -- Get and increment the sequence
    UPDATE voucher_sequences 
    SET current_number = current_number + 1,
        updated_date = CURRENT_TIMESTAMP
    WHERE organization_id = p_org_id 
    AND voucher_type = p_voucher_type 
    AND financial_year = p_financial_year
    RETURNING current_number, prefix, suffix, number_length
    INTO next_num, prefix_val, suffix_val, num_length;
    
    -- If no sequence exists, create it
    IF NOT FOUND THEN
        INSERT INTO voucher_sequences (organization_id, voucher_type, financial_year, current_number, prefix, number_length)
        VALUES (p_org_id, p_voucher_type, p_financial_year, 1, 'VCH', 6);
        next_num := 1;
        prefix_val := 'VCH';
        num_length := 6;
    END IF;
    
    -- Format voucher number
    voucher_no := COALESCE(prefix_val, '') || LPAD(next_num::TEXT, num_length, '0') || COALESCE(suffix_val, '');
    
    RETURN voucher_no;
END;
$$ LANGUAGE plpgsql;

-- Function to get current business date for organization
CREATE OR REPLACE FUNCTION get_current_business_date(p_org_id INTEGER) 
RETURNS DATE AS $$
DECLARE
    current_date DATE;
BEGIN
    SELECT yearly_trans_dates::DATE 
    INTO current_date
    FROM calender 
    WHERE organization_id = p_org_id 
    AND current_day = 'Y'
    LIMIT 1;
    
    RETURN current_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get next account number
CREATE OR REPLACE FUNCTION get_next_account_number(
    p_org_id INTEGER,
    p_account_type VARCHAR
) RETURNS VARCHAR AS $$
DECLARE
    next_num INTEGER;
    account_no VARCHAR;
    prefix_val VARCHAR;
    format_pattern VARCHAR;
BEGIN
    -- Get and increment the sequence
    UPDATE account_number_sequences 
    SET current_number = current_number + 1,
        updated_date = CURRENT_TIMESTAMP
    WHERE organization_id = p_org_id 
    AND account_type = p_account_type
    RETURNING current_number, prefix, format_pattern
    INTO next_num, prefix_val, format_pattern;
    
    -- If no sequence exists, create it
    IF NOT FOUND THEN
        INSERT INTO account_number_sequences (organization_id, account_type, current_number, prefix, format_pattern)
        VALUES (p_org_id, p_account_type, 1, p_account_type, 'PREFIX000000');
        next_num := 1;
        prefix_val := p_account_type;
        format_pattern := 'PREFIX000000';
    END IF;
    
    -- Format account number based on pattern
    account_no := COALESCE(prefix_val, '') || LPAD(next_num::TEXT, 6, '0');
    
    RETURN account_no;
END;
$$ LANGUAGE plpgsql;

-- ===================================================================
-- STEP 9: CREATE UNIQUE CONSTRAINTS FOR ORGANIZATION SCOPING
-- ===================================================================

-- Calendar unique constraint for org-specific dates
ALTER TABLE calender 
DROP CONSTRAINT IF EXISTS uk_calender_org_date;
ALTER TABLE calender 
ADD CONSTRAINT uk_calender_org_date 
UNIQUE(organization_id, yearly_trans_dates);

-- Financial year unique constraint
ALTER TABLE financial_years
DROP CONSTRAINT IF EXISTS uk_financial_years_org;
ALTER TABLE financial_years
ADD CONSTRAINT uk_financial_years_org
UNIQUE(organization_id, financial_years_id);

-- Voucher number unique constraint within organization
ALTER TABLE transaction_head
DROP CONSTRAINT IF EXISTS uk_transaction_head_voucher_org;
ALTER TABLE transaction_head
ADD CONSTRAINT uk_transaction_head_voucher_org
UNIQUE(organization_id, voucher_no);

-- ===================================================================
-- STEP 10: INSERT DEFAULT ORGANIZATION SETTINGS
-- ===================================================================

-- Insert default settings for the default organization
DO $$
DECLARE
    default_org_id INTEGER;
BEGIN
    SELECT organization_id INTO default_org_id 
    FROM organizations 
    WHERE organization_code = 'DEFAULT001';
    
    -- Insert default organization settings
    INSERT INTO organization_settings (organization_id, setting_key, setting_value, setting_type, description)
    VALUES 
    (default_org_id, 'VOUCHER_PREFIX', 'VCH', 'STRING', 'Default voucher number prefix'),
    (default_org_id, 'ACCOUNT_NUMBER_LENGTH', '6', 'NUMBER', 'Default account number length'),
    (default_org_id, 'FINANCIAL_YEAR_START_MONTH', '4', 'NUMBER', 'Financial year starts from month (1-12)'),
    (default_org_id, 'INTEREST_CALCULATION_METHOD', 'DAILY', 'STRING', 'Interest calculation method'),
    (default_org_id, 'ALLOW_BACK_DATED_ENTRY', 'true', 'BOOLEAN', 'Allow back-dated transaction entry'),
    (default_org_id, 'CURRENCY_SYMBOL', '₹', 'STRING', 'Currency symbol for display')
    ON CONFLICT (organization_id, setting_key) DO NOTHING;
    
    RAISE NOTICE 'Inserted default settings for organization ID: %', default_org_id;
END $$;

-- ===================================================================
-- STEP 11: CREATE VIEW FOR ORGANIZATION SUMMARY
-- ===================================================================

CREATE OR REPLACE VIEW organization_summary AS
SELECT 
    o.organization_id,
    o.organization_name,
    o.organization_code,
    o.status,
    o.created_date,
    COUNT(DISTINCT m.members_id) as total_members,
    COUNT(DISTINCT sa.sub_accounts_id) as total_accounts,
    COUNT(DISTINCT th.transaction_head_id) as total_transactions,
    COALESCE(SUM(CASE WHEN td.trans_amount::numeric > 0 THEN td.trans_amount::numeric ELSE 0 END), 0) as total_debits,
    COALESCE(SUM(CASE WHEN td.trans_amount::numeric < 0 THEN ABS(td.trans_amount::numeric) ELSE 0 END), 0) as total_credits
FROM organizations o
LEFT JOIN members m ON o.organization_id = m.organization_id AND m.status = 'ACTIVE'
LEFT JOIN sub_accounts sa ON o.organization_id = sa.organization_id AND sa.status = 'ACTIVE'
LEFT JOIN transaction_head th ON o.organization_id = th.organization_id
LEFT JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
GROUP BY o.organization_id, o.organization_name, o.organization_code, o.status, o.created_date
ORDER BY o.organization_name;

-- ===================================================================
-- VALIDATION QUERIES
-- ===================================================================

-- Check data distribution across organizations
SELECT 
    'Organizations' as table_name,
    COUNT(*) as total_records
FROM organizations
UNION ALL
SELECT 
    'Members with org_id',
    COUNT(*) 
FROM members 
WHERE organization_id IS NOT NULL
UNION ALL
SELECT 
    'Transactions with org_id',
    COUNT(*) 
FROM transaction_head 
WHERE organization_id IS NOT NULL
UNION ALL
SELECT 
    'Sub Accounts with org_id',
    COUNT(*) 
FROM sub_accounts 
WHERE organization_id IS NOT NULL;

-- Verify no orphaned records
SELECT 
    'Members without org' as check_type,
    COUNT(*) as count
FROM members 
WHERE organization_id IS NULL
UNION ALL
SELECT 
    'Transactions without org',
    COUNT(*) 
FROM transaction_head 
WHERE organization_id IS NULL
UNION ALL
SELECT 
    'Sub Accounts without org',
    COUNT(*) 
FROM sub_accounts 
WHERE organization_id IS NULL;

COMMIT;

-- ===================================================================
-- POST-MIGRATION NOTES
-- ===================================================================
/*
1. Test the migration thoroughly in a staging environment first
2. Update application code to include organization_id in all queries
3. Implement user-organization access controls in the application
4. Update reporting queries to be organization-scoped
5. Test voucher number generation functions
6. Verify data isolation between organizations
7. Update backup and recovery procedures for multi-org setup
8. Consider implementing Row Level Security (RLS) for additional protection
9. Monitor query performance with new indexes
10. Plan for organization-specific customizations

IMPORTANT: After running this migration:
- All existing data will be assigned to the "DEFAULT001" organization
- New organizations can be created through the application interface
- Voucher sequences will be automatically created for new organizations
- Account number sequences will be automatically managed per organization
- Calendar management becomes organization-specific
- All transaction processing maintains double-entry integrity within each organization
*/
