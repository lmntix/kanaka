# Database Enums Analysis and Recommendations

## Overview
This document identifies all tables with enum-like fields and provides PostgreSQL enum type recommendations based on actual data patterns and system_constants mappings. Foreign key relationships are excluded as they cannot be enums.

## Core System Status and Type Enums

### **Account Status Types**

#### **General Account Status** (Used by multiple tables)
**System Constants Type 11**: General Status
- `1` → `active` - Active
- `4` → `inactive` - Inactive

**Tables Using This Pattern:**
- `accounts.status` (227 active, 2 inactive)
- `bank_accounts.status` (2 active)

```sql
CREATE TYPE general_status AS ENUM ('active', 'inactive');
```

#### **Entity Status with Close** (Common pattern for member accounts)
**System Constants Type 2**: Account Status
- `1` → `active` - Open
- `2` → `frozen` - Freeze  
- `4` → `closed` - Close

**Tables Using This Pattern:**
- `sub_accounts.status` (7458 active, 4086 closed)
- `loan_accounts.status` (968 active, 2314 closed)
- `recurring_accounts.status` (2334 active, 1440 closed)
- `fd_accounts.status` (48 active, 255 closed)
- `saving_accounts.status` (12 active, 57 closed)

```sql
CREATE TYPE account_entity_status AS ENUM ('active', 'frozen', 'closed');
```

#### **Cheque Status** (For cheque_register)
**Tables Using This Pattern:**
- `cheque_register.status` (33068 active, 236 other)

```sql
CREATE TYPE cheque_status AS ENUM ('active', 'cleared', 'cancelled', 'bounced');
```

### **Balance and Account Types**

#### **Balance Type**
**Tables Using This Pattern:**
- `accounts.balance_type` (78 credit, 110 debit, 41 both)

```sql
CREATE TYPE balance_type AS ENUM (
    'credit',  -- 1 (Credit Balance - Liabilities/Income)
    'debit',   -- 2 (Debit Balance - Assets/Expenses)
    'both'     -- 3 (Can be either debit or credit)
);
```

#### **Account Primary Group**
**Tables Using This Pattern:**
- `account_groups.account_primary_group`

```sql
CREATE TYPE account_primary_group_type AS ENUM (
    'income',     -- 1
    'expense',    -- 2
    'asset',      -- 3  
    'liability'   -- 4
);
```

## Member and Personal Information Enums

### **Member Types**
**System Constants Type 3**: Member Types
- `1` → `regular` - Regular member
- `2` → `nominal` - Nominal member  
- `3` → `nominal_other` - Nominal other member

**Tables Using This Pattern:**
- `members.type` (3726 regular, 46 nominal, 49 nominal_other)

```sql
CREATE TYPE member_type AS ENUM ('regular', 'nominal', 'nominal_other');
```

### **Gender Types**
**System Constants Type 4**: Gender
- `1` → `male` - Male
- `2` → `female` - Female
- `0` → `unspecified` - Not specified

**Tables Using This Pattern:**
- `members.gender` (1997 male, 1808 female, 16 unspecified)

```sql
CREATE TYPE gender_type AS ENUM ('male', 'female', 'unspecified');
```

### **Prefix Types**
**System Constants Type 1**: Name Prefixes
- `1` → `mr` - Mr.
- `2` → `mrs` - Mrs.
- `3` → `shrimati` - Shrimati.
- `4` → `miss` - Miss.
- `5` → `master` - Master.
- `6` → `ms` - M/s.

```sql
CREATE TYPE name_prefix AS ENUM ('mr', 'mrs', 'shrimati', 'miss', 'master', 'ms');
```

## Transaction and Voucher Enums

### **Voucher Types**
**System Constants Type 5**: Voucher Types
- `1` → `credit_receipt` - Credit(receipt)
- `2` → `debit_payment` - Debit(payment)
- `3` → `journal_voucher` - Journal voucher
- `4` → `contra` - Contra
- `5` → `opening_balance` - Opening balance

**Tables Using This Pattern:**
- `transaction_head.voucher_master_id` (2780×1, 1×2, 6×3, 48119×4)

```sql
CREATE TYPE voucher_type AS ENUM (
    'credit_receipt', 
    'debit_payment', 
    'journal_voucher', 
    'contra', 
    'opening_balance'
);
```

### **Cheque Types**
**Tables Using This Pattern:**
- `cheque_register.cheque_type` (28389×1, 4915×2)

```sql
CREATE TYPE cheque_type AS ENUM (
    'outgoing',  -- 1
    'incoming'   -- 2
);
```

## Financial Scheme Enums

### **Interest Type**
**Tables Using This Pattern:**
- `recurring_schemes.interest_type` 
- `fd_schemes.interest_type`
- `saving_schemes.interest_type`

```sql
CREATE TYPE interest_type AS ENUM (
    'none',         -- 0
    'simple',       -- 1
    'compound',     -- 2
    'other'         -- 3+
);
```

### **Compounding Frequency**
**System Constants Type 61**: Frequency patterns
- `0` → `none` - No compounding
- `4` → `monthly` - Monthly
- `6` → `quarterly` - Quarterly  
- `8` → `yearly` - Yearly

**Tables Using This Pattern:**
- `recurring_schemes.compounding`
- `fd_schemes.compounding`

```sql
CREATE TYPE compounding_frequency AS ENUM (
    'none',
    'monthly',
    'quarterly', 
    'half_yearly',
    'yearly'
);
```

## Employee and Management Enums

### **Employee Status**
**Tables Using This Pattern:**
- `employees.current_employee`
- `employees.director_employee`

```sql
CREATE TYPE employee_status AS ENUM ('active', 'inactive');

CREATE TYPE director_status AS ENUM (
    'active',      -- 1
    'inactive'     -- 2
);
```

### **Designation Types**
**System Constants Type 52**: Designations
```sql
CREATE TYPE designation_type AS ENUM (
    'chairman',         -- 1
    'vice_chairman',    -- 3
    'director',         -- 4
    'secretary',        -- 5
    'advisor',          -- 6
    'other'             -- 7
);
```

## Operational Enums

### **Boolean Flags**
Many tables use `'1'`/`'0'` for boolean values that should be converted:

**Tables Using This Pattern:**
- `accounts.memberwise_acc` (59 true, 170 false)
- `category.delete_flag` (10 false)
- Various flag fields across multiple tables

```sql
-- These should be converted to actual BOOLEAN columns
ALTER TABLE accounts ALTER COLUMN memberwise_acc TYPE BOOLEAN USING memberwise_acc = '1';
ALTER TABLE category ALTER COLUMN delete_flag TYPE BOOLEAN USING delete_flag = '1';
```

### **Mode of Operation**
**System Constants Type 18**: Mode of Operation
- `1` → `main_holder_only` - Main account holder only
- `2` → `joint_holder_only` - Joint account holder only
- `3` → `both_compulsory` - Both account holders compulsory
- `4` → `any_one` - Any one holder
- `5` → `self` - Self
- `6` → `any_two` - Any Two Account Holder

```sql
CREATE TYPE mode_of_operation AS ENUM (
    'main_holder_only',
    'joint_holder_only', 
    'both_compulsory',
    'any_one',
    'self',
    'any_two'
);
```

## Application Status Enums

### **Application Status**
**System Constants Type 71**: Application Status
- `1` → `open` - Open
- `2` → `approved` - Approved
- `3` → `rejected` - Rejected
- `4` → `pending` - Pending
- `5` → `closed` - Close

```sql
CREATE TYPE application_status AS ENUM (
    'open',
    'approved', 
    'rejected',
    'pending',
    'closed'
);
```

### **Dividend Calculation Type**
**Tables Using This Pattern:**
- `dividend_setting.div_calc_type`

```sql
CREATE TYPE dividend_calc_type AS ENUM (
    'amount_based',    -- 1
    'percentage_based', -- 2
    'hybrid'           -- 3
);
```

## Implementation Summary

### **Recommended Migration Approach:**

1. **Phase 1: Core Status Types**
   - Convert all status fields to appropriate enum types
   - Convert boolean flags from text to actual boolean

2. **Phase 2: Business Logic Types**
   - Convert member types, gender, prefixes
   - Convert voucher and transaction types

3. **Phase 3: Scheme and Financial Types**
   - Convert interest and compounding types
   - Convert mode of operation types

4. **Phase 4: Operational Types**
   - Convert application statuses
   - Convert remaining specialized enums

### **Benefits of Enum Conversion:**
- **Type Safety**: Prevents invalid values at database level
- **Performance**: More efficient storage and indexing
- **Documentation**: Self-documenting field values
- **Query Optimization**: Better query planner statistics
- **Data Integrity**: Referential integrity for lookup values

### **Tables Most Benefiting from Enums:**
1. **accounts** - balance_type, status, memberwise_acc (boolean)
2. **members** - type, gender, prefix
3. **sub_accounts** - status  
4. **transaction_head** - voucher_master_id
5. **All scheme tables** - status, interest_type, compounding
6. **All account tables** - status fields

This enum system will significantly improve the database's type safety and maintainability while preserving all existing functionality.
