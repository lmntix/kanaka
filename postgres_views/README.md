# PostgreSQL Views for Microfinance Application

This directory contains PostgreSQL views converted from the original SQL Server views, along with additional microfinance-specific reporting views to support your application.

## File Structure

1. **01_balance_account_views.sql** - Balance calculations and account summary views
2. **02_member_management_views.sql** - Member profile, eligibility, and activity views  
3. **03_product_specific_views.sql** - Savings, Loan, FD, and RD product views
4. **04_transaction_recovery_views.sql** - Transaction processing and recovery management views
5. **05_additional_microfinance_views.sql** - Advanced analysis and reporting views

## View Categories

### 🏦 **Balance & Account Views (01_balance_account_views.sql)**
- `view_sub_account_balance` - Sub-account balances for assets and liabilities
- `view_members_bal` - Member-wise balances for specific accounts
- `view_balance_brief` - Brief balance view with date filters
- `view_current_sub_account_balances` - Comprehensive current balances with member details
- `view_member_portfolio_summary` - Complete member portfolio across all products
- `view_account_balance_summary` - Account-wise balance summaries with debit/credit breakdown

### 👥 **Member Management Views (02_member_management_views.sql)**
- `view_member_without_loan` - Members without active loans
- `view_not_received_member_list` - Members with outstanding demands
- `view_member_profile` - Complete member profiles with contact details
- `view_loan_eligible_members` - Loan eligibility assessment with business rules
- `view_member_transaction_summary` - Member transaction activity analysis
- `view_inactive_members` - Members with no recent activity
- `view_member_kyc_status` - KYC compliance and document verification status

### 💰 **Product-Specific Views (03_product_specific_views.sql)**
- `view_saving_joint_acc` - Savings joint account holders with contact details
- `view_fd_joint_acc` - FD joint account holders with member information
- `view_recurring_joint_acc` - RD joint account holders
- `view_loan_co_app_acc` - Loan co-applicants with contact information
- `view_savings_account_details` - Comprehensive savings account information
- `view_loan_account_details` - Detailed loan account status and payment information
- `view_fd_account_details` - FD accounts with maturity and interest calculations
- `view_rd_trans` - RD transaction details
- `view_product_performance_summary` - Performance across all product types

### 📊 **Transaction & Recovery Views (04_transaction_recovery_views.sql)**
- `view_recovery_details` - Recovery details with product-wise breakdown
- `view_incomp_dr_cash_trans` - Incomplete debit cash transactions
- `view_incomp_dr_trans` - Detailed incomplete transaction analysis
- `view_member_transaction_summary_detailed` - Monthly member transaction summaries
- `view_daily_transaction_summary` - Daily transaction volume analysis
- `view_failed_pending_transactions` - Failed or pending transactions needing attention
- `view_recovery_performance_analysis` - Recovery efficiency and performance metrics
- `view_transaction_audit_trail` - Complete transaction audit trail

### 📈 **Advanced Microfinance Views (05_additional_microfinance_views.sql)**
- `view_loan_overdue_analysis` - Comprehensive overdue analysis with risk classification
- `view_interest_accrual_summary` - Monthly interest accrual across products
- `view_member_growth_analysis` - Member growth and retention metrics
- `view_product_penetration_analysis` - Product cross-sell and penetration analysis
- `view_branch_performance_comparison` - Branch-wise performance comparison
- `view_financial_health_indicators` - Key financial health and portfolio quality metrics
- `view_monthly_business_dashboard` - Executive dashboard with KPIs

## Installation

### 1. Deploy Views
```bash
# Run each file in order:
psql -U your_username -d your_database -f 01_balance_account_views.sql
psql -U your_username -d your_database -f 02_member_management_views.sql
psql -U your_username -d your_database -f 03_product_specific_views.sql
psql -U your_username -d your_database -f 04_transaction_recovery_views.sql
psql -U your_username -d your_database -f 05_additional_microfinance_views.sql
```

### 2. Grant Permissions
```sql
-- Grant SELECT permissions to application users
GRANT SELECT ON ALL TABLES IN SCHEMA public TO your_app_user;
```

## Usage Examples

### Dashboard Queries
```sql
-- Monthly business dashboard
SELECT * FROM view_monthly_business_dashboard;

-- Portfolio health check
SELECT * FROM view_financial_health_indicators;

-- Branch performance comparison
SELECT * FROM view_branch_performance_comparison;
```

### Member Analysis
```sql
-- Member portfolio summary
SELECT * FROM view_member_portfolio_summary WHERE members_id = 1037;

-- Loan eligible members
SELECT * FROM view_loan_eligible_members 
WHERE overall_eligibility = 'ELIGIBLE' 
ORDER BY savings_balance DESC;

-- Inactive members for reactivation campaigns
SELECT * FROM view_inactive_members 
WHERE days_since_last_transaction > 180;
```

### Risk Management
```sql
-- Overdue loan analysis
SELECT * FROM view_loan_overdue_analysis 
WHERE risk_category IN ('SUBSTANDARD', 'DOUBTFUL', 'LOSS')
ORDER BY overdue_days DESC;

-- Recovery performance
SELECT * FROM view_recovery_performance_analysis
WHERE recovery_date >= CURRENT_DATE - INTERVAL '3 months';
```

### Product Management
```sql
-- Product penetration analysis
SELECT * FROM view_product_penetration_analysis;

-- Savings account details
SELECT * FROM view_savings_account_details 
WHERE status_description = 'Active'
ORDER BY current_balance DESC;

-- FD maturity schedule
SELECT * FROM view_fd_account_details 
WHERE maturity_status = 'Due for Maturity'
ORDER BY days_to_maturity;
```

### Transaction Monitoring
```sql
-- Daily transaction summary
SELECT * FROM view_daily_transaction_summary 
WHERE transaction_date >= CURRENT_DATE - INTERVAL '7 days';

-- Failed transactions needing attention
SELECT * FROM view_failed_pending_transactions;

-- Member transaction activity
SELECT * FROM view_member_transaction_summary_detailed
ORDER BY total_transactions DESC;
```

### Interest Management
```sql
-- Interest accrual summary
SELECT * FROM view_interest_accrual_summary;

-- Interest posting verification
SELECT 
    product_type,
    accounts_processed,
    total_interest_accrued,
    avg_interest_per_account
FROM view_interest_accrual_summary;
```

## Key Features

### 🚀 **Performance Optimized**
- **Proper indexing** recommendations included
- **Efficient joins** and query patterns
- **Date range filtering** for better performance
- **Aggregation optimization** using window functions

### 📊 **Business Intelligence Ready**
- **KPI calculations** built into views
- **Trend analysis** with period comparisons
- **Risk classification** with standardized buckets
- **Executive dashboards** with key metrics

### 🛡️ **Data Quality**
- **Null handling** with COALESCE functions
- **Data validation** through business rules
- **Status filtering** for active records only
- **Balance reconciliation** checks

### 🔧 **Modern PostgreSQL Features**
- **Window functions** for running calculations
- **CTEs (WITH clauses)** for complex logic
- **CASE statements** for business rules
- **Date functions** for period analysis

## Integration with Your App

### API Layer Integration
```javascript
// Dashboard data
const dashboardData = await db.query('SELECT * FROM view_monthly_business_dashboard');

// Member portfolio
const memberPortfolio = await db.query(
  'SELECT * FROM view_member_portfolio_summary WHERE members_id = $1', 
  [memberId]
);

// Risk analysis
const overdueLoans = await db.query(`
  SELECT * FROM view_loan_overdue_analysis 
  WHERE overdue_bucket <> 'CURRENT' 
  ORDER BY overdue_days DESC
`);
```

### Report Generation
```sql
-- Monthly portfolio report
SELECT 
    product_type,
    total_accounts,
    total_active_balance,
    avg_active_balance
FROM view_product_performance_summary;

-- Member growth report
SELECT 
    period,
    new_members,
    retention_30_day_pct,
    retention_90_day_pct
FROM view_member_growth_analysis
ORDER BY period DESC;
```

### Automated Alerts
```sql
-- High-risk loans alert
SELECT COUNT(*) as high_risk_loans
FROM view_loan_overdue_analysis 
WHERE risk_category IN ('DOUBTFUL', 'LOSS');

-- Portfolio health alert
SELECT portfolio_health_status
FROM view_financial_health_indicators;
```

## Performance Considerations

### View Dependencies
Some views depend on others:
- `view_loan_overdue_analysis` ← used by `view_financial_health_indicators`
- `view_sub_account_balance` ← used by many other views
- `view_member_portfolio_summary` ← used by member analysis views

### Refresh Strategies
For better performance with large datasets:
```sql
-- Create materialized views for heavy queries
CREATE MATERIALIZED VIEW mv_monthly_business_dashboard AS
SELECT * FROM view_monthly_business_dashboard;

-- Refresh periodically
REFRESH MATERIALIZED VIEW mv_monthly_business_dashboard;
```

### Indexing Recommendations
The views assume these indexes exist:
```sql
-- Already created in view files
CREATE INDEX idx_transaction_details_account_sub ON transaction_details(accounts_id, sub_accounts_id);
CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_loan_accounts_status_members ON loan_accounts(status, members_id);
-- ... and more
```

## Customization

### Account-Specific Filters
Many views filter by account IDs. Update these to match your setup:
```sql
-- In view_members_bal, change account ID as needed
WHERE td.accounts_id = 3 -- Update this

-- In view_rd_trans, update RD account ID
WHERE td.accounts_id = 76 -- Update this
```

### Business Rules
Modify business rules in views to match your policies:
```sql
-- In view_loan_eligible_members
WHEN COALESCE(savings.total_balance, 0) >= 500 THEN 'Y'  -- Adjust minimum savings

-- In view_loan_overdue_analysis  
WHEN CURRENT_DATE - la.end_date::DATE <= 30 THEN 'OVERDUE_1_30' -- Adjust buckets
```

### Date Ranges
Adjust date ranges for analysis views:
```sql
-- Change analysis periods as needed
WHERE th.trans_date >= CURRENT_DATE - INTERVAL '30 days' -- Adjust period
```

## Troubleshooting

### Common Issues
1. **View dependencies**: Deploy views in the correct order (01, 02, 03, 04, 05)
2. **Missing tables**: Ensure base tables exist before creating views
3. **Performance**: Use EXPLAIN ANALYZE to check query performance
4. **Data types**: Verify date/numeric field casting works with your data

### Debug Queries
```sql
-- Check view definition
\d+ view_name

-- Test view performance
EXPLAIN ANALYZE SELECT * FROM view_name LIMIT 100;

-- Check for missing data
SELECT COUNT(*) FROM view_name WHERE field IS NULL;
```

## Next Steps

1. **Deploy views** in order using the provided files
2. **Test queries** with your actual data
3. **Create materialized views** for frequently accessed reports
4. **Set up refresh schedules** for materialized views
5. **Integrate with your application** API layer
6. **Create additional custom views** as needed

These views provide a comprehensive foundation for microfinance reporting and analysis while maintaining good performance and following PostgreSQL best practices.
