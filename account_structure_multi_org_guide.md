# Account Structure & Transaction Flow in Multi-Organization System
## Handling Account Types, Sub-Accounts, and GL Integration

## The Core Challenge

In a multi-organization cooperative banking system, each organization needs:
1. **Independent Chart of Accounts** - Different organizations may have different account structures
2. **Flexible Account Types** - Some orgs may have FD, RD, Loans; others may have additional products
3. **Organization-specific GL Codes** - Each org should maintain its own general ledger structure
4. **Transaction Integrity** - Double-entry bookkeeping maintained within each organization

## Current System Analysis

Based on the existing database structure:

```sql
-- Current structure
accounts (accounts_id, account_name, account_type, balance_type)
    ↓ (links to)
sub_accounts (sub_accounts_id, accounts_id, members_id, sub_accounts_no)
    ↓ (links to product tables)
fd_accounts, loan_accounts, recurring_accounts, saving_accounts
    ↓ (transaction references)
transaction_details (sub_accounts_id, trans_amount)
```

## Recommended Multi-Org Account Architecture

### Option 1: Organization-Specific Chart of Accounts (Recommended)

#### 1.1 Enhanced Account Structure

```sql
-- Organizations table (already created)
CREATE TABLE organizations (
    organization_id SERIAL PRIMARY KEY,
    organization_name VARCHAR(200),
    organization_code VARCHAR(50) UNIQUE,
    -- ... other fields
);

-- Account Types Master (System-wide templates)
CREATE TABLE account_types_master (
    account_type_id SERIAL PRIMARY KEY,
    account_type_code VARCHAR(50) UNIQUE NOT NULL,
    account_type_name VARCHAR(100) NOT NULL,
    balance_type VARCHAR(10) CHECK (balance_type IN ('DEBIT', 'CREDIT')),
    description TEXT,
    is_member_specific BOOLEAN DEFAULT FALSE,
    category VARCHAR(50), -- 'ASSETS', 'LIABILITIES', 'INCOME', 'EXPENSE'
    default_gl_code VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert standard account types
INSERT INTO account_types_master (account_type_code, account_type_name, balance_type, category, is_member_specific, default_gl_code) VALUES
('SAVINGS', 'Savings Account', 'CREDIT', 'LIABILITIES', TRUE, '2001'),
('FD', 'Fixed Deposit', 'CREDIT', 'LIABILITIES', TRUE, '2002'),
('RD', 'Recurring Deposit', 'CREDIT', 'LIABILITIES', TRUE, '2003'),
('LOAN', 'Loan Account', 'DEBIT', 'ASSETS', TRUE, '1001'),
('SHARES', 'Share Capital', 'CREDIT', 'EQUITY', TRUE, '3001'),
('CASH', 'Cash in Hand', 'DEBIT', 'ASSETS', FALSE, '1101'),
('BANK', 'Bank Account', 'DEBIT', 'ASSETS', FALSE, '1102'),
('INTEREST_INCOME', 'Interest Income', 'CREDIT', 'INCOME', FALSE, '4001'),
('INTEREST_EXPENSE', 'Interest Expense', 'DEBIT', 'EXPENSE', FALSE, '5001');

-- Organization-specific Account Configuration
CREATE TABLE org_account_types (
    org_account_type_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    account_type_id INTEGER NOT NULL,
    org_gl_code VARCHAR(20) NOT NULL, -- Organization-specific GL code
    org_account_name VARCHAR(100), -- Organization-specific name (optional)
    is_enabled BOOLEAN DEFAULT TRUE,
    sequence_no INTEGER DEFAULT 0,
    settings JSONB DEFAULT '{}', -- Org-specific settings like interest rates, etc.
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, account_type_id),
    UNIQUE(organization_id, org_gl_code),
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id),
    FOREIGN KEY (account_type_id) REFERENCES account_types_master(account_type_id)
);

-- Enhanced Accounts Table (Org-specific instances)
ALTER TABLE accounts ADD COLUMN organization_id INTEGER;
ALTER TABLE accounts ADD COLUMN account_type_id INTEGER;
ALTER TABLE accounts ADD COLUMN gl_code VARCHAR(20);
ALTER TABLE accounts ADD COLUMN parent_account_id INTEGER; -- For sub-GL accounts

-- Add constraints
ALTER TABLE accounts ADD CONSTRAINT fk_accounts_org_type 
    FOREIGN KEY (organization_id, account_type_id) 
    REFERENCES org_account_types(organization_id, account_type_id);
```

#### 1.2 Sub-Accounts Enhancement

```sql
-- Enhanced sub_accounts table (already has organization_id)
ALTER TABLE sub_accounts ADD COLUMN account_type_id INTEGER;
ALTER TABLE sub_accounts ADD COLUMN account_balance DECIMAL(15,2) DEFAULT 0;
ALTER TABLE sub_accounts ADD COLUMN last_transaction_date DATE;

-- Add constraint to ensure sub_account belongs to same org as member and account
ALTER TABLE sub_accounts ADD CONSTRAINT chk_sub_accounts_org_consistency
    CHECK (
        -- Ensure member, account, and sub_account all belong to same org
        organization_id IN (
            SELECT m.organization_id FROM members m WHERE m.members_id = sub_accounts.members_id
        ) AND
        organization_id IN (
            SELECT a.organization_id FROM accounts a WHERE a.accounts_id = sub_accounts.accounts_id
        )
    );
```

### 1.3 Transaction Flow Architecture

```sql
-- Enhanced transaction processing
CREATE OR REPLACE VIEW v_account_structure AS
SELECT 
    o.organization_id,
    o.organization_name,
    atm.account_type_code,
    atm.account_type_name,
    atm.balance_type,
    atm.category,
    oat.org_gl_code,
    oat.is_enabled,
    a.accounts_id,
    a.account_name,
    a.proper_account_name,
    sa.sub_accounts_id,
    sa.sub_accounts_no,
    sa.name as sub_account_name,
    m.members_id,
    m.full_name as member_name
FROM organizations o
JOIN org_account_types oat ON o.organization_id = oat.organization_id AND oat.is_enabled = TRUE
JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
JOIN accounts a ON oat.organization_id = a.organization_id AND oat.account_type_id = a.account_type_id
LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
LEFT JOIN members m ON sa.members_id = m.members_id
WHERE a.status = 'ACTIVE';
```

## Practical Implementation Examples

### Example 1: Member Savings Account Deposit

#### Scenario: 
- **Org 1**: Member deposits ₹1000 to savings account
- **Org 2**: Member deposits ₹2000 to savings account

#### Database Setup for Both Organizations:

```sql
-- Setup account types for both organizations
DO $$
DECLARE
    org1_id INTEGER := 1;
    org2_id INTEGER := 2;
    savings_type_id INTEGER;
    cash_type_id INTEGER;
BEGIN
    -- Get account type IDs
    SELECT account_type_id INTO savings_type_id FROM account_types_master WHERE account_type_code = 'SAVINGS';
    SELECT account_type_id INTO cash_type_id FROM account_types_master WHERE account_type_code = 'CASH';
    
    -- Setup for Organization 1
    INSERT INTO org_account_types (organization_id, account_type_id, org_gl_code, org_account_name)
    VALUES 
    (org1_id, savings_type_id, '2001', 'Member Savings Deposits'),
    (org1_id, cash_type_id, '1001', 'Cash in Hand');
    
    -- Setup for Organization 2 (different GL codes)
    INSERT INTO org_account_types (organization_id, account_type_id, org_gl_code, org_account_name)
    VALUES 
    (org2_id, savings_type_id, '2101', 'Savings Account Deposits'),
    (org2_id, cash_type_id, '1101', 'Cash Balance');
    
    -- Create account instances for both orgs
    -- Org 1 accounts
    INSERT INTO accounts (organization_id, account_type_id, account_name, account_type, balance_type, gl_code)
    SELECT org1_id, oat.account_type_id, oat.org_account_name, atm.account_type_code, atm.balance_type, oat.org_gl_code
    FROM org_account_types oat
    JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
    WHERE oat.organization_id = org1_id;
    
    -- Org 2 accounts
    INSERT INTO accounts (organization_id, account_type_id, account_name, account_type, balance_type, gl_code)
    SELECT org2_id, oat.account_type_id, oat.org_account_name, atm.account_type_code, atm.balance_type, oat.org_gl_code
    FROM org_account_types oat
    JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
    WHERE oat.organization_id = org2_id;
    
END $$;
```

#### Application Code Example:

```typescript
// Service for handling savings deposit
class SavingsDepositService {
    constructor(
        private organizationId: number,
        private transactionRepo: TransactionRepository,
        private accountRepo: AccountRepository
    ) {}

    async depositToSavings(memberId: number, amount: number, narration: string): Promise<string> {
        // Get member's savings sub-account
        const memberSavingsSubAccount = await this.accountRepo.getMemberSavingsAccount(
            this.organizationId, 
            memberId
        );
        
        if (!memberSavingsSubAccount) {
            throw new Error('Member savings account not found');
        }

        // Get organization's cash account
        const cashAccount = await this.accountRepo.getAccountByType(
            this.organizationId, 
            'CASH'
        );

        // Get voucher number for this organization
        const voucherNo = await this.getNextVoucherNumber('CASH_RECEIPT');

        // Create transaction
        const transactionHead: TransactionHead = {
            organization_id: this.organizationId,
            voucher_no: voucherNo,
            trans_date: await this.getCurrentBusinessDate(),
            trans_amount: amount.toString(),
            trans_narration: narration,
            voucher_master_id: 'CASH_RECEIPT',
            users_id: this.getCurrentUserId(),
            branch_id: this.getCurrentBranchId(),
            session_id: this.getSessionId()
        };

        const transactionDetails: TransactionDetail[] = [
            // Debit Cash Account (Asset increases)
            {
                organization_id: this.organizationId,
                sub_accounts_id: cashAccount.sub_accounts_id,
                accounts_id: cashAccount.accounts_id,
                trans_amount: amount.toString() // Positive for debit
            },
            // Credit Member Savings Account (Liability increases)
            {
                organization_id: this.organizationId,
                sub_accounts_id: memberSavingsSubAccount.sub_accounts_id,
                accounts_id: memberSavingsSubAccount.accounts_id,
                trans_amount: (-amount).toString() // Negative for credit
            }
        ];

        // Process transaction
        const transactionId = await this.transactionRepo.createTransaction(
            transactionHead, 
            transactionDetails
        );

        // Update account balances
        await this.updateAccountBalances(transactionDetails);

        return voucherNo;
    }

    // Get or create member savings account
    private async getOrCreateMemberSavingsAccount(memberId: number): Promise<SubAccount> {
        let savingsAccount = await this.accountRepo.getMemberSavingsAccount(
            this.organizationId, 
            memberId
        );

        if (!savingsAccount) {
            savingsAccount = await this.createMemberSavingsAccount(memberId);
        }

        return savingsAccount;
    }

    private async createMemberSavingsAccount(memberId: number): Promise<SubAccount> {
        // Get savings account type for this organization
        const savingsAccountType = await this.accountRepo.getAccountByType(
            this.organizationId, 
            'SAVINGS'
        );

        // Generate account number
        const accountNumber = await this.getNextAccountNumber('SAVINGS');

        // Create sub-account
        const subAccount: SubAccount = {
            organization_id: this.organizationId,
            accounts_id: savingsAccountType.accounts_id,
            members_id: memberId,
            sub_accounts_no: accountNumber,
            name: `Savings Account - ${accountNumber}`,
            status: 'ACTIVE',
            account_type_id: savingsAccountType.account_type_id
        };

        const subAccountId = await this.accountRepo.createSubAccount(subAccount);

        // Create entry in savings_accounts table
        await this.accountRepo.createSavingsAccountRecord({
            organization_id: this.organizationId,
            sub_accounts_id: subAccountId,
            members_id: memberId,
            opening_date: await this.getCurrentBusinessDate(),
            account_status: 'ACTIVE'
        });

        return { ...subAccount, sub_accounts_id: subAccountId };
    }
}
```

#### Repository Implementation:

```typescript
class AccountRepository {
    constructor(private organizationId: number) {}

    async getAccountByType(organizationId: number, accountTypeCode: string): Promise<Account> {
        const query = `
            SELECT a.*, oat.org_gl_code, atm.balance_type, atm.category
            FROM accounts a
            JOIN org_account_types oat ON a.organization_id = oat.organization_id 
                AND a.account_type_id = oat.account_type_id
            JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
            WHERE a.organization_id = $1 
            AND atm.account_type_code = $2 
            AND a.status = 'ACTIVE'
            AND oat.is_enabled = TRUE
            LIMIT 1
        `;
        
        return await db.queryOne(query, [organizationId, accountTypeCode]);
    }

    async getMemberSavingsAccount(organizationId: number, memberId: number): Promise<SubAccount | null> {
        const query = `
            SELECT sa.*, a.account_name, atm.account_type_code
            FROM sub_accounts sa
            JOIN accounts a ON sa.accounts_id = a.accounts_id
            JOIN org_account_types oat ON a.account_type_id = oat.account_type_id 
                AND a.organization_id = oat.organization_id
            JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
            WHERE sa.organization_id = $1 
            AND sa.members_id = $2
            AND atm.account_type_code = 'SAVINGS'
            AND sa.status = 'ACTIVE'
            LIMIT 1
        `;
        
        return await db.queryOne(query, [organizationId, memberId]);
    }

    async getOrganizationChartOfAccounts(organizationId: number): Promise<ChartOfAccounts[]> {
        const query = `
            SELECT 
                atm.account_type_code,
                atm.account_type_name,
                atm.category,
                atm.balance_type,
                oat.org_gl_code,
                oat.org_account_name,
                COUNT(sa.sub_accounts_id) as total_sub_accounts,
                COALESCE(SUM(CASE WHEN atm.balance_type = 'DEBIT' 
                                  THEN sab.balance 
                                  ELSE -sab.balance END), 0) as total_balance
            FROM org_account_types oat
            JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
            JOIN accounts a ON oat.organization_id = a.organization_id 
                AND oat.account_type_id = a.account_type_id
            LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id 
                AND sa.status = 'ACTIVE'
            LEFT JOIN sub_accounts_balance sab ON sa.sub_accounts_id = sab.sub_accounts_id
            WHERE oat.organization_id = $1 AND oat.is_enabled = TRUE
            GROUP BY atm.account_type_code, atm.account_type_name, atm.category, 
                     atm.balance_type, oat.org_gl_code, oat.org_account_name
            ORDER BY atm.category, oat.org_gl_code
        `;
        
        return await db.query(query, [organizationId]);
    }
}
```

## Organization-Specific Account Setup

### Setting up New Organization:

```typescript
class OrganizationSetupService {
    async setupNewOrganization(orgData: OrganizationData): Promise<void> {
        const orgId = await this.createOrganization(orgData);
        
        // Setup default account types
        await this.setupDefaultAccountTypes(orgId);
        
        // Create default accounts
        await this.createDefaultAccounts(orgId);
        
        // Setup voucher sequences
        await this.setupVoucherSequences(orgId);
    }

    private async setupDefaultAccountTypes(orgId: number): Promise<void> {
        const defaultAccountTypes = [
            { typeCode: 'CASH', glCode: '1001', name: 'Cash in Hand' },
            { typeCode: 'BANK', glCode: '1002', name: 'Bank Account' },
            { typeCode: 'SAVINGS', glCode: '2001', name: 'Member Savings' },
            { typeCode: 'FD', glCode: '2002', name: 'Fixed Deposits' },
            { typeCode: 'RD', glCode: '2003', name: 'Recurring Deposits' },
            { typeCode: 'LOAN', glCode: '1101', name: 'Member Loans' },
            { typeCode: 'SHARES', glCode: '3001', name: 'Share Capital' },
            { typeCode: 'INTEREST_INCOME', glCode: '4001', name: 'Interest Income' },
            { typeCode: 'INTEREST_EXPENSE', glCode: '5001', name: 'Interest Expense' }
        ];

        for (const accountType of defaultAccountTypes) {
            const masterTypeId = await this.getAccountTypeMasterId(accountType.typeCode);
            
            await db.query(`
                INSERT INTO org_account_types (organization_id, account_type_id, org_gl_code, org_account_name)
                VALUES ($1, $2, $3, $4)
            `, [orgId, masterTypeId, accountType.glCode, accountType.name]);
        }
    }

    private async createDefaultAccounts(orgId: number): Promise<void> {
        // Create one account instance for each enabled account type
        const query = `
            INSERT INTO accounts (organization_id, account_type_id, account_name, account_type, balance_type, gl_code, status)
            SELECT oat.organization_id, oat.account_type_id, oat.org_account_name, 
                   atm.account_type_code, atm.balance_type, oat.org_gl_code, 'ACTIVE'
            FROM org_account_types oat
            JOIN account_types_master atm ON oat.account_type_id = atm.account_type_id
            WHERE oat.organization_id = $1 AND oat.is_enabled = TRUE
        `;
        
        await db.query(query, [orgId]);
    }
}
```

## Alternative Approach: Fixed System Accounts

If you prefer a more standardized approach:

### Option 2: Fixed Account Structure with Org Prefixes

```sql
-- Fixed account types with organization prefixes
CREATE TABLE system_accounts_template (
    template_id SERIAL PRIMARY KEY,
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    balance_type VARCHAR(10) CHECK (balance_type IN ('DEBIT', 'CREDIT')),
    category VARCHAR(50),
    is_member_specific BOOLEAN DEFAULT FALSE,
    base_gl_code VARCHAR(10) -- Base code, will be prefixed with org code
);

-- Organization accounts (auto-generated from template)
CREATE OR REPLACE FUNCTION create_organization_accounts(p_org_id INTEGER, p_org_code VARCHAR) 
RETURNS VOID AS $$
DECLARE
    template_rec RECORD;
    new_gl_code VARCHAR(20);
BEGIN
    FOR template_rec IN SELECT * FROM system_accounts_template LOOP
        -- Generate org-specific GL code: ORG001-1001
        new_gl_code := p_org_code || '-' || template_rec.base_gl_code;
        
        INSERT INTO accounts (
            organization_id, account_name, account_type, 
            balance_type, gl_code, status
        ) VALUES (
            p_org_id, template_rec.account_name, template_rec.account_type,
            template_rec.balance_type, new_gl_code, 'ACTIVE'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

## Transaction Reporting & Analysis

### Organization-Specific Trial Balance:

```sql
CREATE OR REPLACE VIEW v_trial_balance AS
SELECT 
    o.organization_id,
    o.organization_name,
    a.gl_code,
    a.account_name,
    a.balance_type,
    atm.category,
    COALESCE(SUM(
        CASE 
            WHEN a.balance_type = 'DEBIT' AND td.trans_amount::numeric > 0 THEN td.trans_amount::numeric
            WHEN a.balance_type = 'DEBIT' AND td.trans_amount::numeric < 0 THEN -td.trans_amount::numeric
            WHEN a.balance_type = 'CREDIT' AND td.trans_amount::numeric < 0 THEN -td.trans_amount::numeric  
            WHEN a.balance_type = 'CREDIT' AND td.trans_amount::numeric > 0 THEN td.trans_amount::numeric
            ELSE 0 
        END
    ), 0) as balance
FROM organizations o
JOIN accounts a ON o.organization_id = a.organization_id
LEFT JOIN account_types_master atm ON a.account_type = atm.account_type_code
LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id
WHERE a.status = 'ACTIVE'
GROUP BY o.organization_id, o.organization_name, a.gl_code, a.account_name, a.balance_type, atm.category
ORDER BY o.organization_id, a.gl_code;
```

## Key Benefits of This Approach:

1. **Complete Data Isolation**: Each organization has its own chart of accounts
2. **Flexibility**: Organizations can enable/disable account types as needed
3. **Standardization**: Common account types across all organizations
4. **Customization**: Organization-specific GL codes and naming
5. **Scalability**: Easy to add new account types system-wide
6. **Audit Compliance**: Clear trail of all transactions within each organization
7. **Double-Entry Integrity**: Maintained within each organization's context

This structure allows you to handle the exact scenarios you mentioned - different organizations can have different account structures while maintaining transaction integrity and proper double-entry bookkeeping.
