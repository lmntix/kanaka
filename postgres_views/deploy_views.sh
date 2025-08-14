#!/bin/bash

# PostgreSQL Views Deployment Script
# Usage: ./deploy_views.sh [database_name] [username]

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
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Microfinance PostgreSQL Views Deployment${NC}"
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
execute_view_file() {
    local file=$1
    local description=$2
    local view_count=$3
    
    echo -e "${YELLOW}Deploying: $description${NC}"
    echo "File: $file"
    echo "Expected Views: $view_count"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File $file not found${NC}"
        return 1
    fi
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully deployed $description${NC}"
        
        # Count created views (basic validation)
        local created_views=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
            SELECT COUNT(*) 
            FROM information_schema.views 
            WHERE table_schema = 'public' 
            AND table_name LIKE 'view_%'
        " 2>/dev/null | tr -d ' ')
        
        echo -e "${PURPLE}   Total views in database: $created_views${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to deploy $description${NC}"
        echo "Run the following command to see detailed error:"
        echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $file"
        return 1
    fi
}

# Check for existing views and warn user
existing_views=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
    SELECT COUNT(*) 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name LIKE 'view_%'
" 2>/dev/null | tr -d ' ')

if [ "$existing_views" -gt "0" ]; then
    echo -e "${YELLOW}Warning: Found $existing_views existing views in the database${NC}"
    echo "This deployment will replace any views with the same names."
    echo ""
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

echo -e "${BLUE}Deploying views in dependency order...${NC}"
echo ""

# Array of files and descriptions with expected view counts
declare -a view_files=(
    "01_balance_account_views.sql:Balance & Account Views:6"
    "02_member_management_views.sql:Member Management Views:7"
    "03_product_specific_views.sql:Product-Specific Views:9"
    "04_transaction_recovery_views.sql:Transaction & Recovery Views:8"
    "05_additional_microfinance_views.sql:Advanced Microfinance Views:8"
)

failed_count=0
success_count=0
total_views_deployed=0

for item in "${view_files[@]}"; do
    IFS=':' read -r file description expected_views <<< "$item"
    
    if execute_view_file "$file" "$description" "$expected_views"; then
        ((success_count++))
    else
        ((failed_count++))
    fi
    echo ""
done

# Final view count validation
final_view_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
    SELECT COUNT(*) 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name LIKE 'view_%'
" 2>/dev/null | tr -d ' ')

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Successful file deployments: $success_count${NC}"
echo -e "${RED}Failed file deployments: $failed_count${NC}"
echo -e "${PURPLE}Total views in database: $final_view_count${NC}"

if [ $failed_count -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All view files deployed successfully!${NC}"
    echo ""
    
    # List deployed views by category
    echo -e "${BLUE}Deployed View Categories:${NC}"
    echo ""
    
    # Balance & Account Views
    balance_views=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT string_agg(table_name, ', ') 
        FROM information_schema.views 
        WHERE table_schema = 'public' 
        AND table_name IN (
            'view_sub_account_balance',
            'view_members_bal', 
            'view_balance_brief',
            'view_current_sub_account_balances',
            'view_member_portfolio_summary',
            'view_account_balance_summary'
        )
    " 2>/dev/null)
    echo -e "${YELLOW}Balance & Account Views:${NC} $balance_views"
    
    # Member Management Views
    member_views=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT string_agg(table_name, ', ') 
        FROM information_schema.views 
        WHERE table_schema = 'public' 
        AND table_name IN (
            'view_member_without_loan',
            'view_not_received_member_list', 
            'view_member_profile',
            'view_loan_eligible_members',
            'view_member_transaction_summary',
            'view_inactive_members',
            'view_member_kyc_status'
        )
    " 2>/dev/null)
    echo -e "${YELLOW}Member Management Views:${NC} $member_views"
    
    echo ""
    echo -e "${BLUE}Quick Test Commands:${NC}"
    echo "# Dashboard overview:"
    echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \"SELECT * FROM view_monthly_business_dashboard;\""
    echo ""
    echo "# Member portfolio:"
    echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \"SELECT * FROM view_member_portfolio_summary LIMIT 5;\""
    echo ""
    echo "# Loan overdue analysis:"
    echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \"SELECT * FROM view_loan_overdue_analysis LIMIT 5;\""
    echo ""
    echo -e "${BLUE}For more examples, see README.md${NC}"
else
    echo ""
    echo -e "${RED}⚠ Some deployments failed. Please check the errors above.${NC}"
    echo "You can run individual files manually to see detailed error messages."
    exit 1
fi

# Performance recommendations
echo ""
echo -e "${YELLOW}Performance Recommendations:${NC}"
echo "1. Consider creating materialized views for frequently accessed reports:"
echo "   CREATE MATERIALIZED VIEW mv_monthly_dashboard AS SELECT * FROM view_monthly_business_dashboard;"
echo ""
echo "2. Set up refresh schedules for materialized views:"
echo "   -- Daily refresh example"
echo "   REFRESH MATERIALIZED VIEW mv_monthly_dashboard;"
echo ""
echo "3. Monitor view performance with EXPLAIN ANALYZE:"
echo "   EXPLAIN ANALYZE SELECT * FROM view_name LIMIT 100;"

# Grant permissions reminder
echo ""
echo -e "${YELLOW}Don't forget to grant permissions:${NC}"
echo "GRANT SELECT ON ALL TABLES IN SCHEMA public TO your_app_user;"

# List all created views for reference
echo ""
echo -e "${BLUE}All Deployed Views:${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
SELECT 
    table_name as view_name,
    CASE 
        WHEN table_name LIKE '%balance%' OR table_name LIKE '%account%' THEN 'Balance & Account'
        WHEN table_name LIKE '%member%' THEN 'Member Management'
        WHEN table_name LIKE '%saving%' OR table_name LIKE '%loan%' OR table_name LIKE '%fd%' THEN 'Product Specific'
        WHEN table_name LIKE '%transaction%' OR table_name LIKE '%recovery%' THEN 'Transaction & Recovery'
        ELSE 'Advanced Analysis'
    END as category
FROM information_schema.views 
WHERE table_schema = 'public' 
    AND table_name LIKE 'view_%'
ORDER BY category, table_name;
" 2>/dev/null

echo ""
echo -e "${GREEN}View deployment completed!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the README.md for usage examples"
echo "2. Test key views with your data"
echo "3. Create materialized views for heavy queries"
echo "4. Set up monitoring and refresh schedules"
echo "5. Integrate views with your application"
