# Developer's Business Workflow Guide
## Cooperative Banking System Data Model & Process Flows

### **Your Role as Developer**
This guide explains **exactly what happens in the database** when business events occur. Each scenario shows **step-by-step table insertions/updates** so you can implement the correct application logic.

---

## **🏗️ CORE DATA MODEL UNDERSTANDING**

### **Master Data Hierarchy**
```
members (Member Master)
    └── sub_accounts (Individual Account Numbers)
            └── accounts (Account Types: Shares, Loans, Deposits)
                    └── account_groups (Asset, Liability, Income, Expense)
```

### **Transaction Recording Architecture**
```
Every Business Event → transaction_head → transaction_details (multiple rows)
                          │                      │
                          │                      └── links to sub_accounts
                          │
                          └── may link to: shares, loan_accounts, fd_accounts, etc.
```

### **Key Tables You'll Work With Daily**

1. **`members`** - Customer master data
2. **`sub_accounts`** - Individual account numbers for each customer
3. **`accounts`** - Account type definitions (Shares, RD, FD, Loans)
4. **`transaction_head`** - Transaction header (voucher info)
5. **`transaction_details`** - Double-entry transaction lines
6. **Product-specific tables**: `shares`, `loan_accounts`, `fd_accounts`, `recurring_accounts`, `saving_accounts`

---

## **📋 BUSINESS SCENARIOS & DATABASE WORKFLOWS**

## **SCENARIO 1: New Member Registration**

### **What Happens:**
New member "Ravi Kumar" joins cooperative, wants to subscribe ₹1000 shares.

### **Database Workflow:**

#### **Step 1: Create Member Record**
```sql
INSERT INTO members (
    members_id, full_name, gender, birth_date, pan_no, 
    adhar_id, appli_date, status, type
) VALUES (
    3822, 'Ravi Kumar', '1', '1985-05-15', 'ABCDE1234F',
    '123456789012', '2024-03-15', '1', '1'
);
```

#### **Step 2: Create Sub-Account for Shares**
```sql
INSERT INTO sub_accounts (
    sub_accounts_id, accounts_id, members_id, sub_accounts_no, 
    name, status
) VALUES (
    11545, 1, 3822, '3822', 'Ravi Kumar', '1'
);
```
**Note:** `accounts_id = 1` is "Shares" account type

#### **Step 3: Create Transaction Header**
```sql
INSERT INTO transaction_head (
    transaction_head_id, voucher_master_id, voucher_no, 
    trans_date, trans_amount, trans_narration, 
    financial_years_id, users_id, branch_id
) VALUES (
    227902, '1', '6200', '15/03/2024', '1000', 
    'Share subscription - Ravi Kumar', 1, 'admin', 1
);
```
**Note:** `voucher_master_id = '1'` means Credit/Receipt voucher

#### **Step 4: Create Double-Entry Transaction Details**
```sql
-- DEBIT: Cash account (Money received)
INSERT INTO transaction_details (
    transaction_details_id, transaction_head_id, 
    accounts_id, sub_accounts_id, trans_amount
) VALUES (
    582230, 227902, 11, 111, '1000.0000'
);

-- CREDIT: Member's Share account
INSERT INTO transaction_details (
    transaction_details_id, transaction_head_id, 
    accounts_id, sub_accounts_id, trans_amount
) VALUES (
    582231, 227902, 1, 11545, '-1000.0000'
);
```

#### **Step 5: Record Share Certificate Details**
```sql
INSERT INTO shares (
    shares_id, members_id, transaction_head_id, 
    share_amount, issue_date, share_no_from, share_no_to, 
    certi_no, status
) VALUES (
    1702, 3822, 227902, '1000.0000', '2024-03-15',
    101, 110, 'CERT001', '1'
);
```

### **Summary for Developer:**
- **4-5 table inserts** for member registration with share subscription
- **Always maintain double-entry**: Cash DR + Share Account CR
- **Share certificates** get unique numbers and certificate numbers

---

## **SCENARIO 2: Member Makes Recurring Deposit**

### **What Happens:**
Existing member "Shaila Devi" (member_id=1) deposits ₹200 monthly RD installment.

### **Database Workflow:**

#### **Step 1: Find Member's RD Account**
```sql
-- Developer Query: Find RD sub_account_id
SELECT ra.sub_accounts_id, sa.sub_accounts_no 
FROM recurring_accounts ra 
JOIN sub_accounts sa ON ra.sub_accounts_id = sa.sub_accounts_id
WHERE ra.members_id = 1 AND ra.status = '1';
-- Returns: sub_accounts_id = 252, account_no = "1"
```

#### **Step 2: Create Transaction Header**
```sql
INSERT INTO transaction_head (
    transaction_head_id, voucher_master_id, voucher_no,
    trans_date, trans_amount, trans_narration,
    financial_years_id, users_id
) VALUES (
    227903, '1', '6201', '15/03/2024', '200',
    'RD installment - March 2024', 1, 'cashier'
);
```

#### **Step 3: Double-Entry Transaction**
```sql
-- DEBIT: Cash (Money received)
INSERT INTO transaction_details VALUES (
    582232, 227903, 11, 111, '200.0000'
);

-- CREDIT: Member's RD Account
INSERT INTO transaction_details VALUES (
    582233, 227903, 76, 252, '-200.0000'
);
```
**Note:** `accounts_id = 76` is "Compulsary Diposit" (RD account type)

#### **Step 4: Update Account Balance (Optional - if using balance table)**
```sql
-- Update or insert current balance
INSERT INTO sub_accounts_balance (
    sub_accounts_balance_id, sub_accounts_id, accounts_id,
    balance, date, trans_by, transaction_head_id
) VALUES (
    balance_id, 252, 76, new_balance, '2024-03-15', 'cashier', 227903
);
```

### **Summary for Developer:**
- **Find existing RD account** first
- **2-3 table operations** for deposit
- **Balance calculation**: Sum all transaction_details for the sub_account

---

## **SCENARIO 3: Loan Application & Disbursement**

### **What Happens:**
Member "Goutam Kr. Bowri" applies for ₹50,000 gold loan and gets approved.

### **Database Workflow:**

#### **Step 1: Create Sub-Account for Loan**
```sql
INSERT INTO sub_accounts (
    sub_accounts_id, accounts_id, members_id, 
    sub_accounts_no, name, status
) VALUES (
    11546, 4, 751, '751', 'Goutam Kr. Bowri', '1'
);
```
**Note:** `accounts_id = 4` is "Member Lone" account type

#### **Step 2: Create Loan Account Record**
```sql
INSERT INTO loan_accounts (
    loan_accounts_id, sub_accounts_id, loan_schemes_id, 
    members_id, loan_amount, interest_rate, open_date,
    maturity_date, status
) VALUES (
    3283, 11546, 2, 751, '50000.0000', '12.0', '2024-03-15',
    '2026-03-15', '1'
);
```

#### **Step 3: Record Disbursement Transaction**
```sql
-- Transaction Header
INSERT INTO transaction_head VALUES (
    227904, '2', '6202', '15/03/2024', '50000',
    'Gold loan disbursement - Goutam Kr. Bowri', 1, 'manager'
);

-- DEBIT: Member's Loan Account (Asset for bank)
INSERT INTO transaction_details VALUES (
    582234, 227904, 4, 11546, '50000.0000'
);

-- CREDIT: Cash Account (Money paid out)
INSERT INTO transaction_details VALUES (
    582235, 227904, 11, 111, '-50000.0000'
);
```

#### **Step 4: Link Disbursement to Loan**
```sql
INSERT INTO loan_disbursement (
    loan_disbursement_id, loan_accounts_id, transaction_head_id
) VALUES (
    disburse_id, 3283, 227904
);
```

### **Summary for Developer:**
- **New sub_account** for each loan
- **Loan disbursement** = Debit Loan Asset, Credit Cash
- **Multiple tables** link the loan to transaction

---

## **SCENARIO 4: Loan EMI Payment**

### **What Happens:**
"Goutam Kr. Bowri" pays ₹5,500 EMI (₹5,000 principal + ₹500 interest).

### **Database Workflow:**

#### **Step 1: Calculate EMI Breakdown**
```javascript
// Developer Logic
const emiAmount = 5500;
const interestPortion = calculateInterest(loanBalance, interestRate, days);
const principalPortion = emiAmount - interestPortion;
// Result: principal = 5000, interest = 500
```

#### **Step 2: Create Transaction Header**
```sql
INSERT INTO transaction_head VALUES (
    227905, '1', '6203', '15/04/2024', '5500',
    'Loan EMI payment - Goutam Kr. Bowri', 1, 'cashier'
);
```

#### **Step 3: Triple-Entry Transaction (Cash + Principal + Interest)**
```sql
-- DEBIT: Cash (Money received)
INSERT INTO transaction_details VALUES (
    582236, 227905, 11, 111, '5500.0000'
);

-- CREDIT: Loan Principal (Reduce loan asset)
INSERT INTO transaction_details VALUES (
    582237, 227905, 4, 11546, '-5000.0000'
);

-- CREDIT: Interest Income
INSERT INTO transaction_details VALUES (
    582238, 227905, 128, 128, '-500.0000'  -- Bank interest income account
);
```

#### **Step 4: Record Repayment Link**
```sql
INSERT INTO loan_repayment (
    loan_repayment_id, loan_accounts_id, transaction_head_id
) VALUES (
    repay_id, 3283, 227905
);
```

### **Summary for Developer:**
- **EMI = Principal + Interest** split
- **3-way transaction**: Cash DR, Loan CR, Interest Income CR
- **Auto-calculate interest** based on outstanding balance

---

## **SCENARIO 5: FD Account Opening**

### **What Happens:**
Member opens ₹25,000 FD for 12 months at 8% interest.

### **Database Workflow:**

#### **Step 1: Create FD Sub-Account**
```sql
INSERT INTO sub_accounts VALUES (
    11547, 67, 751, '751-FD-1', 'Goutam Kr. Bowri - FD', '1'
);
```
**Note:** `accounts_id = 67` is Fixed Deposit account type

#### **Step 2: Create FD Account Record**
```sql
INSERT INTO fd_accounts (
    fd_accounts_id, sub_accounts_id, fd_schemes_id, members_id,
    fd_amount, open_date, maturity_date, interest_rate,
    maturity_amount, status
) VALUES (
    304, 11547, 1, 751, '25000.0000', '2024-03-15', '2025-03-15',
    '8.0', '27000.0000', '1'
);
```

#### **Step 3: Record Deposit Transaction**
```sql
-- Transaction Header
INSERT INTO transaction_head VALUES (
    227906, '1', '6204', '15/03/2024', '25000',
    'FD opening - 12 months @ 8%', 1, 'manager'
);

-- DEBIT: Cash (Money received)
INSERT INTO transaction_details VALUES (
    582239, 227906, 11, 111, '25000.0000'
);

-- CREDIT: Member's FD Account
INSERT INTO transaction_details VALUES (
    582240, 227906, 67, 11547, '-25000.0000'
);
```

### **Summary for Developer:**
- **Maturity amount** calculated upfront
- **Same pattern**: Cash DR, FD Account CR
- **Interest calculation** for maturity value

---

## **SCENARIO 6: Automated Interest Posting**

### **What Happens:**
Monthly interest posting run for all saving accounts.

### **Database Workflow (Per Account):**

#### **Step 1: Calculate Interest**
```javascript
// Developer Logic - For each active saving account
const balance = getCurrentBalance(sub_accounts_id);
const rate = getSavingInterestRate(saving_accounts_id);
const interest = (balance * rate * days) / (365 * 100);
```

#### **Step 2: Create Interest Transaction**
```sql
-- For saving account sub_accounts_id = 6788, interest = 285
INSERT INTO transaction_head VALUES (
    227907, '4', '6205', '31/03/2024', '285',
    'Interest upto 31.03.2024', 1, 'SYSTEM'
);

-- DEBIT: Interest Expense (Bank pays interest)
INSERT INTO transaction_details VALUES (
    582241, 227907, 129, 129, '285.0000'  -- Interest expense account
);

-- CREDIT: Member's Saving Account
INSERT INTO transaction_details VALUES (
    582242, 227907, 73, 6788, '-285.0000'
);
```
**Note:** `voucher_master_id = '4'` means Contra voucher (internal transfer)

#### **Step 3: Record Interest Posting**
```sql
INSERT INTO saving_interest_post (
    saving_interest_post_id, sub_accounts_id, transaction_head_id,
    amount, int_date, rate, posting
) VALUES (
    post_id, 6788, 227907, '285.0000', '2024-03-31', '4.0', '1'
);
```

### **Summary for Developer:**
- **Batch process** for all accounts
- **Interest Expense DR, Customer Account CR**
- **Track posting** in separate interest table

---

## **SCENARIO 7: Cash Withdrawal**

### **What Happens:**
Member withdraws ₹2,000 from saving account.

### **Database Workflow:**

#### **Step 1: Validate Balance**
```javascript
// Developer Logic
const currentBalance = calculateBalance(sub_accounts_id);
if (currentBalance < withdrawalAmount) {
    throw "Insufficient balance";
}
```

#### **Step 2: Create Withdrawal Transaction**
```sql
INSERT INTO transaction_head VALUES (
    227908, '2', '6206', '16/03/2024', '2000',
    'Cash withdrawal', 1, 'cashier'
);

-- DEBIT: Member's Saving Account (Reduce liability)
INSERT INTO transaction_details VALUES (
    582243, 227908, 73, 6788, '2000.0000'
);

-- CREDIT: Cash (Money paid out)
INSERT INTO transaction_details VALUES (
    582244, 227908, 11, 111, '-2000.0000'
);
```

### **Summary for Developer:**
- **Balance validation** first
- **Reverse of deposit**: Account DR, Cash CR
- **`voucher_master_id = '2'`** for debit/payment

---

## **SCENARIO 8: Cheque Issue for FD Maturity**

### **What Happens:**
FD matures, issue cheque ₹27,000 to member.

### **Database Workflow:**

#### **Step 1: Create Cheque Record**
```sql
INSERT INTO cheque_register (
    cheque_register_id, bank_accounts_id, cheque_no,
    pay_to, amount, issue_date, cheque_type, status
) VALUES (
    33305, 1, '292226', 'Goutam Kr. Bowri', '27000.0000',
    '2024-03-16', '2', '1'
);
```

#### **Step 2: Create Maturity Transaction**
```sql
INSERT INTO transaction_head VALUES (
    227909, '2', '6207', '16/03/2024', '27000',
    'FD maturity payout', 1, 'manager'
);

-- DEBIT: Member's FD Account (Close FD)
INSERT INTO transaction_details VALUES (
    582245, 227909, 67, 11547, '27000.0000'
);

-- CREDIT: Bank Account (Cheque issued)
INSERT INTO transaction_details VALUES (
    582246, 227909, 112, 112, '-27000.0000'  -- Bank account
);
```

#### **Step 3: Link Cheque to Transaction**
```sql
INSERT INTO cheque_transactions (
    cheque_transactions_id, cheque_register_id, transaction_head_id
) VALUES (
    trans_id, 33305, 227909
);
```

#### **Step 4: Update FD Status**
```sql
UPDATE fd_accounts 
SET status = '4'  -- Closed
WHERE fd_accounts_id = 304;
```

### **Summary for Developer:**
- **Cheque management** integrated with transactions
- **Close FD account** when matured
- **Bank account debited** instead of cash

---

## **🔧 KEY DEVELOPER IMPLEMENTATION PATTERNS**

### **1. Balance Calculation**
```javascript
function calculateBalance(sub_accounts_id) {
    // Sum all transaction_details for this sub_account
    const query = `
        SELECT SUM(CAST(trans_amount AS DECIMAL)) as balance
        FROM transaction_details 
        WHERE sub_accounts_id = ?
    `;
    return executeQuery(query, [sub_accounts_id]);
}
```

### **2. Transaction Validation**
```javascript
function validateTransaction(transactionDetails) {
    const total = transactionDetails.reduce((sum, detail) => 
        sum + parseFloat(detail.amount), 0);
    
    if (Math.abs(total) > 0.001) {  // Allow for rounding
        throw "Transaction not balanced";
    }
}
```

### **3. Voucher Number Generation**
```javascript
function getNextVoucherNumber(voucher_master_id, financial_year_id) {
    const query = `
        SELECT MAX(CAST(voucher_no AS INTEGER)) as last_voucher
        FROM transaction_head 
        WHERE voucher_master_id = ? 
        AND financial_years_id = ?
    `;
    const lastVoucher = executeQuery(query, [voucher_master_id, financial_year_id]);
    return (lastVoucher || 0) + 1;
}
```

### **4. Interest Calculation**
```javascript
function calculateInterest(principal, rate, days) {
    return (principal * rate * days) / (365 * 100);
}
```

## **📊 ESSENTIAL QUERIES FOR YOUR APP**

### **Member Account Summary**
```sql
SELECT 
    a.account_name,
    sa.sub_accounts_no,
    SUM(CAST(td.trans_amount AS DECIMAL)) as balance
FROM sub_accounts sa
JOIN accounts a ON sa.accounts_id = a.accounts_id
LEFT JOIN transaction_details td ON sa.sub_accounts_id = td.sub_accounts_id
WHERE sa.members_id = ?
GROUP BY a.account_name, sa.sub_accounts_no;
```

### **Transaction History**
```sql
SELECT 
    th.trans_date, th.voucher_no, th.trans_narration,
    td.trans_amount, a.account_name
FROM transaction_head th
JOIN transaction_details td ON th.transaction_head_id = td.transaction_head_id
JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
JOIN accounts a ON sa.accounts_id = a.accounts_id
WHERE sa.members_id = ?
ORDER BY th.trans_date DESC, th.voucher_no DESC;
```

### **Daily Cash Position**
```sql
SELECT 
    SUM(CASE WHEN td.trans_amount > 0 THEN CAST(td.trans_amount AS DECIMAL) ELSE 0 END) as cash_in,
    SUM(CASE WHEN td.trans_amount < 0 THEN ABS(CAST(td.trans_amount AS DECIMAL)) ELSE 0 END) as cash_out
FROM transaction_details td
JOIN sub_accounts sa ON td.sub_accounts_id = sa.sub_accounts_id
JOIN transaction_head th ON td.transaction_head_id = th.transaction_head_id
WHERE sa.accounts_id = 11  -- Cash account
AND th.trans_date = ?;
```

---

## **🚨 CRITICAL VALIDATION RULES**

1. **Double-Entry Balance**: Every transaction MUST sum to zero
2. **Account Status**: Only transact on active accounts (`status = '1'`)
3. **Sufficient Balance**: Validate before withdrawals
4. **Sequential Vouchers**: Maintain voucher number sequence
5. **Date Consistency**: Transaction date <= current date
6. **Amount Validation**: No negative amounts in headers
7. **Member Validation**: Member must exist and be active

## **🔄 TRANSACTION STATE MANAGEMENT**

### **Transaction Status Flow**
```
Draft → Validated → Posted → Authorized → Finalized
```

### **Account Status Flow**
```
New (1) → Active (1) → Frozen (2) → Closed (4)
```

This guide gives you **complete clarity** on what happens in the database for every business scenario. Each pattern is consistent and follows the same double-entry principles throughout the system.
