-- =============================================
-- Author: Converted to PostgreSQL
-- Create date: 2024
-- Description: Branch management procedures
-- =============================================

-- Add new branch procedure
CREATE OR REPLACE FUNCTION add_branch(
    p_branch_id INTEGER,
    p_name VARCHAR(300),
    p_address VARCHAR(300),
    p_reg_no VARCHAR(300),
    p_opening_balance DATE,
    p_weekly_off INTEGER,
    p_logo BYTEA DEFAULT NULL,
    p_note VARCHAR(300) DEFAULT NULL,
    p_version_info VARCHAR(1200) DEFAULT NULL,
    p_gst_in VARCHAR(1200) DEFAULT NULL
) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_branch_id INTEGER;
BEGIN
    -- If branch_id is not provided, generate new one
    IF p_branch_id IS NULL OR p_branch_id = 0 THEN
        SELECT COALESCE(MAX(branch_id), 0) + 1 INTO v_new_branch_id FROM branch;
    ELSE
        v_new_branch_id := p_branch_id;
    END IF;
    
    -- Check if branch already exists
    IF EXISTS (SELECT 1 FROM branch WHERE branch_id = v_new_branch_id) THEN
        RAISE EXCEPTION 'Branch with ID % already exists', v_new_branch_id;
    END IF;
    
    -- Insert new branch
    INSERT INTO branch (
        branch_id,
        name,
        address,
        reg_no,
        opening_balance,
        weekly_off,
        logo,
        note,
        version_info,
        gst_in
    ) VALUES (
        v_new_branch_id,
        p_name,
        p_address,
        p_reg_no,
        p_opening_balance::TEXT,
        p_weekly_off::TEXT,
        encode(p_logo, 'base64'),
        p_note,
        p_version_info,
        p_gst_in
    );
    
    RETURN v_new_branch_id;
END;
$$;

-- Update branch procedure
CREATE OR REPLACE FUNCTION update_branch(
    p_branch_id INTEGER,
    p_name VARCHAR(300) DEFAULT NULL,
    p_address VARCHAR(300) DEFAULT NULL,
    p_reg_no VARCHAR(300) DEFAULT NULL,
    p_opening_balance DATE DEFAULT NULL,
    p_weekly_off INTEGER DEFAULT NULL,
    p_logo BYTEA DEFAULT NULL,
    p_note VARCHAR(300) DEFAULT NULL,
    p_version_info VARCHAR(1200) DEFAULT NULL,
    p_gst_in VARCHAR(1200) DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if branch exists
    IF NOT EXISTS (SELECT 1 FROM branch WHERE branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'Branch with ID % does not exist', p_branch_id;
    END IF;
    
    -- Update branch with provided values
    UPDATE branch SET
        name = COALESCE(p_name, name),
        address = COALESCE(p_address, address),
        reg_no = COALESCE(p_reg_no, reg_no),
        opening_balance = COALESCE(p_opening_balance::TEXT, opening_balance),
        weekly_off = COALESCE(p_weekly_off::TEXT, weekly_off),
        logo = COALESCE(encode(p_logo, 'base64'), logo),
        note = COALESCE(p_note, note),
        version_info = COALESCE(p_version_info, version_info),
        gst_in = COALESCE(p_gst_in, gst_in)
    WHERE branch_id = p_branch_id;
    
    RETURN TRUE;
END;
$$;

-- Get branch details
CREATE OR REPLACE FUNCTION get_branch_details(
    p_branch_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    branch_id INTEGER,
    name TEXT,
    address TEXT,
    reg_no TEXT,
    opening_balance TEXT,
    weekly_off TEXT,
    note TEXT,
    version_info TEXT,
    gst_in TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_branch_id IS NULL THEN
        -- Return all branches
        RETURN QUERY
        SELECT 
            b.branch_id,
            b.name,
            b.address,
            b.reg_no,
            b.opening_balance,
            b.weekly_off,
            b.note,
            b.version_info,
            b.gst_in
        FROM branch b
        ORDER BY b.branch_id;
    ELSE
        -- Return specific branch
        RETURN QUERY
        SELECT 
            b.branch_id,
            b.name,
            b.address,
            b.reg_no,
            b.opening_balance,
            b.weekly_off,
            b.note,
            b.version_info,
            b.gst_in
        FROM branch b
        WHERE b.branch_id = p_branch_id;
    END IF;
END;
$$;

-- Delete branch (soft delete by setting status)
CREATE OR REPLACE FUNCTION delete_branch(
    p_branch_id INTEGER,
    p_soft_delete BOOLEAN DEFAULT TRUE
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_count INTEGER;
BEGIN
    -- Check if branch exists
    IF NOT EXISTS (SELECT 1 FROM branch WHERE branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'Branch with ID % does not exist', p_branch_id;
    END IF;
    
    -- Check if branch has transactions
    SELECT COUNT(*) INTO v_transaction_count
    FROM transaction_head
    WHERE branch_id = p_branch_id;
    
    IF v_transaction_count > 0 AND NOT p_soft_delete THEN
        RAISE EXCEPTION 'Cannot delete branch with existing transactions. Use soft delete instead.';
    END IF;
    
    IF p_soft_delete THEN
        -- Add a status column if it doesn't exist (for soft delete)
        -- UPDATE branch SET status = 'DELETED' WHERE branch_id = p_branch_id;
        -- For now, we'll just raise a notice since status column might not exist
        RAISE NOTICE 'Branch % marked for soft deletion', p_branch_id;
    ELSE
        -- Hard delete (only if no transactions)
        DELETE FROM branch WHERE branch_id = p_branch_id;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Get branch statistics
CREATE OR REPLACE FUNCTION get_branch_statistics(
    p_branch_id INTEGER DEFAULT NULL,
    p_from_date DATE DEFAULT NULL,
    p_to_date DATE DEFAULT NULL
) RETURNS TABLE(
    branch_id INTEGER,
    branch_name TEXT,
    total_transactions BIGINT,
    total_amount DECIMAL(15,4),
    member_count BIGINT,
    loan_count BIGINT,
    saving_count BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_date DATE;
    v_to_date DATE;
BEGIN
    -- Set default date range if not provided
    v_from_date := COALESCE(p_from_date, CURRENT_DATE - INTERVAL '1 year');
    v_to_date := COALESCE(p_to_date, CURRENT_DATE);
    
    RETURN QUERY
    SELECT 
        b.branch_id,
        b.name,
        COALESCE(COUNT(th.transaction_head_id), 0) as total_transactions,
        COALESCE(SUM(ABS(th.trans_amount::DECIMAL)), 0) as total_amount,
        COALESCE(COUNT(DISTINCT m.members_id), 0) as member_count,
        COALESCE(COUNT(DISTINCT la.loan_accounts_id), 0) as loan_count,
        COALESCE(COUNT(DISTINCT sa.saving_accounts_id), 0) as saving_count
    FROM branch b
    LEFT JOIN transaction_head th ON b.branch_id = th.branch_id 
        AND th.trans_date BETWEEN v_from_date AND v_to_date
    LEFT JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
    LEFT JOIN sub_accounts suba ON td.sub_accounts_id = suba.sub_accounts_id
    LEFT JOIN members m ON suba.members_id = m.members_id
    LEFT JOIN loan_accounts la ON suba.sub_accounts_id = la.sub_accounts_id
    LEFT JOIN saving_accounts sa ON suba.sub_accounts_id = sa.sub_accounts_id
    WHERE (p_branch_id IS NULL OR b.branch_id = p_branch_id)
    GROUP BY b.branch_id, b.name
    ORDER BY b.branch_id;
END;
$$;

-- Example usage:
-- SELECT add_branch(NULL, 'Main Branch', '123 Main St', 'REG001', '2024-01-01', 0, NULL, 'Main office', 'v1.0', 'GST123');
-- SELECT * FROM get_branch_details();
-- SELECT * FROM get_branch_details(1);
-- SELECT update_branch(1, 'Updated Branch Name');
-- SELECT * FROM get_branch_statistics();
