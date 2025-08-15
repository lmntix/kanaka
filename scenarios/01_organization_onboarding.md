# Scenario 1: Organization Onboarding Process
## Business Analysis Guide for Developer

## Business Context

When a new cooperative society/credit union wants to join your SaaS platform, they need to be fully set up to start their banking operations. This involves both **automatic system setup** (handled by your backend) and **manual configuration** (done by organization admins).

## Given: Organization Basic Data Available

**Assumption**: Organization record already exists in `organizations` table with:
```sql
-- Sample organization record
organization_id: 123
organization_name: "Rural Credit Cooperative Society"  
organization_code: "RCC001"
status: "ACTIVE"
```

## What Happens During Onboarding

### Phase 1: Automatic Backend Setup (Your Code)

#### 1.1 Create Organization's Chart of Accounts
**What**: Set up organization-specific accounts directly in the accounts table
**Why**: Every cooperative needs standard account types (Cash, Savings, Loans, etc.) with their own GL codes

```sql
-- Direct creation of organization-specific accounts
-- ASSETS
INSERT INTO accounts (organization_id, account_name, account_type, opening_balance, gl_code, status, balance_type) VALUES 
(123, 'Cash in Hand', 'ASSET', 0.00, '1001', 'ACTIVE', 'DEBIT'),
(123, 'Bank - Current Account', 'ASSET', 0.00, '1002', 'ACTIVE', 'DEBIT'),
(123, 'Members Loan Accounts', 'ASSET', 0.00, '1100', 'ACTIVE', 'DEBIT');

-- LIABILITIES
INSERT INTO accounts (organization_id, account_name, account_type, opening_balance, gl_code, status, balance_type) VALUES 
(123, 'Share Capital', 'LIABILITY', 0.00, '2001', 'ACTIVE', 'CREDIT'),
(123, 'Members Savings Deposits', 'LIABILITY', 0.00, '2100', 'ACTIVE', 'CREDIT'),
(123, 'Members Fixed Deposits', 'LIABILITY', 0.00, '2200', 'ACTIVE', 'CREDIT');

-- INCOME
INSERT INTO accounts (organization_id, account_name, account_type, opening_balance, gl_code, status, balance_type) VALUES 
(123, 'Interest Income - Loans', 'INCOME', 0.00, '4001', 'ACTIVE', 'CREDIT'),
(123, 'Service Fee Income', 'INCOME', 0.00, '4020', 'ACTIVE', 'CREDIT');

-- EXPENSES
INSERT INTO accounts (organization_id, account_name, account_type, opening_balance, gl_code, status, balance_type) VALUES 
(123, 'Interest Expense - Savings', 'EXPENSE', 0.00, '5001', 'ACTIVE', 'DEBIT'),
(123, 'Staff Salaries', 'EXPENSE', 0.00, '5100', 'ACTIVE', 'DEBIT');

-- Results in organization getting their own chart of accounts:
-- GL 1001 - Cash in Hand (ASSET)
-- GL 1002 - Bank - Current Account (ASSET)
-- GL 2001 - Share Capital (LIABILITY)
-- GL 2100 - Members Savings Deposits (LIABILITY)
-- GL 4001 - Interest Income - Loans (INCOME)
-- GL 5001 - Interest Expense - Savings (EXPENSE)
```

**Your Backend Task**: Create complete chart of accounts directly for the organization using a template function or manual insertion

#### 1.2 Initialize Voucher Sequences
**What**: Set up voucher numbering for the organization
**Why**: Each transaction needs a unique voucher number

```sql
-- Initialize voucher sequences for different transaction types
INSERT INTO voucher_sequences (organization_id, voucher_type, financial_year, current_number, prefix)
VALUES 
(123, 'CASH_RECEIPT', 2024, 0, 'CR'),
(123, 'CASH_PAYMENT', 2024, 0, 'CP'),  
(123, 'BANK_RECEIPT', 2024, 0, 'BR'),
(123, 'JOURNAL_VOUCHER', 2024, 0, 'JV');
```

**Your Backend Task**: Create default voucher sequences for current financial year

#### 1.3 Initialize Account Number Sequences
**What**: Set up account numbering for member accounts
**Why**: Each member account needs unique numbers

```sql
-- Initialize account number sequences
INSERT INTO account_number_sequences (organization_id, account_type, current_number, prefix)
VALUES
(123, 'SAVINGS', 0, 'SAV'),
(123, 'FD', 0, 'FD'),
(123, 'LOAN', 0, 'LOAN');
```

**Your Backend Task**: Create account numbering sequences for member account types

#### 1.4 Setup Organization Calendar
**What**: Create business calendar for the organization  
**Why**: Date management and business day control

```sql
-- Create current financial year calendar entries
INSERT INTO calender (organization_id, financial_years_id, yearly_trans_dates, day_type, current_day)
SELECT 123, fy.financial_years_id, date_series.date_val, 'WORKING', 
       CASE WHEN date_series.date_val = CURRENT_DATE THEN 'Y' ELSE 'N' END
FROM financial_years fy,
     generate_series(fy.from_date::date, fy.to_date::date, '1 day') AS date_series(date_val)
WHERE fy.organization_id = 123;
```

**Your Backend Task**: Generate calendar entries for current financial year

### Phase 2: Manual Organization Admin Setup (In App)

#### 2.1 Organization Settings Configuration
**What**: Organization admin configures business rules
**How**: Admin logs into app → Organization Settings → Configure

**Settings to Configure**:
- Interest rates (Savings: 6%, FD: 8%, Loan: 12%)
- Minimum balances (Savings: ₹100, FD: ₹1000)
- Account opening fees
- SMS/email notifications rules
- Back-dated entry permissions

```sql
-- Example settings that admin configures
INSERT INTO organization_settings (organization_id, setting_key, setting_value)
VALUES 
(123, 'SAVINGS_INTEREST_RATE', '6.0'),
(123, 'MIN_SAVINGS_BALANCE', '100'),
(123, 'ALLOW_BACKDATED_ENTRY', 'true');
```

#### 2.2 User Access Setup
**What**: Add organization users and assign roles
**How**: Admin → User Management → Add Users

```sql
-- Grant access to organization staff
INSERT INTO user_organization_access (user_id, organization_id, role, access_level)
VALUES 
(45, 123, 'CASHIER', 'USER'),
(67, 123, 'MANAGER', 'ADMIN');
```

#### 2.3 Create Non-Member Accounts (Optional)
**What**: Create organizational accounts like Cash, Bank accounts
**How**: Admin → Account Management → Create Account

**Example**: Organization's main cash account
```sql
-- Create cash sub-account for organization operations
INSERT INTO sub_accounts (organization_id, accounts_id, members_id, account_no, opening_balance, account_type, status)
VALUES (123, 
        (SELECT accounts_id FROM accounts WHERE organization_id = 123 AND gl_code = '1001'), 
        NULL, 'CASH-RCC001', 0.00, 'SYSTEM', 'ACTIVE');
```

## What Organization Can Start Doing

### Immediately After Onboarding:
1. **Add Members**: Register new members in the system
2. **Create Member Accounts**: Open savings/FD/loan accounts for members
3. **Process Transactions**: Accept deposits, grant loans, handle withdrawals
4. **Generate Reports**: Access all standard reports

### Sample Member Addition Flow:
```sql
-- 1. Admin adds member
INSERT INTO members (organization_id, full_name, status, appli_date)
VALUES (123, 'Rajesh Kumar', 'ACTIVE', CURRENT_DATE);

-- 2. System auto-creates member's savings account
INSERT INTO sub_accounts (organization_id, accounts_id, members_id, account_no, opening_balance, account_type, status)
VALUES (123, 
        (SELECT accounts_id FROM accounts WHERE organization_id = 123 AND gl_code = '2100'),
        [member_id], 'SAV001001', 0.00, 'SAVINGS', 'ACTIVE');

-- 3. Member makes first deposit
-- Dr. Cash Account, Cr. Member Savings Account
```

## Business Rules Summary

### Backend Automation (Your Code):
✅ **Chart of accounts creation** - Direct organization-specific accounts with custom GL codes  
✅ **Voucher sequence setup** - Transaction numbering per organization  
✅ **Account number sequences** - Member account numbering per organization  
✅ **Calendar initialization** - Business date management per organization  
✅ **Default financial year** - Current year setup per organization

### Manual Admin Tasks (In App):
📝 **Organization settings** - Interest rates, business rules  
📝 **User access management** - Staff roles and permissions  
📝 **Member registration** - Add organization members  
📝 **Account opening** - Create member accounts  
📝 **Daily operations** - Process transactions  

## Validation Points

**For Developer**: Ensure these exist before organization can operate:
```sql
-- Check organization is fully set up
SELECT 
    o.organization_name,
    COUNT(DISTINCT a.accounts_id) as accounts_created,
    COUNT(DISTINCT CASE WHEN a.account_type = 'ASSET' THEN 1 END) as asset_accounts,
    COUNT(DISTINCT CASE WHEN a.account_type = 'LIABILITY' THEN 1 END) as liability_accounts,
    COUNT(DISTINCT CASE WHEN a.account_type = 'INCOME' THEN 1 END) as income_accounts,
    COUNT(DISTINCT CASE WHEN a.account_type = 'EXPENSE' THEN 1 END) as expense_accounts,
    COUNT(DISTINCT vs.sequence_id) as voucher_sequences,
    COUNT(DISTINCT ans.sequence_id) as account_sequences
FROM organizations o
LEFT JOIN accounts a ON o.organization_id = a.organization_id  
LEFT JOIN voucher_sequences vs ON o.organization_id = vs.organization_id
LEFT JOIN account_number_sequences ans ON o.organization_id = ans.organization_id
WHERE o.organization_id = 123
GROUP BY o.organization_id, o.organization_name;

-- Should show: accounts_created: 8+, asset_accounts: 3+, liability_accounts: 3+, 
-- income_accounts: 2+, expense_accounts: 2+, voucher_sequences: 4+, account_sequences: 3+
```

## Key Takeaway

**Organization onboarding is simplified**:
- **System Setup (Backend)**: Direct creation of organization-specific accounts with custom GL codes
- **Business Configuration (Admin)**: Customization and daily operations

The simplified approach creates organization-specific accounts directly in the accounts table with custom GL codes, eliminating the need for complex mapping tables while ensuring complete data isolation and flexibility for each organization.
