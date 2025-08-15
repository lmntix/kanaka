# Accounts and Sub-Accounts System Analysis

## Overview
The system implements a hierarchical chart of accounts structure typical of cooperative banks/financial institutions. It supports both general ledger accounts (for institutional accounting) and member-specific sub-accounts (for individual customer/member tracking).

## Key Tables Structure

### 1. **account_groups** - Chart of Accounts Hierarchy
- **Purpose**: Defines the main categories and groups for organizing accounts
- **Key Fields**:
  - `name`: Group name (e.g., "Shares", "Reserve fund", "Cash and bank balance")
  - `group_type`: Type of group (maps to system_constants for specific meanings)
  - `account_primary_group`: Primary classification (1=Income, 2=Expense, 3=Assets, 4=Liabilities)
  - `sequence_no`: Display order for reports

**Primary Groups Analysis:**
- **Group 1 (Income)**: 7 account groups - revenue and income categories
- **Group 2 (Expense)**: 6 account groups - operational expenses
- **Group 3 (Assets)**: 10 account groups - cash, loans, investments, fixed assets
- **Group 4 (Liabilities)**: 10 account groups - deposits, shares, reserves, payables

### 2. **accounts** - Individual Account Heads
- **Purpose**: Defines specific accounts within each group
- **Key Fields**:
  - `account_groups_id`: Links to account group
  - `account_name`: Account name (e.g., "Shares", "Recurring Deposit", "Cash")
  - `account_type`: Sequential numbering for account categorization (78 being most common)
  - `balance_type`: **1=Credit Balance, 2=Debit Balance, 3=Both**
  - `memberwise_acc`: **1=Member-specific accounts, 0=General ledger only**
  - `status`: **1=Active, 0=Inactive**

**Balance Type Distribution:**
- **Credit Balance (1)**: 78 accounts - Typically liability/income accounts
- **Debit Balance (2)**: 110 accounts - Typically asset/expense accounts  
- **Both (3)**: 41 accounts - Can have either debit or credit balance

### 3. **sub_accounts** - Individual Member/Customer Accounts
- **Purpose**: Creates individual accounts for members under memberwise account heads
- **Key Fields**:
  - `accounts_id`: Links to parent account
  - `members_id`: Links to member (if member-specific)
  - `sub_accounts_no`: Unique account number for the member
  - `name`: Account holder name
  - `status`: **1=Active, 4=Closed**

## How the System Works

### **Two-Tier Account Structure**

#### **Tier 1: General Ledger Accounts (memberwise_acc = '0')**
- Used for institutional accounting
- Examples: "Reserve fund", "Building fund", "Cash"
- Have only ONE sub_account record (acting as the main account)
- Used for bank's own financial statements

#### **Tier 2: Member-Specific Accounts (memberwise_acc = '1')**
- Create individual customer accounts
- Examples: Member shares, deposits, loans
- Each member gets their own sub_account under the main account head
- Used for customer/member tracking and statements

### **Example Structure**

```
Account: "Shares" (accounts_id=1, memberwise_acc='1')
├── Sub-Account: Member #787 - Kamni Devi (sub_accounts_no="787")
├── Sub-Account: Member #1 - Shaila Devi (sub_accounts_no="1")
└── ... (one sub-account per member who owns shares)

Account: "Reserve fund" (accounts_id=85, memberwise_acc='0')
└── Sub-Account: Single general ledger account (sub_accounts_no="85")
```

### **Transaction Flow**
1. **All transactions** are recorded in `transaction_details` table
2. **Debits/Credits** are posted to specific `sub_accounts_id`
3. **Balances** are calculated by summing transactions for each sub_account
4. **Reporting** can aggregate by account or show member-wise details

## System Constants Analysis

### **Relevant Constants Found:**
- **Type 2**: Account Status (1=Open, 2=Freeze, 4=Close)
- **Type 5**: Voucher Types (1=Credit/Receipt, 2=Debit/Payment, 3=Journal, 4=Contra)
- **Type 11**: General Status (1=Active, 4=Inactive)
- **Type 28**: Alternative Status (1=Active, 2=Inactive, 3=Freeze)

## PostgreSQL Enhancement Recommendations

### **1. Create Enums for Better Type Safety**

```sql
-- Account Primary Groups
CREATE TYPE account_primary_group_type AS ENUM (
    'income',      -- 1
    'expense',     -- 2  
    'asset',       -- 3
    'liability'    -- 4
);

-- Balance Types  
CREATE TYPE balance_type AS ENUM (
    'credit',      -- 1 (Credit Balance - Liabilities/Income)
    'debit',       -- 2 (Debit Balance - Assets/Expenses)  
    'both'         -- 3 (Can be either)
);

-- Account Status
CREATE TYPE account_status AS ENUM (
    'inactive',    -- 0
    'active'       -- 1
);

-- Sub-Account Status  
CREATE TYPE sub_account_status AS ENUM (
    'active',      -- 1
    'frozen',      -- 2  
    'closed'       -- 4
);
```

### **2. Update Table Structures**

```sql
-- Update account_groups table
ALTER TABLE account_groups 
ALTER COLUMN account_primary_group TYPE account_primary_group_type 
USING CASE account_primary_group
    WHEN '1' THEN 'income'::account_primary_group_type
    WHEN '2' THEN 'expense'::account_primary_group_type  
    WHEN '3' THEN 'asset'::account_primary_group_type
    WHEN '4' THEN 'liability'::account_primary_group_type
END;

-- Update accounts table
ALTER TABLE accounts
ALTER COLUMN balance_type TYPE balance_type 
USING CASE balance_type
    WHEN '1' THEN 'credit'::balance_type
    WHEN '2' THEN 'debit'::balance_type
    WHEN '3' THEN 'both'::balance_type  
END;

ALTER TABLE accounts 
ALTER COLUMN status TYPE account_status
USING CASE status
    WHEN '0' THEN 'inactive'::account_status
    WHEN '1' THEN 'active'::account_status
END;

-- Convert memberwise_acc to boolean
ALTER TABLE accounts
ALTER COLUMN memberwise_acc TYPE BOOLEAN
USING memberwise_acc = '1';

-- Update sub_accounts table
ALTER TABLE sub_accounts
ALTER COLUMN status TYPE sub_account_status
USING CASE status  
    WHEN '1' THEN 'active'::sub_account_status
    WHEN '2' THEN 'frozen'::sub_account_status
    WHEN '4' THEN 'closed'::sub_account_status
END;
```

## Sample Account Structure

### **Assets (account_primary_group='3')**
- **Cash and Bank Balance**: Daily cash, bank accounts, cheque collection
- **Loans**: Member loans, secured/unsecured loans 
- **Investment**: Fixed deposits, securities, other investments
- **Fixed Assets**: Building, equipment, furniture

### **Liabilities (account_primary_group='4')**  
- **Shares**: Member share capital
- **Deposits**: Saving deposits, recurring deposits, fixed deposits
- **Reserves**: Reserve fund, building fund, other statutory reserves
- **Other Liabilities**: Interest payable, loan provisions

### **Income (account_primary_group='1')**
- **Interest Income**: From loans, investments
- **Fee Income**: Processing fees, service charges
- **Other Income**: Miscellaneous revenue

### **Expenses (account_primary_group='2')**
- **Interest Expense**: On deposits, borrowed funds
- **Operating Expenses**: Staff costs, office expenses
- **Provisions**: Bad debt provisions, depreciation

## Business Logic Insights

### **Member Account Management**
- **Each member** can have multiple sub-accounts across different account types
- **Account numbering** follows sequential pattern per account type
- **Status management** allows for freezing/closing individual member accounts
- **Balance calculation** requires summing all transactions for each sub_account

### **Financial Reporting**
- **Balance Sheet**: Aggregates all sub-accounts by main account and group
- **Member Statements**: Shows transactions and balances for specific member
- **Trial Balance**: Lists all accounts with their current balances
- **Regulatory Reports**: Uses account groupings for compliance reporting

This structure provides both **institutional accounting** (for the cooperative's books) and **member account management** (for individual customer tracking) in a unified system.
