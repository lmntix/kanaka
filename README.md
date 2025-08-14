# Kanaka Microfinance App - Database Documentation

**Last Updated**: August 14, 2025  
**Database Stats**: 3,821 members | 3,282 loan accounts | 50,906 transactions | 229 chart of accounts

## Overview

This document provides comprehensive documentation for the Kanaka microfinance application database. The system is built on a sophisticated cooperative banking model supporting multiple financial products with complete double-entry accounting.

---

## 🏗️ Core Architecture

### 1. Member Management System

**Core Member Tables:**

- **`members`** (3,821 records): Central customer database with KYC, personal details
- **`member_address_contact`**: Current address information
- **`member_address_permanent`**: Permanent address details
- **`member_kyc_document`**: Document verification and compliance tracking
- **`member_approval`**: Member onboarding and approval workflow
- **`employees`** (11 records): Staff management linked to member records

**Organizational Structure:**

- **`branch`**: Multi-branch operations support
- **`offices`**: Physical office/branch locations
- **`city`** (2,404 records): Location master for addresses

### 2. Chart of Accounts System

**Account Hierarchy:**

- **`account_groups`** (33 records): Primary classifications
  - Assets, Liabilities, Income, Expenses
  - Examples: "Asset", "Current Liabilities", "Interest Income"
- **`accounts`** (229 records): Master chart of accounts
  - "Shares", "Member Loan", "Fixed Deposit", "Member Loan Interest"
  - "Dividend Payable", "Interest Receivable", "Penal Interest"
- **`sub_accounts`**: Member-specific account instances
  - Links individual members to account heads
  - Enables member-wise balance tracking
- **`sub_accounts_balance`**: Real-time running balances

**Financial Framework:**

- **`financial_years`**: Fiscal year management and period control
- **`calender`** (3,807 records): Business day calendar for operations
  - Holiday management, working days, session control
- **`calender_details`** (2,886 records): Daily session management

### 3. Financial Products

#### **Loan Management System**

- **`loan_schemes`**: Loan product configurations (interest rates, tenure, eligibility)
- **`loan_accounts`** (3,282 active): Individual member loan records
  - Loan amounts, disbursement dates, repayment schedules
  - Status tracking, guarantor information
- **`loan_charges`**: Fee structure per loan scheme
- **`loan_nominee`**: Guarantor and nominee details
- **`loan_disbursement`**: Loan payout tracking and history
- **`loan_repayment`**: Payment collection records
- **`loan_schedule`**: EMI schedule generation and tracking

#### **Savings Products**

- **`saving_schemes`**: Savings product definitions and rules
- **`saving_accounts`**: Member savings account management
- **`saving_charges`**: Service charges and fees for savings
- **`saving_nominee`**: Nominee information for savings accounts

#### **Fixed Deposits**

- **`fd_schemes`**: FD product configurations (rates, tenure, compounding)
- **`fd_accounts`** (303 active): Individual FD investments
  - Principal amount, maturity calculations, renewal options
- **`fd_charges`**: Associated fees and charges
- **`fd_nominee`**: FD nominee management

#### **Recurring Deposits**

- **`recurring_schemes`**: RD product setup and rules
- **`recurring_accounts`**: Member RD account tracking
- **`recurring_charges`**: RD-related fees and charges

### 4. Transaction Processing Engine

**Core Transaction System (50,906 transactions):**

- **`transaction_head`**: Transaction header with complete audit trail
  ```sql
  -- Sample transaction structure
  {
    "transaction_head_id": 45701,
    "voucher_no": "1358",
    "trans_date": "05/04/2015",
    "trans_amount": "60",
    "trans_narration": "wrongly trf entries correction",
    "users_id": "Pooja",
    "branch_id": 51976
  }
  ```
- **`transaction_details`**: Double-entry transaction lines (Dr/Cr entries)
  - Every transaction follows accounting equation: Assets = Liabilities + Equity
  - Maintains complete audit trail with account-wise impact

**Transaction Management:**

- **`voucher_master`**: Transaction types (Receipt, Payment, Journal, Transfer)
- **`users`**: User management for transaction authorization
- **`account_close`** (4,111 records): Account closure tracking

### 5. Interest Calculation & Posting System

**Interest Accrual Engine:**

- **`accrued_interest`** (40 active records): Daily interest calculations
  ```sql
  -- Interest calculation example
  {
    "accounts_id": 64,
    "sub_accounts_id": 4000,
    "int_date": "2017-03-31",
    "int_rate": "4.0",
    "balance": "2173.0000",
    "int_amount": "87.0000"  -- Calculated interest
  }
  ```

**Interest Posting Workflow:**

1. **Daily Calculation**: System computes interest on outstanding balances
2. **Accrual Storage**: Results stored in `accrued_interest`
3. **Periodic Posting**: Interest transferred to member accounts
4. **Transaction Recording**: Double-entry posted via `transaction_head/details`

**Interest Formula Used:**

```
int_amount = (balance × int_rate × days) / (365 × 100)
```

### 6. Banking & Payment Integration

**Bank Management:**

- **`bank`**: Bank master data (name, code)
- **`bank_branch`**: Branch details with IFSC, MICR codes
- **`bank_accounts`** (2 records): Institution's operational bank accounts
  - Account numbers, branch details, account types
  - Links to `sub_accounts` for GL integration

**Cheque Management System:**

- **`cheque_register`** (33,304 records): Complete cheque book management
  - Issue dates, payee details, amounts, clearance tracking
- **`cheque_in`** (28,389 records): Incoming cheque processing
- **`cheque_transactions`** (33,304 records): Cheque-to-transaction mapping
- **`cheque_return`**: Returned cheque handling

### 7. Charges & Fee Management

**Fee Structure:**

- **`charges`**: Master fee definitions (charge types, amounts, percentages)
- **Product-Specific Charges:**
  - **`loan_charges`**: Loan processing fees, service charges
  - **`saving_charges`**: Savings account maintenance fees
  - **`fd_charges`**: Fixed deposit premature withdrawal penalties
  - **`recurring_charges`**: RD-related service charges

**Charge Application:**

- Automated fee calculation based on product rules
- Integration with transaction system for fee posting

### 8. Member Services & Equity Management

**Share Capital System:**

- **`share_accounts`**: Member equity shareholding
- **`dividend_resolutions`** (10 records): Board-approved dividend declarations
  - Dividend percentages, record dates, resolution details
- **`dividend_register`** (18,471 records): Member-wise dividend calculations
  - Share balances, dividend amounts, warrant details
- **`dividend_paid`** (13,725 records): Actual dividend payment tracking
- **`dividend_setting`**: Dividend calculation parameters and rules

**Categories & Classification:**

- **`category`** (10 records): Member/account categorization for reporting
- **`tds_exemptions`**: Tax deduction management for interest/dividends

---

## 💼 Key Microfinance Operations

### Interest Posting Process

**Daily Interest Accrual:**

```sql
-- Example: Savings interest calculation
INSERT INTO accrued_interest (
  accounts_id, sub_accounts_id, int_date,
  int_rate, balance, int_amount
) VALUES (
  64, 4000, '2017-03-31',
  4.0, 2173.0000, 87.0000
);
```

**Monthly Interest Posting:**

1. **Loan Interest**: Debit Interest Receivable → Credit Interest Income
2. **Savings Interest**: Debit Interest Expense → Credit Member Savings
3. **FD Interest**: Debit Interest Expense → Credit FD Account

### Complete Loan Lifecycle

**1. Application Process:**

- Member applies → `loan_accounts` created
- Documentation → `loan_nominee`, guarantor details
- Approval workflow → `member_approval`

**2. Loan Disbursement:**

```sql
-- Transaction entries for loan disbursement
transaction_head: {
  "voucher_no": "LN001",
  "trans_amount": "50000",
  "trans_narration": "Loan disbursed to member"
}

transaction_details: [
  {"account": "Member Loan", "debit": 50000},      -- Asset increase
  {"account": "Cash", "credit": 50000}             -- Asset decrease
]
```

**3. EMI Collection:**

```sql
-- Monthly EMI payment
transaction_details: [
  {"account": "Cash", "debit": 5500},                    -- Cash received
  {"account": "Member Loan", "credit": 5000},           -- Principal repaid
  {"account": "Interest Income", "credit": 500}         -- Interest earned
]
```

### Savings Operations

**Deposit Transaction:**

```sql
transaction_details: [
  {"account": "Cash", "debit": 1000},                    -- Cash received
  {"account": "Member Savings", "credit": 1000}         -- Liability increase
]
```

**Interest Credit:**

```sql
transaction_details: [
  {"account": "Interest Expense", "debit": 40},          -- Expense
  {"account": "Member Savings", "credit": 40}           -- Member benefit
]
```

### Dividend Distribution

**Board Resolution → Member Calculation → Payment:**

```sql
-- Dividend payment entry
transaction_details: [
  {"account": "Dividend Payable", "debit": 500},        -- Liability decrease
  {"account": "Cash", "credit": 500}                    -- Cash paid
]
```

---

## 📊 Reporting & Analytics

### Financial Statements

- **`bs`** (237 records): Balance sheet preparation with account-wise balances
- **`profit_loss`**: P&L statement generation
- **`trial_balance`**: Account balance verification

### Member Reports

- Individual account statements via `sub_accounts_balance`
- Loan aging reports from `loan_accounts`
- Interest earning statements from `accrued_interest`

### Operational Reports

- Daily cash position from bank reconciliation
- Portfolio quality analysis
- Member growth and retention metrics

---

## 🔧 Technical Architecture

### Database Design Patterns

1. **Member-Centric Design**: Every financial product links to members
2. **Double-Entry Compliance**: All transactions maintain accounting equation
3. **Audit Trail**: Complete transaction history with user tracking
4. **Product Flexibility**: Scheme-based product configuration
5. **Interest Automation**: Systematic interest calculation and posting

### Performance Considerations

- **50,906 transactions** - Requires efficient indexing
- **3,821 members** with multiple accounts - Normalized design
- **Daily interest calculations** - Batch processing optimization

### Data Integrity

- Foreign key relationships maintain referential integrity
- Transaction amount validation ensures balanced entries
- Date-based constraints for financial year operations

---

## 🚀 System Capabilities

✅ **Multi-product support** (Loans, Savings, FD, RD, Shares)  
✅ **Complete accounting integration** (Double-entry system)  
✅ **Interest automation** (Daily calculation, periodic posting)  
✅ **Member lifecycle management** (Onboarding to services)  
✅ **Banking integration** (Cheque management, bank reconciliation)  
✅ **Regulatory compliance** (Financial statements, audit trails)  
✅ **Multi-branch operations** (Branch-wise transaction control)  
✅ **Dividend management** (Share-based dividend distribution)

---

## 📋 Next Steps for Deep Dive

For detailed exploration of specific areas:

1. **Interest Calculation Algorithms** - Daily/monthly calculation mechanics
2. **Transaction Processing Workflows** - Step-by-step double-entry flows
3. **Member Account Management** - Account opening, maintenance, closure
4. **Product Configuration** - Setting up new loan/savings schemes
5. **Month-End Processing** - Period-end calculations and closures
6. **Report Generation** - Financial statement and regulatory report logic

**Database Statistics Summary:**

- **Members**: 3,821 active
- **Loan Accounts**: 3,282 active
- **FD Accounts**: 303 active
- **Transactions**: 50,906 total
- **Chart of Accounts**: 229 account heads
- **Cheque Records**: 33,304 managed

This comprehensive microfinance system handles all core cooperative banking operations with robust financial controls and member service capabilities.

---

## 🔄 Interest Posting System - Complete Guide

### Overview of Interest Posting Tables

Your microfinance app has **four specialized interest posting tables**, each handling interest calculations and postings for different account types:

| Table                         | Purpose                         | Records | Transaction Flow    |
| ----------------------------- | ------------------------------- | ------- | ------------------- |
| **`loan_interest_post`**      | Loan interest accrual & posting | 148,953 | Asset → Income      |
| **`saving_interest_post`**    | Savings interest payment        | 221     | Expense → Liability |
| **`fd_interest_post`**        | Fixed deposit interest          | 556     | Expense → Liability |
| **`recurring_interest_post`** | Recurring deposit interest      | 18,716  | Expense → Liability |

### Table Structure (Common Fields)

Each interest posting table follows the same structure:

```sql
-- Common structure for all *_interest_post tables
{
  "[product]_interest_post_id": "Primary key",
  "sub_accounts_id": "Links to specific member account",
  "transaction_head_id": "Links to actual GL transaction",
  "amount": "Interest amount calculated/posted",
  "int_date": "Interest calculation/posting date",
  "rate": "Interest rate applied",
  "posting": "Status code (1=Posted, 2=Calculated, etc.)",
  "changed_manually": "Manual override flag (0/1)"
}
```

### Interest Posting Workflow

#### **1. Loan Interest Posting (`loan_interest_post`)**

**Purpose**: Charges interest on outstanding loans

**Accounting Entry**:

```sql
-- Example: ₹20 interest on loan account 4088
Dr. Member Loan Interest Receivable (A/c 223)  ₹20.00
    Cr. Weekly Loan Principal (A/c 222)       ₹20.00
```

**Data Flow**:

```sql
-- Step 1: Calculate interest
INSERT INTO loan_interest_post (
  sub_accounts_id, amount, int_date, rate, posting
) VALUES (
  4088, 20.0000, '2015-04-05', 15.0, '2'  -- Status: Calculated
);

-- Step 2: Create GL transaction
INSERT INTO transaction_head (
  trans_amount, trans_narration, trans_date
) VALUES (
  20.0000, 'Interest upto 05.04.2015', '05/04/2015'
);

-- Step 3: Post double-entry
INSERT INTO transaction_details VALUES
  (transaction_head_id, 223, 4088, 20.0000),    -- Dr. Interest Receivable
  (transaction_head_id, 222, 4088, -20.0000);   -- Cr. Loan Principal

-- Step 4: Update posting status
UPDATE loan_interest_post
SET posting = '1', transaction_head_id = [new_id]
WHERE loan_interest_post_id = [record_id];
```

**Key Points**:

- **High volume**: 148,953 records (most active)
- **Rate example**: 15% annual rate
- **Increases** loan receivable (asset)
- **Reduces** loan principal (asset)

#### **2. Savings Interest Posting (`saving_interest_post`)**

**Purpose**: Credits interest to member savings accounts

**Accounting Entry**:

```sql
-- Example: ₹40 interest credit to savings
Dr. Interest Expense (A/c XXX)           ₹40.00
    Cr. Member Savings Account (A/c 64)      ₹40.00
```

**Data Flow**:

```sql
-- Interest posting for savings
INSERT INTO saving_interest_post (
  sub_accounts_id, amount, int_date, rate, posting
) VALUES (
  3893, 40.0000, '2016-03-31', 4.0, '1'  -- Status: Posted
);
```

**Key Points**:

- **Low volume**: 221 records
- **Rate example**: 4% annual rate
- **Creates expense** for the institution
- **Increases member savings** balance

#### **3. Fixed Deposit Interest Posting (`fd_interest_post`)**

**Purpose**: Credits interest on FD accounts

**Accounting Entry**:

```sql
-- Example: ₹13,629 FD interest
Dr. Interest Expense (A/c XXX)           ₹13,629.00
    Cr. Member FD Account (A/c 25)           ₹13,629.00
```

**Data Flow**:

```sql
-- FD interest posting
INSERT INTO fd_interest_post (
  sub_accounts_id, amount, int_date, rate, posting
) VALUES (
  1812, 13629.0000, '2016-03-31', 11.5, '1'
);
```

**Key Points**:

- **Medium volume**: 556 records
- **Highest rates**: 11.5% (attractive FD rates)
- **Large amounts**: Up to ₹13,629 per posting
- **Automatic posting** (`changed_manually = 0`)

#### **4. Recurring Deposit Interest Posting (`recurring_interest_post`)**

**Purpose**: Credits interest on RD accounts

**Accounting Entry**:

```sql
-- Example: RD interest credit
Dr. Interest Expense (A/c XXX)           ₹Amount
    Cr. Member RD Account (A/c XXX)          ₹Amount
```

**Data Flow**:

```sql
-- RD interest posting
INSERT INTO recurring_interest_post (
  sub_accounts_id, amount, int_date, rate, posting
) VALUES (
  1774, 0.0000, '2015-03-31', 10.0, '2'
);
```

**Key Points**:

- **High volume**: 18,716 records
- **Rate example**: 10% annual rate
- **Status '2'**: Different posting logic
- **Monthly processing**: Regular interval postings

### Interest Posting Status Codes

| Status Code | Meaning        | Action                                     |
| ----------- | -------------- | ------------------------------------------ |
| **'1'**     | **Posted**     | Interest posted to GL, transaction created |
| **'2'**     | **Calculated** | Interest calculated but not yet posted     |
| **'3'**     | **Pending**    | Awaiting approval/processing               |
| **'4'**     | **Adjustment** | Manual adjustment or correction            |

### Setting Up Interest Posting in Your App

#### **1. Monthly Interest Calculation Job**

```sql
-- Pseudo-code for interest calculation
CREATE OR REPLACE FUNCTION calculate_monthly_interest()
RETURNS void AS $$
BEGIN
  -- Calculate loan interest
  INSERT INTO loan_interest_post (
    sub_accounts_id, amount, int_date, rate, posting
  )
  SELECT
    la.sub_accounts_id,
    (outstanding_balance * interest_rate * days_in_month / 365 / 100),
    CURRENT_DATE,
    ls.interest_rate,
    '2'  -- Calculated status
  FROM loan_accounts la
  JOIN loan_schemes ls ON la.loan_schemes_id = ls.loan_schemes_id
  WHERE la.status = 'ACTIVE';

  -- Similar logic for savings, FD, RD...
END;
$$ LANGUAGE plpgsql;
```

#### **2. Interest Posting to GL**

```sql
-- Post calculated interest to general ledger
CREATE OR REPLACE FUNCTION post_interest_to_gl()
RETURNS void AS $$
DECLAREipayment_rec RECORD;
BEGIN
  -- Process loan interest postings
  FOR interest_rec IN
    SELECT * FROM loan_interest_post WHERE posting = '2'
  LOOP
    -- Create transaction header
    INSERT INTO transaction_head (
      trans_amount, trans_narration, trans_date, users_id
    ) VALUES (
      interest_rec.amount,
      'Loan Interest - ' || interest_rec.int_date,
      interest_rec.int_date,
      'SYSTEM'
    ) RETURNING transaction_head_id INTO NEW_TRANS_ID;

    -- Create transaction details (double-entry)
    INSERT INTO transaction_details VALUES
      (NEW_TRANS_ID, 223, interest_rec.sub_accounts_id, interest_rec.amount),   -- Dr. Interest Receivable
      (NEW_TRANS_ID, 222, interest_rec.sub_accounts_id, -interest_rec.amount);  -- Cr. Loan Account

    -- Update posting status
    UPDATE loan_interest_post
    SET posting = '1', transaction_head_id = NEW_TRANS_ID
    WHERE loan_interest_post_id = interest_rec.loan_interest_post_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

#### **3. App Integration Points**

**Daily Operations**:

```javascript
// Frontend: Interest accrual display
const getAccruedInterest = async (memberAccountId) => {
  const result = await query(
    `
    SELECT ai.int_amount as accrued_amount,
           ai.int_date as last_calculation
    FROM accrued_interest ai
    WHERE ai.sub_accounts_id = $1
    ORDER BY ai.int_date DESC LIMIT 1
  `,
    [memberAccountId]
  );

  return result.rows[0];
};
```

**Monthly Processing**:

```javascript
// Backend: Monthly interest posting
const processMonthlyInterest = async (processingDate) => {
  // 1. Calculate interest for all active accounts
  await db.query("SELECT calculate_monthly_interest()");

  // 2. Generate approval report
  const pendingInterest = await db.query(`
    SELECT * FROM loan_interest_post WHERE posting = '2'
  `);

  // 3. After approval, post to GL
  await db.query("SELECT post_interest_to_gl()");

  // 4. Update member balances
  await updateMemberBalances();
};
```

### Best Practices for Implementation

#### **1. Transaction Safety**

- **Always use database transactions** for interest posting
- **Validate double-entry balance** before committing
- **Maintain audit trail** with user stamps

#### **2. Error Handling**

- **Rollback capability** for incorrect postings
- **Manual override flags** for corrections
- **Approval workflow** for large amounts

#### **3. Performance Optimization**

- **Batch processing** for large volumes
- **Index on `sub_accounts_id`** for quick lookups
- **Archive old records** to maintain performance

#### **4. Compliance & Reporting**

- **Interest register reports** from posting tables
- **Member-wise interest statements**
- **Regulatory compliance** tracking

This interest posting system provides complete automation of interest calculations while maintaining full audit trails and accounting accuracy across all financial products in your microfinance application.

---

## 📚 Complete Account Type Functionality Guide

### 1️⃣ **SAVINGS ACCOUNTS SYSTEM**

#### **Database Schema**

```sql
-- saving_schemes: Product configuration
{
  saving_schemes_id: 1,
  accounts_id: 64,           -- GL account link
  name: "Saving Account",
  type: "2",                 -- Account type
  min_balance: 100.00,       -- Minimum balance requirement
  max_withdrawal: 1000000.00,
  min_withdrawal: 100.00,
  max_deposit: 1000000.00,
  min_deposit: 100.00,
  interest_calc: "1",        -- Interest calculation method
  transaction_limit: 0,      -- 0 = unlimited
  min_int_setting: "2",      -- Minimum interest setting
  status: "1"                -- Active
}

-- saving_accounts: Individual member accounts
{
  saving_accounts_id: 1,
  sub_accounts_id: 3893,     -- Links to sub_accounts
  saving_schemes_id: 1,      -- Product link
  members_id: 191,           -- Member link
  open_date: "2015-03-31",
  interest_rate: 4.0,        -- 4% annual
  tds_apply: "0",            -- Tax deduction at source
  status: "4"                -- Status codes: 1=Active, 4=Closed
}
```

#### **Interest Posting Process**

```sql
-- STEP 1: Calculate monthly interest
INSERT INTO saving_interest_post (
  sub_accounts_id, amount, int_date, rate, posting
)
SELECT
  sa.sub_accounts_id,
  ROUND((sab.balance * sa.interest_rate * 30) / 36500, 2) as interest,
  '2016-03-31',
  sa.interest_rate,
  '2'  -- Calculated status
FROM saving_accounts sa
JOIN sub_accounts_balance sab ON sa.sub_accounts_id = sab.sub_accounts_id
WHERE sa.status = '1';

-- STEP 2: Post to GL (creates transaction)
-- Real example: ₹84 interest on account 4000

-- Transaction Header
INSERT INTO transaction_head VALUES (
  45695,                     -- transaction_head_id
  '31/03/2016',             -- trans_date
  'Interest upto 31.03.2016',
  84.00                      -- trans_amount
);

-- Transaction Details (Double-entry)
INSERT INTO transaction_details VALUES
  (110301, 45695, 64, 4000, 84.00),    -- Cr. Saving Account (Liability increases)
  (110302, 45695, 65, 4000, -84.00);   -- Dr. Saving Interest Expense

-- STEP 3: Update posting status
UPDATE saving_interest_post
SET posting = '1', transaction_head_id = 45695
WHERE saving_interest_post_id = 74;
```

#### **Configuration in App**

```javascript
// Frontend Configuration Component
const SavingsSchemeConfig = {
  // Basic Settings
  scheme_name: "Regular Savings",
  gl_account_id: 64, // Link to chart of accounts

  // Interest Settings
  interest_rate: 4.0, // Annual percentage
  interest_calc_method: {
    1: "Daily Balance", // Calculate on daily balance
    2: "Monthly Average", // Calculate on average balance
    3: "Minimum Balance", // Calculate on minimum balance
  },
  interest_posting_frequency: "Monthly",

  // Transaction Limits
  min_balance: 100.0,
  max_withdrawal_per_transaction: 1000000.0,
  min_withdrawal: 100.0,
  transaction_limit_per_month: 0, // 0 = unlimited

  // Tax Settings
  tds_applicable: false,
  tds_rate: 10.0, // If TDS applicable

  // Status
  active: true,
};

// Backend Interest Calculation Service
class SavingsInterestService {
  async calculateMonthlyInterest(processingDate) {
    // Get all active savings accounts
    const accounts = await db.query(`
      SELECT sa.*, sab.balance 
      FROM saving_accounts sa
      JOIN sub_accounts_balance sab ON sa.sub_accounts_id = sab.sub_accounts_id
      WHERE sa.status = '1'
    `);

    for (const account of accounts) {
      // Calculate interest based on method
      const interest = this.calculateInterest(
        account.balance,
        account.interest_rate,
        30 // Days in month
      );

      // Insert into posting table
      await db.query(
        `
        INSERT INTO saving_interest_post 
        (sub_accounts_id, amount, int_date, rate, posting)
        VALUES ($1, $2, $3, $4, '2')
      `,
        [
          account.sub_accounts_id,
          interest,
          processingDate,
          account.interest_rate,
        ]
      );
    }
  }

  calculateInterest(balance, rate, days) {
    return (balance * rate * days) / 36500; // 365 * 100
  }
}
```

---

### 2️⃣ **FIXED DEPOSIT (FD) SYSTEM**

#### **Database Schema**

```sql
-- fd_schemes: FD Product Types
{
  fd_schemes_id: 1,
  accounts_id: 34,             -- GL account
  name: "Fixed Deposit",
  type: "1",                   -- 1=Regular, 2=Double, 4=MIS
  interest_type: "2",          -- 1=Simple, 2=Compound
  compounding: "4",            -- 1=Monthly, 2=Quarterly, 4=Yearly
  multiplier: 0.0,             -- For double deposit schemes
  int_rate_after_mat: 0.0,     -- Post-maturity rate
  auto_renewal: "0",           -- Auto renewal flag
  broken_period: "365",        -- Days calculation method
  int_rate_snr_citizen: 0.5    -- Senior citizen additional rate
}

-- fd_accounts: Individual FD Accounts
{
  fd_accounts_id: 10,
  sub_accounts_id: 1785,
  fd_schemes_id: 1,
  members_id: 331,
  tenure_months: 12,
  fd_amount: 14202.00,
  open_date: "2014-03-31",
  interest_rate: 10.0,
  maturity_date: "2015-03-31",
  maturity_amount: 15622.00,   -- Pre-calculated
  receipt_no: "1120",
  reinvest_interest: "0",       -- 0=Pay out, 1=Reinvest
  tds_apply: "0",
  status: "1"                   -- 1=Active, 2=Matured, 3=Closed
}
```

#### **Maturity Calculation**

```sql
-- Compound Interest Formula
-- A = P(1 + r/n)^(nt)
-- Where: P=Principal, r=Rate, n=Compounding frequency, t=Time

CREATE FUNCTION calculate_fd_maturity(
  principal DECIMAL,
  rate DECIMAL,
  tenure_months INT,
  compounding INT
) RETURNS DECIMAL AS $$
DECLARE
  maturity_amount DECIMAL;
  n INT;  -- Compounding frequency per year
BEGIN
  -- Set compounding frequency
  n := CASE compounding
    WHEN 1 THEN 12  -- Monthly
    WHEN 2 THEN 4   -- Quarterly
    WHEN 4 THEN 1   -- Yearly
    ELSE 1
  END;

  -- Calculate maturity
  maturity_amount := principal * POWER(
    (1 + (rate/100/n)),
    (n * tenure_months/12)
  );

  RETURN ROUND(maturity_amount, 2);
END;
$$ LANGUAGE plpgsql;

-- Example: ₹14,202 @ 10% for 12 months = ₹15,622
SELECT calculate_fd_maturity(14202, 10.0, 12, 4);  -- Returns 15622.00
```

#### **Interest Posting Process**

```sql
-- FD Interest posting (Monthly/Quarterly)
INSERT INTO fd_interest_post (
  sub_accounts_id, amount, int_date, rate, posting
) VALUES (
  1812,       -- FD account
  13629.00,   -- Large interest amount
  '2016-03-31',
  11.5,       -- Higher rate for FD
  '1'         -- Posted status
);

-- GL Transaction for FD interest
INSERT INTO transaction_details VALUES
  (trans_id, 35, 1812, -13629.00),  -- Dr. FD Interest Expense
  (trans_id, 34, 1812, 13629.00);   -- Cr. FD Account (Liability)
```

#### **Configuration in App**

```javascript
// FD Scheme Configuration
const FDSchemeConfig = {
  // Product Settings
  scheme_name: "Regular Fixed Deposit",
  minimum_amount: 1000.0,
  maximum_amount: 10000000.0,

  // Tenure Options
  tenure_options: [
    { months: 6, rate: 8.5 },
    { months: 12, rate: 10.0 },
    { months: 24, rate: 10.5 },
    { months: 36, rate: 11.0 },
    { months: 60, rate: 11.5 },
  ],

  // Interest Settings
  interest_type: "Compound",
  compounding_frequency: "Quarterly",
  senior_citizen_bonus: 0.5,

  // Maturity Options
  auto_renewal: false,
  interest_payout_options: ["Monthly", "Quarterly", "At Maturity", "Reinvest"],

  // Premature Closure
  allow_premature_closure: true,
  penalty_rate: 1.0, // 1% penalty

  // Tax
  tds_applicable: true,
  tds_threshold: 40000.0,
};

// FD Maturity Calculator Service
class FDService {
  calculateMaturity(principal, rate, months, compounding = "quarterly") {
    const n = compounding === "quarterly" ? 4 : 12;
    const t = months / 12;

    const maturity = principal * Math.pow(1 + rate / 100 / n, n * t);

    return {
      principal: principal,
      interest: maturity - principal,
      maturityAmount: maturity,
      effectiveRate: (((maturity - principal) / principal) * 100) / t,
    };
  }

  async createFD(memberData) {
    const maturityCalc = this.calculateMaturity(
      memberData.amount,
      memberData.rate,
      memberData.tenure
    );

    // Create FD account
    const fd = await db.query(
      `
      INSERT INTO fd_accounts (
        members_id, fd_amount, tenure_months,
        interest_rate, maturity_date, maturity_amount
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING fd_accounts_id
    `,
      [
        memberData.memberId,
        memberData.amount,
        memberData.tenure,
        memberData.rate,
        maturityCalc.maturityDate,
        maturityCalc.maturityAmount,
      ]
    );

    return fd;
  }
}
```

---

### 3️⃣ **RECURRING DEPOSIT (RD) SYSTEM**

#### **Database Schema**

```sql
-- recurring_schemes: RD Products
{
  recurring_schemes_id: 1,
  accounts_id: 76,
  name: "Compulsary Deposit",
  interest_type: "1",           -- 1=Simple, 2=Compound
  compounding: "0",             -- 0=No compounding
  premat_close_penalty_rate: 0.0,
  missing_inst_penalty_rate: 0.0,
  status: "1"
}

-- recurring_accounts: Member RD Accounts
{
  recurring_accounts_id: 1,
  sub_accounts_id: 252,
  recurring_schemes_id: 1,
  members_id: 1,
  monthly_amount: 200.00,       -- Monthly installment
  period: 1000,                 -- Months (83 years!)
  interest_rate: 8.0,
  maturity_date: "2096-07-31",
  maturity_amount: 1034167.00,  -- Calculated maturity
  status: "1"
}
```

#### **RD Maturity Calculation**

```sql
-- RD Maturity Formula
-- M = P × n + P × n × (n+1) × r / (2 × 12 × 100)
-- Where: P=Monthly deposit, n=Months, r=Annual rate

CREATE FUNCTION calculate_rd_maturity(
  monthly_amount DECIMAL,
  months INT,
  annual_rate DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
  total_deposits DECIMAL;
  interest DECIMAL;
  maturity DECIMAL;
BEGIN
  -- Total deposits
  total_deposits := monthly_amount * months;

  -- Interest calculation (simplified)
  interest := (monthly_amount * months * (months + 1) * annual_rate) / (2 * 12 * 100);

  -- Maturity amount
  maturity := total_deposits + interest;

  RETURN ROUND(maturity, 2);
END;
$$ LANGUAGE plpgsql;

-- Example: ₹200/month for 60 months @ 8%
SELECT calculate_rd_maturity(200, 60, 8.0);  -- Returns ~13,920
```

#### **Monthly Processing**

```sql
-- Process monthly RD installments
CREATE PROCEDURE process_rd_installments(processing_date DATE)
AS $$
BEGIN
  -- Create transactions for each active RD
  INSERT INTO transaction_head (trans_date, trans_narration, trans_amount)
  SELECT
    processing_date,
    'RD Monthly Installment - ' || ra.recurring_accounts_id,
    ra.monthly_amount
  FROM recurring_accounts ra
  WHERE ra.status = '1';

  -- Post to member accounts
  INSERT INTO transaction_details
  SELECT
    th.transaction_head_id,
    1,  -- Cash account
    ra.sub_accounts_id,
    ra.monthly_amount  -- Dr. Cash
  FROM recurring_accounts ra
  JOIN transaction_head th ON ...

  UNION ALL

  SELECT
    th.transaction_head_id,
    76,  -- RD account
    ra.sub_accounts_id,
    -ra.monthly_amount  -- Cr. RD
  FROM recurring_accounts ra
  JOIN transaction_head th ON ...;
END;
$$ LANGUAGE plpgsql;
```

#### **Configuration in App**

```javascript
// RD Scheme Configuration
const RDSchemeConfig = {
  scheme_name: "Monthly Recurring Deposit",

  // Installment Settings
  minimum_installment: 100.0,
  maximum_installment: 50000.0,
  installment_multiples: 100, // Must be in multiples of 100

  // Tenure Options
  minimum_tenure_months: 6,
  maximum_tenure_months: 120,

  // Interest Settings
  interest_rates: [
    { months: 12, rate: 8.0 },
    { months: 24, rate: 8.5 },
    { months: 36, rate: 9.0 },
    { months: 60, rate: 9.5 },
    { months: 120, rate: 10.0 },
  ],

  // Penalties
  missed_installment_penalty: 2.0, // % of installment
  premature_closure_penalty: 1.0, // % reduction in interest

  // Grace Period
  grace_period_days: 10,
};

// RD Management Service
class RDService {
  async processMonthlyInstallments(processingDate) {
    const activeRDs = await db.query(`
      SELECT * FROM recurring_accounts 
      WHERE status = '1'
    `);

    for (const rd of activeRDs) {
      // Check if installment already paid
      const paid = await this.checkInstallmentPaid(rd.id, processingDate);

      if (!paid) {
        // Create installment transaction
        await this.createInstallmentTransaction(rd, processingDate);

        // Update account balance
        await this.updateRDBalance(rd.sub_accounts_id, rd.monthly_amount);
      }
    }
  }

  calculateMaturity(monthlyAmount, tenure, rate) {
    const totalDeposits = monthlyAmount * tenure;
    const interest =
      (monthlyAmount * tenure * (tenure + 1) * rate) / (2 * 12 * 100);

    return {
      totalDeposits,
      totalInterest: interest,
      maturityAmount: totalDeposits + interest,
      effectiveRate: (interest / totalDeposits) * 100,
    };
  }
}
```

---

### 4️⃣ **LOAN ACCOUNTS SYSTEM**

#### **Database Schema**

```sql
-- loan_schemes: Loan Products
{
  loan_schemes_id: 1,
  accounts_id: 4,              -- GL account
  name: "Member Loan",
  type: "2",                   -- Loan type
  int_days_month: "1",         -- Interest calculation
  installment_type: "2",       -- EMI type
  demand_loan: "0",            -- Demand loan flag
  rebate_rate: -1.0,           -- Early payment rebate
  penalty_on: "0",             -- Penalty calculation
  total_guarantors: 0,         -- Required guarantors
  status: "1"
}

-- loan_accounts: Individual Loans
{
  loan_accounts_id: 11,
  sub_accounts_id: 1940,
  loan_schemes_id: 1,
  members_id: 311,
  loan_amount: 2900.00,
  interest_rate: 14.0,         -- 14% annual
  open_date: "2014-12-09",
  first_installment_date: "2015-01-09",
  tenure: 48,                  -- Months
  installment_amt: 500.00,     -- Monthly EMI
  total_installments: 48,
  secured: "0",                -- 0=Unsecured, 1=Secured
  status: "1"                  -- 1=Active, 2=Closed, 3=NPA
}
```

#### **EMI Calculation**

```sql
-- EMI Formula: E = P × r × (1+r)^n / ((1+r)^n - 1)
CREATE FUNCTION calculate_emi(
  principal DECIMAL,
  annual_rate DECIMAL,
  tenure_months INT
) RETURNS DECIMAL AS $$
DECLARE
  monthly_rate DECIMAL;
  emi DECIMAL;
BEGIN
  monthly_rate := annual_rate / 12 / 100;

  emi := principal * monthly_rate * POWER(1 + monthly_rate, tenure_months) /
         (POWER(1 + monthly_rate, tenure_months) - 1);

  RETURN ROUND(emi, 2);
END;
$$ LANGUAGE plpgsql;

-- Example: ₹100,000 @ 14% for 48 months
SELECT calculate_emi(100000, 14, 48);  -- Returns ~2,734
```

#### **Loan Interest Posting**

```sql
-- Daily interest accrual on loans
INSERT INTO loan_interest_post (
  sub_accounts_id, amount, int_date, rate, posting, due_amount
)
SELECT
  la.sub_accounts_id,
  ROUND((outstanding * la.interest_rate) / 36500, 2),  -- Daily interest
  CURRENT_DATE,
  la.interest_rate,
  '2',  -- Calculated
  0     -- Due amount
FROM loan_accounts la
JOIN (
  SELECT
    sub_accounts_id,
    loan_amount - COALESCE(SUM(principal_paid), 0) as outstanding
  FROM loan_repayments
  GROUP BY sub_accounts_id
) bal ON la.sub_accounts_id = bal.sub_accounts_id
WHERE la.status = '1';

-- Monthly interest posting to GL
-- Real example: ₹20 interest on Weekly Loan
INSERT INTO transaction_details VALUES
  (4537, 223, 4088, 20.00),    -- Dr. Loan Interest Receivable
  (4537, 222, 4088, -20.00);   -- Cr. Weekly Loan (reduces principal)
```

#### **Configuration in App**

```javascript
// Loan Scheme Configuration
const LoanSchemeConfig = {
  scheme_name: "Personal Loan",

  // Loan Limits
  minimum_amount: 10000.0,
  maximum_amount: 5000000.0,

  // Interest Settings
  interest_rate_range: {
    minimum: 12.0,
    maximum: 18.0,
  },
  interest_calculation: "Reducing Balance",

  // Tenure
  minimum_tenure_months: 6,
  maximum_tenure_months: 84,

  // Repayment
  repayment_frequency: ["Monthly", "Weekly", "Fortnightly"],

  // Security
  secured_loan: false,
  guarantors_required: 2,

  // Charges
  processing_fee: 2.0, // % of loan amount
  prepayment_charges: 2.0,
  penal_interest: 2.0, // Additional % on overdue

  // Documents Required
  required_documents: [
    "Identity Proof",
    "Address Proof",
    "Income Proof",
    "Bank Statements",
  ],
};

// Loan Management Service
class LoanService {
  async disburseLoan(loanData) {
    // Calculate EMI
    const emi = this.calculateEMI(
      loanData.amount,
      loanData.rate,
      loanData.tenure
    );

    // Create loan account
    const loan = await db.query(
      `
      INSERT INTO loan_accounts (
        members_id, loan_amount, interest_rate,
        tenure, installment_amt, open_date
      ) VALUES ($1, $2, $3, $4, $5, CURRENT_DATE)
      RETURNING loan_accounts_id, sub_accounts_id
    `,
      [loanData.memberId, loanData.amount, loanData.rate, loanData.tenure, emi]
    );

    // Create disbursement transaction
    await this.createDisbursementTransaction(loan, loanData.amount);

    // Generate repayment schedule
    await this.generateRepaymentSchedule(
      loan.loan_accounts_id,
      emi,
      loanData.tenure
    );

    return loan;
  }

  async processEMI(loanId, paymentAmount) {
    const loan = await db.query(
      "SELECT * FROM loan_accounts WHERE loan_accounts_id = $1",
      [loanId]
    );

    // Calculate interest and principal components
    const outstanding = await this.getOutstandingBalance(loanId);
    const interestComponent = (outstanding * loan.interest_rate) / 1200;
    const principalComponent = paymentAmount - interestComponent;

    // Create repayment transaction
    const transId = await this.createTransaction({
      amount: paymentAmount,
      narration: `EMI Payment - Loan ${loanId}`,
    });

    // Post to GL
    await db.query(
      `
      INSERT INTO transaction_details VALUES
      ($1, 1, $2, $3),      -- Dr. Cash
      ($1, 4, $2, $4),      -- Cr. Loan Principal
      ($1, 5, $2, $5)       -- Cr. Interest Income
    `,
      [
        transId,
        loan.sub_accounts_id,
        paymentAmount,
        -principalComponent,
        -interestComponent,
      ]
    );

    // Update loan repayment record
    await db.query(
      `
      INSERT INTO loan_repayments (
        loan_accounts_id, payment_date, principal_paid,
        interest_paid, total_paid
      ) VALUES ($1, CURRENT_DATE, $2, $3, $4)
    `,
      [loanId, principalComponent, interestComponent, paymentAmount]
    );
  }
}
```

---

### 🔧 **CONFIGURATION CHECKLIST FOR APP SETUP**

#### **Global Settings**

```javascript
const GlobalConfig = {
  // Financial Year
  financial_year_start: "April 1",
  financial_year_end: "March 31",

  // Interest Posting
  interest_posting_day: 31, // Last day of month
  interest_calculation_basis: 365, // Days in year

  // Tax Settings
  tds_rate: 10.0,
  tds_threshold: 40000.0,

  // System Settings
  auto_interest_posting: true,
  require_approval_for_interest: false,
  batch_size_for_processing: 100,

  // Audit
  maintain_audit_trail: true,
  audit_retention_years: 7,
};
```

#### **Account Type Configuration Matrix**

| Feature                | Savings      | Fixed Deposit      | Recurring       | Loan          |
| ---------------------- | ------------ | ------------------ | --------------- | ------------- |
| **Interest Type**      | Simple       | Compound           | Simple/Compound | Reducing      |
| **Interest Frequency** | Monthly      | Quarterly/Maturity | Maturity        | Daily/Monthly |
| **Transaction Type**   | Credit/Debit | Credit Only        | Credit Monthly  | Debit (EMI)   |
| **Maturity**           | No           | Yes                | Yes             | Yes (Tenure)  |
| **Premature Closure**  | Yes          | Yes (Penalty)      | Yes (Penalty)   | Yes (Charges) |
| **TDS Applicable**     | Yes          | Yes                | Yes             | No            |
| **Minimum Balance**    | Yes          | No                 | No              | No            |
| **Installments**       | No           | No                 | Yes (Monthly)   | Yes (EMI)     |
| **GL Impact**          | Liability    | Liability          | Liability       | Asset         |

#### **Interest Posting Schedule**

```javascript
// Cron Job Configuration
const InterestPostingSchedule = {
  savings: {
    schedule: "0 0 31 * *", // Last day of month at midnight
    process: "calculateAndPostSavingsInterest",
  },

  fixed_deposit: {
    schedule: "0 0 */3 * *", // Every quarter
    process: "calculateAndPostFDInterest",
  },

  recurring_deposit: {
    schedule: "0 0 1 * *", // First day of month
    process: "processRDInstallments",
  },

  loan: {
    schedule: "0 0 * * *", // Daily
    process: "calculateLoanInterest",
  },

  loan_posting: {
    schedule: "0 0 5 * *", // 5th of every month
    process: "postLoanInterestToGL",
  },
};
```

### 🚀 **Implementation Best Practices**

1. **Transaction Atomicity**: Always wrap interest posting in database transactions
2. **Idempotency**: Ensure interest calculations can be re-run safely
3. **Audit Trail**: Log all interest calculations and postings
4. **Reconciliation**: Daily balance reconciliation between sub_accounts and GL
5. **Error Handling**: Implement rollback mechanisms for failed postings
6. **Performance**: Use batch processing for large volumes
7. **Compliance**: Maintain regulatory reports for interest payments
8. **Testing**: Comprehensive test cases for each account type

This comprehensive guide provides everything needed to understand and implement all account types in your microfinance application with proper interest posting and transaction management.
