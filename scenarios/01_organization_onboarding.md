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
**What**: Set up the basic accounting structure for the organization
**Why**: Every cooperative needs standard account types (Cash, Savings, Loans, etc.)

```sql
-- Example: Setup default account types for organization
INSERT INTO org_account_types (organization_id, account_type_id, org_gl_code, org_account_name, is_enabled)
SELECT 123, account_type_id, default_gl_code, account_type_name, TRUE
FROM account_types_master 
WHERE account_type_code IN ('CASH', 'BANK', 'SAVINGS', 'LOAN', 'SHARES');

-- Results in organization getting:
-- GL 1001 - Cash in Hand
-- GL 1002 - Bank Account  
-- GL 2001 - Member Savings
-- GL 1101 - Member Loans
-- GL 3001 - Share Capital
```

**Your Backend Task**: Create default account configuration automatically when organization status becomes "ACTIVE"

#### 1.2 Create Account Instances
**What**: Create actual account records that will be used in transactions
**Why**: Transactions need actual accounts to debit/credit

```sql
-- Create account instances from the configured account types
INSERT INTO accounts (organization_id, account_type_id, account_name, account_type, balance_type, gl_code, status)
SELECT oat.organization_id, oat.account_type_id, oat.org_account_name, 
       atm.account_type_code, atm.balance_type, oat.org_gl_code, 'ACTIVE'
FROM org_account_types oat
JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
WHERE oat.organization_id = 123;
```

**Your Backend Task**: Auto-create account instances for all enabled account types

#### 1.3 Initialize Voucher Sequences
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

#### 1.4 Initialize Account Number Sequences  
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

#### 1.5 Setup Organization Calendar
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
-- Create cash sub-account for organization
INSERT INTO sub_accounts (organization_id, accounts_id, members_id, sub_accounts_no, name, status)
VALUES (123, [cash_account_id], NULL, 'CASH-RCC001', 'Main Cash Counter', 'ACTIVE');
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
INSERT INTO sub_accounts (organization_id, accounts_id, members_id, sub_accounts_no, name)
VALUES (123, [savings_account_id], [member_id], 'SAV001001', 'Savings Account');

-- 3. Member makes first deposit
-- Dr. Cash Account, Cr. Member Savings Account
```

## Business Rules Summary

### Backend Automation (Your Code):
✅ **Chart of accounts creation** - Standard accounting structure  
✅ **Voucher sequence setup** - Transaction numbering  
✅ **Account number sequences** - Member account numbering  
✅ **Calendar initialization** - Business date management  
✅ **Default financial year** - Current year setup  

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
    COUNT(DISTINCT oat.org_account_type_id) as account_types_configured,
    COUNT(DISTINCT a.accounts_id) as accounts_created,
    COUNT(DISTINCT vs.sequence_id) as voucher_sequences,
    COUNT(DISTINCT ans.sequence_id) as account_sequences
FROM organizations o
LEFT JOIN org_account_types oat ON o.organization_id = oat.organization_id
LEFT JOIN accounts a ON o.organization_id = a.organization_id  
LEFT JOIN voucher_sequences vs ON o.organization_id = vs.organization_id
LEFT JOIN account_number_sequences ans ON o.organization_id = ans.organization_id
WHERE o.organization_id = 123
GROUP BY o.organization_id, o.organization_name;

-- Should show: account_types: 5+, accounts: 5+, voucher_sequences: 4+, account_sequences: 3+
```

## Key Takeaway

**Organization onboarding is split**:
- **System Setup (Backend)**: All foundational data structures
- **Business Configuration (Admin)**: Customization and daily operations

Once your backend completes the automatic setup, the organization admin can immediately start using the system for their cooperative banking operations.
