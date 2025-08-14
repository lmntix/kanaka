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
