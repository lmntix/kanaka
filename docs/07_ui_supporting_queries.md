# Supporting SQL Queries for Multi-Organization UI
## Essential Database Queries for Business Workflows

## 1. Organization Selection Queries

### Get User's Organizations
```sql
-- Show organizations a user has access to
SELECT 
    o.organization_id,
    o.organization_name,
    o.organization_code,
    uoa.role,
    uoa.access_level,
    uoa.last_access_date
FROM organizations o
JOIN user_organization_access uoa ON o.organization_id = uoa.organization_id
WHERE uoa.user_id = ? 
AND uoa.is_active = TRUE
AND o.status = 'ACTIVE'
ORDER BY uoa.last_access_date DESC;
```

### Set Current Organization
```sql
-- Update user's last access for the selected organization
UPDATE user_organization_access 
SET last_access_date = CURRENT_TIMESTAMP
WHERE user_id = ? AND organization_id = ?;
```

## 2. Member Search & Selection

### Search Members in Organization
```sql
-- Search members by name or ID within organization
SELECT 
    m.members_id,
    m.full_name,
    COUNT(sa.sub_accounts_id) as total_accounts,
    COALESCE(SUM(CASE WHEN atm.account_type_code = 'SAVINGS' THEN sab.balance ELSE 0 END), 0) as savings_balance
FROM members m
LEFT JOIN sub_accounts sa ON m.members_id = sa.members_id
LEFT JOIN accounts a ON sa.accounts_id = a.accounts_id
LEFT JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
LEFT JOIN sub_accounts_balance sab ON sa.sub_accounts_id = sab.sub_accounts_id
WHERE m.organization_id = ?
AND m.status = 'ACTIVE'
AND (m.full_name ILIKE '%' || ? || '%' OR m.members_id::text = ?)
GROUP BY m.members_id, m.full_name
ORDER BY m.full_name
LIMIT 10;
```

### Get Member's Accounts
```sql
-- Get all accounts for a specific member
SELECT 
    sa.sub_accounts_id,
    sa.sub_accounts_no,
    sa.name as account_name,
    atm.account_type_code,
    atm.account_type_name,
    a.gl_code,
    COALESCE(sab.balance, 0) as current_balance,
    sa.status
FROM sub_accounts sa
JOIN accounts a ON sa.accounts_id = a.accounts_id
JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
LEFT JOIN sub_accounts_balance sab ON sa.sub_accounts_id = sab.sub_accounts_id
WHERE sa.organization_id = ?
AND sa.members_id = ?
AND sa.status = 'ACTIVE'
ORDER BY atm.account_type_code;
```

## 3. Transaction Processing

### Generate Transaction Preview
```sql
-- Get account details for transaction preview
SELECT 
    a.accounts_id,
    a.account_name,
    a.gl_code,
    atm.balance_type,
    atm.category
FROM accounts a
JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
WHERE a.organization_id = ?
AND atm.account_type_code = ?
AND a.status = 'ACTIVE';
```

### Get Next Voucher Number
```sql
-- Get next voucher number for organization
SELECT get_next_voucher_number(?, ?, ?);
-- Parameters: organization_id, voucher_type, financial_year
```

### Create Transaction Head
```sql
-- Insert transaction head
INSERT INTO transaction_head (
    organization_id, voucher_no, trans_date, trans_time, 
    trans_amount, trans_narration, voucher_master_id,
    users_id, session_id, branch_id, mode_of_operation
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
RETURNING transaction_head_id;
```

### Create Transaction Details
```sql
-- Insert transaction details
INSERT INTO transaction_details (
    organization_id, transaction_head_id, 
    accounts_id, sub_accounts_id, trans_amount
) VALUES (?, ?, ?, ?, ?);
```

## 4. Account Creation

### Create Member Sub-Account
```sql
-- Create new sub-account for member
INSERT INTO sub_accounts (
    organization_id, accounts_id, members_id,
    sub_accounts_no, name, status, account_type_id
) VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?)
RETURNING sub_accounts_id;
```

### Get Next Account Number
```sql
-- Generate next account number
SELECT get_next_account_number(?, ?);
-- Parameters: organization_id, account_type_code
```

### Create Product-Specific Account Record
```sql
-- For savings account
INSERT INTO saving_accounts (
    organization_id, sub_accounts_id, members_id,
    opening_date, account_status
) VALUES (?, ?, ?, ?, 'ACTIVE');
```

## 5. Organization Setup

### Create New Organization
```sql
-- Insert new organization
INSERT INTO organizations (
    organization_name, organization_code, registration_number,
    address, contact_info, status, subscription_plan, license_valid_until
) VALUES (?, ?, ?, ?, ?::jsonb, 'ACTIVE', ?, ?)
RETURNING organization_id;
```

### Setup Organization Account Types
```sql
-- Configure account types for organization
INSERT INTO org_account_types (
    organization_id, account_type_id, org_gl_code, 
    org_account_name, is_enabled
) VALUES (?, ?, ?, ?, TRUE);
```

### Create Organization Accounts
```sql
-- Create account instances for organization
INSERT INTO accounts (
    organization_id, account_type_id, account_name,
    account_type, balance_type, gl_code, status
) VALUES (?, ?, ?, ?, ?, ?, 'ACTIVE');
```

## 6. Dashboard Queries

### Organization Summary
```sql
-- Get organization dashboard data
SELECT 
    o.organization_name,
    COUNT(DISTINCT m.members_id) as total_members,
    COUNT(DISTINCT sa.sub_accounts_id) as total_accounts,
    COUNT(DISTINCT th.transaction_head_id) as total_transactions,
    COALESCE(SUM(CASE WHEN atm.balance_type = 'DEBIT' THEN sab.balance ELSE 0 END), 0) as total_assets,
    COALESCE(SUM(CASE WHEN atm.balance_type = 'CREDIT' THEN sab.balance ELSE 0 END), 0) as total_liabilities
FROM organizations o
LEFT JOIN members m ON o.organization_id = m.organization_id AND m.status = 'ACTIVE'
LEFT JOIN sub_accounts sa ON m.members_id = sa.members_id
LEFT JOIN accounts a ON sa.accounts_id = a.accounts_id
LEFT JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
LEFT JOIN sub_accounts_balance sab ON sa.sub_accounts_id = sab.sub_accounts_id
LEFT JOIN transaction_head th ON o.organization_id = th.organization_id
WHERE o.organization_id = ?
GROUP BY o.organization_id, o.organization_name;
```

### Recent Transactions
```sql
-- Get recent transactions for dashboard
SELECT 
    th.voucher_no,
    th.trans_date,
    th.trans_amount,
    th.trans_narration,
    m.full_name as member_name,
    atm.account_type_name
FROM transaction_head th
JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
LEFT JOIN members m ON sa.members_id = m.members_id
JOIN accounts a ON sa.accounts_id = a.accounts_id
JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
WHERE th.organization_id = ?
ORDER BY th.trans_date DESC, th.transaction_head_id DESC
LIMIT 10;
```

## 7. Reports

### Trial Balance
```sql
-- Generate trial balance for organization
SELECT 
    a.gl_code,
    a.account_name,
    atm.balance_type,
    atm.category,
    COALESCE(SUM(
        CASE 
            WHEN atm.balance_type = 'DEBIT' THEN 
                CASE WHEN td.trans_amount::numeric > 0 THEN td.trans_amount::numeric ELSE -td.trans_amount::numeric END
            ELSE 
                CASE WHEN td.trans_amount::numeric < 0 THEN -td.trans_amount::numeric ELSE td.trans_amount::numeric END
        END
    ), 0) as balance
FROM accounts a
JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id
WHERE a.organization_id = ?
AND a.status = 'ACTIVE'
GROUP BY a.gl_code, a.account_name, atm.balance_type, atm.category
HAVING COALESCE(SUM(
    CASE 
        WHEN atm.balance_type = 'DEBIT' THEN 
            CASE WHEN td.trans_amount::numeric > 0 THEN td.trans_amount::numeric ELSE -td.trans_amount::numeric END
        ELSE 
            CASE WHEN td.trans_amount::numeric < 0 THEN -td.trans_amount::numeric ELSE td.trans_amount::numeric END
    END
), 0) != 0
ORDER BY a.gl_code;
```

### Member Statement
```sql
-- Generate member account statement
SELECT 
    th.trans_date,
    th.voucher_no,
    th.trans_narration,
    td.trans_amount,
    CASE WHEN td.trans_amount::numeric > 0 THEN td.trans_amount ELSE NULL END as debit,
    CASE WHEN td.trans_amount::numeric < 0 THEN ABS(td.trans_amount::numeric) ELSE NULL END as credit,
    -- Running balance calculation would need window function
    SUM(td.trans_amount::numeric) OVER (ORDER BY th.trans_date, th.transaction_head_id) as running_balance
FROM transaction_details td
JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
WHERE td.organization_id = ?
AND td.sub_accounts_id = ?
ORDER BY th.trans_date, th.transaction_head_id;
```

## 8. Organization Settings

### Get Organization Settings
```sql
-- Get all settings for organization
SELECT 
    setting_key,
    setting_value,
    setting_type,
    description
FROM organization_settings
WHERE organization_id = ?
AND is_active = TRUE
ORDER BY setting_key;
```

### Update Organization Setting
```sql
-- Update or insert organization setting
INSERT INTO organization_settings (
    organization_id, setting_key, setting_value, setting_type
) VALUES (?, ?, ?, ?)
ON CONFLICT (organization_id, setting_key) 
DO UPDATE SET 
    setting_value = EXCLUDED.setting_value,
    updated_date = CURRENT_TIMESTAMP;
```

## 9. Validation Queries

### Check Member Belongs to Organization
```sql
-- Validate member belongs to organization
SELECT EXISTS(
    SELECT 1 FROM members 
    WHERE members_id = ? 
    AND organization_id = ? 
    AND status = 'ACTIVE'
);
```

### Check Account Belongs to Organization
```sql
-- Validate account belongs to organization
SELECT EXISTS(
    SELECT 1 FROM sub_accounts sa
    JOIN accounts a ON sa.accounts_id = a.accounts_id
    WHERE sa.sub_accounts_id = ?
    AND a.organization_id = ?
    AND sa.status = 'ACTIVE'
);
```

### Validate User Access to Organization
```sql
-- Check if user has access to organization
SELECT 
    role,
    access_level
FROM user_organization_access
WHERE user_id = ?
AND organization_id = ?
AND is_active = TRUE;
```

These queries support all the UI workflows described in the business guide, ensuring proper data isolation and organization context throughout the system.
