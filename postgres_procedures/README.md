# PostgreSQL Stored Procedures for Microfinance Application

This directory contains PostgreSQL stored procedures converted from the original SQL Server procedures, along with additional microfinance-specific functions to support your application.

## File Structure

1. **01_sp_balance.sql** - Account balance calculations
2. **02_sp_sub_accounts_statement.sql** - Sub-account statement generation  
3. **03_sp_sub_accounts_balance.sql** - Running balance calculations with daily totals
4. **04_branch_procedures.sql** - Branch management operations
5. **05_gl_head_balance.sql** - General ledger and financial reporting procedures
6. **06_microfinance_procedures.sql** - Core microfinance operations (interest posting, loan management, member portfolio)

## Key Features

### 🏦 **Core Banking Operations**
- Balance calculations with financial year support
- Sub-account statement generation
- General ledger operations
- Trial balance and financial reports

### 💰 **Interest Management**
- **Automatic interest posting** for savings and loans
- **Daily interest calculations** with proper accruals
- **Interest rate management** by product type

### 📊 **Loan Management** 
- **EMI calculations** using standard formulas
- **Loan repayment processing** with principal/interest allocation
- **Loan schedule generation** with amortization
- **Outstanding balance tracking**

### 👥 **Member Management**
- **Complete member portfolio** views
- **Multi-product balance summaries**
- **Transaction history tracking**

### 📈 **Financial Reporting**
- **Balance sheet generation**
- **Profit & Loss statements**
- **Trial balance reports**
- **Branch-wise statistics**

## Installation

### 1. Prerequisites
```bash
# Ensure PostgreSQL is installed and running
# Create necessary sequences (if not already created)
```

### 2. Deploy Procedures
```bash
# Run each file in order:
psql -U your_username -d your_database -f 01_sp_balance.sql
psql -U your_username -d your_database -f 02_sp_sub_accounts_statement.sql
psql -U your_username -d your_database -f 03_sp_sub_accounts_balance.sql
psql -U your_username -d your_database -f 04_branch_procedures.sql
psql -U your_username -d your_database -f 05_gl_head_balance.sql
psql -U your_username -d your_database -f 06_microfinance_procedures.sql
```

### 3. Create Required Sequences
```sql
-- Create sequence for voucher numbers
CREATE SEQUENCE IF NOT EXISTS voucher_seq START 1;
```

## Usage Examples

### Balance Operations
```sql
-- Get balances for specific accounts
SELECT * FROM sp_balance('1,4,5,34', '2024-12-31', 'admin_user', ',', 1);

-- Get current balance for a sub-account
SELECT get_sub_account_current_balance(4, 1931, '2024-12-31');

-- Get account balance summary
SELECT * FROM get_account_balance_summary(4);
```

### Interest Posting
```sql
-- Post daily savings interest
SELECT * FROM post_savings_interest('2024-12-31', 'admin_user');

-- Post daily loan interest
SELECT * FROM post_loan_interest('2024-12-31', 'admin_user');
```

### Loan Management
```sql
-- Calculate EMI for a loan
SELECT calculate_emi(100000, 12.5, 60); -- ₹100k @ 12.5% for 60 months

-- Generate loan repayment schedule
SELECT * FROM generate_loan_schedule(1);

-- Process loan repayment
SELECT * FROM process_loan_repayment(1, 5000.00, '2024-12-31');
```

### Member Portfolio
```sql
-- Get complete member portfolio
SELECT * FROM get_member_portfolio(1037);
```

### Financial Reports
```sql
-- Trial balance
SELECT * FROM get_trial_balance('2024-12-31');

-- Balance sheet
SELECT * FROM get_balance_sheet('2024-12-31');

-- Profit & Loss statement
SELECT * FROM get_profit_loss_statement('2024-01-01', '2024-12-31');
```

### Branch Management
```sql
-- Add new branch
SELECT add_branch(NULL, 'New Branch', '123 Street', 'REG001', '2024-01-01', 0);

-- Get branch statistics
SELECT * FROM get_branch_statistics(1, '2024-01-01', '2024-12-31');
```

## Key Improvements Over Original

### 🚀 **Performance**
- **Set-based operations** instead of cursors where possible
- **Proper indexing** recommendations included
- **Window functions** for running calculations
- **Optimized joins** and query patterns

### 🛡️ **Error Handling**
- **Proper exception handling** with meaningful messages
- **Input validation** and null checks
- **Transaction rollback** on errors
- **Data consistency** checks

### 🔧 **Modern PostgreSQL Features**
- **RETURNS TABLE** for better result handling
- **DEFAULT parameters** for easier function calls
- **Array operations** for string splitting
- **Date/time functions** for calculations

### 📊 **Enhanced Functionality**
- **Financial year support** in balance calculations
- **Multi-branch operations**
- **Comprehensive reporting** functions
- **Member portfolio** management

## Integration with Your App

### Daily Operations
```sql
-- End-of-day interest posting (run daily)
SELECT * FROM post_savings_interest();
SELECT * FROM post_loan_interest();
```

### Monthly Operations
```sql
-- Month-end reports
SELECT * FROM get_trial_balance();
SELECT * FROM get_balance_sheet();
```

### Transaction Processing
```sql
-- Process loan repayments
SELECT * FROM process_loan_repayment(loan_id, amount);

-- Check member balances
SELECT * FROM get_member_portfolio(member_id);
```

## Performance Considerations

### Indexing
The procedures assume these indexes exist:
```sql
CREATE INDEX IF NOT EXISTS idx_sub_accounts_balance_trans_by ON sub_accounts_balance(trans_by);
CREATE INDEX IF NOT EXISTS idx_transaction_details_composite ON transaction_details(accounts_id, sub_accounts_id);
CREATE INDEX IF NOT EXISTS idx_transaction_head_date_year ON transaction_head(trans_date, financial_years_id);
CREATE INDEX IF NOT EXISTS idx_sub_accounts_member ON sub_accounts(members_id);
CREATE INDEX IF NOT EXISTS idx_loan_accounts_status ON loan_accounts(status);
CREATE INDEX IF NOT EXISTS idx_saving_accounts_status ON saving_accounts(status);
```

### Batch Processing
For large datasets, consider:
- Running interest posting in smaller batches
- Using background jobs for heavy calculations
- Implementing proper logging and monitoring

## Troubleshooting

### Common Issues
1. **Missing sequences**: Create voucher_seq if transactions fail
2. **Account not found**: Ensure account names match exactly in procedures
3. **Permission issues**: Grant EXECUTE permissions on functions
4. **Date format**: Use YYYY-MM-DD format for dates

### Debug Mode
Add this to procedures for debugging:
```sql
RAISE NOTICE 'Debug: Processing account %', account_id;
```

## Next Steps

1. **Test procedures** with your actual data
2. **Customize account names** in procedures to match your setup
3. **Add application-specific logic** as needed
4. **Set up monitoring** for daily operations
5. **Create backup procedures** for critical functions

## Support

These procedures are optimized for PostgreSQL 12+ and follow microfinance industry standards. They maintain the original logic while leveraging modern PostgreSQL capabilities for better performance and maintainability.
