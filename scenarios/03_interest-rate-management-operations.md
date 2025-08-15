# Interest Rate Management Database Operations Guide

## Introduction

This document provides detailed database-level operations for managing interest rate changes in microfinance accounts. It covers scenarios where administrators need to update interest rates for product schemes and decide whether to apply these changes to existing accounts or only to new accounts going forward.

**Important Note**: Interest rate changes are **administrative/configuration changes**, not financial transactions. They do not involve money movement, so they do not require entries in transaction tables.

## Database Tables Overview

### Core Tables Used in Interest Rate Management:

- **`fd_schemes`** / **`loan_schemes`** / **`savings_schemes`**: Product/scheme master tables
- **`fd_accounts`** / **`loan_accounts`** / **`savings_accounts`**: Individual account tables
- **`loan_repayment_schedule`**: For loan EMI recalculation after rate changes

---

## Interest Rate Management Scenarios

### Scenario 1: Update Product Master Rate (Affects New Accounts Only)

**Business Action**: Change Fixed Deposit interest rate from 8% to 8.5% for new accounts only

**Step 1: Update Product/Scheme Master**
```sql
Table: fd_schemes  -- Or loan_schemes, savings_schemes
UPDATE fd_schemes 
SET interest_rate = 8.50,
    rate_effective_from = '2024-02-01',
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE fd_schemes_id = 5 AND organization_id = 'org-123'
```

**Result**: All new FD accounts created after Feb 1, 2024 will use 8.5% interest rate. Existing accounts remain unchanged.

---

### Scenario 2: Apply Rate Change to All Existing Accounts

**Business Decision**: Apply new 8.5% rate to all existing FDs opened after Jan 1, 2024

**Step 1: Identify Target Accounts**
```sql
-- Query to find eligible accounts
SELECT fd_accounts_id, members_id, sub_accounts_id, fd_amount, 
       interest_rate as current_rate, open_date, maturity_date,
       maturity_amount as current_maturity
FROM fd_accounts 
WHERE fd_schemes_id = 5 
  AND organization_id = 'org-123'
  AND status = '1'                  -- Active accounts only
  AND open_date >= '2024-01-01'     -- Apply to recent accounts
  AND interest_rate != 8.50;        -- Skip if already updated

-- Example result: Account IDs [78, 85, 92, 101]
```

**Step 2: Update Individual FD Accounts**
```sql
Table: fd_accounts
-- For each account identified in Step 1:
UPDATE fd_accounts 
SET interest_rate = 8.50,
    rate_change_date = '2024-02-01',
    maturity_amount = calculate_new_maturity(fd_amount, 8.50, tenure_months),
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE fd_accounts_id IN (78, 85, 92, 101);  -- Account IDs from step 1

-- Example calculations:
-- Account 78: Maturity amount changed from ₹54,000 to ₹54,600
-- Account 85: Maturity amount changed from ₹32,400 to ₹32,760
-- Account 92: Maturity amount changed from ₹43,200 to ₹43,650
-- Account 101: Maturity amount changed from ₹21,600 to ₹21,870
```

---

### Scenario 3: Selective Rate Application (User Choice)

**Business Action**: Present list of existing accounts, allow user to select which accounts get new rate

**Step 1: Present Account List to User**
```sql
-- UI Query: Show eligible accounts for user selection
SELECT fd.fd_accounts_id,
       m.member_name,
       sa.sub_accounts_no as fd_number,
       fd.fd_amount,
       fd.interest_rate as current_rate,
       fd.maturity_amount as current_maturity,
       calculate_new_maturity(fd.fd_amount, 8.50, fd.tenure_months) as new_maturity,
       fd.open_date,
       fd.maturity_date
FROM fd_accounts fd
JOIN sub_accounts sa ON fd.sub_accounts_id = sa.sub_accounts_id
JOIN members m ON fd.members_id = m.members_id
WHERE fd.fd_schemes_id = 5 
  AND fd.organization_id = 'org-123'
  AND fd.status = '1'
  AND fd.interest_rate != 8.50;
```

**Step 2: Process User Selection**
```sql
-- User makes selection:
Selected FD Account IDs: [78, 92]   -- User chose 2 out of 4 eligible accounts
Skipped FD Account IDs: [85, 101]   -- User chose to keep old rates
```

**Step 3: Update Selected Accounts Only**
```sql
Table: fd_accounts
UPDATE fd_accounts 
SET interest_rate = 8.50,
    rate_change_date = '2024-02-01',
    maturity_amount = calculate_new_maturity(fd_amount, 8.50, tenure_months),
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE fd_accounts_id IN (78, 92);   -- Only selected accounts
```

---

### Scenario 4: Loan Interest Rate Change with EMI Recalculation

**Business Action**: Reduce personal loan interest from 12% to 11%, apply to active loans

**Step 1: Update Loan Scheme**
```sql
Table: loan_schemes
UPDATE loan_schemes 
SET interest_rate = 11.00,
    rate_effective_from = '2024-02-01',
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE loan_schemes_id = 3 AND organization_id = 'org-123'
```

**Step 2: Identify Active Loans for Update**
```sql
-- Query to find eligible loan accounts
SELECT loan_accounts_id, members_id, sub_accounts_id, loan_amount,
       outstanding_balance, tenure_months, disbursement_date, 
       emi_amount as current_emi, interest_rate as current_rate,
       DATEDIFF(MONTH, CURDATE(), 
         DATE_ADD(disbursement_date, INTERVAL tenure_months MONTH)) as remaining_tenure
FROM loan_accounts 
WHERE loan_schemes_id = 3 
  AND organization_id = 'org-123'
  AND status = '1'                  -- Active loans only
  AND outstanding_balance > 0       -- Has outstanding amount
  AND interest_rate != 11.00;       -- Skip if already updated

-- Example result: Loan IDs [91, 98, 105]
```

**Step 3: Update Individual Loan Accounts**
```sql
Table: loan_accounts
-- For each loan identified in Step 2:
UPDATE loan_accounts 
SET interest_rate = 11.00,
    emi_amount = calculate_new_emi(outstanding_balance, 11.00, remaining_tenure),
    rate_change_date = '2024-02-01',
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE loan_accounts_id IN (91, 98, 105);  -- Active loan IDs

-- Example calculations:
-- Loan 91: EMI reduced from ₹4,707.35 to ₹4,659.58
-- Loan 98: EMI reduced from ₹3,156.21 to ₹3,125.47  
-- Loan 105: EMI reduced from ₹2,847.89 to ₹2,821.33
```

**Step 4: Update Future Repayment Schedule**
```sql
Table: loan_repayment_schedule
-- Recalculate future installments for each updated loan:
UPDATE loan_repayment_schedule 
SET principal_amount = recalculated_principal,
    interest_amount = recalculated_interest,
    installment_amount = recalculated_total,
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE loan_accounts_id IN (91, 98, 105)
  AND status = 'PENDING'            -- Only future installments
  AND due_date >= '2024-03-01';     -- Next month onwards
```

---

### Scenario 5: Savings Account Interest Rate Change

**Business Action**: Increase savings account interest from 4% to 4.5%

**Step 1: Update Savings Scheme**
```sql
Table: savings_schemes
UPDATE savings_schemes 
SET interest_rate = 4.50,
    rate_effective_from = '2024-02-01',
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE savings_schemes_id = 2 AND organization_id = 'org-123'
```

**Step 2: Identify Active Savings Accounts**
```sql
-- Query to find eligible savings accounts
SELECT savings_accounts_id, members_id, sub_accounts_id, 
       current_balance, interest_rate as current_rate,
       account_opening_date
FROM savings_accounts 
WHERE savings_schemes_id = 2 
  AND organization_id = 'org-123'
  AND status = '1'                  -- Active accounts only
  AND interest_rate != 4.50;        -- Skip if already updated

-- Example result: Account IDs [45, 67, 89, 123, 145]
```

**Step 3: Update Individual Savings Accounts**
```sql
Table: savings_accounts
UPDATE savings_accounts 
SET interest_rate = 4.50,
    rate_change_date = '2024-02-01',
    last_modified_by = 'admin123',
    last_modified_on = NOW()
WHERE savings_accounts_id IN (45, 67, 89, 123, 145);  -- Account IDs from step 2
```

**Result**: Future interest calculations for these accounts will use the new 4.5% rate.

---

## Key Points for Business Analysts

### Rate Change Decision Matrix:
1. **New Accounts Only**: Update scheme master, no existing account changes
2. **All Existing Accounts**: Bulk update all qualifying accounts automatically
3. **Selective Update**: User chooses which accounts to update from eligible list
4. **Criteria-Based**: Apply to accounts meeting specific conditions (date range, amount, etc.)

### Data Validation Points:
1. **Account Status**: Only update active accounts (`status = '1'`)
2. **Already Updated**: Skip accounts that already have the new rate
3. **Outstanding Balance**: For loans, only update accounts with balance > 0
4. **Future Dates**: Rate changes are typically effective from future dates
5. **User Permissions**: Verify user has authority to make rate changes

### Calculation Requirements:
- **FD Maturity Amount**: Recalculate based on new rate and remaining tenure
- **Loan EMI**: Recalculate based on new rate and remaining balance/tenure
- **Repayment Schedule**: Update future installments for loans
- **Interest Projections**: Update future interest calculations for savings

### Why No Transaction Entries?
Interest rate changes are administrative actions that modify account terms and conditions. They are:
- **Configuration changes**, not monetary transactions
- **Rate adjustments**, not money movement
- **Administrative actions**, not customer transactions

Transaction tables (`transaction_head`, `transaction_details`) are reserved for actual financial movements like deposits, withdrawals, loan disbursements, etc.

### Fields to Add to Existing Tables:
```sql
-- Add to fd_accounts, loan_accounts, savings_accounts:
ALTER TABLE fd_accounts ADD COLUMN rate_change_date DATE;

-- For tracking in schemes table:
ALTER TABLE fd_schemes ADD COLUMN rate_effective_from DATE;
```

This simplified approach maintains proper audit trails through existing `last_modified_by` and `last_modified_on` fields without creating unnecessary complexity.
