#!/bin/bash

# PostgreSQL Stored Procedures Deployment Script
# Usage: ./deploy.sh [database_name] [username]

set -e  # Exit on error

# Configuration
DB_NAME=${1:-"microfinance_db"}
DB_USER=${2:-"postgres"}
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"5432"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Microfinance PostgreSQL Procedures Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if PostgreSQL is running
echo -e "${YELLOW}Checking PostgreSQL connection...${NC}"
if ! pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; then
    echo -e "${RED}Error: Cannot connect to PostgreSQL at ${DB_HOST}:${DB_PORT}${NC}"
    echo "Please ensure PostgreSQL is running and accessible."
    exit 1
fi

echo -e "${GREEN}✓ PostgreSQL connection successful${NC}"
echo ""

# Function to execute SQL file
execute_sql_file() {
    local file=$1
    local description=$2
    
    echo -e "${YELLOW}Deploying: $description${NC}"
    echo "File: $file"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File $file not found${NC}"
        return 1
    fi
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully deployed $description${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to deploy $description${NC}"
        echo "Run the following command to see detailed error:"
        echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $file"
        return 1
    fi
}

# Create necessary sequences first
echo -e "${YELLOW}Creating required sequences...${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
CREATE SEQUENCE IF NOT EXISTS voucher_seq START 1;
" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Sequences created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create sequences${NC}"
fi
echo ""

# Deploy procedures in order
echo -e "${BLUE}Deploying stored procedures...${NC}"
echo ""

# Array of files and descriptions
declare -a files=(
    "01_sp_balance.sql:Account Balance Calculations"
    "02_sp_sub_accounts_statement.sql:Sub-Account Statement Generation"
    "03_sp_sub_accounts_balance.sql:Running Balance Calculations"
    "04_branch_procedures.sql:Branch Management Operations"
    "05_gl_head_balance.sql:General Ledger & Financial Reports"
    "06_microfinance_procedures.sql:Core Microfinance Operations"
)

failed_count=0
success_count=0

for item in "${files[@]}"; do
    IFS=':' read -r file description <<< "$item"
    
    if execute_sql_file "$file" "$description"; then
        ((success_count++))
    else
        ((failed_count++))
    fi
    echo ""
done

# Create recommended indexes
echo -e "${YELLOW}Creating recommended indexes for performance...${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 << 'EOF' > /dev/null 2>&1
-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_sub_accounts_balance_trans_by ON sub_accounts_balance(trans_by);
CREATE INDEX IF NOT EXISTS idx_transaction_details_composite ON transaction_details(accounts_id, sub_accounts_id);
CREATE INDEX IF NOT EXISTS idx_transaction_head_date_year ON transaction_head(trans_date, financial_years_id);
CREATE INDEX IF NOT EXISTS idx_sub_accounts_member ON sub_accounts(members_id);
CREATE INDEX IF NOT EXISTS idx_loan_accounts_status ON loan_accounts(status);
CREATE INDEX IF NOT EXISTS idx_saving_accounts_status ON saving_accounts(status);
CREATE INDEX IF NOT EXISTS idx_transaction_head_branch ON transaction_head(branch_id);
CREATE INDEX IF NOT EXISTS idx_members_status ON members(status);
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Performance indexes created successfully${NC}"
else
    echo -e "${YELLOW}⚠ Some indexes may already exist (this is normal)${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Successful deployments: $success_count${NC}"
echo -e "${RED}Failed deployments: $failed_count${NC}"

if [ $failed_count -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All procedures deployed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Quick Test Commands:${NC}"
    echo "# Test balance calculation:"
    echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \"SELECT get_sub_account_current_balance(1, 1, CURRENT_DATE);\""
    echo ""
    echo "# Test member portfolio:"
    echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \"SELECT * FROM get_member_portfolio(1) LIMIT 1;\""
    echo ""
    echo -e "${BLUE}For more examples, see README.md${NC}"
else
    echo ""
    echo -e "${RED}⚠ Some deployments failed. Please check the errors above.${NC}"
    echo "You can run individual files manually to see detailed error messages."
    exit 1
fi

# Verify deployment by listing functions
echo ""
echo -e "${YELLOW}Verifying deployed functions...${NC}"
function_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
SELECT COUNT(*) FROM information_schema.routines 
WHERE routine_type = 'FUNCTION' 
AND routine_name IN (
    'sp_balance', 'sp_sub_accounts_statement', 'sp_sub_accounts_balance', 
    'add_branch', 'sp_glhead_balance', 'post_savings_interest',
    'post_loan_interest', 'calculate_emi', 'generate_loan_schedule',
    'process_loan_repayment', 'get_member_portfolio'
);
" 2>/dev/null | tr -d ' ')

echo "Functions deployed: $function_count"

if [ "$function_count" -gt "10" ]; then
    echo -e "${GREEN}✓ Function verification successful${NC}"
else
    echo -e "${YELLOW}⚠ Some functions may not have been deployed correctly${NC}"
fi

echo ""
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the README.md for usage examples"
echo "2. Test the procedures with your data"
echo "3. Customize account names in procedures if needed"
echo "4. Set up daily/monthly job schedules for interest posting"
