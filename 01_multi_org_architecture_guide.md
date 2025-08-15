# Multi-Organization SaaS Architecture Guide
## Cooperative Banking System Transformation

## Executive Summary

This document outlines the transformation of a single-organization cooperative banking system into a multi-tenant SaaS platform with complete data isolation between organizations. The approach ensures scalability while maintaining the double-entry bookkeeping integrity and existing functionality patterns.

## Current System Analysis

### Core Transaction Architecture
The system currently uses a robust double-entry bookkeeping system with:

1. **Transaction Head (`transaction_head`)**
   - Primary transaction metadata container
   - Fields: `voucher_no`, `trans_date`, `trans_amount`, `trans_narration`, `voucher_master_id`
   - Audit fields: `users_id`, `branch_id`, `session_id`

2. **Transaction Details (`transaction_details`)**
   - Individual debit/credit entries
   - Links to specific member accounts via `sub_accounts_id`
   - Amount handling with positive/negative values for debit/credit

3. **Account Structure**
   - `accounts`: Main account types (shares, loans, FD, RD, etc.)
   - `sub_accounts`: Individual member account instances
   - Product-specific tables: `fd_accounts`, `loan_accounts`, `recurring_accounts`, `saving_accounts`

4. **Date Management**
   - `calender` table with `yearly_trans_dates`, `current_day`, `day_end` flags
   - Manual date advancement for back-dated entry control

## Multi-Organization Architecture Strategy

### 1. Data Isolation Approach

#### Primary Strategy: Organization ID Column
Add `organization_id` to all tenant-specific tables to ensure complete data segregation.

#### Tables Requiring Organization Scoping

**Core Transaction Tables:**
```sql
ALTER TABLE transaction_head ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE transaction_details ADD COLUMN organization_id INTEGER NOT NULL;
```

**Member and Account Tables:**
```sql
ALTER TABLE members ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE accounts ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE sub_accounts ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE sub_accounts_balance ADD COLUMN organization_id INTEGER NOT NULL;
```

**Product-Specific Tables:**
```sql
ALTER TABLE fd_accounts ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE loan_accounts ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE recurring_accounts ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE saving_accounts ADD COLUMN organization_id INTEGER NOT NULL;
```

**Financial Management Tables:**
```sql
ALTER TABLE financial_years ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE calender ADD COLUMN organization_id INTEGER NOT NULL;
```

**Scheme and Configuration Tables:**
```sql
ALTER TABLE fd_schemes ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE loan_schemes ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE fd_interest_rate ADD COLUMN organization_id INTEGER NOT NULL;
ALTER TABLE loan_interest_rate ADD COLUMN organization_id INTEGER NOT NULL;
```

#### Tables Remaining System-Wide
- `branch` (if shared across orgs) or add org_id if org-specific
- System users and roles (with org association)
- System-level configuration tables

### 2. Organization Management Structure

#### Organizations Master Table
```sql
CREATE TABLE organizations (
    organization_id SERIAL PRIMARY KEY,
    organization_name VARCHAR(200) NOT NULL,
    organization_code VARCHAR(50) UNIQUE NOT NULL,
    registration_number VARCHAR(100),
    address TEXT,
    contact_info JSONB,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subscription_plan VARCHAR(50),
    license_valid_until DATE,
    CONSTRAINT chk_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'INACTIVE'))
);
```

#### User-Organization Association
```sql
CREATE TABLE user_organization_access (
    user_org_access_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    organization_id INTEGER NOT NULL,
    role VARCHAR(50) NOT NULL,
    access_level VARCHAR(20) DEFAULT 'USER',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, organization_id),
    CONSTRAINT chk_access_level CHECK (access_level IN ('ADMIN', 'USER', 'READ_ONLY'))
);
```

### 3. Organization-Specific vs System-Wide Settings

#### Organization-Specific Settings
```sql
CREATE TABLE organization_settings (
    setting_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'STRING',
    description TEXT,
    UNIQUE(organization_id, setting_key)
);
```

**Org-Specific Settings Include:**
- Interest calculation methods
- Voucher numbering sequences
- Account number formats
- Financial year definitions
- Local compliance rules
- Member registration workflows

#### System-Wide Settings
- Global application configuration
- System maintenance schedules
- Security policies
- Email templates (with org customization parameters)
- System user management

### 4. Voucher Number Management

#### Organization-Scoped Voucher Sequences
```sql
CREATE TABLE voucher_sequences (
    sequence_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    voucher_type VARCHAR(50) NOT NULL,
    financial_year INTEGER NOT NULL,
    current_number INTEGER DEFAULT 0,
    prefix VARCHAR(10),
    suffix VARCHAR(10),
    UNIQUE(organization_id, voucher_type, financial_year)
);
```

#### Voucher Number Generation Function
```sql
CREATE OR REPLACE FUNCTION get_next_voucher_number(
    p_org_id INTEGER,
    p_voucher_type VARCHAR,
    p_financial_year INTEGER
) RETURNS VARCHAR AS $$
DECLARE
    next_num INTEGER;
    voucher_no VARCHAR;
    prefix_val VARCHAR;
    suffix_val VARCHAR;
BEGIN
    -- Get and increment the sequence
    UPDATE voucher_sequences 
    SET current_number = current_number + 1
    WHERE organization_id = p_org_id 
    AND voucher_type = p_voucher_type 
    AND financial_year = p_financial_year
    RETURNING current_number, prefix, suffix 
    INTO next_num, prefix_val, suffix_val;
    
    -- If no sequence exists, create it
    IF NOT FOUND THEN
        INSERT INTO voucher_sequences (organization_id, voucher_type, financial_year, current_number, prefix)
        VALUES (p_org_id, p_voucher_type, p_financial_year, 1, 'VCH');
        next_num := 1;
        prefix_val := 'VCH';
    END IF;
    
    -- Format voucher number
    voucher_no := COALESCE(prefix_val, '') || LPAD(next_num::TEXT, 6, '0') || COALESCE(suffix_val, '');
    
    RETURN voucher_no;
END;
$$ LANGUAGE plpgsql;
```

### 5. Account Number Management

#### Organization-Scoped Account Numbers
```sql
CREATE TABLE account_number_sequences (
    sequence_id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    current_number INTEGER DEFAULT 0,
    prefix VARCHAR(10),
    format_pattern VARCHAR(50),
    UNIQUE(organization_id, account_type)
);
```

### 6. Date Management Per Organization

#### Organization-Specific Calendar
```sql
-- Enhanced calendar table
ALTER TABLE calender ADD COLUMN organization_id INTEGER;
ALTER TABLE calender ADD CONSTRAINT fk_calender_org 
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);

-- Create unique constraint for org-specific dates
ALTER TABLE calender ADD CONSTRAINT uk_calender_org_date 
    UNIQUE(organization_id, yearly_trans_dates);
```

#### Current Date Management Function
```sql
CREATE OR REPLACE FUNCTION get_current_business_date(p_org_id INTEGER) 
RETURNS DATE AS $$
DECLARE
    current_date DATE;
BEGIN
    SELECT yearly_trans_dates::DATE 
    INTO current_date
    FROM calender 
    WHERE organization_id = p_org_id 
    AND current_day = 'Y'
    LIMIT 1;
    
    RETURN current_date;
END;
$$ LANGUAGE plpgsql;
```

### 7. Database Constraints and Indexes

#### Organization-Scoped Indexes
```sql
-- Transaction tables
CREATE INDEX idx_transaction_head_org_date ON transaction_head(organization_id, trans_date);
CREATE INDEX idx_transaction_details_org_sub_acc ON transaction_details(organization_id, sub_accounts_id);

-- Member and account indexes
CREATE INDEX idx_members_org_status ON members(organization_id, status);
CREATE INDEX idx_sub_accounts_org_member ON sub_accounts(organization_id, members_id);

-- Product-specific indexes
CREATE INDEX idx_fd_accounts_org ON fd_accounts(organization_id);
CREATE INDEX idx_loan_accounts_org ON loan_accounts(organization_id);
```

#### Referential Integrity
```sql
-- Add foreign key constraints
ALTER TABLE members ADD CONSTRAINT fk_members_org 
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);
    
ALTER TABLE sub_accounts ADD CONSTRAINT fk_sub_accounts_org 
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);
    
-- Composite foreign keys for cross-table references within org
ALTER TABLE sub_accounts ADD CONSTRAINT fk_sub_accounts_member_org
    FOREIGN KEY (members_id, organization_id) REFERENCES members(members_id, organization_id);
```

### 8. Application Layer Changes

#### Session Management
```typescript
interface UserSession {
  userId: number;
  currentOrganizationId: number;
  organizationAccess: Array<{
    organizationId: number;
    role: string;
    accessLevel: string;
  }>;
}
```

#### Data Access Layer
```typescript
class BaseRepository {
  protected organizationId: number;
  
  constructor(organizationId: number) {
    this.organizationId = organizationId;
  }
  
  protected addOrgFilter(query: QueryBuilder) {
    return query.where('organization_id', this.organizationId);
  }
}

class TransactionRepository extends BaseRepository {
  async createTransaction(transactionData: TransactionHead): Promise<number> {
    // Ensure organization context
    transactionData.organization_id = this.organizationId;
    
    // Generate voucher number for this org
    const voucherNo = await this.getNextVoucherNumber(
      transactionData.voucher_master_id,
      transactionData.financial_years_id
    );
    
    transactionData.voucher_no = voucherNo;
    
    return await this.insert(transactionData);
  }
}
```

#### Transaction Management with Org Context
```typescript
class TransactionService {
  async recordTransaction(
    orgId: number,
    transactionHead: TransactionHead,
    transactionDetails: TransactionDetail[]
  ): Promise<void> {
    const transaction = await db.beginTransaction();
    
    try {
      // Ensure all data is org-scoped
      transactionHead.organization_id = orgId;
      
      // Create transaction head
      const headId = await this.transactionRepo.create(transactionHead);
      
      // Create transaction details with org context
      for (const detail of transactionDetails) {
        detail.organization_id = orgId;
        detail.transaction_head_id = headId;
        
        // Validate sub_account belongs to same org
        await this.validateSubAccountOrg(detail.sub_accounts_id, orgId);
        
        await this.transactionDetailsRepo.create(detail);
      }
      
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
}
```

### 9. Migration Strategy

#### Phase 1: Schema Updates
1. Add organization table
2. Add organization_id columns to existing tables
3. Create default organization for existing data
4. Update existing data with default organization_id

#### Phase 2: Application Updates
1. Update all queries to include organization context
2. Implement user-organization access control
3. Update voucher and account number generation
4. Modify reporting to be org-scoped

#### Phase 3: Testing and Validation
1. Test data isolation between organizations
2. Validate transaction integrity within each org
3. Test user access controls
4. Performance testing with multiple orgs

### 10. Security Considerations

#### Data Isolation Validation
```sql
-- Row Level Security (RLS) as additional protection
ALTER TABLE transaction_head ENABLE ROW LEVEL SECURITY;

CREATE POLICY transaction_head_org_policy ON transaction_head
    FOR ALL TO application_role
    USING (organization_id = current_setting('app.current_organization_id')::INTEGER);
```

#### API Security
```typescript
// Middleware to ensure organization context
async function validateOrgAccess(req: Request, res: Response, next: NextFunction) {
  const requestedOrgId = req.params.organizationId || req.body.organization_id;
  const userOrgAccess = req.user.organizationAccess;
  
  if (!userOrgAccess.find(access => access.organizationId === requestedOrgId)) {
    return res.status(403).json({ error: 'Organization access denied' });
  }
  
  req.organizationId = requestedOrgId;
  next();
}
```

### 11. Performance Considerations

#### Partitioning Strategy (Future Enhancement)
```sql
-- Consider table partitioning for large organizations
CREATE TABLE transaction_head_partitioned (
    LIKE transaction_head INCLUDING ALL
) PARTITION BY HASH (organization_id);

-- Create partitions
CREATE TABLE transaction_head_p0 PARTITION OF transaction_head_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);
```

#### Query Optimization
- Ensure all queries include organization_id in WHERE clauses
- Create composite indexes starting with organization_id
- Monitor query performance across organizations

### 12. Backup and Recovery

#### Organization-Specific Backups
```bash
# Script for org-specific data export
pg_dump -t "transaction_head" \
        -t "transaction_details" \
        -t "members" \
        --where "organization_id = 1" \
        cooperative_db > org_1_backup.sql
```

## Implementation Checklist

### Database Changes
- [ ] Create organizations table
- [ ] Add organization_id to all tenant tables
- [ ] Update foreign key constraints
- [ ] Create org-scoped indexes
- [ ] Implement voucher sequences per org
- [ ] Update calendar management for multi-org

### Application Changes  
- [ ] Update all repository classes for org context
- [ ] Implement user-organization access control
- [ ] Modify transaction processing for org isolation
- [ ] Update voucher and account number generation
- [ ] Implement org-specific settings management

### Testing
- [ ] Data isolation validation
- [ ] Transaction integrity testing
- [ ] User access control testing
- [ ] Performance testing with multiple orgs
- [ ] Backup and recovery testing

### Security
- [ ] Row level security policies
- [ ] API endpoint protection
- [ ] Audit logging for cross-org access attempts
- [ ] Data encryption at rest and transit

## Conclusion

This multi-organization architecture ensures complete data isolation while preserving the robust double-entry bookkeeping system. The organization-scoped approach maintains data integrity and provides a scalable foundation for SaaS operations. Each organization operates independently with its own voucher sequences, account numbers, and financial calendars, while sharing the underlying application infrastructure.

The implementation maintains backward compatibility with existing transaction logic while adding the necessary layers for multi-tenancy. This approach ensures that cooperative banking operations remain uninterrupted during the transition to a multi-organization platform.
