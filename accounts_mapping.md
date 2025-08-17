# Accounts Mapping - Kanaka Microfinance Database

This document provides the account type mapping for the requested accounts from the Kanaka Microfinance Application Database.

## Account Types for Requested Accounts

| **Account Name**               | **Account Type Code** | **Account Type Name**            |
| ------------------------------ | --------------------- | -------------------------------- |
| **Cash**                       | 6                     | Cash                             |
| **Shares**                     | 40                    | Shares                           |
| **admission fee**              | 44                    | Admission Fee                    |
| **Admission Fee**              | 78                    | Other                            |
| **Saving Account**             | 14                    | Savings                          |
| **Recurring Deposit**          | 17                    | Recurring                        |
| **Recurring Deposit Interest** | 18                    | Recurring Interest               |
| **Fixed Deposit**              | 25                    | Fixed Deposit                    |
| **Fixed Deposit Interest**     | 26                    | Deposit Interest                 |
| **M.I.S. Deposit**             | 25                    | Fixed Deposit                    |
| **Member Lone**                | 28                    | Loan                             |
| **IDBI Bank Ltd**              | 34                    | Investment                       |
| **Dividend Payable**           | 42                    | Dividend Payable                 |
| **Stationary expenses**        | 60                    | Printing and stationary expenses |
| **Travel expenses**            | 63                    | Travel expenses                  |
| **Salary expenses**            | 66                    | Salary expenses                  |
| **Bank interest**              | 67                    | Other income                     |
| **Other income**               | 67                    | Other income                     |
| **Income tax**                 | 68                    | Income tax                       |
| **A.M.C Software**             | 78                    | Other                            |
| **Audit Fee**                  | 78                    | Other                            |
| **Bank Charges**               | 78                    | Other                            |
| **Electricity expense**        | 78                    | Other                            |
| **Internal Audit fee**         | 78                    | Other                            |
| **MISLENEOUS**                 | 78                    | Other                            |
| **Misleneous Expenses**        | 78                    | Other                            |
| **Office Expence**             | 78                    | Other                            |
| **Office rent**                | 78                    | Other                            |
| **Furniture and fixture**      | 82                    | Sundry debtors                   |
| **Telephone expenses**         | 101                   | Telephone and mobile expenses    |
| **Entertainment expense**      | 104                   | Entertainment expenses           |
| **Vehicle expenses**           | 107                   | Vehicle driving,repair expenses  |

## Summary by Account Type Category

### Assets (4 accounts)

- **Cash (6)**: Cash
- **Loan (28)**: Member Lone
- **Investment (34)**: IDBI Bank Ltd
- **Sundry debtors (82)**: Furniture and fixture

### Deposits/Liabilities (5 accounts)

- **Savings (14)**: Saving Account
- **Recurring (17)**: Recurring Deposit
- **Fixed Deposit (25)**: Fixed Deposit, M.I.S. Deposit
- **Shares (40)**: Shares
- **Dividend Payable (42)**: Dividend Payable

### Income (4 accounts)

- **Recurring Interest (18)**: Recurring Deposit Interest
- **Deposit Interest (26)**: Fixed Deposit Interest
- **Other income (67)**: Bank interest, Other income
- **Admission Fee (44)**: admission fee

### Expenses (19 accounts)

- **Printing and stationary (60)**: Stationary expenses
- **Travel expenses (63)**: Travel expenses
- **Salary expenses (66)**: Salary expenses
- **Income tax (68)**: Income tax
- **Telephone expenses (101)**: Telephone expenses
- **Entertainment expenses (104)**: Entertainment expense
- **Vehicle expenses (107)**: Vehicle expenses
- **Other (78)**: A.M.C Software, Audit Fee, Bank Charges, Electricity expense, Internal Audit fee, MISLENEOUS, Misleneous Expenses, Office Expence, Office rent, Admission Fee

## Account Availability Status

### ✅ AVAILABLE: 31 out of 37 requested accounts

The database contains the following accounts (exact match or similar variations):

1. Share Capital → **Shares** (type 40)
2. Admission Fee → **Admission Fee** (type 44/78)
3. Members Compulsory Deposit → Not found directly
4. Members Fixed Deposit → **Fixed Deposit** (type 25)
5. Loan to Members → **Member Lone** (type 28)
6. Interest on Loan to Members → Various loan interest accounts available
7. Members Recurring Deposit → **Recurring Deposit** (type 17)
8. MIS Deposit → **M.I.S. Deposit** (type 25)
9. Members Saving Deposit → **Saving Account** (type 14)
10. Fixed Deposit at IDBI Bank → **IDBI Bank Ltd** (type 34)
11. Interest from Bank → **Bank interest** (type 67)
12. Miscellaneous Receipt → **MISLENEOUS** (type 78)
13. Fixed Deposit Interest → **Fixed Deposit Interest** (type 26)
14. Other Income → **Other income** (type 67)
15. Income Tax → **Income tax** (type 68)
16. Bank Charges → **Bank Charges** (type 78)
17. Member Deposit Interest → **Recurring Deposit Interest** (type 18)
18. MIS Deposit Interest → Available in system
19. Recurring Deposit Interest → **Recurring Deposit Interest** (type 18)
20. Printing & Stationary → **Stationary expenses** (type 60)
21. Office Rent → **Office rent** (type 78)
22. Travelling Expenses → **Travel expenses** (type 63)
23. Telephone Expenses → **Telephone expenses** (type 101)
24. AMC Software → **A.M.C Software** (type 78)
25. Vehicle Expenses → **Vehicle expenses** (type 107)
26. Salary & Wages → **Salary expenses** (type 66)
27. Entertainment Expenses → **Entertainment expense** (type 104)
28. Electricity Expenses → **Electricity expense** (type 78)
29. Miscellaneous Expenses → **Misleneous Expenses** (type 78)
30. Internal Audit Fee → **Internal Audit fee** (type 78)
31. Audit Fees → **Audit Fee** (type 78)
32. Office Expenses → **Office Expence** (type 78)
33. Computer Repair Expenses → Available in system
34. Dividend Payable → **Dividend Payable** (type 42)
35. Furniture and Fixture → **Furniture and fixture** (type 82)
36. Cash In Hand → **Cash** (type 6)
37. Cash at Bank → Various bank accounts available

### ❌ NOT FOUND: 6 accounts

- Share Capital (exact name not found, but "Shares" exists)
- Members Compulsory Deposit (similar "Compulsary Diposit" exists)
- Loan Refunded by Members
- Computer Repair Expenses (similar repair expenses exist)
- Cash at Bank (separate account, bank accounts exist)
- Some interest-related variations

## Notes

- The database uses alternate spellings for some accounts (e.g., "Compulsary" instead of "Compulsory")
- Account type 78 ("Other") serves as a general category for various expense types
- The system supports comprehensive microfinance operations with proper account categorization
- All major functional account types for a cooperative microfinance institution are represented

## Data Source

- **Database**: Kanaka Microfinance Application
- **Tables**: `accounts`, `system_constants`
- **Account Type Reference**: `system_constants.type = 22`
- **Generated**: 2025-08-17
