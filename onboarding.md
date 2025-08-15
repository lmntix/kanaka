# Organization Onboarding with Automated GL Account Linking

## Overview

Based on the existing Supabase microfinance structure, this document outlines how to implement **seamless GL account linking** using the actual `accounts`, `sub_accounts`, and `bank_accounts` tables. The key insight is using **predictable account linking** to eliminate manual GL account selection during transactions.

## Understanding the Existing Structure

From the Supabase database, we have:

### 1. **accounts** table (Chart of Accounts)
```sql
-- Key columns from accounts table:
accounts_id          -- Primary key 
account_groups_id    -- Link to account groups (Asset, Liability, etc.)
account_name         -- "Member Lone", "Fixed Deposit", "Savings", etc.
account_type         -- Numeric codes (28, 29, 40, 41, 42, etc.)
balance_type         -- 1=Credit, 2=Debit, 3=Income/Expense
sequence_no          -- Display order
status               -- 1=Active, 0=Inactive
memberwise_acc       -- 1=Member-specific, 0=Organization-level
proper_account_name  -- Localized name
english_name         -- English translation
```

### 2. **sub_accounts** table (Individual Account Instances)
```sql
-- Key columns from sub_accounts table:
sub_accounts_id      -- Primary key
accounts_id          -- Link to accounts (Chart of Accounts)
members_id           -- 0=Organization account, >0=Member account
sub_accounts_no      -- Account number
name                 -- Account holder name or "-" for system accounts
status               -- 1=Active, 0=Inactive
```

### 3. **bank_accounts** table (Organization Bank Accounts)
```sql
-- Key columns from bank_accounts table:
bank_accounts_id     -- Primary key
sub_accounts_id      -- Links to sub_accounts
name                 -- Bank name
acc_no              -- Bank account number
branch              -- Bank branch
address             -- Bank address
acc_type            -- Account type
status              -- 1=Active, 0=Inactive
```

## The Core Problem

### Current Pain Points:
1. **Poor UX**: Users must manually select GL accounts when creating FD/RD/Savings accounts
2. **Error-Prone**: Wrong GL account selection leads to incorrect financial reports  
3. **Training Overhead**: Staff needs to understand accounting to use the system
4. **Inconsistency**: Different users might select different GL accounts for same product type
5. **Organization Bank Account Complexity**: Tracking org-side transactions in separate bank accounts

### The Solution: Automated Account Linking with System Accounts

By creating **standardized accounts with predictable account_type codes**, we can:
1. **Auto-link** product accounts to correct GL accounts based on `account_type`
2. **Eliminate** GL account selection from user interfaces
3. **Guarantee** correct accounting without user intervention
4. **Separate** member accounts from organization system accounts using `memberwise_acc` flag
5. **Handle** organization bank transactions through designated system accounts

## Updated Drizzle Schema Based on Supabase Structure

```typescript
// Updated schema to match Supabase structure

// Enums
export const accountStatusEnum = pgEnum('account_status', ['1', '0']); // 1=Active, 0=Inactive  
export const memberWiseEnum = pgEnum('memberwise_acc', ['1', '0']); // 1=Member-specific, 0=Organization-level
export const balanceTypeEnum = pgEnum('balance_type', ['1', '2', '3']); // 1=Credit, 2=Debit, 3=Income/Expense

// Core tables matching Supabase structure

// 1. Account Groups (Categories like Asset, Liability, etc.)
const accountGroups = pgTable('account_groups', {
  accountGroupsId: serial('account_groups_id').primaryKey(),
  name: text('name'), // "Shares", "Deposit", "Reserve fund", etc.
  groupType: text('group_type'), // "1", "2", "3", etc. (numeric codes)
  accountPrimaryGroup: text('account_primary_group'), // "4" for Liabilities, etc.
  sequenceNo: text('sequence_no'),
  otherName: text('other_name'),
});

// 2. Chart of Accounts (GL Accounts)
const accounts = pgTable('accounts', {
  accountsId: serial('accounts_id').primaryKey(),
  accountGroupsId: integer('account_groups_id').references(() => accountGroups.accountGroupsId),
  accountName: text('account_name').notNull(), // "Fixed Deposit", "Member Loan", etc.
  accountType: text('account_type').notNull(), // "28", "29", "40", "41", "42", etc.
  balanceType: balanceTypeEnum('balance_type').notNull(), // 1=Credit, 2=Debit, 3=Income
  sequenceNo: text('sequence_no'),
  status: accountStatusEnum('status').default('1'),
  memberwiseAcc: memberWiseEnum('memberwise_acc').default('0'), // KEY: 0=System, 1=Member
  properAccountName: text('proper_account_name'),
  englishName: text('english_name'),
  // Add organization support
  organizationId: uuid('organization_id').references(() => organizations.id),
  // Add system account flag  
  isSystemAccount: boolean('is_system_account').default(false), // Prevents deletion
});

// 3. Sub Accounts (Individual Account Instances)
const subAccounts = pgTable('sub_accounts', {
  subAccountsId: serial('sub_accounts_id').primaryKey(),
  accountsId: integer('accounts_id').references(() => accounts.accountsId),
  membersId: integer('members_id').default(0), // 0=Organization account, >0=Member account
  subAccountsNo: text('sub_accounts_no'), // Account number
  name: text('name'), // Account holder name or "-" for system accounts
  status: accountStatusEnum('status').default('1'),
});

// 4. Bank Accounts (Organization Bank Accounts)
const bankAccounts = pgTable('bank_accounts', {
  bankAccountsId: serial('bank_accounts_id').primaryKey(),
  subAccountsId: integer('sub_accounts_id').references(() => subAccounts.subAccountsId),
  lastModifiedBy: text('last_modified_by'),
  name: text('name'), // "Bank IDBI", "DHANBAD CENTRAL Co-Op Bank"
  accNo: text('acc_no'), // Bank account number
  branch: text('branch'),
  address: text('address'),
  accType: text('acc_type'), // "1" for savings, etc.
  againstInvst: text('against_invst'),
  lastModifiedOn: text('last_modified_on'),
  status: accountStatusEnum('status').default('1'),
});

// Product Account Tables (FD, RD, etc.) - Simplified
const fdAccounts = pgTable('fd_accounts', {
  fdAccountsId: serial('fd_accounts_id').primaryKey(),
  subAccountsId: integer('sub_accounts_id').references(() => subAccounts.subAccountsId),
  fdSchemesId: integer('fd_schemes_id'), // Link to FD schemes
  membersId: integer('members_id'), // Customer
  fdAmount: text('fd_amount'),
  interestRate: text('interest_rate'),
  tenureMonths: text('tenure_months'),
  openDate: text('open_date'),
  maturityDate: text('maturity_date'),
  maturityAmount: text('maturity_amount'),
  status: text('status'),
  // Add direct organization link
  organizationId: uuid('organization_id').references(() => organizations.id),
});
```

## The Key Insight: Using `memberwise_acc` + `account_type` for Auto-Linking

### Problem Scenario (Before):
```typescript
// User creating FD account has to:
// 1. Select customer
// 2. Enter FD details (amount, rate, tenure) 
// 3. SELECT WHICH GL ACCOUNT TO USE ❌ (Bad UX)
// 4. SELECT WHICH ORG BANK ACCOUNT TO DEBIT ❌ (Complex)

const fdAccount = {
  membersId: 123,
  fdAmount: 100000,
  interestRate: 8.5,
  glAccountId: '???' // User has to select from dropdown ❌
  orgBankAccountId: '???' // User has to select org bank ❌
};
```

### Solution Scenario (After):
```typescript
// System automatically resolves all account linking
// User only focuses on business data ✅

const fdAccount = {
  membersId: 123, 
  fdAmount: 100000,
  interestRate: 8.5,
  // All GL linking handled automatically ✅
};

// Behind the scenes:
const fdGLAccount = await getSystemAccountByType('FIXED_DEPOSIT');
const orgBankAccount = await getDefaultOrgBankAccount();
// System handles all the complexity ✅
```

## The Key Helper Functions Based on Supabase Structure

```typescript
// lib/services/account-resolver.ts
import { db } from '@/lib/db';
import { accounts, subAccounts, bankAccounts } from '@/lib/schema';
import { eq, and } from 'drizzle-orm';

// Get system GL account by account type (eliminates user selection)
export async function getSystemAccountByType(
  organizationId: string,
  accountType: string // "28" for Member Loan, "40" for Shares, etc.
) {
  const systemAccount = await db.select()
    .from(accounts)
    .where(
      and(
        eq(accounts.organizationId, organizationId),
        eq(accounts.accountType, accountType),
        eq(accounts.status, '1'), // Active
        eq(accounts.memberwiseAcc, '0') // System account, not member-specific
      )
    )
    .limit(1);

  if (!systemAccount.length) {
    throw new Error(`System account not found for type: ${accountType}`);
  }

  return systemAccount[0];
}

// Get system sub-account (organization-level account instance)
export async function getSystemSubAccount(
  organizationId: string,
  accountType: string
) {
  const systemAccount = await getSystemAccountByType(organizationId, accountType);
  
  const systemSubAccount = await db.select()
    .from(subAccounts)
    .where(
      and(
        eq(subAccounts.accountsId, systemAccount.accountsId),
        eq(subAccounts.membersId, 0), // Organization account (not member)
        eq(subAccounts.status, '1') // Active
      )
    )
    .limit(1);

  if (!systemSubAccount.length) {
    throw new Error(`System sub-account not found for account type: ${accountType}`);
  }

  return {
    account: systemAccount,
    subAccount: systemSubAccount[0]
  };
}

// Get default organization bank account for cash transactions
export async function getDefaultOrgBankAccount(organizationId: string) {
  // First find the cash/bank system account
  const cashAccount = await getSystemSubAccount(organizationId, 'CASH_BANK'); // Define your cash account type
  
  // Then find the bank account linked to it
  const orgBankAccount = await db.select()
    .from(bankAccounts)
    .where(
      and(
        eq(bankAccounts.subAccountsId, cashAccount.subAccount.subAccountsId),
        eq(bankAccounts.status, '1') // Active
      )
    )
    .limit(1);

  if (!orgBankAccount.length) {
    throw new Error('No active organization bank account found');
  }

  return {
    ...cashAccount,
    bankAccount: orgBankAccount[0]
  };
}

// Predefined account type mappings (based on Supabase data)
export const ACCOUNT_TYPES = {
  // Assets  
  CASH_BANK: '10',
  MEMBER_LOANS: '28',
  
  // Liabilities
  FIXED_DEPOSITS: '45', // You'd map these based on your actual data
  SAVINGS_DEPOSITS: '46',
  RECURRING_DEPOSITS: '47',
  
  // Income
  LOAN_INTEREST_INCOME: '29',
  PROCESSING_FEE_INCOME: '30',
  
  // Expenses  
  INTEREST_ON_FD: '31',
  INTEREST_ON_SAVINGS: '32',
} as const;

// Simplified helper for common operations
export async function getAccountsForTransaction(
  organizationId: string,
  transactionType: 'FD_OPENING' | 'SAVINGS_DEPOSIT' | 'LOAN_DISBURSEMENT'
) {
  switch (transactionType) {
    case 'FD_OPENING':
      return {
        cash: await getSystemSubAccount(organizationId, ACCOUNT_TYPES.CASH_BANK),
        fdLiability: await getSystemSubAccount(organizationId, ACCOUNT_TYPES.FIXED_DEPOSITS),
        orgBank: await getDefaultOrgBankAccount(organizationId)
      };
      
    case 'SAVINGS_DEPOSIT':
      return {
        cash: await getSystemSubAccount(organizationId, ACCOUNT_TYPES.CASH_BANK),
        savingsLiability: await getSystemSubAccount(organizationId, ACCOUNT_TYPES.SAVINGS_DEPOSITS),
        orgBank: await getDefaultOrgBankAccount(organizationId)
      };
      
    case 'LOAN_DISBURSEMENT':
      return {
        loanAsset: await getSystemSubAccount(organizationId, ACCOUNT_TYPES.MEMBER_LOANS),
        cash: await getSystemSubAccount(organizationId, ACCOUNT_TYPES.CASH_BANK),
        orgBank: await getDefaultOrgBankAccount(organizationId)
      };
      
    default:
      throw new Error(`Unsupported transaction type: ${transactionType}`);
  }
}
```

## Improved Account Creation APIs

### Fixed Deposit Account Creation (Clean UX)

```typescript
// app/api/accounts/fixed-deposit/create/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { fixedDepositAccounts, transactions } from '@/lib/schema';
import { getGLAccountByProductType, getTransactionGLAccounts } from '@/lib/services/gl-account-resolver';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { 
      organizationId, 
      customerId, 
      principalAmount, 
      interestRate, 
      tenure 
    } = body;

    // ✅ NO GL account selection needed by user!
    // System automatically resolves correct accounts
    
    return await db.transaction(async (tx) => {
      // 1. Auto-resolve FD GL account (user never sees this)
      const fdGLAccount = await getGLAccountByProductType(organizationId, 'FIXED_DEPOSIT');
      
      // 2. Get other transaction accounts
      const glAccounts = await getTransactionGLAccounts(organizationId);
      
      // 3. Generate account number
      const org = await tx.select().from(organizations).where(eq(organizations.id, organizationId)).limit(1);
      const accountNumber = `${org[0].code}FD${Date.now().toString().slice(-4)}`;
      
      // 4. Calculate maturity date
      const maturityDate = new Date();
      maturityDate.setMonth(maturityDate.getMonth() + tenure);
      
      // 5. Create FD account with auto-linked GL account
      const [fdAccount] = await tx.insert(fixedDepositAccounts).values({
        organizationId,
        accountNumber,
        customerId,
        glAccountId: fdGLAccount.id, // ✅ Automatically linked!
        principalAmount,
        interestRate,
        tenure,
        maturityDate: maturityDate.toISOString().split('T')[0],
        status: 'ACTIVE',
      }).returning();
      
      // 6. Create opening transaction (also auto-linked)
      await tx.insert(transactions).values({
        organizationId,
        transactionType: 'DEPOSIT',
        debitAccountId: glAccounts.cash!.id, // ✅ Auto-linked
        creditAccountId: glAccounts.fixedDeposits!.id, // ✅ Auto-linked
        amount: principalAmount,
        description: `FD Opening Deposit - ${accountNumber}`,
        productAccountType: 'FIXED_DEPOSIT',
        productAccountId: fdAccount.id,
      });
      
      return NextResponse.json({
        success: true,
        data: {
          fdAccount,
          accountNumber,
          maturityDate: maturityDate.toISOString().split('T')[0],
          // User sees business info, not accounting details
        }
      });
    });
    
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

### Savings Account Creation (Clean UX)

```typescript
// app/api/accounts/savings/create/route.ts
export async function POST(request: NextRequest) {
  try {
    const { organizationId, customerId, initialDeposit } = await request.json();
    
    return await db.transaction(async (tx) => {
      // ✅ System auto-resolves GL accounts
      const savingsGLAccount = await getGLAccountByProductType(organizationId, 'SAVINGS');
      const glAccounts = await getTransactionGLAccounts(organizationId);
      
      // Generate account number
      const org = await tx.select().from(organizations).where(eq(organizations.id, organizationId)).limit(1);
      const accountNumber = `${org[0].code}SAV${Date.now().toString().slice(-4)}`;
      
      // Create savings account
      const [savingsAccount] = await tx.insert(savingsAccounts).values({
        organizationId,
        accountNumber,
        customerId,
        glAccountId: savingsGLAccount.id, // ✅ Auto-linked!
        balance: initialDeposit,
        interestRate: 4.5, // Could be from org settings
        status: 'ACTIVE',
      }).returning();
      
      // Record initial deposit
      if (initialDeposit > 0) {
        await tx.insert(transactions).values({
          organizationId,
          transactionType: 'DEPOSIT',
          debitAccountId: glAccounts.cash!.id, // ✅ Auto-linked
          creditAccountId: savingsGLAccount.id, // ✅ Auto-linked
          amount: initialDeposit,
          description: `Savings Account Opening - ${accountNumber}`,
          productAccountType: 'SAVINGS',
          productAccountId: savingsAccount.id,
        });
      }
      
      return NextResponse.json({
        success: true,
        data: { savingsAccount, accountNumber }
      });
    });
    
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

## Frontend User Experience

### Before (Bad UX - User has to select GL accounts):

```jsx
// ❌ Complex form with accounting knowledge required
function CreateFDAccountForm() {
  return (
    <form>
      <input name="customerId" placeholder="Select Customer" />
      <input name="principalAmount" placeholder="Principal Amount" />
      <input name="interestRate" placeholder="Interest Rate" />
      <input name="tenure" placeholder="Tenure (months)" />
      
      {/* ❌ User has to understand accounting! */}
      <select name="glAccountId">
        <option>Select GL Account</option>
        <option value="coa-001">1110 - Cash and Bank</option>
        <option value="coa-002">2220 - Fixed Deposits</option>
        <option value="coa-003">2210 - Savings Deposits</option>
        {/* User might select wrong account! */}
      </select>
      
      <button>Create FD Account</button>
    </form>
  );
}
```

### After (Good UX - System handles GL linking):

```jsx
// ✅ Clean form focused on business logic
function CreateFDAccountForm() {
  return (
    <form>
      <input name="customerId" placeholder="Select Customer" />
      <input name="principalAmount" placeholder="Principal Amount" />
      <input name="interestRate" placeholder="Interest Rate" />
      <input name="tenure" placeholder="Tenure (months)" />
      
      {/* ✅ No GL account selection needed! */}
      {/* System automatically links to correct accounts */}
      
      <button>Create FD Account</button>
    </form>
  );
}
```

## Transaction Recording (Also Simplified)

### FD Interest Posting (Auto GL Linking)

```typescript
// lib/services/interest-posting.ts
export async function postFDInterest(fdAccountId: string, interestAmount: number) {
  const fdAccount = await db.select().from(fixedDepositAccounts).where(eq(fixedDepositAccounts.id, fdAccountId)).limit(1);
  const organizationId = fdAccount[0].organizationId;
  
  // ✅ System automatically knows which GL accounts to use
  const glAccounts = await getTransactionGLAccounts(organizationId);
  
  return await db.transaction(async (tx) => {
    // Create interest transaction
    await tx.insert(transactions).values({
      organizationId,
      transactionType: 'INTEREST_CREDIT',
      debitAccountId: glAccounts.interestExpenseOnFD!.id, // ✅ Auto-linked
      creditAccountId: glAccounts.fixedDeposits!.id, // ✅ Auto-linked  
      amount: interestAmount,
      description: `FD Interest - ${fdAccount[0].accountNumber}`,
      productAccountType: 'FIXED_DEPOSIT',
      productAccountId: fdAccountId,
    });
  });
}
```

## Benefits Summary

### 🎯 **User Experience Benefits:**
1. **No Accounting Knowledge Required**: Users focus on business, not GL accounts
2. **Faster Data Entry**: Fewer fields to fill out
3. **Error Prevention**: Impossible to select wrong GL account
4. **Consistent Experience**: Same flow across all organizations

### 🔧 **Technical Benefits:**
1. **Predictable Account Codes**: Always know where to find specific GL accounts
2. **Automated Linking**: System handles all GL-to-product mappings
3. **Easier Testing**: Consistent data structure across environments
4. **Simpler Reporting**: Reliable account structure for financial reports

### 💼 **Business Benefits:**
1. **Reduced Training**: Staff doesn't need to learn Chart of Accounts
2. **Faster Onboarding**: New organizations immediately operational
3. **Compliance**: Ensures proper accounting without human intervention
4. **Scalability**: Same process works for any number of organizations

## The Core Insight

By creating **standardized Chart of Accounts with predictable account codes**, we transform the user experience from:

**"User selects GL accounts" → "System automatically links correct GL accounts"**

This is only possible because:
1. Every organization gets the same CoA structure via triggers
2. Account codes are consistent (2220 = Fixed Deposits everywhere)
3. Helper functions can reliably find the right accounts
4. UI can focus on business data instead of accounting details
```

## Implementation Approaches

### Approach 1: PostgreSQL Trigger (Recommended)

#### Benefits:
- **Database-Level Guarantee**: CoA creation happens regardless of how organization is created
- **Performance**: Faster execution than application-level transactions
- **Atomicity**: If CoA creation fails, organization creation is rolled back
- **Independence**: Works with direct database inserts, admin panels, APIs, etc.
- **Centralized Logic**: Single source of truth for CoA template

#### Implementation:

```sql
-- Step 1: Create the trigger function
CREATE OR REPLACE FUNCTION create_default_coa_for_organization()
RETURNS TRIGGER AS $$
DECLARE
    org_id UUID := NEW.id;
    org_code VARCHAR := NEW.code;
BEGIN
    -- Insert comprehensive Chart of Accounts
    INSERT INTO chart_of_accounts (id, organization_id, account_code, account_name, account_type, product_type, is_active) VALUES
    
    -- =================
    -- ASSETS (1000s)
    -- =================
    (gen_random_uuid(), org_id, '1000', 'Assets', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1100', 'Current Assets', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1110', 'Cash and Bank', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1120', 'Petty Cash', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1130', 'Bank Account - Operations', 'ASSET', NULL, true),
    
    -- Loan Portfolio
    (gen_random_uuid(), org_id, '1200', 'Loan Portfolio', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1210', 'Personal Loans', 'ASSET', 'LOAN', true),
    (gen_random_uuid(), org_id, '1220', 'Business Loans', 'ASSET', 'LOAN', true),
    (gen_random_uuid(), org_id, '1230', 'Micro Loans', 'ASSET', 'LOAN', true),
    (gen_random_uuid(), org_id, '1240', 'Agricultural Loans', 'ASSET', 'LOAN', true),
    
    -- Other Assets
    (gen_random_uuid(), org_id, '1300', 'Fixed Assets', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1310', 'Office Equipment', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1320', 'Computer Equipment', 'ASSET', NULL, true),
    (gen_random_uuid(), org_id, '1330', 'Furniture & Fixtures', 'ASSET', NULL, true),
    
    -- =================
    -- LIABILITIES (2000s)
    -- =================
    (gen_random_uuid(), org_id, '2000', 'Liabilities', 'LIABILITY', NULL, true),
    (gen_random_uuid(), org_id, '2100', 'Current Liabilities', 'LIABILITY', NULL, true),
    
    -- Customer Deposits
    (gen_random_uuid(), org_id, '2200', 'Customer Deposits', 'LIABILITY', NULL, true),
    (gen_random_uuid(), org_id, '2210', 'Savings Deposits', 'LIABILITY', 'SAVINGS', true),
    (gen_random_uuid(), org_id, '2220', 'Fixed Deposits', 'LIABILITY', 'FIXED_DEPOSIT', true),
    (gen_random_uuid(), org_id, '2230', 'Recurring Deposits', 'LIABILITY', 'RECURRING_DEPOSIT', true),
    (gen_random_uuid(), org_id, '2240', 'Current Account Deposits', 'LIABILITY', 'SAVINGS', true),
    
    -- Other Liabilities
    (gen_random_uuid(), org_id, '2300', 'Accrued Liabilities', 'LIABILITY', NULL, true),
    (gen_random_uuid(), org_id, '2310', 'Interest Payable', 'LIABILITY', NULL, true),
    (gen_random_uuid(), org_id, '2320', 'Staff Salaries Payable', 'LIABILITY', NULL, true),
    
    -- =================
    -- EQUITY (3000s)
    -- =================
    (gen_random_uuid(), org_id, '3000', 'Equity', 'EQUITY', NULL, true),
    (gen_random_uuid(), org_id, '3100', 'Share Capital', 'EQUITY', NULL, true),
    (gen_random_uuid(), org_id, '3200', 'Retained Earnings', 'EQUITY', NULL, true),
    (gen_random_uuid(), org_id, '3300', 'Current Year Earnings', 'EQUITY', NULL, true),
    
    -- =================
    -- INCOME (4000s)
    -- =================
    (gen_random_uuid(), org_id, '4000', 'Income', 'INCOME', NULL, true),
    
    -- Interest Income
    (gen_random_uuid(), org_id, '4100', 'Interest Income', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4110', 'Personal Loan Interest', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4120', 'Business Loan Interest', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4130', 'Micro Loan Interest', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4140', 'Agricultural Loan Interest', 'INCOME', NULL, true),
    
    -- Fee Income
    (gen_random_uuid(), org_id, '4200', 'Fee Income', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4210', 'Processing Fees', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4220', 'Late Payment Charges', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4230', 'Account Maintenance Fees', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4240', 'Prepayment Penalties', 'INCOME', NULL, true),
    
    -- Other Income
    (gen_random_uuid(), org_id, '4300', 'Other Income', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4310', 'Investment Income', 'INCOME', NULL, true),
    (gen_random_uuid(), org_id, '4320', 'Miscellaneous Income', 'INCOME', NULL, true),
    
    -- =================
    -- EXPENSES (5000s)
    -- =================
    (gen_random_uuid(), org_id, '5000', 'Expenses', 'EXPENSE', NULL, true),
    
    -- Interest Expenses
    (gen_random_uuid(), org_id, '5100', 'Interest Expense', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5110', 'Interest on Savings', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5120', 'Interest on Fixed Deposits', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5130', 'Interest on Recurring Deposits', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5140', 'Interest on Current Accounts', 'EXPENSE', NULL, true),
    
    -- Operating Expenses
    (gen_random_uuid(), org_id, '5200', 'Operating Expenses', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5210', 'Staff Salaries', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5220', 'Office Rent', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5230', 'Utilities', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5240', 'Communications', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5250', 'Travel & Transportation', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5260', 'Office Supplies', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5270', 'Professional Services', 'EXPENSE', NULL, true),
    
    -- Provision Expenses
    (gen_random_uuid(), org_id, '5300', 'Provision Expenses', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5310', 'Bad Debt Provision', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5320', 'Loan Loss Provision', 'EXPENSE', NULL, true),
    
    -- Administrative Expenses
    (gen_random_uuid(), org_id, '5400', 'Administrative Expenses', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5410', 'Audit Fees', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5420', 'Legal Fees', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5430', 'Registration & Compliance', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5440', 'Software Licenses', 'EXPENSE', NULL, true),
    
    -- Depreciation
    (gen_random_uuid(), org_id, '5500', 'Depreciation', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5510', 'Equipment Depreciation', 'EXPENSE', NULL, true),
    (gen_random_uuid(), org_id, '5520', 'Computer Depreciation', 'EXPENSE', NULL, true);
    
    -- Log the creation
    RAISE NOTICE 'Created default Chart of Accounts for organization: % (%)', NEW.name, NEW.code;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create the trigger
DROP TRIGGER IF EXISTS trigger_create_default_coa ON organizations;
CREATE TRIGGER trigger_create_default_coa
    AFTER INSERT ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION create_default_coa_for_organization();
```

#### Testing the Trigger:

```sql
-- Test organization creation
INSERT INTO organizations (name, code) VALUES 
('Green Valley Microfinance', 'GVM');

-- Verify CoA creation
SELECT 
    account_code, 
    account_name, 
    account_type, 
    product_type,
    is_active
FROM chart_of_accounts 
WHERE organization_id = (SELECT id FROM organizations WHERE code = 'GVM')
ORDER BY account_code;
```

### Approach 2: Application-Level Implementation

#### When to Use:
- Need complex business logic during CoA creation
- Want to customize CoA based on organization type/region
- Need to call external APIs during setup
- Want more control over error handling and logging

```typescript
// lib/services/organization-onboarding.ts
import { db } from '@/lib/db';
import { organizations, chartOfAccounts } from '@/lib/schema';

export interface OrganizationOnboardingData {
  name: string;
  code: string;
  organizationType?: 'MICROFINANCE' | 'COOPERATIVE' | 'BANK';
  region?: string;
  customCoATemplate?: string;
}

export async function onboardOrganization(data: OrganizationOnboardingData) {
  return await db.transaction(async (tx) => {
    try {
      // 1. Create organization
      const [org] = await tx.insert(organizations).values({
        name: data.name,
        code: data.code,
      }).returning();

      // 2. Create default Chart of Accounts
      const coaTemplate = getCoATemplate(data.organizationType || 'MICROFINANCE');
      await tx.insert(chartOfAccounts).values(
        coaTemplate.map(account => ({
          ...account,
          organizationId: org.id,
        }))
      );

      // 3. Log the onboarding
      console.log(`Successfully onboarded organization: ${org.name} (${org.code})`);

      return {
        success: true,
        organization: org,
        coaAccountsCreated: coaTemplate.length,
      };

    } catch (error) {
      console.error('Organization onboarding failed:', error);
      throw error;
    }
  });
}

function getCoATemplate(orgType: 'MICROFINANCE' | 'COOPERATIVE' | 'BANK') {
  // Base template for microfinance
  const baseTemplate = [
    // Assets
    { accountCode: '1000', accountName: 'Assets', accountType: 'ASSET' as const, productType: null },
    { accountCode: '1110', accountName: 'Cash and Bank', accountType: 'ASSET' as const, productType: null },
    { accountCode: '1210', accountName: 'Personal Loans', accountType: 'ASSET' as const, productType: 'LOAN' as const },
    
    // Liabilities
    { accountCode: '2000', accountName: 'Liabilities', accountType: 'LIABILITY' as const, productType: null },
    { accountCode: '2210', accountName: 'Savings Deposits', accountType: 'LIABILITY' as const, productType: 'SAVINGS' as const },
    { accountCode: '2220', accountName: 'Fixed Deposits', accountType: 'LIABILITY' as const, productType: 'FIXED_DEPOSIT' as const },
    { accountCode: '2230', accountName: 'Recurring Deposits', accountType: 'LIABILITY' as const, productType: 'RECURRING_DEPOSIT' as const },
    
    // Income
    { accountCode: '4000', accountName: 'Income', accountType: 'INCOME' as const, productType: null },
    { accountCode: '4110', accountName: 'Personal Loan Interest', accountType: 'INCOME' as const, productType: null },
    { accountCode: '4210', accountName: 'Processing Fees', accountType: 'INCOME' as const, productType: null },
    
    // Expenses
    { accountCode: '5000', accountName: 'Expenses', accountType: 'EXPENSE' as const, productType: null },
    { accountCode: '5110', accountName: 'Interest on Savings', accountType: 'EXPENSE' as const, productType: null },
    { accountCode: '5120', accountName: 'Interest on Fixed Deposits', accountType: 'EXPENSE' as const, productType: null },
    { accountCode: '5210', accountName: 'Staff Salaries', accountType: 'EXPENSE' as const, productType: null },
  ];

  // Customize based on organization type
  switch (orgType) {
    case 'COOPERATIVE':
      return [
        ...baseTemplate,
        { accountCode: '3110', accountName: 'Member Share Capital', accountType: 'EQUITY' as const, productType: null },
        { accountCode: '4320', accountName: 'Member Dividend', accountType: 'EXPENSE' as const, productType: null },
      ];
    case 'BANK':
      return [
        ...baseTemplate,
        { accountCode: '1300', accountName: 'Investment Portfolio', accountType: 'ASSET' as const, productType: null },
        { accountCode: '2400', accountName: 'Regulatory Deposits', accountType: 'LIABILITY' as const, productType: null },
      ];
    default:
      return baseTemplate;
  }
}
```

#### NextJS API Implementation:

```typescript
// app/api/organizations/onboard/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { onboardOrganization } from '@/lib/services/organization-onboarding';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, code, organizationType, region } = body;

    // Validate required fields
    if (!name || !code) {
      return NextResponse.json(
        { success: false, error: 'Name and code are required' },
        { status: 400 }
      );
    }

    // Onboard the organization
    const result = await onboardOrganization({
      name,
      code: code.toUpperCase(),
      organizationType,
      region,
    });

    return NextResponse.json(result);

  } catch (error: any) {
    console.error('Organization onboarding error:', error);
    
    // Handle specific errors
    if (error.message?.includes('duplicate key')) {
      return NextResponse.json(
        { success: false, error: 'Organization code already exists' },
        { status: 409 }
      );
    }

    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

## Sample Result After Automated Onboarding

When you create a new organization, here's what gets automatically generated:

### Organizations Table:
| id | name | code | created_at |
|---|---|---|---|
| org-004 | Green Valley Microfinance | GVM | 2025-08-15 11:26:00 |

### Auto-Generated Chart of Accounts (74 accounts total):

#### Assets (1000s)
| account_code | account_name | account_type | product_type |
|---|---|---|---|
| 1000 | Assets | ASSET | NULL |
| 1110 | Cash and Bank | ASSET | NULL |
| 1210 | Personal Loans | ASSET | LOAN |
| 1220 | Business Loans | ASSET | LOAN |
| 1230 | Micro Loans | ASSET | LOAN |
| 1310 | Office Equipment | ASSET | NULL |

#### Liabilities (2000s)
| account_code | account_name | account_type | product_type |
|---|---|---|---|
| 2000 | Liabilities | LIABILITY | NULL |
| 2210 | Savings Deposits | LIABILITY | SAVINGS |
| 2220 | Fixed Deposits | LIABILITY | FIXED_DEPOSIT |
| 2230 | Recurring Deposits | LIABILITY | RECURRING_DEPOSIT |
| 2310 | Interest Payable | LIABILITY | NULL |

#### Income (4000s)
| account_code | account_name | account_type | product_type |
|---|---|---|---|
| 4000 | Income | INCOME | NULL |
| 4110 | Personal Loan Interest | INCOME | NULL |
| 4210 | Processing Fees | INCOME | NULL |
| 4220 | Late Payment Charges | INCOME | NULL |

#### Expenses (5000s)
| account_code | account_name | account_type | product_type |
|---|---|---|---|
| 5000 | Expenses | EXPENSE | NULL |
| 5110 | Interest on Savings | EXPENSE | NULL |
| 5120 | Interest on Fixed Deposits | EXPENSE | NULL |
| 5210 | Staff Salaries | EXPENSE | NULL |
| 5310 | Bad Debt Provision | EXPENSE | NULL |

## Maintenance and Updates

### Updating CoA Template

To add new accounts to the template for future organizations:

```sql
-- Update the trigger function
CREATE OR REPLACE FUNCTION create_default_coa_for_organization()
RETURNS TRIGGER AS $$
BEGIN
    -- Add your new accounts to the INSERT statement
    INSERT INTO chart_of_accounts (id, organization_id, account_code, account_name, account_type, product_type, is_active) VALUES
    -- ... existing accounts ...
    (gen_random_uuid(), NEW.id, '4250', 'Digital Transaction Fees', 'INCOME', NULL, true),
    (gen_random_uuid(), NEW.id, '5450', 'Digital Platform Costs', 'EXPENSE', NULL, true);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Adding Accounts to Existing Organizations

```sql
-- For organizations that need new accounts added
INSERT INTO chart_of_accounts (organization_id, account_code, account_name, account_type, product_type, is_active)
SELECT 
    id, 
    '4250', 
    'Digital Transaction Fees', 
    'INCOME', 
    NULL, 
    true
FROM organizations 
WHERE created_at < '2025-08-15'  -- Add to older organizations
AND NOT EXISTS (
    SELECT 1 FROM chart_of_accounts 
    WHERE organization_id = organizations.id 
    AND account_code = '4250'
);
```

## Best Practices

1. **Version Control**: Track changes to CoA template in database migrations
2. **Backup Strategy**: Always backup before updating trigger functions
3. **Testing**: Test trigger changes on staging environment first
4. **Documentation**: Document any custom accounts added per organization type
5. **Monitoring**: Set up alerts for failed CoA creation
6. **Rollback Plan**: Have procedures to rollback CoA changes if needed

## Recommended Approach

**Use PostgreSQL Trigger** for:
- Standard microfinance organizations
- Consistent CoA requirements
- High-volume onboarding
- Minimal customization needs

**Use Application-Level** for:
- Complex business logic
- Different organization types
- Integration with external systems
- Custom workflow requirements

The PostgreSQL trigger approach provides the best balance of reliability, performance, and maintainability for most microfinance applications.

---

*This document should be updated whenever changes are made to the default Chart of Accounts template or onboarding process.*
