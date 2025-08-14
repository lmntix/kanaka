-- =============================================
-- Author: Converted to PostgreSQL
-- Create date: 2024
-- Description: Calculate running balance for sub-account with daily totals
-- Usage: SELECT sp_sub_accounts_balance(4, 1931, 0.00, '2024-01-01', '2024-12-31', 'user123');
-- =============================================

CREATE OR REPLACE FUNCTION sp_sub_accounts_balance(
    p_accounts_id INTEGER,
    p_sub_accounts_id INTEGER,
    p_opening_balance DECIMAL(15,4),
    p_from_date DATE,
    p_to_date DATE,
    p_user_id VARCHAR(300)
) RETURNS TABLE(
    sub_accounts_balance_id INTEGER,
    accounts_id INTEGER,
    sub_accounts_id INTEGER,
    running_balance DECIMAL(15,4),
    trans_date DATE,
    trans_by VARCHAR(300)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_running_total DECIMAL(15,4);
    v_trans_date DATE;
    v_trans_amt DECIMAL(15,4);
    v_sub_acc_bal_id INTEGER;
    
    -- Cursor for distinct transaction dates
    date_cursor CURSOR FOR
        SELECT DISTINCT th.trans_date
        FROM transaction_head th 
        INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
        WHERE td.sub_accounts_id = p_sub_accounts_id 
            AND th.trans_date >= p_from_date 
            AND th.trans_date <= p_to_date
        ORDER BY th.trans_date;
BEGIN
    -- Initialize running total with opening balance
    v_running_total := p_opening_balance;
    
    -- Clear existing balance records for this user
    DELETE FROM sub_accounts_balance WHERE trans_by = p_user_id;
    
    -- Process each transaction date
    FOR date_rec IN date_cursor
    LOOP
        v_trans_date := date_rec.trans_date;
        
        -- Calculate sum of transactions for this date
        SELECT COALESCE(SUM(td.trans_amount), 0)
        INTO v_trans_amt
        FROM transaction_head th 
        INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
        WHERE td.accounts_id = p_accounts_id 
            AND td.sub_accounts_id = p_sub_accounts_id 
            AND th.trans_date = v_trans_date;
        
        -- Update running total
        v_running_total := v_running_total + v_trans_amt;
        
        -- Insert balance record
        INSERT INTO sub_accounts_balance (
            accounts_id,
            sub_accounts_id,
            balance_amount,
            balance_date,
            trans_by,
            transaction_head_id
        ) VALUES (
            p_accounts_id,
            p_sub_accounts_id,
            v_running_total,
            v_trans_date,
            p_user_id,
            -1
        );
    END LOOP;
    
    -- Return the balance results
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
        AND sab.accounts_id = p_accounts_id
        AND sab.sub_accounts_id = p_sub_accounts_id
    ORDER BY sab.balance_date;
END;
$$;

-- Optimized version using window functions (more efficient)
CREATE OR REPLACE FUNCTION sp_sub_accounts_balance_optimized(
    p_accounts_id INTEGER,
    p_sub_accounts_id INTEGER,
    p_opening_balance DECIMAL(15,4),
    p_from_date DATE,
    p_to_date DATE,
    p_user_id VARCHAR(300)
) RETURNS TABLE(
    sub_accounts_balance_id INTEGER,
    accounts_id INTEGER,
    sub_accounts_id INTEGER,
    running_balance DECIMAL(15,4),
    trans_date DATE,
    trans_by VARCHAR(300)
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clear existing balance records for this user
    DELETE FROM sub_accounts_balance WHERE trans_by = p_user_id;
    
    -- Insert running balances using window function
    INSERT INTO sub_accounts_balance (
        accounts_id,
        sub_accounts_id,
        balance_amount,
        balance_date,
        trans_by,
        transaction_head_id
    )
    SELECT 
        p_accounts_id,
        p_sub_accounts_id,
        p_opening_balance + SUM(daily_amount) OVER (ORDER BY trans_date ROWS UNBOUNDED PRECEDING),
        trans_date,
        p_user_id,
        -1
    FROM (
        SELECT 
            th.trans_date,
            SUM(td.trans_amount) as daily_amount
        FROM transaction_head th 
        INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
        WHERE td.accounts_id = p_accounts_id 
            AND td.sub_accounts_id = p_sub_accounts_id 
            AND th.trans_date >= p_from_date 
            AND th.trans_date <= p_to_date
        GROUP BY th.trans_date
        ORDER BY th.trans_date
    ) daily_transactions;
    
    -- Return the balance results
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
        AND sab.accounts_id = p_accounts_id
        AND sab.sub_accounts_id = p_sub_accounts_id
    ORDER BY sab.balance_date;
END;
$$;

-- Function to get current balance for a sub-account
CREATE OR REPLACE FUNCTION get_sub_account_current_balance(
    p_accounts_id INTEGER,
    p_sub_accounts_id INTEGER,
    p_as_of_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(15,4)
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance DECIMAL(15,4);
BEGIN
    SELECT COALESCE(SUM(td.trans_amount), 0)
    INTO v_balance
    FROM transaction_head th 
    INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
    WHERE td.accounts_id = p_accounts_id 
        AND td.sub_accounts_id = p_sub_accounts_id 
        AND th.trans_date <= p_as_of_date;
    
    RETURN v_balance;
END;
$$;

-- Function to get balance summary for all sub-accounts of an account
CREATE OR REPLACE FUNCTION get_account_balance_summary(
    p_accounts_id INTEGER,
    p_as_of_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    sub_accounts_id INTEGER,
    member_name TEXT,
    current_balance DECIMAL(15,4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sa.sub_accounts_id,
        COALESCE(m.full_name, 'N/A') as member_name,
        COALESCE(SUM(td.trans_amount), 0) as current_balance
    FROM sub_accounts sa
    LEFT JOIN members m ON sa.members_id = m.members_id
    LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id 
        AND sa.accounts_id = td.accounts_id
    LEFT JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
        AND th.trans_date <= p_as_of_date
    WHERE sa.accounts_id = p_accounts_id
    GROUP BY sa.sub_accounts_id, m.full_name
    ORDER BY sa.sub_accounts_id;
END;
$$;

-- Example usage:
-- SELECT * FROM sp_sub_accounts_balance(4, 1931, 0.00, '2024-01-01', '2024-12-31', 'admin_user');
-- SELECT * FROM sp_sub_accounts_balance_optimized(4, 1931, 0.00, '2024-01-01', '2024-12-31', 'admin_user');
-- SELECT get_sub_account_current_balance(4, 1931);
-- SELECT * FROM get_account_balance_summary(4);
