# Complete Example: Savings Deposit for Multiple Organizations
## Step-by-step Implementation with Real Database Operations

## Scenario Setup

Let's create a complete working example where:
- **Organization 1**: "ABC Cooperative Society" - Member deposits ₹1000 to savings
- **Organization 2**: "XYZ Credit Union" - Member deposits ₹2000 to savings

Each organization has its own account structure, GL codes, and member accounts.

## Step 1: Database Schema Setup

```sql
-- Execute this complete setup script

BEGIN;

-- 1. Create master account types (system-wide templates)
CREATE TABLE account_types_master (
    account_type_id SERIAL PRIMARY KEY,
    account_type_code VARCHAR(50) UNIQUE NOT NULL,
    account_type_name VARCHAR(100) NOT NULL,
    balance_type VARCHAR(10) CHECK (balance_type IN ('DEBIT', 'CREDIT')),
    category VARCHAR(50),
    is_member_specific BOOLEAN DEFAULT FALSE,
    default_gl_code VARCHAR(20),
    description TEXT
);

-- Insert standard account types
INSERT INTO account_types_master (account_type_code, account_type_name, balance_type, category, is_member_specific, default_gl_code, description) VALUES
('SAVINGS', 'Savings Account', 'CREDIT', 'LIABILITIES', TRUE, '2001', 'Member savings deposits'),
('FD', 'Fixed Deposit', 'CREDIT', 'LIABILITIES', TRUE, '2002', 'Fixed deposit accounts'),
('RD', 'Recurring Deposit', 'CREDIT', 'LIABILITIES', TRUE, '2003', 'Recurring deposit accounts'),
('LOAN', 'Loan Account', 'DEBIT', 'ASSETS', TRUE, '1001', 'Member loan accounts'),
('SHARES', 'Share Capital', 'CREDIT', 'EQUITY', TRUE, '3001', 'Member share accounts'),
('CASH', 'Cash in Hand', 'DEBIT', 'ASSETS', FALSE, '1101', 'Cash balance'),
('BANK', 'Bank Account', 'DEBIT', 'ASSETS', FALSE, '1102', 'Bank account balance'),
('INTEREST_INCOME', 'Interest Income', 'CREDIT', 'INCOME', FALSE, '4001', 'Interest earned'),
('INTEREST_EXPENSE', 'Interest Expense', 'DEBIT', 'EXPENSE', FALSE, '5001', 'Interest paid to members');

-- 2. Create organization-specific account configuration
CREATE TABLE org_account_types (
    org_account_type_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    account_type_id INTEGER NOT NULL,
    org_gl_code VARCHAR(20) NOT NULL,
    org_account_name VARCHAR(100),
    is_enabled BOOLEAN DEFAULT TRUE,
    sequence_no INTEGER DEFAULT 0,
    settings JSONB DEFAULT '{}',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, account_type_id),
    UNIQUE(organization_id, org_gl_code),
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id),
    FOREIGN KEY (account_type_id) REFERENCES account_types_master(account_type_id)
);

-- 3. Update existing tables with new structure
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS account_type_id INTEGER;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS gl_code VARCHAR(20);
ALTER TABLE sub_accounts ADD COLUMN IF NOT EXISTS account_type_id INTEGER;

-- 4. Add constraints
ALTER TABLE accounts ADD CONSTRAINT fk_accounts_org_type 
    FOREIGN KEY (organization_id, account_type_id) 
    REFERENCES org_account_types(organization_id, account_type_id);

COMMIT;
```

## Step 2: Setup Organizations and Their Account Structures

```sql
-- Setup both organizations with their specific account structures

DO $$
DECLARE
    org1_id INTEGER;
    org2_id INTEGER;
    savings_type_id INTEGER;
    cash_type_id INTEGER;
    bank_type_id INTEGER;
    interest_income_type_id INTEGER;
BEGIN
    -- Get organization IDs
    SELECT organization_id INTO org1_id FROM organizations WHERE organization_code = 'ABC001';
    SELECT organization_id INTO org2_id FROM organizations WHERE organization_code = 'XYZ001';
    
    -- If organizations don't exist, create them
    IF org1_id IS NULL THEN
        INSERT INTO organizations (organization_name, organization_code, status)
        VALUES ('ABC Cooperative Society', 'ABC001', 'ACTIVE')
        RETURNING organization_id INTO org1_id;
    END IF;
    
    IF org2_id IS NULL THEN
        INSERT INTO organizations (organization_name, organization_code, status)
        VALUES ('XYZ Credit Union', 'XYZ001', 'ACTIVE')
        RETURNING organization_id INTO org2_id;
    END IF;
    
    -- Get account type IDs
    SELECT account_type_id INTO savings_type_id FROM account_types_master WHERE account_type_code = 'SAVINGS';
    SELECT account_type_id INTO cash_type_id FROM account_types_master WHERE account_type_code = 'CASH';
    SELECT account_type_id INTO bank_type_id FROM account_types_master WHERE account_type_code = 'BANK';
    SELECT account_type_id INTO interest_income_type_id FROM account_types_master WHERE account_type_code = 'INTEREST_INCOME';
    
    -- Setup Organization 1 account types (ABC Cooperative)
    INSERT INTO org_account_types (organization_id, account_type_id, org_gl_code, org_account_name) VALUES
    (org1_id, savings_type_id, '2001', 'Member Savings Deposits'),
    (org1_id, cash_type_id, '1001', 'Cash in Hand'),
    (org1_id, bank_type_id, '1002', 'Bank Current Account'),
    (org1_id, interest_income_type_id, '4001', 'Interest Income Account')
    ON CONFLICT (organization_id, account_type_id) DO NOTHING;
    
    -- Setup Organization 2 account types (XYZ Credit Union) - Different GL codes
    INSERT INTO org_account_types (organization_id, account_type_id, org_gl_code, org_account_name) VALUES
    (org2_id, savings_type_id, '2101', 'Savings Account Liabilities'),
    (org2_id, cash_type_id, '1101', 'Cash Balance'),
    (org2_id, bank_type_id, '1102', 'Bank Account Balance'),
    (org2_id, interest_income_type_id, '4101', 'Interest Income')
    ON CONFLICT (organization_id, account_type_id) DO NOTHING;
    
    -- Create actual account instances for Organization 1
    INSERT INTO accounts (organization_id, account_type_id, account_name, account_type, balance_type, gl_code, status)
    SELECT 
        oat.organization_id,
        oat.account_type_id,
        oat.org_account_name,
        atm.account_type_code,
        atm.balance_type,
        oat.org_gl_code,
        'ACTIVE'
    FROM org_account_types oat
    JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
    WHERE oat.organization_id = org1_id
    ON CONFLICT DO NOTHING;
    
    -- Create actual account instances for Organization 2
    INSERT INTO accounts (organization_id, account_type_id, account_name, account_type, balance_type, gl_code, status)
    SELECT 
        oat.organization_id,
        oat.account_type_id,
        oat.org_account_name,
        atm.account_type_code,
        atm.balance_type,
        oat.org_gl_code,
        'ACTIVE'
    FROM org_account_types oat
    JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
    WHERE oat.organization_id = org2_id
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Setup completed for organizations % and %', org1_id, org2_id;
END $$;
```

## Step 3: Create Sample Members for Both Organizations

```sql
-- Create members for both organizations
DO $$
DECLARE
    org1_id INTEGER;
    org2_id INTEGER;
    member1_id INTEGER;
    member2_id INTEGER;
BEGIN
    SELECT organization_id INTO org1_id FROM organizations WHERE organization_code = 'ABC001';
    SELECT organization_id INTO org2_id FROM organizations WHERE organization_code = 'XYZ001';
    
    -- Create member for Organization 1
    INSERT INTO members (organization_id, full_name, status, appli_date)
    VALUES (org1_id, 'Rajesh Kumar', 'ACTIVE', CURRENT_DATE::TEXT)
    RETURNING members_id INTO member1_id;
    
    -- Create member for Organization 2
    INSERT INTO members (organization_id, full_name, status, appli_date)
    VALUES (org2_id, 'Priya Sharma', 'ACTIVE', CURRENT_DATE::TEXT)
    RETURNING members_id INTO member2_id;
    
    RAISE NOTICE 'Created members: Org1 Member ID %, Org2 Member ID %', member1_id, member2_id;
END $$;
```

## Step 4: Application Code Implementation

### Service Layer Implementation

```typescript
interface OrganizationContext {
  organizationId: number;
  organizationCode: string;
  currentBusinessDate: string;
  userId: string;
  sessionId: string;
  branchId: number;
}

class SavingsTransactionService {
  constructor(private orgContext: OrganizationContext) {}

  async depositToSavings(
    memberId: number, 
    amount: number, 
    narration: string = 'Cash Deposit to Savings'
  ): Promise<{voucherNo: string, transactionId: number}> {
    
    // Step 1: Get or create member's savings account
    const memberSavingsAccount = await this.getOrCreateMemberSavingsAccount(memberId);
    
    // Step 2: Get organization's cash account (where the cash is received)
    const cashAccount = await this.getOrganizationCashAccount();
    
    // Step 3: Generate voucher number
    const voucherNo = await this.generateVoucherNumber('CASH_RECEIPT');
    
    // Step 4: Create transaction head
    const transactionHead: TransactionHead = {
      organization_id: this.orgContext.organizationId,
      voucher_no: voucherNo,
      trans_date: this.orgContext.currentBusinessDate,
      trans_time: new Date().toTimeString().slice(0, 8),
      trans_amount: amount.toString(),
      trans_narration: `${narration} - Member: ${memberId}`,
      voucher_master_id: 'CASH_RECEIPT',
      users_id: this.orgContext.userId,
      session_id: this.orgContext.sessionId,
      branch_id: this.orgContext.branchId,
      mode_of_operation: 'CASH'
    };
    
    // Step 5: Create transaction details (Double Entry)
    const transactionDetails: TransactionDetail[] = [
      // Debit: Cash Account (Asset increases - money received)
      {
        organization_id: this.orgContext.organizationId,
        accounts_id: cashAccount.accounts_id,
        sub_accounts_id: cashAccount.sub_accounts_id,
        trans_amount: amount.toString() // Positive amount for debit
      },
      // Credit: Member Savings Account (Liability increases - money owed to member)
      {
        organization_id: this.orgContext.organizationId,
        accounts_id: memberSavingsAccount.accounts_id,
        sub_accounts_id: memberSavingsAccount.sub_accounts_id,
        trans_amount: (-amount).toString() // Negative amount for credit
      }
    ];
    
    // Step 6: Process transaction
    const transactionId = await this.processTransaction(transactionHead, transactionDetails);
    
    // Step 7: Update account balances
    await this.updateAccountBalances(transactionDetails);
    
    return { voucherNo, transactionId };
  }

  private async getOrCreateMemberSavingsAccount(memberId: number): Promise<SubAccountDetails> {
    // Check if member already has a savings account
    let savingsAccount = await this.findMemberSavingsAccount(memberId);
    
    if (!savingsAccount) {
      savingsAccount = await this.createMemberSavingsAccount(memberId);
    }
    
    return savingsAccount;
  }

  private async findMemberSavingsAccount(memberId: number): Promise<SubAccountDetails | null> {
    const query = `
      SELECT 
        sa.sub_accounts_id,
        sa.accounts_id,
        sa.sub_accounts_no,
        sa.name,
        a.account_name,
        a.gl_code,
        atm.account_type_code,
        atm.balance_type
      FROM sub_accounts sa
      JOIN accounts a ON sa.accounts_id = a.accounts_id
      JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
      WHERE sa.organization_id = $1 
        AND sa.members_id = $2
        AND atm.account_type_code = 'SAVINGS'
        AND sa.status = 'ACTIVE'
      LIMIT 1
    `;
    
    const result = await db.queryOne(query, [this.orgContext.organizationId, memberId]);
    return result || null;
  }

  private async createMemberSavingsAccount(memberId: number): Promise<SubAccountDetails> {
    // Get savings account type for this organization
    const savingsAccountMaster = await this.getAccountByType('SAVINGS');
    
    // Generate unique account number
    const accountNumber = await this.generateAccountNumber('SAVINGS');
    
    // Create sub-account
    const subAccountData = {
      organization_id: this.orgContext.organizationId,
      accounts_id: savingsAccountMaster.accounts_id,
      members_id: memberId,
      sub_accounts_no: accountNumber,
      name: `Savings Account`,
      status: 'ACTIVE',
      account_type_id: savingsAccountMaster.account_type_id
    };
    
    const subAccountId = await this.createSubAccount(subAccountData);
    
    // Create entry in savings_accounts table for additional tracking
    await this.createSavingsAccountRecord(subAccountId, memberId);
    
    return {
      sub_accounts_id: subAccountId,
      accounts_id: savingsAccountMaster.accounts_id,
      sub_accounts_no: accountNumber,
      name: subAccountData.name,
      account_name: savingsAccountMaster.account_name,
      gl_code: savingsAccountMaster.gl_code,
      account_type_code: 'SAVINGS',
      balance_type: 'CREDIT'
    };
  }

  private async getAccountByType(accountTypeCode: string): Promise<AccountDetails> {
    const query = `
      SELECT 
        a.accounts_id,
        a.account_name,
        a.gl_code,
        a.account_type_id,
        atm.balance_type,
        atm.category
      FROM accounts a
      JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
      WHERE a.organization_id = $1 
        AND atm.account_type_code = $2
        AND a.status = 'ACTIVE'
      LIMIT 1
    `;
    
    const result = await db.queryOne(query, [this.orgContext.organizationId, accountTypeCode]);
    
    if (!result) {
      throw new Error(`Account type ${accountTypeCode} not found for organization ${this.orgContext.organizationId}`);
    }
    
    return result;
  }

  private async getOrganizationCashAccount(): Promise<SubAccountDetails> {
    // For cash account, we need a sub-account instance
    // Check if cash sub-account exists, create if not
    let cashSubAccount = await this.findOrganizationCashSubAccount();
    
    if (!cashSubAccount) {
      cashSubAccount = await this.createOrganizationCashSubAccount();
    }
    
    return cashSubAccount;
  }

  private async findOrganizationCashSubAccount(): Promise<SubAccountDetails | null> {
    const query = `
      SELECT 
        sa.sub_accounts_id,
        sa.accounts_id,
        sa.sub_accounts_no,
        sa.name,
        a.account_name,
        a.gl_code,
        atm.account_type_code,
        atm.balance_type
      FROM sub_accounts sa
      JOIN accounts a ON sa.accounts_id = a.accounts_id
      JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
      WHERE sa.organization_id = $1 
        AND atm.account_type_code = 'CASH'
        AND sa.status = 'ACTIVE'
      LIMIT 1
    `;
    
    const result = await db.queryOne(query, [this.orgContext.organizationId]);
    return result || null;
  }

  private async createOrganizationCashSubAccount(): Promise<SubAccountDetails> {
    const cashAccountMaster = await this.getAccountByType('CASH');
    
    const subAccountData = {
      organization_id: this.orgContext.organizationId,
      accounts_id: cashAccountMaster.accounts_id,
      members_id: null, // Cash account is not member-specific
      sub_accounts_no: `CASH-${this.orgContext.organizationCode}`,
      name: 'Cash in Hand',
      status: 'ACTIVE',
      account_type_id: cashAccountMaster.account_type_id
    };
    
    const subAccountId = await this.createSubAccount(subAccountData);
    
    return {
      sub_accounts_id: subAccountId,
      accounts_id: cashAccountMaster.accounts_id,
      sub_accounts_no: subAccountData.sub_accounts_no,
      name: subAccountData.name,
      account_name: cashAccountMaster.account_name,
      gl_code: cashAccountMaster.gl_code,
      account_type_code: 'CASH',
      balance_type: 'DEBIT'
    };
  }

  private async processTransaction(
    transactionHead: TransactionHead, 
    transactionDetails: TransactionDetail[]
  ): Promise<number> {
    const db = await getDBConnection();
    
    try {
      await db.begin();
      
      // Insert transaction head
      const headQuery = `
        INSERT INTO transaction_head (
          organization_id, voucher_no, trans_date, trans_time, trans_amount, 
          trans_narration, voucher_master_id, users_id, session_id, branch_id, mode_of_operation
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING transaction_head_id
      `;
      
      const headResult = await db.queryOne(headQuery, [
        transactionHead.organization_id,
        transactionHead.voucher_no,
        transactionHead.trans_date,
        transactionHead.trans_time,
        transactionHead.trans_amount,
        transactionHead.trans_narration,
        transactionHead.voucher_master_id,
        transactionHead.users_id,
        transactionHead.session_id,
        transactionHead.branch_id,
        transactionHead.mode_of_operation
      ]);
      
      const transactionHeadId = headResult.transaction_head_id;
      
      // Insert transaction details
      for (const detail of transactionDetails) {
        const detailQuery = `
          INSERT INTO transaction_details (
            organization_id, transaction_head_id, accounts_id, sub_accounts_id, trans_amount
          ) VALUES ($1, $2, $3, $4, $5)
        `;
        
        await db.query(detailQuery, [
          detail.organization_id,
          transactionHeadId,
          detail.accounts_id,
          detail.sub_accounts_id,
          detail.trans_amount
        ]);
      }
      
      await db.commit();
      return transactionHeadId;
      
    } catch (error) {
      await db.rollback();
      throw error;
    }
  }

  // Additional helper methods...
  private async generateVoucherNumber(voucherType: string): Promise<string> {
    return await db.queryOne(
      'SELECT get_next_voucher_number($1, $2, $3)', 
      [this.orgContext.organizationId, voucherType, new Date().getFullYear()]
    ).then(result => result.get_next_voucher_number);
  }

  private async generateAccountNumber(accountType: string): Promise<string> {
    return await db.queryOne(
      'SELECT get_next_account_number($1, $2)', 
      [this.orgContext.organizationId, accountType]
    ).then(result => result.get_next_account_number);
  }
}
```

## Step 5: Example Usage - Processing Deposits for Both Organizations

```typescript
// Example usage for both organizations
async function processSavingsDeposits() {
  
  // Organization 1 Context (ABC Cooperative)
  const org1Context: OrganizationContext = {
    organizationId: 1,
    organizationCode: 'ABC001',
    currentBusinessDate: '2024-01-15',
    userId: 'user001',
    sessionId: 'session001',
    branchId: 1
  };
  
  // Organization 2 Context (XYZ Credit Union)
  const org2Context: OrganizationContext = {
    organizationId: 2,
    organizationCode: 'XYZ001',
    currentBusinessDate: '2024-01-15',
    userId: 'user002',
    sessionId: 'session002',
    branchId: 1
  };
  
  try {
    // Process deposit for Organization 1
    const savingsService1 = new SavingsTransactionService(org1Context);
    const result1 = await savingsService1.depositToSavings(
      1, // member_id from org 1
      1000, 
      'Initial savings deposit'
    );
    
    console.log(`Org 1 Transaction: Voucher ${result1.voucherNo}, Transaction ID: ${result1.transactionId}`);
    
    // Process deposit for Organization 2  
    const savingsService2 = new SavingsTransactionService(org2Context);
    const result2 = await savingsService2.depositToSavings(
      2, // member_id from org 2
      2000, 
      'Opening savings account'
    );
    
    console.log(`Org 2 Transaction: Voucher ${result2.voucherNo}, Transaction ID: ${result2.transactionId}`);
    
    // Verify account balances
    await verifyAccountBalances();
    
  } catch (error) {
    console.error('Transaction failed:', error);
  }
}

async function verifyAccountBalances() {
  // Check balances for Organization 1
  const org1Balances = await db.query(`
    SELECT 
      o.organization_name,
      a.account_name,
      a.gl_code,
      atm.balance_type,
      SUM(CASE WHEN atm.balance_type = 'DEBIT' THEN td.trans_amount::numeric ELSE -td.trans_amount::numeric END) as balance
    FROM organizations o
    JOIN accounts a ON o.organization_id = a.organization_id
    JOIN account_types_master atm ON a.account_type_id = atm.account_type_id  
    JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
    JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id
    WHERE o.organization_id = 1
    GROUP BY o.organization_name, a.account_name, a.gl_code, atm.balance_type
  `);
  
  console.log('Organization 1 Balances:', org1Balances);
  
  // Check balances for Organization 2
  const org2Balances = await db.query(`
    SELECT 
      o.organization_name,
      a.account_name, 
      a.gl_code,
      atm.balance_type,
      SUM(CASE WHEN atm.balance_type = 'DEBIT' THEN td.trans_amount::numeric ELSE -td.trans_amount::numeric END) as balance
    FROM organizations o
    JOIN accounts a ON o.organization_id = a.organization_id
    JOIN account_types_master atm ON a.account_type_id = atm.account_type_id
    JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
    JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id
    WHERE o.organization_id = 2
    GROUP BY o.organization_name, a.account_name, a.gl_code, atm.balance_type
  `);
  
  console.log('Organization 2 Balances:', org2Balances);
}
```

## Expected Results

After running the deposits:

### Organization 1 (ABC Cooperative) - ₹1000 Deposit
```
Voucher: VCH000001
GL Code 1001 (Cash in Hand): ₹1000 Debit
GL Code 2001 (Member Savings): ₹1000 Credit
```

### Organization 2 (XYZ Credit Union) - ₹2000 Deposit  
```
Voucher: VCH000001 (independent sequence)
GL Code 1101 (Cash Balance): ₹2000 Debit  
GL Code 2101 (Savings Account Liabilities): ₹2000 Credit
```

## Key Points Demonstrated

1. **Complete Data Isolation**: Each organization has its own accounts, GL codes, and voucher sequences
2. **Flexible Account Structure**: Organizations can have different GL codes for the same account types
3. **Double-Entry Integrity**: Each transaction maintains proper debit/credit balance within the organization
4. **Member-Specific Accounts**: Each member gets their own sub-account under the organization's savings account
5. **Independent Operations**: Both organizations can operate completely independently
6. **Audit Trail**: Complete transaction history maintained per organization

This example shows exactly how your multi-organization cooperative banking system would handle the scenarios you described, with complete isolation and proper accounting practices maintained for each organization.
