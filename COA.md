# Chart of Accounts (CoA) Design for Multi-Tenant Microfinance Application

## Overview

This document outlines the Chart of Accounts design based on the **actual Supabase microfinance database structure**. The key innovation is using automated GL account linking through the `accounts`, `sub_accounts`, and `bank_accounts` relationships to eliminate manual account selection and provide seamless user experience.

## Core Business Problem

### Current Pain Points:
1. **Complex UX**: Users must understand accounting to select correct GL accounts
2. **Error-Prone**: Wrong account selection leads to financial reporting errors
3. **Training Overhead**: Staff needs accounting knowledge to operate the system
4. **Bank Account Complexity**: Managing organization bank accounts alongside member accounts
5. **Inconsistent Linking**: Different users might link accounts differently

### Our Solution: Automated Account Resolution
Using **predictable account type codes** and **system account flags** to automatically resolve GL accounts, eliminating user selection entirely.

## Database Schema (Based on Supabase Structure)

### Enums
```typescript
// Enums matching Supabase values
export const accountStatusEnum = pgEnum('account_status', ['1', '0']); // 1=Active, 0=Inactive  
export const memberWiseEnum = pgEnum('memberwise_acc', ['1', '0']); // 1=Member-specific, 0=Organization-level
export const balanceTypeEnum = pgEnum('balance_type', ['1', '2', '3']); // 1=Credit, 2=Debit, 3=Income/Expense
export const organizationStatusEnum = pgEnum('org_status', ['ACTIVE', 'INACTIVE', 'SUSPENDED']);
```

### Core Tables

#### 1. Organizations (Multi-Tenant Layer)
```typescript
const organizations = pgTable('organizations', {
  organizationId: uuid('organization_id').defaultRandom().primaryKey(),
  name: text('name').notNull(),
  code: varchar('code', { length: 10 }).unique().notNull(),
  regNo: text('reg_no'),
  address: text('address'),
  weeklyOff: text('weekly_off'),
  status: organizationStatusEnum('status').default('ACTIVE'),
  createdAt: timestamp('created_at').defaultNow(),
});
```

#### 2. Account Groups (Categories like Asset, Liability, etc.)
```typescript
const accountGroups = pgTable('account_groups', {
  accountGroupsId: serial('account_groups_id').primaryKey(),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  name: text('name').notNull(), // "Shares", "Deposit", "Reserve fund", etc.
  groupType: text('group_type').notNull(), // "1", "2", "3", etc. (numeric codes)
  accountPrimaryGroup: text('account_primary_group').notNull(), // "4" for Liabilities, etc.
  sequenceNo: text('sequence_no'),
  otherName: text('other_name'),
});
```

#### 3. Chart of Accounts (GL Accounts)
```typescript
const accounts = pgTable('accounts', {
  accountsId: serial('accounts_id').primaryKey(),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  accountGroupsId: integer('account_groups_id').references(() => accountGroups.accountGroupsId),
  
  // Core account details
  accountName: text('account_name').notNull(), // "Fixed Deposit", "Member Loan", "Cash & Bank"
  accountType: text('account_type').notNull(), // "28", "29", "40", "41", "42", etc.
  balanceType: balanceTypeEnum('balance_type').notNull(), // 1=Credit, 2=Debit, 3=Income
  
  // Display and organization
  sequenceNo: text('sequence_no'),
  status: accountStatusEnum('status').default('1'),
  
  // KEY COLUMNS for automated linking
  memberwiseAcc: memberWiseEnum('memberwise_acc').default('0'), // 0=System, 1=Member-specific
  isSystemAccount: boolean('is_system_account').default(false), // Prevents deletion by users
  
  // Localization
  properAccountName: text('proper_account_name'),
  englishName: text('english_name'),
  
  // Audit
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
}, (table) => ({
  uniqueOrgAccountType: unique().on(table.organizationId, table.accountType),
  uniqueOrgAccountCode: unique().on(table.organizationId, table.sequenceNo),
}));
```

#### 4. Sub Accounts (Individual Account Instances)
```typescript
const subAccounts = pgTable('sub_accounts', {
  subAccountsId: serial('sub_accounts_id').primaryKey(),
  accountsId: integer('accounts_id').references(() => accounts.accountsId),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  
  // Account holder details
  membersId: integer('members_id').default(0), // 0=Organization account, >0=Member account
  subAccountsNo: text('sub_accounts_no'), // Account number (auto-generated)
  name: text('name'), // Account holder name or "-" for system accounts
  
  // Status and audit
  status: accountStatusEnum('status').default('1'),
  createdAt: timestamp('created_at').defaultNow(),
  openedDate: date('opened_date').defaultNow(),
}, (table) => ({
  uniqueOrgSubAccountNo: unique().on(table.organizationId, table.subAccountsNo),
}));
```

#### 5. Bank Accounts (Organization Bank Accounts)
```typescript
const bankAccounts = pgTable('bank_accounts', {
  bankAccountsId: serial('bank_accounts_id').primaryKey(),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  subAccountsId: integer('sub_accounts_id').references(() => subAccounts.subAccountsId),
  
  // Bank details
  name: text('name').notNull(), // "Bank IDBI", "DHANBAD CENTRAL Co-Op Bank"
  accNo: text('acc_no').notNull(), // Bank account number
  branch: text('branch'),
  address: text('address'),
  accType: text('acc_type'), // "1" for savings, "2" for current, etc.
  
  // Configuration
  againstInvst: text('against_invst').default('0'),
  isDefault: boolean('is_default').default(false), // Primary bank account for organization
  
  // Audit
  status: accountStatusEnum('status').default('1'),
  lastModifiedBy: text('last_modified_by'),
  lastModifiedOn: timestamp('last_modified_on').defaultNow(),
}, (table) => ({
  uniqueOrgBankAccount: unique().on(table.organizationId, table.accNo),
}));
```

### Product Account Tables

#### 6. Fixed Deposit Accounts
```typescript
const fdAccounts = pgTable('fd_accounts', {
  fdAccountsId: serial('fd_accounts_id').primaryKey(),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  
  // Links to GL system
  subAccountsId: integer('sub_accounts_id').references(() => subAccounts.subAccountsId),
  fdSchemesId: integer('fd_schemes_id'), // Link to FD schemes/products
  
  // Customer details
  membersId: integer('members_id').notNull(), // Customer ID
  
  // FD specifics
  fdAmount: decimal('fd_amount', { precision: 18, scale: 2 }).notNull(),
  interestRate: decimal('interest_rate', { precision: 5, scale: 2 }).notNull(),
  tenureMonths: integer('tenure_months').notNull(),
  tenureDays: integer('tenure_days'),
  
  // Dates
  openDate: date('open_date').notNull(),
  interestStartDate: date('interest_start_date'),
  maturityDate: date('maturity_date').notNull(),
  
  // Calculated values
  maturityAmount: decimal('maturity_amount', { precision: 18, scale: 2 }),
  
  // Receipt details
  receiptPrefix: text('receipt_prefix'),
  receiptNo: text('receipt_no'),
  receiptDate: date('receipt_date'),
  
  // Configuration
  reinvestInterest: boolean('reinvest_interest').default(false),
  interestTransferTo: text('interest_transfer_to'),
  
  // Status and audit
  status: accountStatusEnum('status').default('1'),
  lastModifiedBy: text('last_modified_by'),
  lastModifiedOn: timestamp('last_modified_on').defaultNow(),
});
```

#### 7. Savings Accounts
```typescript
const savingsAccounts = pgTable('savings_accounts', {
  savingsAccountsId: serial('savings_accounts_id').primaryKey(),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  
  // Links to GL system
  subAccountsId: integer('sub_accounts_id').references(() => subAccounts.subAccountsId),
  savingSchemesId: integer('saving_schemes_id'),
  
  // Customer details
  membersId: integer('members_id').notNull(),
  
  // Account specifics
  currentBalance: decimal('current_balance', { precision: 18, scale: 2 }).default('0'),
  interestRate: decimal('interest_rate', { precision: 5, scale: 2 }),
  minBalance: decimal('min_balance', { precision: 18, scale: 2 }).default('0'),
  
  // Dates
  openDate: date('open_date').notNull(),
  lastTransactionDate: date('last_transaction_date'),
  
  // Status and audit
  status: accountStatusEnum('status').default('1'),
  lastModifiedBy: text('last_modified_by'),
  lastModifiedOn: timestamp('last_modified_on').defaultNow(),
});
```

#### 8. Loan Accounts
```typescript
const loanAccounts = pgTable('loan_accounts', {
  loanAccountsId: serial('loan_accounts_id').primaryKey(),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  
  // Links to GL system
  subAccountsId: integer('sub_accounts_id').references(() => subAccounts.subAccountsId),
  loanSchemesId: integer('loan_schemes_id'),
  
  // Customer details
  membersId: integer('members_id').notNull(),
  
  // Loan specifics
  loanAmount: decimal('loan_amount', { precision: 18, scale: 2 }).notNull(),
  outstandingBalance: decimal('outstanding_balance', { precision: 18, scale: 2 }),
  interestRate: decimal('interest_rate', { precision: 5, scale: 2 }).notNull(),
  tenureMonths: integer('tenure_months').notNull(),
  emiAmount: decimal('emi_amount', { precision: 18, scale: 2 }),
  
  // Dates
  applicationDate: date('application_date'),
  disbursementDate: date('disbursement_date'),
  firstEmiDate: date('first_emi_date'),
  nextDueDate: date('next_due_date'),
  
  // Status and audit
  status: accountStatusEnum('status').default('1'),
  lastModifiedBy: text('last_modified_by'),
  lastModifiedOn: timestamp('last_modified_on').defaultNow(),
});
```

## Account Type Mapping (Based on Supabase Data)

```typescript
// Standard account type codes used across all organizations
export const STANDARD_ACCOUNT_TYPES = {
  // Assets
  CASH_BANK: '10',
  PETTY_CASH: '11', 
  MEMBER_LOANS: '28',
  LOAN_INTEREST_RECEIVABLE: '29',
  
  // Liabilities  
  SHARES: '40',
  DIVIDEND_PAYABLE: '42',
  FIXED_DEPOSITS: '45',
  SAVINGS_DEPOSITS: '46',
  RECURRING_DEPOSITS: '47',
  CURRENT_DEPOSITS: '48',
  
  // Income
  LOAN_INTEREST_INCOME: '50',
  FD_INTEREST_INCOME: '51',
  PROCESSING_FEES: '52',
  PENALTY_INCOME: '53',
  
  // Expenses
  INTEREST_ON_SHARES: '60',
  INTEREST_ON_FD: '61',
  INTEREST_ON_SAVINGS: '62',
  INTEREST_ON_RD: '63',
  STAFF_SALARY: '70',
  OFFICE_RENT: '71',
  
} as const;
```

## Automated GL Account Resolution

### Core Helper Functions

```typescript
// lib/services/account-resolver.ts
import { db } from '@/lib/db';
import { accounts, subAccounts, bankAccounts } from '@/lib/schema';
import { eq, and } from 'drizzle-orm';
import { STANDARD_ACCOUNT_TYPES } from './account-types';

/**
 * Get system GL account by account type (eliminates user selection)
 * Uses memberwise_acc = '0' to find organization-level accounts
 */
export async function getSystemAccountByType(
  organizationId: string,
  accountType: keyof typeof STANDARD_ACCOUNT_TYPES
) {
  const accountTypeCode = STANDARD_ACCOUNT_TYPES[accountType];
  
  const systemAccount = await db.select()
    .from(accounts)
    .where(
      and(
        eq(accounts.organizationId, organizationId),
        eq(accounts.accountType, accountTypeCode),
        eq(accounts.status, '1'), // Active
        eq(accounts.memberwiseAcc, '0') // System account, not member-specific
      )
    )
    .limit(1);

  if (!systemAccount.length) {
    throw new Error(`System account not found for type: ${accountType} (${accountTypeCode})`);
  }

  return systemAccount[0];
}

/**
 * Get system sub-account (organization-level account instance)
 * This represents the actual GL account balance
 */
export async function getSystemSubAccount(
  organizationId: string,
  accountType: keyof typeof STANDARD_ACCOUNT_TYPES
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

/**
 * Get default organization bank account for cash transactions
 * Links to the Cash & Bank GL account through sub_accounts
 */
export async function getDefaultOrgBankAccount(organizationId: string) {
  // First find the cash/bank system account
  const cashAccount = await getSystemSubAccount(organizationId, 'CASH_BANK');
  
  // Then find the bank account linked to it
  const orgBankAccount = await db.select()
    .from(bankAccounts)
    .where(
      and(
        eq(bankAccounts.organizationId, organizationId),
        eq(bankAccounts.status, '1'), // Active
        eq(bankAccounts.isDefault, true) // Primary bank account
      )
    )
    .limit(1);

  if (!orgBankAccount.length) {
    // Fallback to any active bank account
    const fallbackBank = await db.select()
      .from(bankAccounts)
      .where(
        and(
          eq(bankAccounts.organizationId, organizationId),
          eq(bankAccounts.status, '1')
        )
      )
      .limit(1);
      
    if (!fallbackBank.length) {
      throw new Error('No active organization bank account found');
    }
    
    return {
      ...cashAccount,
      bankAccount: fallbackBank[0]
    };
  }

  return {
    ...cashAccount,
    bankAccount: orgBankAccount[0]
  };
}

/**
 * Simplified helper for common transaction patterns
 * Returns all accounts needed for a specific transaction type
 */
export async function getAccountsForTransaction(
  organizationId: string,
  transactionType: 'FD_OPENING' | 'SAVINGS_DEPOSIT' | 'LOAN_DISBURSEMENT' | 'INTEREST_POSTING'
) {
  const baseAccounts = {
    cash: await getSystemSubAccount(organizationId, 'CASH_BANK'),
    orgBank: await getDefaultOrgBankAccount(organizationId)
  };
  
  switch (transactionType) {
    case 'FD_OPENING':
      return {
        ...baseAccounts,
        fdLiability: await getSystemSubAccount(organizationId, 'FIXED_DEPOSITS'),
      };
      
    case 'SAVINGS_DEPOSIT':
      return {
        ...baseAccounts,
        savingsLiability: await getSystemSubAccount(organizationId, 'SAVINGS_DEPOSITS'),
      };
      
    case 'LOAN_DISBURSEMENT':
      return {
        ...baseAccounts,
        loanAsset: await getSystemSubAccount(organizationId, 'MEMBER_LOANS'),
      };
      
    case 'INTEREST_POSTING':
      return {
        ...baseAccounts,
        interestIncome: await getSystemSubAccount(organizationId, 'LOAN_INTEREST_INCOME'),
        interestExpenseFD: await getSystemSubAccount(organizationId, 'INTEREST_ON_FD'),
        interestExpenseSavings: await getSystemSubAccount(organizationId, 'INTEREST_ON_SAVINGS'),
      };
      
    default:
      throw new Error(`Unsupported transaction type: ${transactionType}`);
  }
}
```

## Transaction Recording System

### Transaction Head and Details (Based on Supabase)

```typescript
const transactionHead = pgTable('transaction_head', {
  transactionHeadId: serial('transaction_head_id').primaryKey(),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  branchId: integer('branch_id'), // If multi-branch
  
  // Transaction identification
  transactionNo: text('transaction_no').unique(),
  transactionDate: date('transaction_date').notNull(),
  transactionType: text('transaction_type').notNull(), // 'FD_OPENING', 'SAVINGS_DEPOSIT', etc.
  
  // Reference details
  referenceType: text('reference_type'), // 'FD_ACCOUNT', 'SAVINGS_ACCOUNT', etc.
  referenceId: text('reference_id'), // ID of the related account
  
  // Financial summary
  totalAmount: decimal('total_amount', { precision: 18, scale: 2 }).notNull(),
  description: text('description'),
  
  // Audit
  createdBy: text('created_by'),
  createdAt: timestamp('created_at').defaultNow(),
  isReversed: boolean('is_reversed').default(false),
  reversalReason: text('reversal_reason'),
});

const transactionDetails = pgTable('transaction_details', {
  transactionDetailsId: serial('transaction_details_id').primaryKey(),
  transactionHeadId: integer('transaction_head_id').references(() => transactionHead.transactionHeadId),
  organizationId: uuid('organization_id').references(() => organizations.organizationId),
  
  // GL Account references
  accountsId: integer('accounts_id').references(() => accounts.accountsId),
  subAccountsId: integer('sub_accounts_id').references(() => subAccounts.subAccountsId),
  
  // Transaction amounts (double-entry)
  debitAmount: decimal('debit_amount', { precision: 18, scale: 2 }).default('0'),
  creditAmount: decimal('credit_amount', { precision: 18, scale: 2 }).default('0'),
  
  // Description
  particulars: text('particulars'),
  
  // Audit
  createdAt: timestamp('created_at').defaultNow(),
});
```

## API Implementation Example

### FD Account Creation with Automated GL Linking

```typescript
// app/api/accounts/fixed-deposit/create/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { fdAccounts, subAccounts, transactionHead, transactionDetails } from '@/lib/schema';
import { getAccountsForTransaction } from '@/lib/services/account-resolver';

export async function POST(request: NextRequest) {
  try {
    const { 
      organizationId, 
      membersId, 
      fdAmount, 
      interestRate, 
      tenureMonths 
    } = await request.json();

    // ✅ NO GL account selection needed by user!
    // System automatically resolves all required accounts
    
    return await db.transaction(async (tx) => {
      // 1. Get all required accounts automatically
      const accounts = await getAccountsForTransaction(organizationId, 'FD_OPENING');
      
      // 2. Generate FD account number
      const org = await tx.select().from(organizations)
        .where(eq(organizations.organizationId, organizationId)).limit(1);
      const fdAccountNo = `${org[0].code}FD${Date.now().toString().slice(-4)}`;
      
      // 3. Create member sub-account for this FD
      const [memberSubAccount] = await tx.insert(subAccounts).values({
        accountsId: accounts.fdLiability.account.accountsId,
        organizationId,
        membersId, // This links to the customer
        subAccountsNo: fdAccountNo,
        name: `FD Account - ${fdAccountNo}`,
        status: '1'
      }).returning();
      
      // 4. Calculate maturity details
      const openDate = new Date();
      const maturityDate = new Date(openDate);
      maturityDate.setMonth(maturityDate.getMonth() + tenureMonths);
      
      const simpleInterest = (fdAmount * interestRate * tenureMonths) / (100 * 12);
      const maturityAmount = fdAmount + simpleInterest;
      
      // 5. Create FD account record
      const [fdAccount] = await tx.insert(fdAccounts).values({
        organizationId,
        subAccountsId: memberSubAccount.subAccountsId,
        membersId,
        fdAmount,
        interestRate,
        tenureMonths,
        openDate: openDate.toISOString().split('T')[0],
        maturityDate: maturityDate.toISOString().split('T')[0],
        maturityAmount,
        receiptNo: fdAccountNo,
        receiptDate: openDate.toISOString().split('T')[0],
        status: '1'
      }).returning();
      
      // 6. Create transaction header
      const [txnHead] = await tx.insert(transactionHead).values({
        organizationId,
        transactionNo: `TXN${Date.now()}`,
        transactionDate: openDate.toISOString().split('T')[0],
        transactionType: 'FD_OPENING',
        referenceType: 'FD_ACCOUNT',
        referenceId: fdAccount.fdAccountsId.toString(),
        totalAmount: fdAmount,
        description: `FD Account Opening - ${fdAccountNo}`,
        createdBy: 'SYSTEM' // Could be actual user ID
      }).returning();
      
      // 7. Create double-entry transaction details
      await tx.insert(transactionDetails).values([
        // Debit: Cash & Bank (Asset increased)
        {
          transactionHeadId: txnHead.transactionHeadId,
          organizationId,
          accountsId: accounts.cash.account.accountsId,
          subAccountsId: accounts.cash.subAccount.subAccountsId,
          debitAmount: fdAmount,
          creditAmount: 0,
          particulars: `Cash received for FD - ${fdAccountNo}`
        },
        // Credit: Fixed Deposit Liability (Liability increased)
        {
          transactionHeadId: txnHead.transactionHeadId,
          organizationId,
          accountsId: accounts.fdLiability.account.accountsId,
          subAccountsId: memberSubAccount.subAccountsId, // Member-specific sub-account
          debitAmount: 0,
          creditAmount: fdAmount,
          particulars: `FD account created - ${fdAccountNo}`
        }
      ]);
      
      return NextResponse.json({
        success: true,
        data: {
          fdAccount,
          accountNumber: fdAccountNo,
          maturityAmount,
          maturityDate: maturityDate.toISOString().split('T')[0],
          transactionNumber: txnHead.transactionNo
        }
      });
    });
    
  } catch (error: any) {
    console.error('FD Creation Error:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

## Organization Onboarding with Default Accounts

### PostgreSQL Trigger for Automated Setup

```sql
-- Create trigger to automatically setup Chart of Accounts for new organizations
CREATE OR REPLACE FUNCTION create_default_accounts_for_organization()
RETURNS TRIGGER AS $$
DECLARE
    org_id UUID := NEW.organization_id;
    org_code VARCHAR := NEW.code;
    
    -- Account Group IDs (will be created)
    asset_group_id INT;
    liability_group_id INT;
    income_group_id INT;
    expense_group_id INT;
    
    -- Account IDs (for sub-account creation)
    cash_account_id INT;
    fd_account_id INT;
    savings_account_id INT;
    loan_account_id INT;
BEGIN
    -- Create Account Groups
    INSERT INTO account_groups (organization_id, name, group_type, account_primary_group, sequence_no) VALUES
    (org_id, 'Assets', '1', '1', '1') RETURNING account_groups_id INTO asset_group_id;
    
    INSERT INTO account_groups (organization_id, name, group_type, account_primary_group, sequence_no) VALUES
    (org_id, 'Liabilities', '2', '2', '2') RETURNING account_groups_id INTO liability_group_id;
    
    INSERT INTO account_groups (organization_id, name, group_type, account_primary_group, sequence_no) VALUES
    (org_id, 'Income', '3', '3', '3') RETURNING account_groups_id INTO income_group_id;
    
    INSERT INTO account_groups (organization_id, name, group_type, account_primary_group, sequence_no) VALUES
    (org_id, 'Expenses', '4', '4', '4') RETURNING account_groups_id INTO expense_group_id;
    
    -- Create Standard Chart of Accounts
    
    -- ASSETS
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, asset_group_id, 'Cash & Bank', '10', '2', '10', '1', '0', true, 'Cash & Bank') RETURNING accounts_id INTO cash_account_id;
    
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, asset_group_id, 'Member Loans', '28', '2', '28', '1', '1', true, 'Member Loans') RETURNING accounts_id INTO loan_account_id;
    
    -- LIABILITIES
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, liability_group_id, 'Fixed Deposits', '45', '1', '45', '1', '1', true, 'Fixed Deposits') RETURNING accounts_id INTO fd_account_id;
    
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, liability_group_id, 'Savings Deposits', '46', '1', '46', '1', '1', true, 'Savings Deposits') RETURNING accounts_id INTO savings_account_id;
    
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, liability_group_id, 'Recurring Deposits', '47', '1', '47', '1', '1', true, 'Recurring Deposits');
    
    -- INCOME
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, income_group_id, 'Loan Interest Income', '50', '1', '50', '1', '0', true, 'Loan Interest Income');
    
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, income_group_id, 'Processing Fees', '52', '1', '52', '1', '0', true, 'Processing Fees');
    
    -- EXPENSES
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, expense_group_id, 'Interest on Fixed Deposits', '61', '2', '61', '1', '0', true, 'Interest on Fixed Deposits');
    
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, expense_group_id, 'Interest on Savings', '62', '2', '62', '1', '0', true, 'Interest on Savings');
    
    INSERT INTO accounts (organization_id, account_groups_id, account_name, account_type, balance_type, sequence_no, status, memberwise_acc, is_system_account, english_name) VALUES
    (org_id, expense_group_id, 'Staff Salary', '70', '2', '70', '1', '0', true, 'Staff Salary');
    
    -- Create System Sub-Accounts (Organization-level balances)
    
    -- Cash & Bank system sub-account
    INSERT INTO sub_accounts (accounts_id, organization_id, members_id, sub_accounts_no, name, status) VALUES
    (cash_account_id, org_id, 0, org_code || 'CASH001', 'Organization Cash Account', '1');
    
    -- FD system sub-account (for aggregated FD balances)
    INSERT INTO sub_accounts (accounts_id, organization_id, members_id, sub_accounts_no, name, status) VALUES
    (fd_account_id, org_id, 0, org_code || 'FD000', 'Fixed Deposit Control Account', '1');
    
    -- Savings system sub-account
    INSERT INTO sub_accounts (accounts_id, organization_id, members_id, sub_accounts_no, name, status) VALUES
    (savings_account_id, org_id, 0, org_code || 'SAV000', 'Savings Control Account', '1');
    
    -- Loan system sub-account
    INSERT INTO sub_accounts (accounts_id, organization_id, members_id, sub_accounts_no, name, status) VALUES
    (loan_account_id, org_id, 0, org_code || 'LN000', 'Loan Control Account', '1');
    
    RAISE NOTICE 'Created default Chart of Accounts for organization: % (%)', NEW.name, org_code;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_create_default_accounts ON organizations;
CREATE TRIGGER trigger_create_default_accounts
    AFTER INSERT ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION create_default_accounts_for_organization();
```

## Key Benefits

### 🎯 **User Experience Benefits**
1. **Zero Accounting Knowledge Required**: Users never see GL accounts
2. **Faster Account Creation**: Only business data entry needed
3. **Error Prevention**: Impossible to select wrong accounts
4. **Consistent Experience**: Same across all organizations

### 🔧 **Technical Benefits**  
1. **Predictable Account Structure**: Standard account type codes
2. **Automated GL Linking**: System handles all complexity
3. **Multi-Tenant Isolation**: Complete organization separation
4. **Audit Trail**: Complete transaction history with GL mapping

### 💼 **Business Benefits**
1. **Reduced Training**: Staff focus on business, not accounting
2. **Faster Onboarding**: New organizations operational immediately
3. **Compliance**: Proper double-entry bookkeeping guaranteed
4. **Scalability**: Handles unlimited organizations uniformly

## Sample Data After Organization Creation

### When "Green Valley Microfinance" (GVM) is created:

#### Organizations Table
| organization_id | name | code | status |
|---|---|---|---|
| org-123 | Green Valley Microfinance | GVM | ACTIVE |

#### Auto-Created Accounts (Sample)
| accounts_id | account_name | account_type | memberwise_acc | is_system_account |
|---|---|---|---|---|
| 1 | Cash & Bank | 10 | 0 | true |
| 2 | Member Loans | 28 | 1 | true |
| 3 | Fixed Deposits | 45 | 1 | true |
| 4 | Savings Deposits | 46 | 1 | true |

#### Auto-Created Sub-Accounts (System Level)
| sub_accounts_id | accounts_id | members_id | sub_accounts_no | name |
|---|---|---|---|---|
| 1 | 1 | 0 | GVMCASH001 | Organization Cash Account |
| 2 | 3 | 0 | GVMFD000 | Fixed Deposit Control Account |
| 3 | 4 | 0 | GVMSAV000 | Savings Control Account |

## Best Practices

1. **Account Type Codes**: Keep consistent across all organizations
2. **System Account Protection**: Use `is_system_account = true` to prevent deletion
3. **Member vs System**: Use `memberwise_acc` and `members_id = 0` properly
4. **Bank Account Linking**: Always link organization bank accounts to Cash & Bank GL
5. **Transaction Integrity**: Always create both transaction header and details
6. **Audit Trail**: Maintain complete history of all GL movements

## Future Enhancements

- [ ] Interest calculation automation
- [ ] Statement generation from GL
- [ ] Financial reporting dashboards  
- [ ] Multi-currency support
- [ ] Advanced approval workflows
- [ ] Integration with external banking APIs

---

*This document will be updated as the system evolves and new requirements emerge.*
