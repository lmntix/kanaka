-- =============================================
-- Author: Converted to PostgreSQL
-- Create date: 2024
-- Description: Calculate Balance as per sub_accounts_id
-- Usage: SELECT sp_balance('1,2,3,4', '2024-12-31', 'user123', ',', 1);
-- =============================================

CREATE OR REPLACE FUNCTION sp_balance(
    p_account_list TEXT,
    p_to_date DATE,
    p_user_id VARCHAR(300),
    p_delimiter CHAR(1) DEFAULT ',',
    p_fin_year_id INTEGER DEFAULT NULL
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
    v_temp_id INTEGER;
    v_prim_group_type INTEGER;
    v_account_array TEXT[];
    v_account TEXT;
    v_sub_account_cursor CURSOR FOR 
        SELECT sa.sub_accounts_id 
        FROM sub_accounts sa 
        WHERE sa.accounts_id = v_account_id 
        AND sa.sub_accounts_no <> 0;
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
        
        -- Get primary group type for account
        SELECT ag.account_primary_group 
        INTO v_prim_group_type
        FROM accounts a 
        INNER JOIN account_groups ag ON a.account_groups_id = ag.account_groups_id 
        WHERE a.accounts_id = v_account_id;
        
        -- Check if account has sub-accounts
        IF NOT EXISTS (
            SELECT 1 FROM sub_accounts 
            WHERE accounts_id = v_account_id AND sub_accounts_no <> 0
        ) THEN
            -- Handle accounts without proper sub-accounts (if accounts_family table exists)
            CONTINUE;
        END IF;
        
        -- Process each sub-account
        FOR v_sub_account_id IN 
            SELECT sa.sub_accounts_id 
            FROM sub_accounts sa 
            WHERE sa.accounts_id = v_account_id
        LOOP
            -- Calculate transaction amount
            IF p_fin_year_id IS NOT NULL AND (v_prim_group_type = 1 OR v_prim_group_type = 2) THEN
                -- For Income and Expense accounts, filter by financial year
                SELECT COALESCE(SUM(td.trans_amount), 0)
                INTO v_trans_amt
                FROM transaction_head th 
                INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
                WHERE td.accounts_id = v_account_id 
                    AND td.sub_accounts_id = v_sub_account_id
                    AND th.financial_years_id = p_fin_year_id
                    AND th.trans_date <= p_to_date;
            ELSE
                -- For other accounts, use cumulative balance
                SELECT COALESCE(SUM(td.trans_amount), 0)
                INTO v_trans_amt
                FROM transaction_head th 
                INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
                WHERE td.accounts_id = v_account_id 
                    AND td.sub_accounts_id = v_sub_account_id
                    AND th.trans_date <= p_to_date;
            END IF;
            
            -- Insert balance record if amount is not null
            IF v_trans_amt IS NOT NULL THEN
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
            END IF;
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

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_sub_accounts_balance_trans_by ON sub_accounts_balance(trans_by);
CREATE INDEX IF NOT EXISTS idx_transaction_details_composite ON transaction_details(accounts_id, sub_accounts_id);
CREATE INDEX IF NOT EXISTS idx_transaction_head_date_year ON transaction_head(trans_date, financial_years_id);

-- Example usage:
-- SELECT * FROM sp_balance('1,4,5,34', '2024-12-31', 'admin_user', ',', 1);
