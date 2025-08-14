-- =============================================
-- Author: Converted to PostgreSQL
-- Create date: 2024
-- Description: Calculate Balance for GL heads (sub_accounts_no = 0)
-- Usage: SELECT sp_glhead_balance('1,2,3,4', '2024-12-31', 'user123');
-- =============================================

CREATE OR REPLACE FUNCTION sp_glhead_balance(
    p_account_list TEXT,
    p_to_date DATE,
    p_user_id VARCHAR(300),
    p_delimiter CHAR(1) DEFAULT ','
) RETURNS TABLE(
    sub_accounts_balance_id INTEGER,
    accounts_id INTEGER,
    sub_accounts_id INTEGER,
    balance_amount DECIMAL(15,4),
    balance_date DATE,
    created_by VARCHAR(300)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id INTEGER;
    v_sub_account_id INTEGER;
    v_trans_amt DECIMAL(15,4);
    v_account_array TEXT[];
    v_account TEXT;
BEGIN
    -- Clear existing balance records for this user
    DELETE FROM sub_accounts_balance WHERE trans_by = p_user_id;
    
    -- Split the account list into array
    v_account_array := string_to_array(p_account_list, p_delimiter);
    
    -- Process each account
    FOR i IN 1..array_length(v_account_array, 1)
    LOOP
        v_account := trim(v_account_array[i]);
        IF v_account = '' THEN
            CONTINUE;
        END IF;
        
        v_account_id := v_account::INTEGER;
        
        -- Check if account has GL head sub-accounts (sub_accounts_no = 0)
        IF NOT EXISTS (
            SELECT 1 FROM sub_accounts 
            WHERE accounts_id = v_account_id AND sub_accounts_no = 0
        ) THEN
            CONTINUE;
        END IF;
        
        -- Process each GL head sub-account
        FOR v_sub_account_id IN 
            SELECT sa.sub_accounts_id 
            FROM sub_accounts sa 
            WHERE sa.accounts_id = v_account_id 
                AND sa.sub_accounts_no = 0
        LOOP
            -- Calculate transaction amount for GL head
            SELECT COALESCE(SUM(td.trans_amount), 0)
            INTO v_trans_amt
            FROM transaction_head th 
            INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
            WHERE td.accounts_id = v_account_id 
                AND td.sub_accounts_id = v_sub_account_id
                AND th.trans_date <= p_to_date;
            
            -- Insert balance record
            INSERT INTO sub_accounts_balance (
                accounts_id, 
                sub_accounts_id, 
                balance_amount, 
                balance_date, 
                trans_by, 
                transaction_head_id
            ) VALUES (
                v_account_id, 
                v_sub_account_id, 
                v_trans_amt, 
                p_to_date, 
                p_user_id, 
                -1
            );
        END LOOP;
    END LOOP;
    
    -- Return the results
    RETURN QUERY
    SELECT 
        sab.sub_accounts_balance_id,
        sab.accounts_id,
        sab.sub_accounts_id,
        sab.balance_amount,
        sab.balance_date,
        sab.trans_by
    FROM sub_accounts_balance sab
    WHERE sab.trans_by = p_user_id
    ORDER BY sab.accounts_id, sab.sub_accounts_id;
END;
$$;

-- Get GL summary for all account groups
CREATE OR REPLACE FUNCTION get_gl_summary(
    p_to_date DATE DEFAULT CURRENT_DATE,
    p_fin_year_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    account_group_id INTEGER,
    account_group_name TEXT,
    account_primary_group TEXT,
    total_balance DECIMAL(15,4),
    account_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH account_balances AS (
        SELECT 
            a.accounts_id,
            a.account_groups_id,
            ag.account_primary_group,
            COALESCE(SUM(td.trans_amount), 0) as balance
        FROM accounts a
        INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
        LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id AND sa.sub_accounts_no = 0
        LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
            AND sa.accounts_id = td.accounts_id
        LEFT JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
            AND th.trans_date <= p_to_date
            AND (p_fin_year_id IS NULL OR th.financial_years_id = p_fin_year_id)
        GROUP BY a.accounts_id, a.account_groups_id, ag.account_primary_group
    )
    SELECT 
        ag.account_groups_id,
        ag.name,
        ag.account_primary_group,
        SUM(ab.balance),
        COUNT(ab.accounts_id)
    FROM account_groups ag
    LEFT JOIN account_balances ab ON ag.account_groups_id = ab.account_groups_id
    GROUP BY ag.account_groups_id, ag.name, ag.account_primary_group
    ORDER BY ag.account_groups_id;
END;
$$;

-- Get trial balance
CREATE OR REPLACE FUNCTION get_trial_balance(
    p_to_date DATE DEFAULT CURRENT_DATE,
    p_fin_year_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    accounts_id INTEGER,
    account_name TEXT,
    account_group_name TEXT,
    balance_type TEXT,
    debit_balance DECIMAL(15,4),
    credit_balance DECIMAL(15,4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH account_balances AS (
        SELECT 
            a.accounts_id,
            a.account_name,
            ag.name as account_group_name,
            a.balance_type,
            COALESCE(SUM(td.trans_amount), 0) as balance
        FROM accounts a
        INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
        LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
        LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
            AND sa.accounts_id = td.accounts_id
        LEFT JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
            AND th.trans_date <= p_to_date
            AND (p_fin_year_id IS NULL OR 
                 (ag.account_primary_group IN ('1', '2') AND th.financial_years_id = p_fin_year_id) OR
                 ag.account_primary_group NOT IN ('1', '2'))
        GROUP BY a.accounts_id, a.account_name, ag.name, a.balance_type
    )
    SELECT 
        ab.accounts_id,
        ab.account_name,
        ab.account_group_name,
        ab.balance_type,
        CASE 
            WHEN ab.balance >= 0 THEN ab.balance 
            ELSE 0 
        END as debit_balance,
        CASE 
            WHEN ab.balance < 0 THEN ABS(ab.balance) 
            ELSE 0 
        END as credit_balance
    FROM account_balances ab
    WHERE ab.balance <> 0
    ORDER BY ab.accounts_id;
END;
$$;

-- Get balance sheet data
CREATE OR REPLACE FUNCTION get_balance_sheet(
    p_to_date DATE DEFAULT CURRENT_DATE,
    p_fin_year_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    section TEXT,
    account_group_name TEXT,
    account_name TEXT,
    amount DECIMAL(15,4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH account_balances AS (
        SELECT 
            a.accounts_id,
            a.account_name,
            ag.name as account_group_name,
            ag.account_primary_group,
            a.balance_type,
            COALESCE(SUM(td.trans_amount), 0) as balance
        FROM accounts a
        INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
        LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
        LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
            AND sa.accounts_id = td.accounts_id
        LEFT JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
            AND th.trans_date <= p_to_date
        WHERE ag.account_primary_group IN ('3', '4', '5') -- Assets, Liabilities, Capital
        GROUP BY a.accounts_id, a.account_name, ag.name, ag.account_primary_group, a.balance_type
    )
    SELECT 
        CASE 
            WHEN ab.account_primary_group = '3' THEN 'ASSETS'
            WHEN ab.account_primary_group = '4' THEN 'LIABILITIES'
            WHEN ab.account_primary_group = '5' THEN 'CAPITAL'
        END as section,
        ab.account_group_name,
        ab.account_name,
        ab.balance
    FROM account_balances ab
    WHERE ab.balance <> 0
    ORDER BY 
        CASE ab.account_primary_group 
            WHEN '3' THEN 1 
            WHEN '4' THEN 2 
            WHEN '5' THEN 3 
        END,
        ab.account_group_name,
        ab.account_name;
END;
$$;

-- Get profit & loss statement
CREATE OR REPLACE FUNCTION get_profit_loss_statement(
    p_from_date DATE DEFAULT NULL,
    p_to_date DATE DEFAULT CURRENT_DATE,
    p_fin_year_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    section TEXT,
    account_group_name TEXT,
    account_name TEXT,
    amount DECIMAL(15,4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_date DATE;
BEGIN
    -- Set default from date if not provided
    v_from_date := COALESCE(p_from_date, DATE_TRUNC('year', p_to_date));
    
    RETURN QUERY
    WITH account_balances AS (
        SELECT 
            a.accounts_id,
            a.account_name,
            ag.name as account_group_name,
            ag.account_primary_group,
            COALESCE(SUM(td.trans_amount), 0) as balance
        FROM accounts a
        INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id
        LEFT JOIN sub_accounts sa ON a.accounts_id = sa.accounts_id
        LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
            AND sa.accounts_id = td.accounts_id
        LEFT JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
            AND th.trans_date BETWEEN v_from_date AND p_to_date
            AND (p_fin_year_id IS NULL OR th.financial_years_id = p_fin_year_id)
        WHERE ag.account_primary_group IN ('1', '2') -- Income and Expenses
        GROUP BY a.accounts_id, a.account_name, ag.name, ag.account_primary_group
    )
    SELECT 
        CASE 
            WHEN ab.account_primary_group = '1' THEN 'INCOME'
            WHEN ab.account_primary_group = '2' THEN 'EXPENSES'
        END as section,
        ab.account_group_name,
        ab.account_name,
        ab.balance
    FROM account_balances ab
    WHERE ab.balance <> 0
    ORDER BY 
        CASE ab.account_primary_group 
            WHEN '1' THEN 1 
            WHEN '2' THEN 2 
        END,
        ab.account_group_name,
        ab.account_name;
END;
$$;

-- Example usage:
-- SELECT * FROM sp_glhead_balance('1,2,3,34', '2024-12-31', 'admin_user');
-- SELECT * FROM get_gl_summary('2024-12-31', 1);
-- SELECT * FROM get_trial_balance('2024-12-31');
-- SELECT * FROM get_balance_sheet('2024-12-31');
-- SELECT * FROM get_profit_loss_statement('2024-01-01', '2024-12-31', 1);
