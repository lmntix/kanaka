-- =============================================
-- Microfinance-Specific Procedures
-- Author: PostgreSQL Conversion
-- Create date: 2024
-- Description: Core microfinance operations
-- =============================================

-- ================================
-- INTEREST POSTING PROCEDURES
-- ================================

-- Calculate and post savings interest
CREATE OR REPLACE FUNCTION post_savings_interest(
    p_as_of_date DATE DEFAULT CURRENT_DATE,
    p_user_id VARCHAR(300) DEFAULT 'SYSTEM',
    p_branch_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    processed_accounts INTEGER,
    total_interest_amount DECIMAL(15,4),
    transaction_head_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trans_head_id INTEGER;
    v_processed_count INTEGER := 0;
    v_total_interest DECIMAL(15,4) := 0;
    v_saving_account RECORD;
    v_balance DECIMAL(15,4);
    v_interest_amount DECIMAL(15,4);
    v_interest_rate DECIMAL(8,4);
    v_days_in_month INTEGER;
BEGIN
    -- Get days in current month
    v_days_in_month := EXTRACT(DAY FROM DATE_TRUNC('month', p_as_of_date) + INTERVAL '1 month - 1 day');
    
    -- Create transaction head for interest posting
    INSERT INTO transaction_head (
        financial_years_id, 
        users_id, 
        branch_id, 
        voucher_no, 
        trans_date, 
        trans_time, 
        trans_amount, 
        trans_narration, 
        mode_of_operation
    ) VALUES (
        (SELECT financial_years_id FROM financial_years WHERE status = '1' LIMIT 1),
        p_user_id,
        COALESCE(p_branch_id, 1),
        NEXTVAL('voucher_seq'),
        p_as_of_date,
        CURRENT_TIME,
        0, -- Will be updated later
        'Savings Interest Posted for ' || p_as_of_date,
        '0'
    ) RETURNING transaction_head_id INTO v_trans_head_id;
    
    -- Process each active savings account
    FOR v_saving_account IN
        SELECT 
            sa.saving_accounts_id,
            sa.sub_accounts_id,
            sa.interest_rate::DECIMAL as rate,
            sub_acc.accounts_id,
            get_sub_account_current_balance(sub_acc.accounts_id, sa.sub_accounts_id, p_as_of_date) as balance
        FROM saving_accounts sa
        INNER JOIN sub_accounts sub_acc ON sa.sub_accounts_id = sub_acc.sub_accounts_id
        WHERE sa.status = '1' -- Active accounts
            AND sa.interest_rate::DECIMAL > 0
    LOOP
        v_balance := v_saving_account.balance;
        v_interest_rate := v_saving_account.rate;
        
        -- Calculate daily interest: (Balance * Rate * Days) / (365 * 100)
        v_interest_amount := (v_balance * v_interest_rate * 1) / (365 * 100);
        v_interest_amount := ROUND(v_interest_amount, 2);
        
        IF v_interest_amount > 0 THEN
            -- Credit interest to member's savings account
            INSERT INTO transaction_details (
                transaction_head_id,
                accounts_id,
                sub_accounts_id,
                trans_amount
            ) VALUES (
                v_trans_head_id,
                v_saving_account.accounts_id,
                v_saving_account.sub_accounts_id,
                v_interest_amount
            );
            
            -- Debit from interest expense account
            INSERT INTO transaction_details (
                transaction_head_id,
                accounts_id,
                sub_accounts_id,
                trans_amount
            ) VALUES (
                v_trans_head_id,
                (SELECT accounts_id FROM accounts WHERE account_name = 'Savings Interest' LIMIT 1),
                (SELECT sub_accounts_id FROM sub_accounts WHERE accounts_id = (SELECT accounts_id FROM accounts WHERE account_name = 'Savings Interest' LIMIT 1) AND sub_accounts_no = 0 LIMIT 1),
                -v_interest_amount
            );
            
            -- Insert interest posting record
            INSERT INTO saving_interest_post (
                saving_accounts_id,
                transaction_head_id,
                interest_date,
                interest_amount,
                interest_rate,
                balance_amount,
                created_by
            ) VALUES (
                v_saving_account.saving_accounts_id,
                v_trans_head_id,
                p_as_of_date,
                v_interest_amount,
                v_interest_rate,
                v_balance,
                p_user_id
            );
            
            v_processed_count := v_processed_count + 1;
            v_total_interest := v_total_interest + v_interest_amount;
        END IF;
    END LOOP;
    
    -- Update transaction head with total amount
    UPDATE transaction_head 
    SET trans_amount = v_total_interest::TEXT 
    WHERE transaction_head_id = v_trans_head_id;
    
    RETURN QUERY SELECT v_processed_count, v_total_interest, v_trans_head_id;
END;
$$;

-- Calculate and post loan interest
CREATE OR REPLACE FUNCTION post_loan_interest(
    p_as_of_date DATE DEFAULT CURRENT_DATE,
    p_user_id VARCHAR(300) DEFAULT 'SYSTEM',
    p_branch_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    processed_accounts INTEGER,
    total_interest_amount DECIMAL(15,4),
    transaction_head_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trans_head_id INTEGER;
    v_processed_count INTEGER := 0;
    v_total_interest DECIMAL(15,4) := 0;
    v_loan_account RECORD;
    v_outstanding_balance DECIMAL(15,4);
    v_interest_amount DECIMAL(15,4);
    v_interest_rate DECIMAL(8,4);
BEGIN
    -- Create transaction head for interest posting
    INSERT INTO transaction_head (
        financial_years_id, 
        users_id, 
        branch_id, 
        voucher_no, 
        trans_date, 
        trans_time, 
        trans_amount, 
        trans_narration, 
        mode_of_operation
    ) VALUES (
        (SELECT financial_years_id FROM financial_years WHERE status = '1' LIMIT 1),
        p_user_id,
        COALESCE(p_branch_id, 1),
        NEXTVAL('voucher_seq'),
        p_as_of_date,
        CURRENT_TIME,
        0, -- Will be updated later
        'Loan Interest Posted for ' || p_as_of_date,
        '0'
    ) RETURNING transaction_head_id INTO v_trans_head_id;
    
    -- Process each active loan account
    FOR v_loan_account IN
        SELECT 
            la.loan_accounts_id,
            la.sub_accounts_id,
            la.interest_rate::DECIMAL as rate,
            sub_acc.accounts_id,
            ABS(get_sub_account_current_balance(sub_acc.accounts_id, la.sub_accounts_id, p_as_of_date)) as outstanding_balance
        FROM loan_accounts la
        INNER JOIN sub_accounts sub_acc ON la.sub_accounts_id = sub_acc.sub_accounts_id
        WHERE la.status IN ('1', '2') -- Active/Disbursed loans
            AND la.interest_rate::DECIMAL > 0
    LOOP
        v_outstanding_balance := v_loan_account.outstanding_balance;
        v_interest_rate := v_loan_account.rate;
        
        -- Calculate daily interest: (Outstanding * Rate * 1) / (365 * 100)
        v_interest_amount := (v_outstanding_balance * v_interest_rate * 1) / (365 * 100);
        v_interest_amount := ROUND(v_interest_amount, 2);
        
        IF v_interest_amount > 0 THEN
            -- Debit interest from member's loan account (increases loan balance)
            INSERT INTO transaction_details (
                transaction_head_id,
                accounts_id,
                sub_accounts_id,
                trans_amount
            ) VALUES (
                v_trans_head_id,
                v_loan_account.accounts_id,
                v_loan_account.sub_accounts_id,
                -v_interest_amount -- Negative because it's a loan (liability to member)
            );
            
            -- Credit to interest income account
            INSERT INTO transaction_details (
                transaction_head_id,
                accounts_id,
                sub_accounts_id,
                trans_amount
            ) VALUES (
                v_trans_head_id,
                (SELECT accounts_id FROM accounts WHERE account_name = 'Member Lone Interest' LIMIT 1),
                (SELECT sub_accounts_id FROM sub_accounts WHERE accounts_id = (SELECT accounts_id FROM accounts WHERE account_name = 'Member Lone Interest' LIMIT 1) AND sub_accounts_no = 0 LIMIT 1),
                v_interest_amount
            );
            
            -- Insert interest posting record
            INSERT INTO loan_interest_post (
                loan_accounts_id,
                transaction_head_id,
                interest_date,
                interest_amount,
                interest_rate,
                outstanding_balance,
                created_by
            ) VALUES (
                v_loan_account.loan_accounts_id,
                v_trans_head_id,
                p_as_of_date,
                v_interest_amount,
                v_interest_rate,
                v_outstanding_balance,
                p_user_id
            );
            
            v_processed_count := v_processed_count + 1;
            v_total_interest := v_total_interest + v_interest_amount;
        END IF;
    END LOOP;
    
    -- Update transaction head with total amount
    UPDATE transaction_head 
    SET trans_amount = v_total_interest::TEXT 
    WHERE transaction_head_id = v_trans_head_id;
    
    RETURN QUERY SELECT v_processed_count, v_total_interest, v_trans_head_id;
END;
$$;

-- ================================
-- LOAN MANAGEMENT PROCEDURES
-- ================================

-- Calculate EMI for a loan
CREATE OR REPLACE FUNCTION calculate_emi(
    p_principal DECIMAL(15,4),
    p_interest_rate DECIMAL(8,4),
    p_tenure_months INTEGER
) RETURNS DECIMAL(15,4)
LANGUAGE plpgsql
AS $$
DECLARE
    v_monthly_rate DECIMAL(15,6);
    v_emi DECIMAL(15,4);
BEGIN
    -- Convert annual rate to monthly rate
    v_monthly_rate := p_interest_rate / (12 * 100);
    
    -- EMI = [P * r * (1+r)^n] / [(1+r)^n - 1]
    IF v_monthly_rate = 0 THEN
        v_emi := p_principal / p_tenure_months;
    ELSE
        v_emi := (p_principal * v_monthly_rate * POWER(1 + v_monthly_rate, p_tenure_months)) / 
                 (POWER(1 + v_monthly_rate, p_tenure_months) - 1);
    END IF;
    
    RETURN ROUND(v_emi, 2);
END;
$$;

-- Generate loan repayment schedule
CREATE OR REPLACE FUNCTION generate_loan_schedule(
    p_loan_accounts_id INTEGER
) RETURNS TABLE(
    installment_no INTEGER,
    due_date DATE,
    opening_balance DECIMAL(15,4),
    principal_amount DECIMAL(15,4),
    interest_amount DECIMAL(15,4),
    emi_amount DECIMAL(15,4),
    closing_balance DECIMAL(15,4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_loan RECORD;
    v_emi DECIMAL(15,4);
    v_balance DECIMAL(15,4);
    v_monthly_rate DECIMAL(15,6);
    v_principal_part DECIMAL(15,4);
    v_interest_part DECIMAL(15,4);
    v_due_date DATE;
    i INTEGER;
BEGIN
    -- Get loan details
    SELECT 
        loan_amount::DECIMAL,
        interest_rate::DECIMAL,
        tenure::INTEGER,
        installment_amt::DECIMAL,
        first_installment_date::DATE
    INTO v_loan
    FROM loan_accounts
    WHERE loan_accounts_id = p_loan_accounts_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Loan account not found: %', p_loan_accounts_id;
    END IF;
    
    v_emi := v_loan.installment_amt;
    v_balance := v_loan.loan_amount;
    v_monthly_rate := v_loan.interest_rate / (12 * 100);
    v_due_date := v_loan.first_installment_date;
    
    -- Generate schedule
    FOR i IN 1..v_loan.tenure
    LOOP
        v_interest_part := v_balance * v_monthly_rate;
        v_principal_part := v_emi - v_interest_part;
        
        -- Adjust last installment
        IF i = v_loan.tenure THEN
            v_principal_part := v_balance;
            v_emi := v_balance + v_interest_part;
        END IF;
        
        RETURN QUERY SELECT 
            i,
            v_due_date,
            v_balance,
            v_principal_part,
            v_interest_part,
            v_emi,
            v_balance - v_principal_part;
        
        v_balance := v_balance - v_principal_part;
        v_due_date := v_due_date + INTERVAL '1 month';
    END LOOP;
END;
$$;

-- Process loan repayment
CREATE OR REPLACE FUNCTION process_loan_repayment(
    p_loan_accounts_id INTEGER,
    p_payment_amount DECIMAL(15,4),
    p_payment_date DATE DEFAULT CURRENT_DATE,
    p_user_id VARCHAR(300) DEFAULT 'SYSTEM',
    p_branch_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    transaction_head_id INTEGER,
    principal_paid DECIMAL(15,4),
    interest_paid DECIMAL(15,4),
    remaining_balance DECIMAL(15,4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trans_head_id INTEGER;
    v_loan RECORD;
    v_outstanding_balance DECIMAL(15,4);
    v_interest_due DECIMAL(15,4);
    v_principal_payment DECIMAL(15,4);
    v_interest_payment DECIMAL(15,4);
BEGIN
    -- Get loan details
    SELECT 
        la.sub_accounts_id,
        sub_acc.accounts_id,
        ABS(get_sub_account_current_balance(sub_acc.accounts_id, la.sub_accounts_id, p_payment_date)) as balance
    INTO v_loan
    FROM loan_accounts la
    INNER JOIN sub_accounts sub_acc ON la.sub_accounts_id = sub_acc.sub_accounts_id
    WHERE la.loan_accounts_id = p_loan_accounts_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Loan account not found: %', p_loan_accounts_id;
    END IF;
    
    v_outstanding_balance := v_loan.balance;
    
    -- Calculate interest due (simplified - should be based on actual interest posting)
    v_interest_due := 0; -- This should be calculated based on accrued interest
    
    -- Allocate payment (interest first, then principal)
    v_interest_payment := LEAST(p_payment_amount, v_interest_due);
    v_principal_payment := p_payment_amount - v_interest_payment;
    
    -- Create transaction head
    INSERT INTO transaction_head (
        financial_years_id, 
        users_id, 
        branch_id, 
        voucher_no, 
        trans_date, 
        trans_time, 
        trans_amount, 
        trans_narration, 
        mode_of_operation
    ) VALUES (
        (SELECT financial_years_id FROM financial_years WHERE status = '1' LIMIT 1),
        p_user_id,
        COALESCE(p_branch_id, 1),
        NEXTVAL('voucher_seq'),
        p_payment_date,
        CURRENT_TIME,
        p_payment_amount::TEXT,
        'Loan Repayment - Loan ID: ' || p_loan_accounts_id,
        '1'
    ) RETURNING transaction_head_id INTO v_trans_head_id;
    
    -- Credit loan account (reduces loan balance)
    INSERT INTO transaction_details (
        transaction_head_id,
        accounts_id,
        sub_accounts_id,
        trans_amount
    ) VALUES (
        v_trans_head_id,
        v_loan.accounts_id,
        v_loan.sub_accounts_id,
        p_payment_amount
    );
    
    -- Debit cash account
    INSERT INTO transaction_details (
        transaction_head_id,
        accounts_id,
        sub_accounts_id,
        trans_amount
    ) VALUES (
        v_trans_head_id,
        (SELECT accounts_id FROM accounts WHERE account_name = 'Cash' LIMIT 1),
        (SELECT sub_accounts_id FROM sub_accounts WHERE accounts_id = (SELECT accounts_id FROM accounts WHERE account_name = 'Cash' LIMIT 1) AND sub_accounts_no = 0 LIMIT 1),
        -p_payment_amount
    );
    
    -- Insert repayment record
    INSERT INTO loan_repayment (
        loan_accounts_id,
        transaction_head_id,
        repayment_date,
        repayment_amount,
        principal_amount,
        interest_amount,
        created_by
    ) VALUES (
        p_loan_accounts_id,
        v_trans_head_id,
        p_payment_date,
        p_payment_amount,
        v_principal_payment,
        v_interest_payment,
        p_user_id
    );
    
    RETURN QUERY SELECT 
        v_trans_head_id,
        v_principal_payment,
        v_interest_payment,
        v_outstanding_balance - v_principal_payment;
END;
$$;

-- ================================
-- MEMBER MANAGEMENT PROCEDURES
-- ================================

-- Get member portfolio summary
CREATE OR REPLACE FUNCTION get_member_portfolio(
    p_member_id INTEGER,
    p_as_of_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    member_id INTEGER,
    member_name TEXT,
    savings_balance DECIMAL(15,4),
    loan_balance DECIMAL(15,4),
    fd_balance DECIMAL(15,4),
    share_balance DECIMAL(15,4),
    total_assets DECIMAL(15,4),
    total_liabilities DECIMAL(15,4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.members_id,
        m.full_name,
        COALESCE(savings.balance, 0) as savings_balance,
        COALESCE(ABS(loans.balance), 0) as loan_balance,
        COALESCE(fd.balance, 0) as fd_balance,
        COALESCE(shares.balance, 0) as share_balance,
        COALESCE(savings.balance, 0) + COALESCE(fd.balance, 0) + COALESCE(shares.balance, 0) as total_assets,
        COALESCE(ABS(loans.balance), 0) as total_liabilities
    FROM members m
    LEFT JOIN (
        SELECT 
            sa.members_id,
            SUM(get_sub_account_current_balance(sub_acc.accounts_id, sa.sub_accounts_id, p_as_of_date)) as balance
        FROM saving_accounts sa
        INNER JOIN sub_accounts sub_acc ON sa.sub_accounts_id = sub_acc.sub_accounts_id
        WHERE sa.status = '1'
        GROUP BY sa.members_id
    ) savings ON m.members_id = savings.members_id
    LEFT JOIN (
        SELECT 
            la.members_id,
            SUM(get_sub_account_current_balance(sub_acc.accounts_id, la.sub_accounts_id, p_as_of_date)) as balance
        FROM loan_accounts la
        INNER JOIN sub_accounts sub_acc ON la.sub_accounts_id = sub_acc.sub_accounts_id
        WHERE la.status IN ('1', '2')
        GROUP BY la.members_id
    ) loans ON m.members_id = loans.members_id
    LEFT JOIN (
        SELECT 
            fa.members_id,
            SUM(get_sub_account_current_balance(sub_acc.accounts_id, fa.sub_accounts_id, p_as_of_date)) as balance
        FROM fd_accounts fa
        INNER JOIN sub_accounts sub_acc ON fa.sub_accounts_id = sub_acc.sub_accounts_id
        WHERE fa.status = '1'
        GROUP BY fa.members_id
    ) fd ON m.members_id = fd.members_id
    LEFT JOIN (
        SELECT 
            s.members_id,
            SUM(get_sub_account_current_balance(sub_acc.accounts_id, s.sub_accounts_id, p_as_of_date)) as balance
        FROM shares s
        INNER JOIN sub_accounts sub_acc ON s.sub_accounts_id = sub_acc.sub_accounts_id
        WHERE s.status = '1'
        GROUP BY s.members_id
    ) shares ON m.members_id = shares.members_id
    WHERE m.members_id = p_member_id;
END;
$$;

-- Example usage:
-- SELECT * FROM post_savings_interest('2024-12-31', 'admin');
-- SELECT * FROM post_loan_interest('2024-12-31', 'admin');
-- SELECT calculate_emi(100000, 12, 60);
-- SELECT * FROM generate_loan_schedule(1);
-- SELECT * FROM process_loan_repayment(1, 5000);
-- SELECT * FROM get_member_portfolio(1037);
