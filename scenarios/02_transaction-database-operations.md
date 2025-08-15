# Transaction Database Operations Guide for Business Analysts

## Introduction

This document provides detailed database-level operations for each transaction scenario in the microfinance application. It shows exactly which tables get updated, what data is inserted, and the complete flow from user action to database entries.

## Database Tables Overview

### Core Tables Used in Transactions:

- **`transaction_head`**: Main transaction record
- **`transaction_details`**: Individual accounting entries (debits/credits)
- **`sub_accounts`**: Individual member/organization account balances
- **`fd_accounts`**: Fixed deposit account details
- **`savings_accounts`**: Savings account details
- **`loan_accounts`**: Loan account details
- **`accounts`**: Chart of accounts (GL accounts)
- **`members`**: Member master data
- **`organizations`**: Organization master data

---

## Transaction Scenarios with Database Operations

### Scenario 1: Fixed Deposit Account Opening

**Business Action**: Member deposits ₹50,000 cash to open FD

**Step 1: Create Sub-Account Entry**
```
Table: sub_accounts
INSERT INTO sub_accounts (
  accounts_id = 45,              // From accounts table where account_type = 'FIXED_DEPOSITS'
  organization_id = 'org-123',   // Current organization
  members_id = 1234,             // Selected member ID
  sub_accounts_no = 'FD001234',  // Auto-generated FD number
  name = 'Rajesh Kumar - FD',    // Member name + account type
  status = '1',                  // Active
  opened_date = '2024-01-15'     // Current date
)
```

**Step 2: Create FD Account Details**
```
Table: fd_accounts
INSERT INTO fd_accounts (
  organization_id = 'org-123',
  sub_accounts_id = 156,         // ID from step 1
  fd_schemes_id = 5,             // Selected FD scheme
  members_id = 1234,
  fd_amount = 50000,
  interest_rate = 8.00,
  tenure_months = 12,
  open_date = '2024-01-15',
  maturity_date = '2025-01-15',  // Calculated
  maturity_amount = 54000,       // Calculated
  receipt_no = 'FD001234',
  status = '1'
)
```

**Step 3: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401150001',  // Auto-generated
  transaction_date = '2024-01-15',
  transaction_type = 'FIXED_DEPOSIT_OPENING',
  reference_type = 'FD_ACCOUNT',
  reference_id = '78',                 // fd_accounts_id from step 2
  total_amount = 50000,
  description = 'FD Account Opening - FD001234',
  created_by = 'user123'
)
```

**Step 4: Create Transaction Details (Double Entry)**
```
Table: transaction_details
-- Entry 1: Debit Cash Account
INSERT INTO transaction_details (
  transaction_head_id = 501,     // From step 3
  organization_id = 'org-123',
  accounts_id = 10,              // Cash & Bank account from accounts table
  sub_accounts_id = 25,          // Organization's cash sub-account
  debit_amount = 50000,
  credit_amount = 0,
  particulars = 'Cash received for FD opening - FD001234'
)

-- Entry 2: Credit FD Account
INSERT INTO transaction_details (
  transaction_head_id = 501,     // Same as above
  organization_id = 'org-123',
  accounts_id = 45,              // Fixed Deposits account from accounts table
  sub_accounts_id = 156,         // Member's FD sub-account from step 1
  debit_amount = 0,
  credit_amount = 50000,
  particulars = 'FD account opened - FD001234'
)
```

---

### Scenario 2: Savings Account Deposit

**Business Action**: Member deposits ₹10,000 in existing savings account SAV001234

**Step 1: Update Savings Account Balance**
```
Table: savings_accounts
UPDATE savings_accounts 
SET current_balance = current_balance + 10000,
    last_transaction_date = '2024-01-15',
    last_modified_by = 'user123',
    last_modified_on = NOW()
WHERE savings_accounts_id = 45        // Found by searching with member ID
```

**Step 2: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401150002',
  transaction_date = '2024-01-15',
  transaction_type = 'SAVINGS_ACCOUNT_DEPOSIT',
  reference_type = 'SAVINGS_ACCOUNT',
  reference_id = '45',                 // savings_accounts_id
  total_amount = 10000,
  description = 'Deposit to savings account - SAV001234',
  created_by = 'user123'
)
```

**Step 3: Create Transaction Details**
```
Table: transaction_details
-- Entry 1: Debit Cash
INSERT INTO transaction_details (
  transaction_head_id = 502,
  organization_id = 'org-123',
  accounts_id = 10,              // Cash & Bank
  sub_accounts_id = 25,          // Org cash account
  debit_amount = 10000,
  credit_amount = 0,
  particulars = 'Cash deposit to savings - SAV001234'
)

-- Entry 2: Credit Savings Account
INSERT INTO transaction_details (
  transaction_head_id = 502,
  organization_id = 'org-123',
  accounts_id = 46,              // Savings Deposits account
  sub_accounts_id = 87,          // Member's savings sub-account
  debit_amount = 0,
  credit_amount = 10000,
  particulars = 'Deposit credited to savings - SAV001234'
)
```

---

### Scenario 3: Loan Disbursement

**Business Action**: Disburse ₹100,000 personal loan, collect ₹2,000 processing fee

**Step 1: Create Loan Sub-Account**
```
Table: sub_accounts
INSERT INTO sub_accounts (
  accounts_id = 28,              // Member Loans account
  organization_id = 'org-123',
  members_id = 1234,
  sub_accounts_no = 'LOAN001234',
  name = 'Rajesh Kumar - Personal Loan',
  status = '1',
  opened_date = '2024-01-15'
)
```

**Step 2: Create/Update Loan Account**
```
Table: loan_accounts
INSERT INTO loan_accounts (
  organization_id = 'org-123',
  sub_accounts_id = 201,         // From step 1
  loan_schemes_id = 3,           // Selected loan product
  members_id = 1234,
  loan_amount = 100000,
  outstanding_balance = 100000,
  interest_rate = 12.00,
  tenure_months = 24,
  disbursement_date = '2024-01-15',
  first_emi_date = '2024-02-15',  // Calculated
  next_due_date = '2024-02-15',
  emi_amount = 4707.35,          // Calculated
  status = '1'
)
```

**Step 3: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401150003',
  transaction_date = '2024-01-15',
  transaction_type = 'PERSONAL_LOAN_DISBURSEMENT_WITH_FEE',
  reference_type = 'LOAN_ACCOUNT',
  reference_id = '91',           // loan_accounts_id from step 2
  total_amount = 100000,         // Gross loan amount
  description = 'Loan disbursed - LOAN001234',
  created_by = 'user123'
)
```

**Step 4: Create Transaction Details**
```
Table: transaction_details
-- Entry 1: Debit Loan Account (Asset)
INSERT INTO transaction_details (
  transaction_head_id = 503,
  organization_id = 'org-123',
  accounts_id = 28,              // Member Loans
  sub_accounts_id = 201,         // Member's loan sub-account
  debit_amount = 100000,         // Full loan amount
  credit_amount = 0,
  particulars = 'Personal loan disbursed - LOAN001234'
)

-- Entry 2: Credit Cash (Net disbursement)
INSERT INTO transaction_details (
  transaction_head_id = 503,
  organization_id = 'org-123',
  accounts_id = 10,              // Cash & Bank
  sub_accounts_id = 25,          // Org cash account
  debit_amount = 0,
  credit_amount = 98000,         // Net amount (100000 - 2000)
  particulars = 'Net cash disbursed after fee deduction - LOAN001234'
)

-- Entry 3: Credit Processing Fee Income
INSERT INTO transaction_details (
  transaction_head_id = 503,
  organization_id = 'org-123',
  accounts_id = 52,              // Processing Fees account
  sub_accounts_id = 35,          // Org processing fee sub-account
  debit_amount = 0,
  credit_amount = 2000,
  particulars = 'Processing fee collected - LOAN001234'
)
```

---

### Scenario 4: EMI Collection

**Business Action**: Collect ₹9,500 EMI (₹7,200 principal + ₹2,300 interest)

**Step 1: Update Loan Account**
```
Table: loan_accounts
UPDATE loan_accounts 
SET outstanding_balance = outstanding_balance - 7200,  // Reduce principal
    next_due_date = '2024-03-15',                      // Next month
    last_modified_by = 'user123',
    last_modified_on = NOW()
WHERE loan_accounts_id = 91
```

**Step 2: Create Loan Repayment Schedule Entry (if tracking)**
```
Table: loan_repayment_schedule  // Optional table for detailed tracking
UPDATE loan_repayment_schedule
SET paid_principal = 7200,
    paid_interest = 2300,
    payment_date = '2024-01-15',
    status = 'PAID'
WHERE loan_accounts_id = 91 AND installment_number = 5
```

**Step 3: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401150004',
  transaction_date = '2024-01-15',
  transaction_type = 'LOAN_EMI_COLLECTION',
  reference_type = 'LOAN_ACCOUNT',
  reference_id = '91',
  total_amount = 9500,
  description = 'EMI collection - LOAN001234 - Installment 5',
  created_by = 'user123'
)
```

**Step 4: Create Transaction Details**
```
Table: transaction_details
-- Entry 1: Debit Cash
INSERT INTO transaction_details (
  transaction_head_id = 504,
  organization_id = 'org-123',
  accounts_id = 10,              // Cash & Bank
  sub_accounts_id = 25,          // Org cash account
  debit_amount = 9500,
  credit_amount = 0,
  particulars = 'EMI collection - LOAN001234'
)

-- Entry 2: Credit Loan Account (Principal)
INSERT INTO transaction_details (
  transaction_head_id = 504,
  organization_id = 'org-123',
  accounts_id = 28,              // Member Loans
  sub_accounts_id = 201,         // Member's loan sub-account
  debit_amount = 0,
  credit_amount = 7200,          // Principal component
  particulars = 'Principal repayment - LOAN001234'
)

-- Entry 3: Credit Interest Income
INSERT INTO transaction_details (
  transaction_head_id = 504,
  organization_id = 'org-123',
  accounts_id = 50,              // Loan Interest Income
  sub_accounts_id = 41,          // Org interest income sub-account
  debit_amount = 0,
  credit_amount = 2300,          // Interest component
  particulars = 'Interest income - LOAN001234'
)
```

---

### Scenario 5: Interest Posting on Savings

**Business Action**: Monthly interest posting for account SAV001234 (₹83.33)

**Step 1: Update Savings Account Balance**
```
Table: savings_accounts
UPDATE savings_accounts 
SET current_balance = current_balance + 83.33,
    last_transaction_date = '2024-01-31',
    last_modified_by = 'SYSTEM',
    last_modified_on = NOW()
WHERE savings_accounts_id = 45
```

**Step 2: Create Interest Calculation Record**
```
Table: interest_calculations  // Optional tracking table
INSERT INTO interest_calculations (
  account_type = 'SAVINGS',
  account_id = 45,              // savings_accounts_id
  calculation_date = '2024-01-31',
  interest_period_from = '2024-01-01',
  interest_period_to = '2024-01-31',
  average_balance = 25000,      // Calculated
  interest_rate = 4.00,
  interest_amount = 83.33,
  posted = true
)
```

**Step 3: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401310001',
  transaction_date = '2024-01-31',
  transaction_type = 'SAVINGS_INTEREST_POSTING',
  reference_type = 'SAVINGS_ACCOUNT',
  reference_id = '45',
  total_amount = 83.33,
  description = 'Interest posting - January 2024 - SAV001234',
  created_by = 'SYSTEM'
)
```

**Step 4: Create Transaction Details**
```
Table: transaction_details
-- Entry 1: Debit Interest Expense
INSERT INTO transaction_details (
  transaction_head_id = 505,
  organization_id = 'org-123',
  accounts_id = 62,              // Interest on Savings expense account
  sub_accounts_id = 48,          // Org expense sub-account
  debit_amount = 83.33,
  credit_amount = 0,
  particulars = 'Interest expense - January 2024 - SAV001234'
)

-- Entry 2: Credit Member Savings
INSERT INTO transaction_details (
  transaction_head_id = 505,
  organization_id = 'org-123',
  accounts_id = 46,              // Savings Deposits
  sub_accounts_id = 87,          // Member's savings sub-account
  debit_amount = 0,
  credit_amount = 83.33,
  particulars = 'Interest credited - January 2024 - SAV001234'
)
```

---

### Scenario 6: Internal Transfer (Savings to FD)

**Business Action**: Transfer ₹15,000 from savings SAV001234 to create new FD

**Step 1: Update Source Savings Account**
```
Table: savings_accounts
UPDATE savings_accounts 
SET current_balance = current_balance - 15000,
    last_transaction_date = '2024-01-15',
    last_modified_by = 'user123'
WHERE savings_accounts_id = 45
```

**Step 2: Create New FD Sub-Account**
```
Table: sub_accounts
INSERT INTO sub_accounts (
  accounts_id = 45,              // Fixed Deposits
  organization_id = 'org-123',
  members_id = 1234,             // Same member
  sub_accounts_no = 'FD001235',  // New FD number
  name = 'Rajesh Kumar - FD Transfer',
  status = '1',
  opened_date = '2024-01-15'
)
```

**Step 3: Create New FD Account**
```
Table: fd_accounts
INSERT INTO fd_accounts (
  organization_id = 'org-123',
  sub_accounts_id = 301,         // From step 2
  fd_schemes_id = 5,
  members_id = 1234,
  fd_amount = 15000,
  interest_rate = 8.00,
  tenure_months = 12,
  open_date = '2024-01-15',
  maturity_date = '2025-01-15',
  maturity_amount = 16200,       // Calculated
  receipt_no = 'FD001235',
  status = '1'
)
```

**Step 4: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401150005',
  transaction_date = '2024-01-15',
  transaction_type = 'INTERNAL_TRANSFER_SAVINGS_TO_FD',
  reference_type = 'TRANSFER',
  reference_id = 'SAV001234_TO_FD001235',
  total_amount = 15000,
  description = 'Transfer from SAV001234 to FD001235',
  created_by = 'user123'
)
```

**Step 5: Create Transaction Details**
```
Table: transaction_details
-- Entry 1: Debit Source Savings Account
INSERT INTO transaction_details (
  transaction_head_id = 506,
  organization_id = 'org-123',
  accounts_id = 46,              // Savings Deposits
  sub_accounts_id = 87,          // Source savings sub-account
  debit_amount = 15000,
  credit_amount = 0,
  particulars = 'Transfer from savings - SAV001234'
)

-- Entry 2: Credit Destination FD Account
INSERT INTO transaction_details (
  transaction_head_id = 506,
  organization_id = 'org-123',
  accounts_id = 45,              // Fixed Deposits
  sub_accounts_id = 301,         // New FD sub-account
  debit_amount = 0,
  credit_amount = 15000,
  particulars = 'FD created from transfer - FD001235'
)
```

---

### Scenario 7: Staff Salary Payment

**Business Action**: Pay monthly salary ₹250,000 to all staff via bank transfer

**Step 1: Create Individual Payroll Records**
```
Table: staff_payroll  // Optional detailed tracking
INSERT INTO staff_payroll (
  organization_id = 'org-123',
  employee_id = 'EMP001',
  salary_month = '2024-01',
  basic_salary = 45000,
  allowances = 5000,
  gross_salary = 50000,
  deductions = 5000,
  net_salary = 45000,
  payment_date = '2024-01-31',
  payment_method = 'BANK_TRANSFER'
)
-- Repeat for each employee
```

**Step 2: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401310002',
  transaction_date = '2024-01-31',
  transaction_type = 'STAFF_SALARY_PAYMENT',
  reference_type = 'PAYROLL',
  reference_id = '2024-01',       // Salary month
  total_amount = 250000,
  description = 'Staff salary payment - January 2024',
  created_by = 'admin123'
)
```

**Step 3: Create Transaction Details**
```
Table: transaction_details
-- Entry 1: Debit Salary Expense
INSERT INTO transaction_details (
  transaction_head_id = 507,
  organization_id = 'org-123',
  accounts_id = 70,              // Staff Salary expense account
  sub_accounts_id = 55,          // Org salary expense sub-account
  debit_amount = 250000,
  credit_amount = 0,
  particulars = 'Staff salary expense - January 2024'
)

-- Entry 2: Credit Bank Account
INSERT INTO transaction_details (
  transaction_head_id = 507,
  organization_id = 'org-123',
  accounts_id = 10,              // Cash & Bank
  sub_accounts_id = 26,          // Org bank sub-account (selected by user)
  debit_amount = 0,
  credit_amount = 250000,
  particulars = 'Salary paid via bank transfer - January 2024'
)
```

---

### Scenario 8: Loan Write-Off

**Business Action**: Write off ₹75,000 bad debt loan

**Step 1: Update Loan Status**
```
Table: loan_accounts
UPDATE loan_accounts 
SET status = '3',                    // Status: Written Off
    outstanding_balance = 0,
    write_off_date = '2024-01-15',
    write_off_amount = 75000,
    write_off_reason = 'Member Deceased',
    last_modified_by = 'manager123'
WHERE loan_accounts_id = 91
```

**Step 2: Create Write-Off Record**
```
Table: loan_write_offs  // Optional detailed tracking
INSERT INTO loan_write_offs (
  organization_id = 'org-123',
  loan_accounts_id = 91,
  write_off_date = '2024-01-15',
  principal_amount = 75000,
  interest_amount = 8500,
  total_write_off = 83500,
  reason = 'Member Deceased',
  approval_reference = 'BOARD_RES_2024_05',
  approved_by = 'manager123'
)
```

**Step 3: Create Transaction Head**
```
Table: transaction_head
INSERT INTO transaction_head (
  organization_id = 'org-123',
  transaction_no = 'TXN202401150006',
  transaction_date = '2024-01-15',
  transaction_type = 'LOAN_WRITE_OFF_BAD_DEBT',
  reference_type = 'LOAN_ACCOUNT',
  reference_id = '91',
  total_amount = 75000,
  description = 'Loan write-off - LOAN001234',
  created_by = 'manager123'
)
```

**Step 4: Create Transaction Details**
```
Table: transaction_details
-- Entry 1: Debit Bad Debt Expense
INSERT INTO transaction_details (
  transaction_head_id = 508,
  organization_id = 'org-123',
  accounts_id = 75,              // Bad Debt Expense account
  sub_accounts_id = 58,          // Org bad debt expense sub-account
  debit_amount = 75000,
  credit_amount = 0,
  particulars = 'Bad debt expense - LOAN001234 written off'
)

-- Entry 2: Credit Loan Account
INSERT INTO transaction_details (
  transaction_head_id = 508,
  organization_id = 'org-123',
  accounts_id = 28,              // Member Loans
  sub_accounts_id = 201,         // Member's loan sub-account
  debit_amount = 0,
  credit_amount = 75000,
  particulars = 'Loan account written off - LOAN001234'
)
```

---

## Key Points for Business Analysts

### Account Resolution Logic:
1. **Member Accounts**: Found by querying `sub_accounts` where `members_id = selected_member`
2. **GL Accounts**: Found by querying `accounts` where `account_type = predefined_code` and `memberwise_acc = '0'`
3. **Organization Accounts**: Sub-accounts where `members_id = 0`

### Transaction Numbering:
- Format: `TXN + YYYYMMDD + Sequential Number`
- Example: `TXN202401150001` = Transaction on Jan 15, 2024, sequence 1

### Data Validation Points:
1. **Balance Checks**: Query current balance before debiting
2. **Account Status**: Ensure accounts are active (`status = '1'`)
3. **Amount Matching**: Total debits = Total credits in transaction_details
4. **Reference Integrity**: All foreign keys must exist

### Audit Trail Requirements:
- Every INSERT/UPDATE must have `created_by` or `last_modified_by`
- Timestamp fields (`created_at`, `last_modified_on`) auto-populated
- Original transaction data never deleted, only status updated

This technical guide provides the exact database operations needed for each business scenario in the microfinance application.
