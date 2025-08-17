# System Constants Enums - Tabular Format

This document provides a tabular representation of all system constants from the `system_constants` table for the Kanaka Microfinance Application.

## Type 1 - SALUTATION_ENUM

**Purpose**: Member title/salutation prefixes for addressing members  
**Referenced Tables**: `members`, `saving_nominee`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MR | 1 | Mr. |
| MRS | 2 | Mrs. |
| SHRIMATI | 3 | Shrimati. |
| MISS | 4 | Miss. |
| MASTER | 5 | Master. |
| MS | 6 | M/s. |

## Type 2 - ACCOUNT_STATUS_ENUM

**Purpose**: General account status states  
**Referenced Tables**: `accounts.status`, `bank_accounts.status`, `cheque_register.status`, `fd_accounts.status`, `loan_accounts.status`, `recurring_accounts.status`, `saving_accounts.status`, `sub_accounts.status`, `users.status`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| OPEN | 1 | Open |
| FREEZE | 2 | Freeze |
| CLOSE | 4 | Close |

## Type 3 - MEMBER_TYPE_ENUM

**Purpose**: Classification of member categories in cooperative  
**Referenced Tables**: `members.type`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| REGULAR_MEMBER | 1 | Regular member |
| NOMINAL_MEMBER | 2 | Nominal member |
| NOMINAL_OTHER_MEMBER | 3 | Nominal other member |

## Type 4 - GENDER_ENUM

**Purpose**: Gender classification for members and nominees  
**Referenced Tables**: `members.gender`, `saving_nominee.gender`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MALE | 1 | Male |
| FEMALE | 2 | Female |

## Type 5 - VOUCHER_TYPE_ENUM

**Purpose**: Transaction/voucher entry types for double-entry bookkeeping  
**Referenced Tables**: `transaction_head.voucher_type`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| CREDIT_RECEIPT | 1 | Credit(receipt) |
| DEBIT_PAYMENT | 2 | Debit(payment) |
| JOURNAL_VOUCHER | 3 | Journal voucher |
| CONTRA | 4 | Contra |
| OPENING_BALANCE | 5 | Opening balance |

## Type 6 - ENTITY_TYPE_ENUM

**Purpose**: System entity classifications for configuration  
**Referenced Tables**: System configuration tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ACCOUNT | 1 | Account |
| GROUP | 2 | Group |
| DEMAND_RULES | 3 | Demand rules |

## Type 11 - GENERAL_STATUS_ENUM

**Purpose**: General active/inactive status for various entities  
**Referenced Tables**: `offices.status`, scheme status fields

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ACTIVE | 1 | Active |
| INACTIVE | 4 | Inactive |

## Type 18 - OPERATION_MODE_ENUM

**Purpose**: Account operation permissions for transactions and withdrawals  
**Referenced Tables**: `saving_schemes`, `fd_schemes`, `loan_schemes`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MAIN_HOLDER_ONLY | 1 | Main account holder only |
| JOINT_HOLDER_ONLY | 2 | Joint account holder only |
| BOTH_HOLDERS_REQUIRED | 3 | Both account holders compulsory |
| ANY_ONE_HOLDER | 4 | Any one holder |
| SELF | 5 | Self |
| ANY_TWO_HOLDERS | 6 | Any Two Account Holder |

## Type 21 - ACCOUNT_GROUP_ENUM

**Purpose**: Chart of accounts grouping for financial reporting and balance sheet categorization  
**Referenced Tables**: `account_groups.group_type`, `accounts.account_type`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| SHARES | 1 | Shares |
| RESERVE_FUND | 2 | Reserve and other fund |
| DEPOSIT | 3 | Deposit |
| LOAN | 4 | Loan |
| INVESTMENT | 5 | Investment |
| DEPOSIT_INTEREST | 6 | Deposit Interest |
| LOAN_INTEREST | 7 | Loan Interest |
| INVESTMENT_INTEREST | 8 | Investment Interest |
| CASH_BANK_BALANCE | 9 | Cash and bank balance |
| OTHER_LIABILITY | 10 | Other liability |
| SUNDRY_DEBTORS | 11 | Sundry debtors |
| OTHER_INCOME | 12 | Other income |
| OTHER_EXPENSES | 13 | Other expenses |
| GENERAL_EXPENSES | 14 | General expenses |
| MANAGEMENT_EXPENSES | 15 | Management expenses |
| UNPAID_DIVIDEND | 16 | Unpaid dividend |
| PAID_DIVIDEND | 17 | Paid dividend |
| DIVIDEND_RECEIVED | 18 | Dividend received |
| LOAN_ADVANCES | 19 | Loan advances |
| SECURED_LOAN | 20 | Secured loan |
| UNSECURED_LOAN | 21 | Unsecured loan |
| PROVISION_DOUBTFUL_DEBT | 22 | Provision to doubtful and bad debts |
| CURRENT_LIABILITIES | 23 | Current Liabilities Provision |
| CURRENT_ASSET | 24 | Current asset |
| SUNDRY_ASSETS | 25 | Sundry assets |
| FIXED_ASSETS | 26 | Fixed Assets |
| DEPRECIATION_FIXED_ASSETS | 27 | Depreciation on fixed assets |
| OTHER | 28 | Other |
| PROFIT_LOSS | 29 | Profit loss |
| NET_PROFIT | 30 | Net profit |
| NET_LOSS | 31 | Net loss |
| INTEREST_RECEIVABLE | 32 | Interest Receivable |
| INTEREST_PAYABLE | 33 | Interest Payable |

## Type 22 - SUB_ACCOUNT_TYPE_ENUM

**Purpose**: Detailed account type classification for specific financial products and transactions  
**Referenced Tables**: `sub_accounts.sub_account_type`, `sub_account_type`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| OPENING_BALANCE | 1 | Opening balance |
| CURRENT_PROFIT | 2 | Current profit |
| PREVIOUS_PROFIT | 3 | Previous profit |
| CURRENT_LOSS | 4 | Current loss |
| PREVIOUS_LOSS | 5 | Previous loss |
| CASH | 6 | Cash |
| DIFFERENCE_OPENING | 7 | Difference in opening balance |
| BANK | 8 | Bank |
| BANK_LOAN_INTEREST | 12 | Bank Loan Interest |
| SAVINGS | 14 | Savings |
| SAVINGS_INTEREST | 15 | Savings Interest |
| SAVINGS_INTEREST_PAYABLE | 16 | Savings Interest Payable |
| RECURRING | 17 | Recurring |
| RECURRING_INTEREST | 18 | Recurring Interest |
| RECURRING_INTEREST_PAYABLE | 19 | Recurring Interest Payable |
| RECURRING_PENALTY | 20 | Recurring Penalty |
| DAILY | 21 | Daily |
| DAILY_INTEREST | 22 | Daily Interest |
| DAILY_INTEREST_PAYABLE | 23 | Daily interest Payable |
| DAILY_AGENT_COMMISSION | 24 | Daily Agent Commission |
| FIXED_DEPOSIT | 25 | Fixed Deposit |
| DEPOSIT_INTEREST | 26 | Deposit Interest |
| FD_INTEREST_PAYABLE | 27 | Fixed Deposit Interest Payable |
| LOAN | 28 | Loan |
| LOAN_INTEREST | 29 | Loan Interest |
| LOAN_INTEREST_RECEIVABLE | 30 | Loan Interest Receivable |
| LOAN_PENAL_INTEREST | 31 | Loan Penal Interest |
| LOAN_PENAL_INTEREST_RECEIVABLE | 32 | Loan Penal Interest Receivable |
| LOAN_REBATE | 33 | Loan rebate |
| INVESTMENT | 34 | Investment |
| INVESTMENT_INTEREST | 35 | Investment Interest |
| INVESTMENT_INTEREST_RECEIVABLE | 36 | Investment Interest Receivable |
| CURRENT | 37 | Current |
| CURRENT_INTEREST | 38 | Current Interest |
| CURRENT_INTEREST_PAYABLE | 39 | Current Interest Payable |
| SHARES | 40 | Shares |
| DIVIDEND_PAID | 41 | Dividend Paid |
| DIVIDEND_PAYABLE | 42 | Dividend Payable |
| SHARES_APPLICATION_MONEY | 43 | Shares application money |
| ADMISSION_FEE | 44 | Admission Fee |
| SHARES_TRANSFER_FEE | 45 | Shares transfer fee |
| DEADSTOCK | 46 | Deadstock |
| DEPRECIATION | 47 | Depreciation |
| INSURANCE | 49 | Insurance |
| ADVANCE_ACCOUNT | 50 | Advance account |
| RESERVE_FUND | 52 | Reserve fund |
| BUILDING_FUND | 53 | Building fund |
| DOUBTFUL_BAD_DEBT_FUND | 55 | Doubtful and bad debt fund |
| CHARITY_FUND | 57 | Charity fund |
| DIVIDEND_EQUALISATION_FUND | 58 | Dividend equalisation fund |
| CURRENT_EXPENSES | 59 | Current expenses |
| PRINTING_STATIONARY | 60 | Printing and stationary expenses |
| NOTICE_EXPENSES | 61 | Notice expenses |
| POSTAL_EXPENSES | 62 | Postal expenses |
| TRAVEL_EXPENSES | 63 | Travel expenses |
| NOMINAL_EXPENSES | 64 | Nominal expenses |
| AUDIT_FEE_EXPENSES | 65 | Audit fee expences |
| SALARY_EXPENSES | 66 | Salary expenses |
| OTHER_INCOME | 67 | Other income |
| INCOME_TAX | 68 | Income tax |
| PROFESSIONAL_TAX | 69 | Professional tax |
| SERVICE_TAX | 70 | Service tax |
| FRINGE_BENEFIT_TAX | 73 | Fringe benefit tax |
| LOAN_NPA_ADVANCE | 74 | Loan NPA advance |
| DEPOSIT_ACCOUNT | 75 | Deposit account |
| PIGMY_AGENT_COMMISSION_REDUCTION | 76 | pigmy agent commission reduction |
| CREDIT_PIGMY_PENALTY | 77 | Credit pigmy penalty |
| OTHER | 78 | Other |
| OTHER_LIABILITY | 81 | Other liability |
| SUNDRY_DEBTORS | 82 | Sundry debtors |
| PROFIT | 83 | Profit |
| LOSS | 84 | Loss |
| NOMINAL_ENTRY_FEE | 86 | Nominal entry fee |
| MEMBER_EMPLOYEE_WELFARE_FUND | 87 | Member and employee welfare fund |
| PROVIDENT_FUND | 88 | Provident Fund |
| GRATUITY_FUND | 89 | Gratuity Fund |
| DEPRECIATION_FUND | 90 | Depreciation fund |
| TDS_PAYABLE | 91 | T.D.S. Payable |
| PROFESSIONAL_TAX_PAYABLE | 92 | Professional Tax Payable |
| FRINGE_BENEFIT_TAX_PAYABLE | 93 | Fringe Benefit Tax Payable |
| AUDIT_FEE_PAYABLE | 94 | Audit fee payable |
| SURCHARGE_PAYABLE | 95 | Surcharge Payable |
| SERVICE_TAX_PAYABLE | 96 | Service Tax Payable |
| LOAN_NPA_PROVISION | 97 | Loan NPA Provision |
| REMAINING_STATIONARY | 98 | Remaining stationary |
| NPA_LOAN_INTEREST_RECEIVABLE | 99 | NPA Loan Interest Receivable |
| DRAFT_COMMISSION | 100 | Draft commission |
| TELEPHONE_MOBILE_EXPENSES | 101 | Telephone and mobile expenses |
| OVERDUE_INTEREST_PROVISION | 102 | overdue interest provision expenses |
| DOUBTFUL_BAD_DEBT_LOAN_FUND | 103 | Doubtful and bad debt loan fund |
| ENTERTAINMENT_EXPENSES | 104 | Entertainment expenses |
| HOSPITALITY_EXPENSES | 105 | Hospitality expenses |
| HOTEL_LODGING_BOARDING | 106 | Hotel, Lodging, Boarding Expenses |
| VEHICLE_DRIVING_REPAIR | 107 | Vehicle driving,repair expenses |
| VEHICLE_DEPRECIATION | 108 | Vehicle depreciation |
| EMPLOYEE_WELFARE_FUND | 109 | Employee welfare fund |
| CONFERENCE_MANAGEMENT_EXPENSE | 110 | Conference management expense |
| SUPER_ANNUATION_FUND | 111 | Super annuation fund expenses |
| EMPLOYEE_PERSONAL_TRAVEL | 112 | Employee personal travel expenses |
| GIFT_SCHOLARSHIP_EXPENSES | 113 | Gift and scholarship expenses |
| RESTHOUSE_MAINTENANCE | 114 | Resthouse maintenence expenses |
| FESTIVAL_CELEBRATION | 115 | Festival celebration expenses |
| SELL_PROSPERITY_EXPENSE | 116 | Sell prosperity expense |
| HEALTH_CLUB_EXPENSES | 117 | Health club expenses |
| EMPLOYEE_FUTURE_MAINTENANCE | 118 | Employee future maintenance fund expenses |
| EMPLOYEE_GRATUITY_FUND | 119 | Employee gratuity fund expenses |
| AGENT_COLLECTION | 120 | Agent collection |
| DEMAND_COLLECTION | 121 | Demand collection |
| RECOVERY_EXPENSES | 122 | Recovery expenses |
| SLR_INVESTMENT | 123 | SLR Investment |
| DEMAND_MULTIPLE_RECURRING | 124 | Demand for multiple recurring accounts |
| PREVIOUS_PENDING_LOAN | 125 | Previous Pending Loan |
| ELECTRICITY_BILL | 126 | Electricity Bill |
| WATER_BILL | 127 | Water Bill |
| LOAN_OIR | 128 | Loan O.I.R. |
| OBC | 129 | O.B.C. |
| OBR | 130 | O.B.R. |
| BANK_CHARGES | 131 | Bank Charges |
| CHEQUE_RETURN_CHARGES | 132 | Cheque Return Charges |
| CHEQUE_ISSUE_CHARGES | 133 | Cheque Issue Charges |
| LOCKER_RENT | 134 | Locker Rent |
| MISSING_INSTALLMENT_PENALTY | 135 | Missing installment penalty |
| MEMBERSHIP_TRANSACTION | 136 | Membership Transaction |
| DRAFT_COLLECTION | 137 | Draft collection |
| NOMINAL_MEMBER_SHARES | 138 | Nominal Member Shares |
| NOMINAL_MEMBER_DIVIDEND_PAID | 139 | Nominal Member Dividend Paid |
| NOMINAL_MEMBER_DIVIDEND_PAYABLE | 140 | Nominal Member Dividend Payable |
| MEETING_ALLOWANCE | 141 | Meeting Allowance |
| INVESTMENT_CALL_DEPOSIT | 142 | Investment Call Deposit |
| MEMBER_SETTLEMENT | 143 | Member Settlement |
| HO_DEMAND_DRAFT_ACCOUNT | 144 | HO Demand Draft Account |
| HO_DD_PAYABLE_AT_ACCOUNT | 145 | HO DD Payable At Account |
| BANK_OD_INTEREST | 146 | Bank OD Interest |
| CGST | 147 | CGST |
| SGST | 148 | SGST |
| IGST | 149 | IGST |

## Type 26 - DEDUCTION_TYPE_ENUM

**Purpose**: Types of deductions applicable to various accounts and transactions  
**Referenced Tables**: `charges.charge_type`, fee calculation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| SAVING_MIN_BALANCE | 1 | Saving minimum balance |
| ADVANCE_INSTALLMENT | 3 | Advance installment |
| LOAN_PROCESSING_FEE | 4 | Loan processing fee |
| LOAN_RECOVERY | 5 | Loan recovery |
| STATIONARY | 6 | Stationary |
| INSURANCE | 7 | Insurance |
| POSTAGE | 8 | Postage |
| COURT_CASES | 9 | Court cases |
| TRAVEL_EXPENSES | 10 | Travel expenses |
| DEPRECIATION | 11 | Depreciation |
| OTHER_DEDUCTION | 12 | Other deduction |
| SHARE | 13 | Share |
| TDS_AGENT_COMMISSION | 15 | TDS agent commission |
| TDS_INTEREST_POSTING | 16 | TDS interest posting |
| NON_REFUNDABLE_DEPOSIT | 17 | Non refundable deposit |
| RECURRING_MISSING_INSTALLMENTS | 18 | Recurring missing installments |
| NON_OPERATING | 19 | Non operating |
| PREMATURE_CLOSE | 20 | Premature close |
| DAILY_WITHDRAWAL | 21 | Daily withdrawal |
| MATURED_ACCOUNT | 22 | Matured Account |
| INVESTMENT_TDS | 23 | Investment TDS Deduction |
| DEPOSIT_TDS | 24 | Deposit TDS Deduction |

## Type 28 - PRODUCT_STATUS_ENUM

**Purpose**: Status of financial products/schemes  
**Referenced Tables**: `fd_schemes.status`, `loan_schemes.status`, `saving_schemes.status`, `recurring_schemes.status`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ACTIVE | 1 | Active |
| INACTIVE | 2 | Inactive |
| FREEZE | 3 | Freeze |

## Type 33 - SAVINGS_ACCOUNT_TYPE_ENUM

**Purpose**: Types of savings account products  
**Referenced Tables**: `saving_schemes.type`, `saving_accounts`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| NON_REFUNDABLE_DEPOSIT | 1 | Non refundable deposit |
| SAVING | 2 | Saving |
| CURRENT | 3 | Current |
| GUARANTOR_RECOVERY | 4 | Guarantor Recovery |
| NON_OPERATIVE_ACCOUNTS | 5 | Non Operative Accounts |

## Type 34 - DEPOSIT_PRODUCT_TYPE_ENUM

**Purpose**: Types of deposit products offered  
**Referenced Tables**: `fd_schemes.type`, `fd_accounts`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| FIXED_DEPOSIT | 1 | Fixed deposit |
| DOUBLE_MONEY | 2 | Double money |
| CASH_CERTIFICATE | 3 | Cash certificate |
| PENSION | 4 | Pension |
| CALL_DEPOSIT | 5 | Call Deposit |

## Type 35 - INTEREST_FREQUENCY_ENUM

**Purpose**: Interest payment frequency options  
**Referenced Tables**: `fd_schemes.interest_type`, `recurring_schemes.interest_type`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MONTHLY | 1 | Monthly |
| QUARTERLY | 2 | Quarterly |
| HALF_YEARLY | 3 | Half yearly |
| YEARLY | 4 | Yearly |

## Type 40 - LOAN_TYPE_ENUM

**Purpose**: Classification of loan products offered  
**Referenced Tables**: `loan_schemes.type`, `loan_accounts`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| SECURED_LOAN | 1 | Secured loan |
| UNSECURED_LOAN | 2 | Unsecured loan |
| MEMBER_LOAN | 3 | Member loan |
| DEPOSIT_LOAN | 4 | Deposit loan |
| RECURRING_LOAN | 5 | Recurring loan |
| NON_REFUNDABLE_LOAN | 6 | Non refundable loan |
| GOLD_LOAN | 7 | Gold Loan |
| CASH_CREDIT_LOAN | 8 | Cash credit loan |
| DAILY_LOAN | 9 | Daily loan |
| IN_DAYS | 10 | In Days |
| POLICY_LOAN | 11 | Policy loan |
| HP_LOAN | 12 | HP Loan |

## Type 42 - LEGAL_CASE_TYPE_ENUM

**Purpose**: Types of legal cases filed for loan recovery  
**Referenced Tables**: Legal case management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| SECTION_91 | 91 | Case Under Section 91 - Co-Operative Court |
| SECTION_101 | 101 | Case Under Section 101 |
| SECTION_138 | 138 | Case Under Section 138 - Assistant Registrar |

## Type 49 - SECURITY_TYPE_ENUM

**Purpose**: Types of securities/collateral for loans  
**Referenced Tables**: Loan security/collateral tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| IMMOVABLE_ASSET | 1 | Immovable & other asset |
| MACHINERY | 2 | Machinery |
| FIXED_ASSET | 3 | Fixed asset |
| GOLD_LOAN | 4 | Gold Loan |
| HOME_LOAN | 5 | Home Loan |
| CROP_LOAN | 6 | Crop Loan |
| PENSION | 7 | Pension |
| HP_LOAN | 8 | HP Loan |
| SALARY_LOAN | 9 | Salary Loan |

## Type 50 - ORGANIZATION_TYPE_ENUM

**Purpose**: Organization structure hierarchy types  
**Referenced Tables**: `offices`, organizational structure tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| HEADOFFICE | 1 | Headoffice |
| OFFICE | 2 | Office |
| DEPARTMENT | 3 | Department |
| DESIGNATION | 4 | Designation |

## Type 51 - LOOKUP_CATEGORY_ENUM

**Purpose**: Categories for various lookup/dropdown options  
**Referenced Tables**: Various lookup and configuration tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ACCOUNT | 1 | Account |
| GROUP | 2 | Group |
| APPROVAL_OFFICER | 3 | Approval officer |
| CASTE | 4 | Caste |
| CASE_FILED_STATUS | 5 | Case filed status |
| EMPLOYEE | 6 | Employee |
| CALENDER | 7 | Calender |
| LOCATION | 8 | Location |
| MEMBER_FORM_OPTION | 9 | Member form option |
| OCCUPATION | 10 | Occupation |
| RELATION | 11 | Relation |
| SESSION | 12 | Session |
| LOAN_REASON | 13 | Loan reason |
| DEDUCTION_FEE | 14 | Deduction fee |
| TDS | 15 | TDS |
| RELATED_ACCOUNT | 16 | Related account |
| VOUCHER_MASTER | 17 | Voucher master |
| DIRECTOR | 18 | Director |

## Type 52 - BOARD_POSITION_ENUM

**Purpose**: Board positions in cooperative society  
**Referenced Tables**: Board member/director tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| CHAIRMAN | 1 | Chairman |
| VICE_CHAIRMAN | 3 | Vice chairman |
| DIRECTOR | 4 | Director |
| SECRETARY | 5 | Secretary |
| ADVISOR | 6 | Advisor |
| OTHER | 7 | Other |

## Type 53 - EXECUTIVE_POSITION_ENUM

**Purpose**: Executive positions in organization  
**Referenced Tables**: Executive management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MANAGING_DIRECTOR | 2 | Managing director |
| OTHER | 7 | Other |

## Type 54 - LOAN_STATUS_ENUM

**Purpose**: Loan account status including legal action status  
**Referenced Tables**: `loan_accounts.status`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| OPEN | 1 | Open |
| FREEZE | 2 | Freeze |
| CASE_FILED | 3 | Case filed |
| CLOSE | 4 | Close |

## Type 55 - CHARGE_ACTION_ENUM

**Purpose**: Actions for loan charges/liens  
**Referenced Tables**: Charge management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| CREATE_CHARGE | 1 | Create Charge |
| REMOVE_CHARGE | 2 | Remove Charge |

## Type 56 - BANK_ACCOUNT_TYPE_ENUM

**Purpose**: Types of bank accounts  
**Referenced Tables**: `bank_accounts.acc_type`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| SAVINGS | 1 | Savings |
| CURRENT | 2 | Current |
| CASH_CREDIT_OD | 3 | Cash credit/O.D |
| SOCIETY | 4 | Society |
| OTHER_SOCIETY | 5 | Other Society |

## Type 57 - TIME_PERIOD_TYPE_ENUM

**Purpose**: Time period units for tenure calculations  
**Referenced Tables**: Interest rate and tenure calculation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| DAYS | 1 | Days |
| MONTHS | 2 | Months |
| YEAR | 3 | Year |

## Type 58 - PENALTY_PERIOD_TYPE_ENUM

**Purpose**: Period types for penalty calculations  
**Referenced Tables**: Penalty calculation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| DAYS | 1 | Days |
| MONTHS | 2 | Months |

## Type 59 - SOFTWARE_VERSION_ENUM

**Purpose**: Different software versions/systems for data migration compatibility  
**Referenced Tables**: Migration and compatibility tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| BALAJI | 1 | Balaji |
| ENVEE | 2 | Envee |
| ENERGY_NEW | 3 | Energy new |
| AFTEK | 4 | Aftek |
| ENERGY_LOAN | 5 | Energy loan |
| AFTEK_MARATHI | 6 | Aftek marathi |
| ENERGY_NEW_4 | 7 | Energy New 4 |
| AFTEK_SMART_PIGMY | 8 | Aftek Smart Pigmy |
| SOFTLAND | 9 | Softland |
| SAI_BALAJI | 10 | Sai Balaji |
| PEOCIT_MOBILE | 11 | Peocit Mobile |
| BALAJI_9_DIGIT | 12 | Balaji 9 Digit |
| BALAJI_MULTIGL | 13 | Balaji MultiGL |
| ENERGY_LOAN_NEW | 14 | Energy Loan New |
| BALAJI_4_DIGIT | 15 | Balaji 4 digit |
| AFTEK_4_DIGIT | 16 | Aftek 4 digit |
| ADAGAR | 17 | Adagar |
| AFTEK_7_DIGIT | 18 | Aftek 7 digit |
| SAIBALAJI_MULTIGL | 19 | SaiBalaji MultiGL |
| ENERGY_LOAN_NEW_MOBILE | 20 | Energy Loan New Mobile |

## Type 60 - CALCULATION_TYPE_ENUM

**Purpose**: Types of calculation methods for fees/charges  
**Referenced Tables**: Charge calculation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| RUPEES | 1 | Rupees |
| CALCULATED | 2 | Calculated |
| PERCENTAGE | 3 | Percentage |

## Type 61 - FREQUENCY_ENUM

**Purpose**: Transaction/payment frequency options  
**Referenced Tables**: Recurring transaction and payment tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| DAILY | 1 | Daily |
| WEEKLY | 2 | Weekly |
| BIWEEKLY | 3 | Biweekly |
| MONTHLY | 4 | Monthly |
| SPECIFIED_DATE | 5 | Specified Date |
| QUARTERLY | 6 | Quarterly |
| HALF_YEARLY | 7 | Half yearly |
| YEARLY | 8 | Yearly |

## Type 62 - TRANSACTION_MODE_ENUM

**Purpose**: Transaction processing modes  
**Referenced Tables**: Transaction processing tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ALL | 0 |  (All) |
| AUTO | 1 | Auto |
| MANUAL | 2 | Manual |

## Type 63 - TRANSACTION_STATUS_ENUM

**Purpose**: Transaction completion status  
**Referenced Tables**: Transaction history/log tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| SUCCESSFUL | 1 | Successful |
| UNSUCCESSFUL | 2 | Unsuccessful |

## Type 64 - WEEKDAY_ENUM

**Purpose**: Days of the week for scheduling and calendar operations  
**Referenced Tables**: `calender`, scheduling tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| SUNDAY | 0 | Sunday |
| MONDAY | 1 | Monday |
| TUESDAY | 2 | Tuesday |
| WEDNESDAY | 3 | Wednesday |
| THURSDAY | 4 | Thursday |
| FRIDAY | 5 | Friday |
| SATURDAY | 6 | Saturday |

## Type 65 - DEMAND_SORT_ORDER_ENUM

**Purpose**: Sorting options for demand/collection reports  
**Referenced Tables**: Report generation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| DEMAND_DATE | 0 | Demand date |
| DEMAND_NUMBER | 1 | Demand number |
| MONTH | 2 | Month |

## Type 66 - RECOVERY_SORT_ORDER_ENUM

**Purpose**: Sorting options for recovery/payment reports  
**Referenced Tables**: Recovery tracking tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| RECOVERY_DATE | 0 | Recovery date |
| RECEIPT_NUMBER | 1 | Receipt number |
| DEMAND_NUMBER | 2 | Demand number |
| MONTH | 3 | Month |

## Type 67 - LEDGER_SORT_ORDER_ENUM

**Purpose**: Sorting options for ledger reports  
**Referenced Tables**: Ledger and account statement tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| LEDGER_NUMBER | 0 | Ledger number |
| ACCOUNT_NO | 1 | Account No. |
| DEBIT | 2 | Debit |
| MEMBER_NO | 3 | Member No. |

## Type 68 - MOBILE_NUMBER_FILTER_ENUM

**Purpose**: Filtering options for mobile number validation and communication  
**Referenced Tables**: Member communication and SMS tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| WITH_MOBILE | 1 | With Mobile Number |
| WITHOUT_MOBILE | 2 | Without Mobile Number |
| WITH_WRONG_MOBILE | 3 | With Wrong Mobile Number |
| WITH_LOCAL_MOBILE | 4 | With Local Mobile Number |
| WITH_STD_MOBILE | 5 | With STD Mobile Number |
| WITH_ISD_MOBILE | 6 | With ISD Mobile Number |
| WITH_NON_MEMBER_INFO | 7 | With Non Member Information |

## Type 69 - STATIONERY_TYPE_ENUM

**Purpose**: Types of stationery and assets for inventory management  
**Referenced Tables**: Inventory and asset management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| DEADSTOCK | 1 | Deadstock |
| LEDGER | 2 | Ledger |
| PASSBOOK | 3 | Passbook |
| REGISTER | 4 | Register |
| APPLICATION | 5 | Application |
| FD_SLIP | 6 | FD slip |
| CHEQUE | 7 | Cheque |
| DRAFT | 8 | Draft |
| DAILY_RECEIPT | 9 | Daily receipt |
| OTHER | 10 | Other |
| ELECTRONIC_GOODS | 11 | Electronic Goods |
| FURNITURE | 12 | Furniture |
| LIBRARY | 13 | Library |
| BUILDING | 14 | Building |

## Type 70 - PASSBOOK_STATUS_ENUM

**Purpose**: Status of passbook requests/issues  
**Referenced Tables**: Passbook management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| OPEN | 1 | Open |
| CLOSE | 2 | Close |
| REJECTED | 3 | Rejected |
| PENDING | 4 | Pending |

## Type 71 - APPLICATION_STATUS_ENUM

**Purpose**: Status of various applications (loans, accounts, etc.)  
**Referenced Tables**: Application workflow tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| OPEN | 1 | Open |
| APPROVED | 2 | Approved |
| REJECTED | 3 | Rejected |
| PENDING | 4 | Pending |
| CLOSE | 5 | Close |

## Type 72 - GST_RATE_ENUM

**Purpose**: GST tax rates for service charges  
**Referenced Tables**: Tax calculation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| GST_18 | 1 | 18 |
| GST_22 | 2 | 22 |
| GST_24 | 3 | 24 |

## Type 73 - LOAN_NOTICE_TYPE_ENUM

**Purpose**: Types of notices sent for loans  
**Referenced Tables**: Loan notice and communication tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| LOAN_END_REMINDER | 1 | Loan End Reminder |
| LEGAL_ACTION_NOTICE | 2 | Legal Action Notice |
| LOAN_BALANCE | 3 | Loan Balance |

## Type 74 - NOTICE_TYPE_ENUM

**Purpose**: Various types of notices and reminders sent to members  
**Referenced Tables**: Notice generation and tracking tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| OVERDUE_REMINDER | 1 | Overdue Notice / Reminder |
| NOTICE_1 | 2 | Notice 1 |
| NOTICE_2 | 3 | Notice 2 |
| NOTICE_3 | 4 | Notice 3 |
| LAST_NOTICE | 5 | Last Notice |
| REGISTER_NOTICE | 6 | Register Notice |
| CHEQUE_BOUNCE_NOTICE | 7 | Cheque Bounce Notice |
| GOLD_LOAN_NOTICE | 8 | Gold Loan Notice |
| GOLD_LOAN_FINAL_NOTICE | 9 | Gold Loan Final Notice |
| PRE_CUSTODY_NOTICE | 10 | Pre-Custody Notice |
| DEMAND_NOTICE | 11 | Demand Notice |
| DEPOSIT_REMINDER | 12 | Deposit Reminder Letter |
| DEPOSIT_LAST_NOTICE | 13 | Deposit Last Notice |
| DUE_INTEREST_REMINDER | 14 | Due Interest Reminder |

## Type 75 - NOTICE_TARGET_ENUM

**Purpose**: Target recipients for notices  
**Referenced Tables**: Notice distribution tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| OVERDUE_REMINDER | 1 | Overdue Notice / Reminder |
| NOTICE_TO_GUARANTOR | 2 | Notice To Guarantor |
| NOTICE_TO_OFFICE_INDIVIDUAL | 3 | Notice To Office - Individual |
| NOTICE_TO_OFFICE_ALL | 4 | Notice To Office - All |

## Type 76 - ACCOUNT_CATEGORY_ENUM

**Purpose**: Special account categories for different member types  
**Referenced Tables**: Account setup and interest calculation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| REGULAR_ACCOUNT | 1 | Regular Account |
| SENIOR_CITIZEN_ACCOUNT | 2 | Senior Citizen Account |
| FEMALE | 3 | Female |
| WIDOW | 4 | Widow |
| HANDICAPPED | 5 | Handicapped |
| OTHER_SOCIETY | 6 | Other Society |
| EMPLOYEE | 7 | Employee |
| FREEDOM_FIGHTER | 8 | Freedom Fighter |

## Type 77 - CHEQUE_BOOK_TYPE_ENUM

**Purpose**: Types of chequebooks issued  
**Referenced Tables**: Chequebook management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| REGULAR_CHEQUEBOOK | 1 | Regular Chequebook |
| LOOSE_CHEQUEBOOK | 2 | Loose Chequebook |

## Type 78 - CHEQUE_STATUS_ENUM

**Purpose**: Status of individual cheques  
**Referenced Tables**: `cheque_register.status`

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ISSUED | 1 | Issued |
| CLOSE | 2 | Close |

## Type 79 - CHEQUE_STOP_REASON_ENUM

**Purpose**: Reasons for stopping cheque payments  
**Referenced Tables**: Cheque stop payment tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| CHEQUE_MISSING | 1 | Cheque missing |
| VALIDITY_EXPIRED | 2 | Validity expired |
| CHEQUE_DISHONORED | 3 | Cheque dishonored |
| OTHER | 4 | Other |

## Type 80 - LOAN_SECURITY_TYPE_ENUM

**Purpose**: Types of loan securities for specific loan products  
**Referenced Tables**: Loan security and collateral tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| GOLD_LOAN | 1 | Gold Loan |
| POLICY_LOAN | 2 | Policy Loan |
| SECURED_LOAN | 3 | Secured Loan |
| OTHER_LOAN | 4 | Other Loan |
| HP_LOAN | 5 | HP Loan |

## Type 81 - LOCKER_STATUS_ENUM

**Purpose**: Status of bank lockers  
**Referenced Tables**: Locker management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| AVAILABLE | 1 | Available |
| ALLOTED | 2 | Alloted |
| CLOSE | 3 | Close |

## Type 82 - TIME_PERIOD_ENUM

**Purpose**: Time period indicators  
**Referenced Tables**: Time-based scheduling tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| AM | 1 | AM |
| PM | 2 | PM |

## Type 83 - CHEQUE_TRANSACTION_STATUS_ENUM

**Purpose**: Status of cheque transactions  
**Referenced Tables**: `cheque_register`, cheque clearing tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ISSUED | 1 | Issued |
| CLEARED | 2 | Cleared |
| RETURNED | 3 | Returned |

## Type 84 - IDENTITY_PROOF_TYPE_ENUM

**Purpose**: Types of identity proof documents  
**Referenced Tables**: Member KYC and document tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| DRIVING_LICENSE | 1 | Driving License |
| VOTERS_ID | 2 | Voters Identity Card |
| PAN_CARD | 3 | PAN Card |
| PASSPORT | 4 | Passport |
| AADHAR_CARD | 5 | Aadhar Card |
| EMPLOYMENT_ID | 6 | Employment ID |

## Type 85 - ADDRESS_PROOF_TYPE_ENUM

**Purpose**: Types of address proof documents  
**Referenced Tables**: Member address verification tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| RATION_CARD | 1 | Ration Card |
| ELECTRICITY_BILL | 2 | Electricity Bill |
| TELEPHONE_BILL | 3 | Telephone Bill |
| BANK_STATEMENT | 4 | Bank Account Statement/ Pass Book |
| RENT_AGREEMENT | 5 | House Rent Agreement  |
| INCOME_TAX_CHALAN | 6 | Income Tax Chalan |
| DRIVING_LICENSE | 7 | Driving License |
| VOTERS_ID | 8 | Voters Identity Card |
| PASSPORT | 9 | Passport |
| AADHAR_CARD | 10 | Aadhar Card |
| DOMICILE_CERTIFICATE | 11 | Domestic Certificate |
| GOVT_OFFICE_PROOF | 12 | Residence proof any govt office. |

## Type 86 - INSURANCE_TYPE_ENUM

**Purpose**: Types of insurance products  
**Referenced Tables**: Insurance and member benefit tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ACCIDENTAL_CLAIM | 1 | Accidental Claim |
| GENERAL_INSURANCE | 2 | General Insurance |
| LIFE_INSURANCE | 3 | Life Insurance |
| MEDICLAIM | 4 | Mediclaim |
| OTHER | 5 | Other |

## Type 87 - ROOF_TYPE_ENUM

**Purpose**: Types of house roofing for member surveys  
**Referenced Tables**: Member socioeconomic survey tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| THATCHED | 1 | Thatched |
| TILES | 2 | Tiles |
| STONES | 3 | Stones |
| SHEETS | 4 | Sheets |
| RCC | 5 | RCC |
| OTHER | 6 | Other |

## Type 88 - WATER_SOURCE_ENUM

**Purpose**: Water source types for member surveys  
**Referenced Tables**: Member socioeconomic survey tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MUNICIPAL_TAP | 1 | Municipal Tap |
| COMMUNITY_TAP | 2 | Community Tap |
| BORE_WELL | 3 | Bore Well Water and Pumps |
| OPEN_WELL | 4 | Open Well |
| TANKER | 5 | Tanker |
| CANAL | 6 | Canal |
| LAKE | 7 | Lake |
| RIVER | 8 | River |
| OTHER | 9 | Other |

## Type 89 - TOILET_TYPE_ENUM

**Purpose**: Toilet facility types for member surveys  
**Referenced Tables**: Member socioeconomic survey tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| TOILET_IN_HOUSE | 1 | Toilet In House |
| COMMUNITY_TOILET | 2 | Community Toilet |
| PUBLIC_TOILET | 3 | Public Toilet |
| OTHER | 4 | Other |

## Type 90 - HEALTHCARE_ACCESS_ENUM

**Purpose**: Healthcare access types for member surveys  
**Referenced Tables**: Member socioeconomic survey tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| GOVERNMENT_HOSPITALS | 1 | Government Hospitals |
| PRIVATE_HOSPITALS | 2 | Private Hospitals |
| CLINIC_DISPENSARIES | 3 | Clinic and Dispensaries |
| OTHER | 4 | Other |

## Type 91 - EMPLOYEE_ROLE_ENUM

**Purpose**: Employee roles in the organization  
**Referenced Tables**: `employees`, role management tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| PROMOTER | 1 | Promoter |
| GROUP_ACCOUNTANT | 2 | Group Accountant |
| CREDIT_OFFICER | 3 | Credit Officer |

## Type 92 - APPROVAL_STATUS_ENUM

**Purpose**: Approval status for various transactions and applications  
**Referenced Tables**: Approval workflow tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| PASSED | 1 | Passed |
| UNPASSED | 2 | UnPassed |
| REJECTED | 3 | Rejected |

## Type 93 - ENTITY_REFERENCE_ENUM

**Purpose**: Entity types for reference in various operations  
**Referenced Tables**: Cross-reference and audit tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MEMBER | 1 | Member |
| SAVING_ACCOUNT | 2 | Saving Account |
| DAILY_ACCOUNT | 3 | Daily Account |
| FD_ACCOUNT | 4 | FD Account |
| RECURRING_ACCOUNT | 5 | Recurring Account |
| LOAN_ACCOUNT | 6 | Loan Account |
| INVESTMENT_ACCOUNT | 7 | Investment Account |

## Type 94 - CRUD_OPERATION_ENUM

**Purpose**: CRUD operations for audit trail  
**Referenced Tables**: Audit log and change tracking tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| ADD | 1 | Add |
| MODIFY | 2 | Modify |
| DELETE | 3 | Delete |

## Type 95 - CONTACT_METHOD_ENUM

**Purpose**: Methods of contacting members for recovery/communication  
**Referenced Tables**: Member contact and recovery tracking tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| REMINDER | 1 | Reminder |
| NOTICE_1 | 2 | Notice 1 |
| NOTICE_2 | 3 | Notice 2 |
| NOTICE_3 | 4 | Notice 3 |
| LEGAL_NOTICE | 5 | Legal Notice |
| VISIT | 6 | Visit |
| NAME | 6 | Name |
| PHONE_CALL | 7 | Phone Call |
| SMS | 8 | S.M.S. |
| EMAIL | 9 | E - mail |

## Type 96 - REPORT_FIELD_ENUM

**Purpose**: Field types for report generation  
**Referenced Tables**: Report configuration and generation tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| MEMBERS_ID | 1 | Members Id |
| EMPLOYEE_ID | 2 | Employee Id |
| TOTAL | 5 | Total |
| SR_NO | 7 | Sr No |

## Type 100 - INVESTMENT_BANK_CATEGORY_ENUM

**Purpose**: Categories of banks for investment purposes  
**Referenced Tables**: Investment and bank relationship tables

| Enum Key | Value | Display Name |
|----------|-------|--------------|
| STATE_COOP_BANK | 1 | State Co-Op Bank |
| DCC_BANK | 2 | DCC Bank |
| A_GRADE_CIVIL_COOP_BANK | 3 | "A" Grade Civil Co-Op Bank |
| A_GRADE_NATIONALIZE_BANK | 4 | "A" Grade Nationalize or Regional Bank |
| OTHER_INVESTMENT | 5 | Other Investment |

---

## Summary

This document contains **68 different enum types** with a total of **over 500 individual enum values** that can be converted from database constants to application-level enums for better performance, type safety, and maintainability in your microfinance application.

Each table shows the recommended enum key name, numeric value, and display name that should be used in your application code.
