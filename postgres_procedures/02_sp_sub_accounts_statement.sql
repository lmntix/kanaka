-- =============================================
-- Author: Converted to PostgreSQL
-- Create date: 2024
-- Description: Generate sub-account statement with transaction details
-- Usage: SELECT sp_sub_accounts_statement(4, 1931, 0.00, '2024-01-01', '2024-12-31', 'user123');
-- =============================================

CREATE OR REPLACE FUNCTION sp_sub_accounts_statement(
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
    trans_amount DECIMAL(15,4),
    trans_date DATE,
    trans_by VARCHAR(300),
    transaction_head_id INTEGER
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_trans_head_id INTEGER;
    v_account_id INTEGER;
    v_sub_account_id INTEGER;
    v_trans_amt DECIMAL(15,4);
    v_trans_date DATE;
    v_sub_acc_bal_id INTEGER;
    
    -- Cursor for transaction heads
    trans_head_cursor CURSOR FOR
        SELECT DISTINCT th.transaction_head_id
        FROM transaction_head th 
        INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
        RIGHT OUTER JOIN transaction_passing tp ON th.transaction_head_id = tp.transaction_head_id
        WHERE td.sub_accounts_id = p_sub_accounts_id 
            AND th.trans_date >= p_from_date 
            AND th.trans_date <= p_to_date;
    
    -- Cursor for transaction details
    trans_detail_cursor CURSOR(c_trans_head_id INTEGER) FOR
        SELECT 
            td.accounts_id,
            td.sub_accounts_id,
            td.trans_amount,
            th.trans_date
        FROM transaction_head th 
        INNER JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
        WHERE td.transaction_head_id = c_trans_head_id 
            AND (td.sub_accounts_id <> p_sub_accounts_id OR td.accounts_id <> p_accounts_id)
        ORDER BY th.transaction_head_id;
BEGIN
    -- Clear existing statement records for this user
    DELETE FROM sub_accounts_balance WHERE trans_by = p_user_id;
    
    -- Open transaction head cursor
    OPEN trans_head_cursor;
    
    LOOP
        FETCH trans_head_cursor INTO v_trans_head_id;
        EXIT WHEN NOT FOUND;
        
        -- Open transaction detail cursor for current transaction head
        FOR trans_detail_rec IN trans_detail_cursor(v_trans_head_id)
        LOOP
            v_account_id := trans_detail_rec.accounts_id;
            v_sub_account_id := trans_detail_rec.sub_accounts_id;
            v_trans_amt := trans_detail_rec.trans_amount;
            v_trans_date := trans_detail_rec.trans_date;
            
            -- Insert into sub_accounts_balance
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
                v_trans_date,
                p_user_id,
                v_trans_head_id
            );
        END LOOP;
    END LOOP;
    
    CLOSE trans_head_cursor;
    
    -- Return the statement results
    RETURN QUERY
    SELECT 
        sab.sub_accounts_balance_id,
        sab.accounts_id,
        sab.sub_accounts_id,
        sab.balance_amount,
        sab.balance_date,
        sab.trans_by,
        sab.transaction_head_id
    FROM sub_accounts_balance sab
    WHERE sab.trans_by = p_user_id
    ORDER BY sab.balance_date, sab.transaction_head_id;
END;
$$;

-- Alternative optimized version without cursors (more PostgreSQL-like)
CREATE OR REPLACE FUNCTION sp_sub_accounts_statement_optimized(
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
    trans_amount DECIMAL(15,4),
    trans_date DATE,
    trans_by VARCHAR(300),
    transaction_head_id INTEGER
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clear existing statement records for this user
    DELETE FROM sub_accounts_balance WHERE trans_by = p_user_id;
    
    -- Insert statement records using set-based operations
    INSERT INTO sub_accounts_balance (
        accounts_id,
        sub_accounts_id,
        balance_amount,
        balance_date,
        trans_by,
        transaction_head_id
    )
    SELECT 
        td2.accounts_id,
        td2.sub_accounts_id,
        td2.trans_amount,
        th.trans_date,
        p_user_id,
        th.transaction_head_id
    FROM transaction_head th 
    INNER JOIN transaction_details td1 ON th.transaction_head_id = td1.transaction_head_id
    INNER JOIN transaction_details td2 ON th.transaction_head_id = td2.transaction_head_id
    RIGHT OUTER JOIN transaction_passing tp ON th.transaction_head_id = tp.transaction_head_id
    WHERE td1.sub_accounts_id = p_sub_accounts_id 
        AND th.trans_date >= p_from_date 
        AND th.trans_date <= p_to_date
        AND (td2.sub_accounts_id <> p_sub_accounts_id OR td2.accounts_id <> p_accounts_id);
    
    -- Return the statement results
    RETURN QUERY
    SELECT 
        sab.sub_accounts_balance_id,
        sab.accounts_id,
        sab.sub_accounts_id,
        sab.balance_amount,
        sab.balance_date,
        sab.trans_by,
        sab.transaction_head_id
    FROM sub_accounts_balance sab
    WHERE sab.trans_by = p_user_id
    ORDER BY sab.balance_date, sab.transaction_head_id;
END;
$$;

-- Example usage:
-- SELECT * FROM sp_sub_accounts_statement(4, 1931, 0.00, '2024-01-01', '2024-12-31', 'admin_user');
-- SELECT * FROM sp_sub_accounts_statement_optimized(4, 1931, 0.00, '2024-01-01', '2024-12-31', 'admin_user');
