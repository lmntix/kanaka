# System Constants Analysis for Microfinance Application

This document provides a complete analysis of all system constants from the `system_constants` table, converted to TypeScript/JavaScript enums for the Kanaka Microfinance Application.

## Type 1 - SALUTATION_ENUM
- **App Name**: `SalutationEnum`
- **Values**: 
  - `MR = 1` ("Mr.")
  - `MRS = 2` ("Mrs.")
  - `SHRIMATI = 3` ("Shrimati.")
  - `MISS = 4` ("Miss.")
  - `MASTER = 5` ("Master.")
  - `MS = 6` ("M/s.")
- **Purpose**: Member title/salutation prefixes for addressing members
- **Referenced in Tables**: `members`, `saving_nominee`

## Type 2 - ACCOUNT_STATUS_ENUM
- **App Name**: `AccountStatusEnum`
- **Values**: 
  - `OPEN = 1` ("Open")
  - `FREEZE = 2` ("Freeze")
  - `CLOSE = 4` ("Close")
- **Purpose**: General account status states
- **Referenced in Tables**: `accounts.status`, `bank_accounts.status`, `cheque_register.status`, `fd_accounts.status`, `loan_accounts.status`, `recurring_accounts.status`, `saving_accounts.status`, `sub_accounts.status`, `users.status`

## Type 3 - MEMBER_TYPE_ENUM
- **App Name**: `MemberTypeEnum`
- **Values**: 
  - `REGULAR_MEMBER = 1` ("Regular member")
  - `NOMINAL_MEMBER = 2` ("Nominal member")
  - `NOMINAL_OTHER_MEMBER = 3` ("Nominal other member")
- **Purpose**: Classification of member categories in cooperative
- **Referenced in Tables**: `members.type`

## Type 4 - GENDER_ENUM
- **App Name**: `GenderEnum`
- **Values**: 
  - `MALE = 1` ("Male")
  - `FEMALE = 2` ("Female")
- **Purpose**: Gender classification for members and nominees
- **Referenced in Tables**: `members.gender`, `saving_nominee.gender`

## Type 5 - VOUCHER_TYPE_ENUM
- **App Name**: `VoucherTypeEnum`
- **Values**: 
  - `CREDIT_RECEIPT = 1` ("Credit(receipt)")
  - `DEBIT_PAYMENT = 2` ("Debit(payment)")
  - `JOURNAL_VOUCHER = 3` ("Journal voucher")
  - `CONTRA = 4` ("Contra")
  - `OPENING_BALANCE = 5` ("Opening balance")
- **Purpose**: Transaction/voucher entry types for double-entry bookkeeping
- **Referenced in Tables**: `transaction_head.voucher_type`

## Type 6 - ENTITY_TYPE_ENUM
- **App Name**: `EntityTypeEnum`
- **Values**: 
  - `ACCOUNT = 1` ("Account")
  - `GROUP = 2` ("Group")
  - `DEMAND_RULES = 3` ("Demand rules")
- **Purpose**: System entity classifications for configuration
- **Referenced in Tables**: System configuration tables

## Type 11 - GENERAL_STATUS_ENUM
- **App Name**: `GeneralStatusEnum`
- **Values**: 
  - `ACTIVE = 1` ("Active")
  - `INACTIVE = 4` ("Inactive")
- **Purpose**: General active/inactive status for various entities
- **Referenced in Tables**: `offices.status`, scheme status fields

## Type 18 - OPERATION_MODE_ENUM
- **App Name**: `OperationModeEnum`
- **Values**: 
  - `MAIN_HOLDER_ONLY = 1` ("Main account holder only")
  - `JOINT_HOLDER_ONLY = 2` ("Joint account holder only")
  - `BOTH_HOLDERS_REQUIRED = 3` ("Both account holders compulsory")
  - `ANY_ONE_HOLDER = 4` ("Any one holder")
  - `SELF = 5` ("Self")
  - `ANY_TWO_HOLDERS = 6` ("Any Two Account Holder")
- **Purpose**: Account operation permissions for transactions and withdrawals
- **Referenced in Tables**: Account scheme tables (`saving_schemes`, `fd_schemes`, `loan_schemes`)

## Type 21 - ACCOUNT_GROUP_ENUM
- **App Name**: `AccountGroupEnum`
- **Values**: 
  - `SHARES = 1` ("Shares")
  - `RESERVE_FUND = 2` ("Reserve and other fund")
  - `DEPOSIT = 3` ("Deposit")
  - `LOAN = 4` ("Loan")
  - `INVESTMENT = 5` ("Investment")
  - `DEPOSIT_INTEREST = 6` ("Deposit Interest")
  - `LOAN_INTEREST = 7` ("Loan Interest")
  - `INVESTMENT_INTEREST = 8` ("Investment Interest")
  - `CASH_BANK_BALANCE = 9` ("Cash and bank balance")
  - `OTHER_LIABILITY = 10` ("Other liability")
  - `SUNDRY_DEBTORS = 11` ("Sundry debtors")
  - `OTHER_INCOME = 12` ("Other income")
  - `OTHER_EXPENSES = 13` ("Other expenses")
  - `GENERAL_EXPENSES = 14` ("General expenses")
  - `MANAGEMENT_EXPENSES = 15` ("Management expenses")
  - `UNPAID_DIVIDEND = 16` ("Unpaid dividend")
  - `PAID_DIVIDEND = 17` ("Paid dividend")
  - `DIVIDEND_RECEIVED = 18` ("Dividend received")
  - `LOAN_ADVANCES = 19` ("Loan advances")
  - `SECURED_LOAN = 20` ("Secured loan")
  - `UNSECURED_LOAN = 21` ("Unsecured loan")
  - `PROVISION_DOUBTFUL_DEBT = 22` ("Provision to doubtful and bad debts")
  - `CURRENT_LIABILITIES = 23` ("Current Liabilities Provision")
  - `CURRENT_ASSET = 24` ("Current asset")
  - `SUNDRY_ASSETS = 25` ("Sundry assets")
  - `FIXED_ASSETS = 26` ("Fixed Assets")
  - `DEPRECIATION_FIXED_ASSETS = 27` ("Depreciation on fixed assets")
  - `OTHER = 28` ("Other")
  - `PROFIT_LOSS = 29` ("Profit loss")
  - `NET_PROFIT = 30` ("Net profit")
  - `NET_LOSS = 31` ("Net loss")
  - `INTEREST_RECEIVABLE = 32` ("Interest Receivable")
  - `INTEREST_PAYABLE = 33` ("Interest Payable")
- **Purpose**: Chart of accounts grouping for financial reporting and balance sheet categorization
- **Referenced in Tables**: `account_groups.group_type`, `accounts.account_type`

## Type 22 - SUB_ACCOUNT_TYPE_ENUM
- **App Name**: `SubAccountTypeEnum`
- **Values**: (149 values - showing key ones)
  - `OPENING_BALANCE = 1` ("Opening balance")
  - `CURRENT_PROFIT = 2` ("Current profit")
  - `PREVIOUS_PROFIT = 3` ("Previous profit")
  - `CURRENT_LOSS = 4` ("Current loss")
  - `PREVIOUS_LOSS = 5` ("Previous loss")
  - `CASH = 6` ("Cash")
  - `DIFFERENCE_OPENING = 7` ("Difference in opening balance")
  - `BANK = 8` ("Bank")
  - `BANK_LOAN_INTEREST = 12` ("Bank Loan Interest")
  - `SAVINGS = 14` ("Savings")
  - `SAVINGS_INTEREST = 15` ("Savings Interest")
  - `SAVINGS_INTEREST_PAYABLE = 16` ("Savings Interest Payable")
  - `RECURRING = 17` ("Recurring")
  - `RECURRING_INTEREST = 18` ("Recurring Interest")
  - `RECURRING_INTEREST_PAYABLE = 19` ("Recurring Interest Payable")
  - `RECURRING_PENALTY = 20` ("Recurring Penalty")
  - `DAILY = 21` ("Daily")
  - `DAILY_INTEREST = 22` ("Daily Interest")
  - `DAILY_INTEREST_PAYABLE = 23` ("Daily interest Payable")
  - `DAILY_AGENT_COMMISSION = 24` ("Daily Agent Commission")
  - `FIXED_DEPOSIT = 25` ("Fixed Deposit")
  - `DEPOSIT_INTEREST = 26` ("Deposit Interest")
  - `FD_INTEREST_PAYABLE = 27` ("Fixed Deposit Interest Payable")
  - `LOAN = 28` ("Loan")
  - `LOAN_INTEREST = 29` ("Loan Interest")
  - `LOAN_INTEREST_RECEIVABLE = 30` ("Loan Interest Receivable")
  - `LOAN_PENAL_INTEREST = 31` ("Loan Penal Interest")
  - `LOAN_PENAL_INTEREST_RECEIVABLE = 32` ("Loan Penal Interest Receivable")
  - `LOAN_REBATE = 33` ("Loan rebate")
  - `INVESTMENT = 34` ("Investment")
  - `INVESTMENT_INTEREST = 35` ("Investment Interest")
  - `INVESTMENT_INTEREST_RECEIVABLE = 36` ("Investment Interest Receivable")
  - `CURRENT = 37` ("Current")
  - `CURRENT_INTEREST = 38` ("Current Interest")
  - `CURRENT_INTEREST_PAYABLE = 39` ("Current Interest Payable")
  - `SHARES = 40` ("Shares")
  - `DIVIDEND_PAID = 41` ("Dividend Paid")
  - `DIVIDEND_PAYABLE = 42` ("Dividend Payable")
  - `SHARES_APPLICATION_MONEY = 43` ("Shares application money")
  - `ADMISSION_FEE = 44` ("Admission Fee")
  - `SHARES_TRANSFER_FEE = 45` ("Shares transfer fee")
  - `DEADSTOCK = 46` ("Deadstock")
  - `DEPRECIATION = 47` ("Depreciation")
  - `INSURANCE = 49` ("Insurance")
  - `ADVANCE_ACCOUNT = 50` ("Advance account")
  - `RESERVE_FUND = 52` ("Reserve fund")
  - `BUILDING_FUND = 53` ("Building fund")
  - `DOUBTFUL_BAD_DEBT_FUND = 55` ("Doubtful and bad debt fund")
  - `CHARITY_FUND = 57` ("Charity fund")
  - `DIVIDEND_EQUALISATION_FUND = 58` ("Dividend equalisation fund")
  - `CURRENT_EXPENSES = 59` ("Current expenses")
  - `PRINTING_STATIONARY = 60` ("Printing and stationary expenses")
  - `NOTICE_EXPENSES = 61` ("Notice expenses")
  - `POSTAL_EXPENSES = 62` ("Postal expenses")
  - `TRAVEL_EXPENSES = 63` ("Travel expenses")
  - `NOMINAL_EXPENSES = 64` ("Nominal expenses")
  - `AUDIT_FEE_EXPENSES = 65` ("Audit fee expences")
  - `SALARY_EXPENSES = 66` ("Salary expenses")
  - `OTHER_INCOME = 67` ("Other income")
  - `INCOME_TAX = 68` ("Income tax")
  - `PROFESSIONAL_TAX = 69` ("Professional tax")
  - `SERVICE_TAX = 70` ("Service tax")
  - `FRINGE_BENEFIT_TAX = 73` ("Fringe benefit tax")
  - `LOAN_NPA_ADVANCE = 74` ("Loan NPA advance")
  - `DEPOSIT_ACCOUNT = 75` ("Deposit account")
  - `PIGMY_AGENT_COMMISSION_REDUCTION = 76` ("pigmy agent commission reduction")
  - `CREDIT_PIGMY_PENALTY = 77` ("Credit pigmy penalty")
  - `OTHER = 78` ("Other")
  - `OTHER_LIABILITY = 81` ("Other liability")
  - `SUNDRY_DEBTORS = 82` ("Sundry debtors")
  - `PROFIT = 83` ("Profit")
  - `LOSS = 84` ("Loss")
  - `NOMINAL_ENTRY_FEE = 86` ("Nominal entry fee")
  - `MEMBER_EMPLOYEE_WELFARE_FUND = 87` ("Member and employee welfare fund")
  - `PROVIDENT_FUND = 88` ("Provident Fund")
  - `GRATUITY_FUND = 89` ("Gratuity Fund")
  - `DEPRECIATION_FUND = 90` ("Depreciation fund")
  - `TDS_PAYABLE = 91` ("T.D.S. Payable")
  - `PROFESSIONAL_TAX_PAYABLE = 92` ("Professional Tax Payable")
  - `FRINGE_BENEFIT_TAX_PAYABLE = 93` ("Fringe Benefit Tax Payable")
  - `AUDIT_FEE_PAYABLE = 94` ("Audit fee payable")
  - `SURCHARGE_PAYABLE = 95` ("Surcharge Payable")
  - `SERVICE_TAX_PAYABLE = 96` ("Service Tax Payable")
  - `LOAN_NPA_PROVISION = 97` ("Loan NPA Provision")
  - `REMAINING_STATIONARY = 98` ("Remaining stationary")
  - `NPA_LOAN_INTEREST_RECEIVABLE = 99` ("NPA Loan Interest Receivable")
  - `DRAFT_COMMISSION = 100` ("Draft commission")
  - And 49+ more detailed classifications...
- **Purpose**: Detailed account type classification for specific financial products and transactions
- **Referenced in Tables**: `sub_accounts.sub_account_type`, `sub_account_type`

## Type 26 - DEDUCTION_TYPE_ENUM
- **App Name**: `DeductionTypeEnum`
- **Values**: 
  - `SAVING_MIN_BALANCE = 1` ("Saving minimum balance")
  - `ADVANCE_INSTALLMENT = 3` ("Advance installment")
  - `LOAN_PROCESSING_FEE = 4` ("Loan processing fee")
  - `LOAN_RECOVERY = 5` ("Loan recovery")
  - `STATIONARY = 6` ("Stationary")
  - `INSURANCE = 7` ("Insurance")
  - `POSTAGE = 8` ("Postage")
  - `COURT_CASES = 9` ("Court cases")
  - `TRAVEL_EXPENSES = 10` ("Travel expenses")
  - `DEPRECIATION = 11` ("Depreciation")
  - `OTHER_DEDUCTION = 12` ("Other deduction")
  - `SHARE = 13` ("Share")
  - `TDS_AGENT_COMMISSION = 15` ("TDS agent commission")
  - `TDS_INTEREST_POSTING = 16` ("TDS interest posting")
  - `NON_REFUNDABLE_DEPOSIT = 17` ("Non refundable deposit")
  - `RECURRING_MISSING_INSTALLMENTS = 18` ("Recurring missing installments")
  - `NON_OPERATING = 19` ("Non operating")
  - `PREMATURE_CLOSE = 20` ("Premature close")
  - `DAILY_WITHDRAWAL = 21` ("Daily withdrawal")
  - `MATURED_ACCOUNT = 22` ("Matured Account")
  - `INVESTMENT_TDS = 23` ("Investment TDS Deduction")
  - `DEPOSIT_TDS = 24` ("Deposit TDS Deduction")
- **Purpose**: Types of deductions applicable to various accounts and transactions
- **Referenced in Tables**: `charges.charge_type`, fee calculation tables

## Type 28 - PRODUCT_STATUS_ENUM
- **App Name**: `ProductStatusEnum`
- **Values**: 
  - `ACTIVE = 1` ("Active")
  - `INACTIVE = 2` ("Inactive")
  - `FREEZE = 3` ("Freeze")
- **Purpose**: Status of financial products/schemes
- **Referenced in Tables**: `fd_schemes.status`, `loan_schemes.status`, `saving_schemes.status`, `recurring_schemes.status`

## Type 33 - SAVINGS_ACCOUNT_TYPE_ENUM
- **App Name**: `SavingsAccountTypeEnum`
- **Values**: 
  - `NON_REFUNDABLE_DEPOSIT = 1` ("Non refundable deposit")
  - `SAVING = 2` ("Saving")
  - `CURRENT = 3` ("Current")
  - `GUARANTOR_RECOVERY = 4` ("Guarantor Recovery")
  - `NON_OPERATIVE_ACCOUNTS = 5` ("Non Operative Accounts")
- **Purpose**: Types of savings account products
- **Referenced in Tables**: `saving_schemes.type`, `saving_accounts`

## Type 34 - DEPOSIT_PRODUCT_TYPE_ENUM
- **App Name**: `DepositProductTypeEnum`
- **Values**: 
  - `FIXED_DEPOSIT = 1` ("Fixed deposit")
  - `DOUBLE_MONEY = 2` ("Double money")
  - `CASH_CERTIFICATE = 3` ("Cash certificate")
  - `PENSION = 4` ("Pension")
  - `CALL_DEPOSIT = 5` ("Call Deposit")
- **Purpose**: Types of deposit products offered
- **Referenced in Tables**: `fd_schemes.type`, `fd_accounts`

## Type 35 - INTEREST_FREQUENCY_ENUM
- **App Name**: `InterestFrequencyEnum`
- **Values**: 
  - `MONTHLY = 1` ("Monthly")
  - `QUARTERLY = 2` ("Quarterly")
  - `HALF_YEARLY = 3` ("Half yearly")
  - `YEARLY = 4` ("Yearly")
- **Purpose**: Interest payment frequency options
- **Referenced in Tables**: `fd_schemes.interest_type`, `recurring_schemes.interest_type`

## Type 40 - LOAN_TYPE_ENUM
- **App Name**: `LoanTypeEnum`
- **Values**: 
  - `SECURED_LOAN = 1` ("Secured loan")
  - `UNSECURED_LOAN = 2` ("Unsecured loan")
  - `MEMBER_LOAN = 3` ("Member loan")
  - `DEPOSIT_LOAN = 4` ("Deposit loan")
  - `RECURRING_LOAN = 5` ("Recurring loan")
  - `NON_REFUNDABLE_LOAN = 6` ("Non refundable loan")
  - `GOLD_LOAN = 7` ("Gold Loan")
  - `CASH_CREDIT_LOAN = 8` ("Cash credit loan")
  - `DAILY_LOAN = 9` ("Daily loan")
  - `IN_DAYS = 10` ("In Days")
  - `POLICY_LOAN = 11` ("Policy loan")
  - `HP_LOAN = 12` ("HP Loan")
- **Purpose**: Classification of loan products offered
- **Referenced in Tables**: `loan_schemes.type`, `loan_accounts`

## Type 42 - LEGAL_CASE_TYPE_ENUM
- **App Name**: `LegalCaseTypeEnum`
- **Values**: 
  - `SECTION_91 = 91` ("Case Under Section 91 - Co-Operative Court")
  - `SECTION_101 = 101` ("Case Under Section 101")
  - `SECTION_138 = 138` ("Case Under Section 138 - Assistant Registrar")
- **Purpose**: Types of legal cases filed for loan recovery
- **Referenced in Tables**: Legal case management tables

## Type 49 - SECURITY_TYPE_ENUM
- **App Name**: `SecurityTypeEnum`
- **Values**: 
  - `IMMOVABLE_ASSET = 1` ("Immovable & other asset")
  - `MACHINERY = 2` ("Machinery")
  - `FIXED_ASSET = 3` ("Fixed asset")
  - `GOLD_LOAN = 4` ("Gold Loan")
  - `HOME_LOAN = 5` ("Home Loan")
  - `CROP_LOAN = 6` ("Crop Loan")
  - `PENSION = 7` ("Pension")
  - `HP_LOAN = 8` ("HP Loan")
  - `SALARY_LOAN = 9` ("Salary Loan")
- **Purpose**: Types of securities/collateral for loans
- **Referenced in Tables**: Loan security/collateral tables

## Type 50 - ORGANIZATION_TYPE_ENUM
- **App Name**: `OrganizationTypeEnum`
- **Values**: 
  - `HEADOFFICE = 1` ("Headoffice")
  - `OFFICE = 2` ("Office")
  - `DEPARTMENT = 3` ("Department")
  - `DESIGNATION = 4` ("Designation")
- **Purpose**: Organization structure hierarchy types
- **Referenced in Tables**: `offices`, organizational structure tables

## Type 51 - LOOKUP_CATEGORY_ENUM
- **App Name**: `LookupCategoryEnum`
- **Values**: 
  - `ACCOUNT = 1` ("Account")
  - `GROUP = 2` ("Group")
  - `APPROVAL_OFFICER = 3` ("Approval officer")
  - `CASTE = 4` ("Caste")
  - `CASE_FILED_STATUS = 5` ("Case filed status")
  - `EMPLOYEE = 6` ("Employee")
  - `CALENDER = 7` ("Calender")
  - `LOCATION = 8` ("Location")
  - `MEMBER_FORM_OPTION = 9` ("Member form option")
  - `OCCUPATION = 10` ("Occupation")
  - `RELATION = 11` ("Relation")
  - `SESSION = 12` ("Session")
  - `LOAN_REASON = 13` ("Loan reason")
  - `DEDUCTION_FEE = 14` ("Deduction fee")
  - `TDS = 15` ("TDS")
  - `RELATED_ACCOUNT = 16` ("Related account")
  - `VOUCHER_MASTER = 17` ("Voucher master")
  - `DIRECTOR = 18` ("Director")
- **Purpose**: Categories for various lookup/dropdown options
- **Referenced in Tables**: Various lookup and configuration tables

## Type 52 - BOARD_POSITION_ENUM
- **App Name**: `BoardPositionEnum`
- **Values**: 
  - `CHAIRMAN = 1` ("Chairman")
  - `VICE_CHAIRMAN = 3` ("Vice chairman")
  - `DIRECTOR = 4` ("Director")
  - `SECRETARY = 5` ("Secretary")
  - `ADVISOR = 6` ("Advisor")
  - `OTHER = 7` ("Other")
- **Purpose**: Board positions in cooperative society
- **Referenced in Tables**: Board member/director tables

## Type 53 - EXECUTIVE_POSITION_ENUM
- **App Name**: `ExecutivePositionEnum`
- **Values**: 
  - `MANAGING_DIRECTOR = 2` ("Managing director")
  - `OTHER = 7` ("Other")
- **Purpose**: Executive positions in organization
- **Referenced in Tables**: Executive management tables

## Type 54 - LOAN_STATUS_ENUM
- **App Name**: `LoanStatusEnum`
- **Values**: 
  - `OPEN = 1` ("Open")
  - `FREEZE = 2` ("Freeze")
  - `CASE_FILED = 3` ("Case filed")
  - `CLOSE = 4` ("Close")
- **Purpose**: Loan account status including legal action status
- **Referenced in Tables**: `loan_accounts.status`

## Type 55 - CHARGE_ACTION_ENUM
- **App Name**: `ChargeActionEnum`
- **Values**: 
  - `CREATE_CHARGE = 1` ("Create Charge")
  - `REMOVE_CHARGE = 2` ("Remove Charge")
- **Purpose**: Actions for loan charges/liens
- **Referenced in Tables**: Charge management tables

## Type 56 - BANK_ACCOUNT_TYPE_ENUM
- **App Name**: `BankAccountTypeEnum`
- **Values**: 
  - `SAVINGS = 1` ("Savings")
  - `CURRENT = 2` ("Current")
  - `CASH_CREDIT_OD = 3` ("Cash credit/O.D")
  - `SOCIETY = 4` ("Society")
  - `OTHER_SOCIETY = 5` ("Other Society")
- **Purpose**: Types of bank accounts
- **Referenced in Tables**: `bank_accounts.acc_type`

## Type 57 - TIME_PERIOD_TYPE_ENUM
- **App Name**: `TimePeriodTypeEnum`
- **Values**: 
  - `DAYS = 1` ("Days")
  - `MONTHS = 2` ("Months")
  - `YEAR = 3` ("Year")
- **Purpose**: Time period units for tenure calculations
- **Referenced in Tables**: Interest rate and tenure calculation tables

## Type 58 - PENALTY_PERIOD_TYPE_ENUM
- **App Name**: `PenaltyPeriodTypeEnum`
- **Values**: 
  - `DAYS = 1` ("Days")
  - `MONTHS = 2` ("Months")
- **Purpose**: Period types for penalty calculations
- **Referenced in Tables**: Penalty calculation tables

## Type 59 - SOFTWARE_VERSION_ENUM
- **App Name**: `SoftwareVersionEnum`
- **Values**: (20 software versions)
  - `BALAJI = 1` ("Balaji")
  - `ENVEE = 2` ("Envee")
  - `ENERGY_NEW = 3` ("Energy new")
  - `AFTEK = 4` ("Aftek")
  - `ENERGY_LOAN = 5` ("Energy loan")
  - `AFTEK_MARATHI = 6` ("Aftek marathi")
  - `ENERGY_NEW_4 = 7` ("Energy New 4")
  - `AFTEK_SMART_PIGMY = 8` ("Aftek Smart Pigmy")
  - `SOFTLAND = 9` ("Softland")
  - `SAI_BALAJI = 10` ("Sai Balaji")
  - `PEOCIT_MOBILE = 11` ("Peocit Mobile")
  - `BALAJI_9_DIGIT = 12` ("Balaji 9 Digit")
  - `BALAJI_MULTIGL = 13` ("Balaji MultiGL")
  - `ENERGY_LOAN_NEW = 14` ("Energy Loan New")
  - `BALAJI_4_DIGIT = 15` ("Balaji 4 digit")
  - `AFTEK_4_DIGIT = 16` ("Aftek 4 digit")
  - `ADAGAR = 17` ("Adagar")
  - `AFTEK_7_DIGIT = 18` ("Aftek 7 digit")
  - `SAIBALAJI_MULTIGL = 19` ("SaiBalaji MultiGL")
  - `ENERGY_LOAN_NEW_MOBILE = 20` ("Energy Loan New Mobile")
- **Purpose**: Different software versions/systems for data migration compatibility
- **Referenced in Tables**: Migration and compatibility tables

## Type 60 - CALCULATION_TYPE_ENUM
- **App Name**: `CalculationTypeEnum`
- **Values**: 
  - `RUPEES = 1` ("Rupees")
  - `CALCULATED = 2` ("Calculated")
  - `PERCENTAGE = 3` ("Percentage")
- **Purpose**: Types of calculation methods for fees/charges
- **Referenced in Tables**: Charge calculation tables

## Type 61 - FREQUENCY_ENUM
- **App Name**: `FrequencyEnum`
- **Values**: 
  - `DAILY = 1` ("Daily")
  - `WEEKLY = 2` ("Weekly")
  - `BIWEEKLY = 3` ("Biweekly")
  - `MONTHLY = 4` ("Monthly")
  - `SPECIFIED_DATE = 5` ("Specified Date")
  - `QUARTERLY = 6` ("Quarterly")
  - `HALF_YEARLY = 7` ("Half yearly")
  - `YEARLY = 8` ("Yearly")
- **Purpose**: Transaction/payment frequency options
- **Referenced in Tables**: Recurring transaction and payment tables

## Type 62 - TRANSACTION_MODE_ENUM
- **App Name**: `TransactionModeEnum`
- **Values**: 
  - `ALL = 0` (" (All)")
  - `AUTO = 1` ("Auto")
  - `MANUAL = 2` ("Manual")
- **Purpose**: Transaction processing modes
- **Referenced in Tables**: Transaction processing tables

## Type 63 - TRANSACTION_STATUS_ENUM
- **App Name**: `TransactionStatusEnum`
- **Values**: 
  - `SUCCESSFUL = 1` ("Successful")
  - `UNSUCCESSFUL = 2` ("Unsuccessful")
- **Purpose**: Transaction completion status
- **Referenced in Tables**: Transaction history/log tables

## Type 64 - WEEKDAY_ENUM
- **App Name**: `WeekdayEnum`
- **Values**: 
  - `SUNDAY = 0` ("Sunday")
  - `MONDAY = 1` ("Monday")
  - `TUESDAY = 2` ("Tuesday")
  - `WEDNESDAY = 3` ("Wednesday")
  - `THURSDAY = 4` ("Thursday")
  - `FRIDAY = 5` ("Friday")
  - `SATURDAY = 6` ("Saturday")
- **Purpose**: Days of the week for scheduling and calendar operations
- **Referenced in Tables**: `calender`, scheduling tables

## Type 65 - DEMAND_SORT_ORDER_ENUM
- **App Name**: `DemandSortOrderEnum`
- **Values**: 
  - `DEMAND_DATE = 0` ("Demand date")
  - `DEMAND_NUMBER = 1` ("Demand number")
  - `MONTH = 2` ("Month")
- **Purpose**: Sorting options for demand/collection reports
- **Referenced in Tables**: Report generation tables

## Type 66 - RECOVERY_SORT_ORDER_ENUM
- **App Name**: `RecoverySortOrderEnum`
- **Values**: 
  - `RECOVERY_DATE = 0` ("Recovery date")
  - `RECEIPT_NUMBER = 1` ("Receipt number")
  - `DEMAND_NUMBER = 2` ("Demand number")
  - `MONTH = 3` ("Month")
- **Purpose**: Sorting options for recovery/payment reports
- **Referenced in Tables**: Recovery tracking tables

## Type 67 - LEDGER_SORT_ORDER_ENUM
- **App Name**: `LedgerSortOrderEnum`
- **Values**: 
  - `LEDGER_NUMBER = 0` ("Ledger number")
  - `ACCOUNT_NO = 1` ("Account No.")
  - `DEBIT = 2` ("Debit")
  - `MEMBER_NO = 3` ("Member No.")
- **Purpose**: Sorting options for ledger reports
- **Referenced in Tables**: Ledger and account statement tables

## Type 68 - MOBILE_NUMBER_FILTER_ENUM
- **App Name**: `MobileNumberFilterEnum`
- **Values**: 
  - `WITH_MOBILE = 1` ("With Mobile Number")
  - `WITHOUT_MOBILE = 2` ("Without Mobile Number")
  - `WITH_WRONG_MOBILE = 3` ("With Wrong Mobile Number")
  - `WITH_LOCAL_MOBILE = 4` ("With Local Mobile Number")
  - `WITH_STD_MOBILE = 5` ("With STD Mobile Number")
  - `WITH_ISD_MOBILE = 6` ("With ISD Mobile Number")
  - `WITH_NON_MEMBER_INFO = 7` ("With Non Member Information")
- **Purpose**: Filtering options for mobile number validation and communication
- **Referenced in Tables**: Member communication and SMS tables

## Type 69 - STATIONERY_TYPE_ENUM
- **App Name**: `StationeryTypeEnum`
- **Values**: 
  - `DEADSTOCK = 1` ("Deadstock")
  - `LEDGER = 2` ("Ledger")
  - `PASSBOOK = 3` ("Passbook")
  - `REGISTER = 4` ("Register")
  - `APPLICATION = 5` ("Application")
  - `FD_SLIP = 6` ("FD slip")
  - `CHEQUE = 7` ("Cheque")
  - `DRAFT = 8` ("Draft")
  - `DAILY_RECEIPT = 9` ("Daily receipt")
  - `OTHER = 10` ("Other")
  - `ELECTRONIC_GOODS = 11` ("Electronic Goods")
  - `FURNITURE = 12` ("Furniture")
  - `LIBRARY = 13` ("Library")
  - `BUILDING = 14` ("Building")
- **Purpose**: Types of stationery and assets for inventory management
- **Referenced in Tables**: Inventory and asset management tables

## Type 70 - PASSBOOK_STATUS_ENUM
- **App Name**: `PassbookStatusEnum`
- **Values**: 
  - `OPEN = 1` ("Open")
  - `CLOSE = 2` ("Close")
  - `REJECTED = 3` ("Rejected")
  - `PENDING = 4` ("Pending")
- **Purpose**: Status of passbook requests/issues
- **Referenced in Tables**: Passbook management tables

## Type 71 - APPLICATION_STATUS_ENUM
- **App Name**: `ApplicationStatusEnum`
- **Values**: 
  - `OPEN = 1` ("Open")
  - `APPROVED = 2` ("Approved")
  - `REJECTED = 3` ("Rejected")
  - `PENDING = 4` ("Pending")
  - `CLOSE = 5` ("Close")
- **Purpose**: Status of various applications (loans, accounts, etc.)
- **Referenced in Tables**: Application workflow tables

## Type 72 - GST_RATE_ENUM
- **App Name**: `GstRateEnum`
- **Values**: 
  - `GST_18 = 1` ("18")
  - `GST_22 = 2` ("22")
  - `GST_24 = 3` ("24")
- **Purpose**: GST tax rates for service charges
- **Referenced in Tables**: Tax calculation tables

## Type 73 - LOAN_NOTICE_TYPE_ENUM
- **App Name**: `LoanNoticeTypeEnum`
- **Values**: 
  - `LOAN_END_REMINDER = 1` ("Loan End Reminder")
  - `LEGAL_ACTION_NOTICE = 2` ("Legal Action Notice")
  - `LOAN_BALANCE = 3` ("Loan Balance")
- **Purpose**: Types of notices sent for loans
- **Referenced in Tables**: Loan notice and communication tables

## Type 74 - NOTICE_TYPE_ENUM
- **App Name**: `NoticeTypeEnum`
- **Values**: 
  - `OVERDUE_REMINDER = 1` ("Overdue Notice / Reminder")
  - `NOTICE_1 = 2` ("Notice 1")
  - `NOTICE_2 = 3` ("Notice 2")
  - `NOTICE_3 = 4` ("Notice 3")
  - `LAST_NOTICE = 5` ("Last Notice")
  - `REGISTER_NOTICE = 6` ("Register Notice")
  - `CHEQUE_BOUNCE_NOTICE = 7` ("Cheque Bounce Notice")
  - `GOLD_LOAN_NOTICE = 8` ("Gold Loan Notice")
  - `GOLD_LOAN_FINAL_NOTICE = 9` ("Gold Loan Final Notice")
  - `PRE_CUSTODY_NOTICE = 10` ("Pre-Custody Notice")
  - `DEMAND_NOTICE = 11` ("Demand Notice")
  - `DEPOSIT_REMINDER = 12` ("Deposit Reminder Letter")
  - `DEPOSIT_LAST_NOTICE = 13` ("Deposit Last Notice")
  - `DUE_INTEREST_REMINDER = 14` ("Due Interest Reminder")
- **Purpose**: Various types of notices and reminders sent to members
- **Referenced in Tables**: Notice generation and tracking tables

## Type 75 - NOTICE_TARGET_ENUM
- **App Name**: `NoticeTargetEnum`
- **Values**: 
  - `OVERDUE_REMINDER = 1` ("Overdue Notice / Reminder")
  - `NOTICE_TO_GUARANTOR = 2` ("Notice To Guarantor")
  - `NOTICE_TO_OFFICE_INDIVIDUAL = 3` ("Notice To Office - Individual")
  - `NOTICE_TO_OFFICE_ALL = 4` ("Notice To Office - All")
- **Purpose**: Target recipients for notices
- **Referenced in Tables**: Notice distribution tables

## Type 76 - ACCOUNT_CATEGORY_ENUM
- **App Name**: `AccountCategoryEnum`
- **Values**: 
  - `REGULAR_ACCOUNT = 1` ("Regular Account")
  - `SENIOR_CITIZEN_ACCOUNT = 2` ("Senior Citizen Account")
  - `FEMALE = 3` ("Female")
  - `WIDOW = 4` ("Widow")
  - `HANDICAPPED = 5` ("Handicapped")
  - `OTHER_SOCIETY = 6` ("Other Society")
  - `EMPLOYEE = 7` ("Employee")
  - `FREEDOM_FIGHTER = 8` ("Freedom Fighter")
- **Purpose**: Special account categories for different member types
- **Referenced in Tables**: Account setup and interest calculation tables

## Type 77 - CHEQUE_BOOK_TYPE_ENUM
- **App Name**: `ChequeBookTypeEnum`
- **Values**: 
  - `REGULAR_CHEQUEBOOK = 1` ("Regular Chequebook")
  - `LOOSE_CHEQUEBOOK = 2` ("Loose Chequebook")
- **Purpose**: Types of chequebooks issued
- **Referenced in Tables**: Chequebook management tables

## Type 78 - CHEQUE_STATUS_ENUM
- **App Name**: `ChequeStatusEnum`
- **Values**: 
  - `ISSUED = 1` ("Issued")
  - `CLOSE = 2` ("Close")
- **Purpose**: Status of individual cheques
- **Referenced in Tables**: `cheque_register.status`

## Type 79 - CHEQUE_STOP_REASON_ENUM
- **App Name**: `ChequeStopReasonEnum`
- **Values**: 
  - `CHEQUE_MISSING = 1` ("Cheque missing")
  - `VALIDITY_EXPIRED = 2` ("Validity expired")
  - `CHEQUE_DISHONORED = 3` ("Cheque dishonored")
  - `OTHER = 4` ("Other")
- **Purpose**: Reasons for stopping cheque payments
- **Referenced in Tables**: Cheque stop payment tables

## Type 80 - LOAN_SECURITY_TYPE_ENUM
- **App Name**: `LoanSecurityTypeEnum`
- **Values**: 
  - `GOLD_LOAN = 1` ("Gold Loan")
  - `POLICY_LOAN = 2` ("Policy Loan")
  - `SECURED_LOAN = 3` ("Secured Loan")
  - `OTHER_LOAN = 4` ("Other Loan")
  - `HP_LOAN = 5` ("HP Loan")
- **Purpose**: Types of loan securities for specific loan products
- **Referenced in Tables**: Loan security and collateral tables

## Type 81 - LOCKER_STATUS_ENUM
- **App Name**: `LockerStatusEnum`
- **Values**: 
  - `AVAILABLE = 1` ("Available")
  - `ALLOTED = 2` ("Alloted")
  - `CLOSE = 3` ("Close")
- **Purpose**: Status of bank lockers
- **Referenced in Tables**: Locker management tables

## Type 82 - TIME_PERIOD_ENUM
- **App Name**: `TimePeriodEnum`
- **Values**: 
  - `AM = 1` ("AM")
  - `PM = 2` ("PM")
- **Purpose**: Time period indicators
- **Referenced in Tables**: Time-based scheduling tables

## Type 83 - CHEQUE_TRANSACTION_STATUS_ENUM
- **App Name**: `ChequeTransactionStatusEnum`
- **Values**: 
  - `ISSUED = 1` ("Issued")
  - `CLEARED = 2` ("Cleared")
  - `RETURNED = 3` ("Returned")
- **Purpose**: Status of cheque transactions
- **Referenced in Tables**: `cheque_register`, cheque clearing tables

## Type 84 - IDENTITY_PROOF_TYPE_ENUM
- **App Name**: `IdentityProofTypeEnum`
- **Values**: 
  - `DRIVING_LICENSE = 1` ("Driving License")
  - `VOTERS_ID = 2` ("Voters Identity Card")
  - `PAN_CARD = 3` ("PAN Card")
  - `PASSPORT = 4` ("Passport")
  - `AADHAR_CARD = 5` ("Aadhar Card")
  - `EMPLOYMENT_ID = 6` ("Employment ID")
- **Purpose**: Types of identity proof documents
- **Referenced in Tables**: Member KYC and document tables

## Type 85 - ADDRESS_PROOF_TYPE_ENUM
- **App Name**: `AddressProofTypeEnum`
- **Values**: 
  - `RATION_CARD = 1` ("Ration Card")
  - `ELECTRICITY_BILL = 2` ("Electricity Bill")
  - `TELEPHONE_BILL = 3` ("Telephone Bill")
  - `BANK_STATEMENT = 4` ("Bank Account Statement/ Pass Book")
  - `RENT_AGREEMENT = 5` ("House Rent Agreement ")
  - `INCOME_TAX_CHALAN = 6` ("Income Tax Chalan")
  - `DRIVING_LICENSE = 7` ("Driving License")
  - `VOTERS_ID = 8` ("Voters Identity Card")
  - `PASSPORT = 9` ("Passport")
  - `AADHAR_CARD = 10` ("Aadhar Card")
  - `DOMICILE_CERTIFICATE = 11` ("Domestic Certificate")
  - `GOVT_OFFICE_PROOF = 12` ("Residence proof any govt office.")
- **Purpose**: Types of address proof documents
- **Referenced in Tables**: Member address verification tables

## Type 86 - INSURANCE_TYPE_ENUM
- **App Name**: `InsuranceTypeEnum`
- **Values**: 
  - `ACCIDENTAL_CLAIM = 1` ("Accidental Claim")
  - `GENERAL_INSURANCE = 2` ("General Insurance")
  - `LIFE_INSURANCE = 3` ("Life Insurance")
  - `MEDICLAIM = 4` ("Mediclaim")
  - `OTHER = 5` ("Other")
- **Purpose**: Types of insurance products
- **Referenced in Tables**: Insurance and member benefit tables

## Type 87 - ROOF_TYPE_ENUM
- **App Name**: `RoofTypeEnum`
- **Values**: 
  - `THATCHED = 1` ("Thatched")
  - `TILES = 2` ("Tiles")
  - `STONES = 3` ("Stones")
  - `SHEETS = 4` ("Sheets")
  - `RCC = 5` ("RCC")
  - `OTHER = 6` ("Other")
- **Purpose**: Types of house roofing for member surveys
- **Referenced in Tables**: Member socioeconomic survey tables

## Type 88 - WATER_SOURCE_ENUM
- **App Name**: `WaterSourceEnum`
- **Values**: 
  - `MUNICIPAL_TAP = 1` ("Municipal Tap")
  - `COMMUNITY_TAP = 2` ("Community Tap")
  - `BORE_WELL = 3` ("Bore Well Water and Pumps")
  - `OPEN_WELL = 4` ("Open Well")
  - `TANKER = 5` ("Tanker")
  - `CANAL = 6` ("Canal")
  - `LAKE = 7` ("Lake")
  - `RIVER = 8` ("River")
  - `OTHER = 9` ("Other")
- **Purpose**: Water source types for member surveys
- **Referenced in Tables**: Member socioeconomic survey tables

## Type 89 - TOILET_TYPE_ENUM
- **App Name**: `ToiletTypeEnum`
- **Values**: 
  - `TOILET_IN_HOUSE = 1` ("Toilet In House")
  - `COMMUNITY_TOILET = 2` ("Community Toilet")
  - `PUBLIC_TOILET = 3` ("Public Toilet")
  - `OTHER = 4` ("Other")
- **Purpose**: Toilet facility types for member surveys
- **Referenced in Tables**: Member socioeconomic survey tables

## Type 90 - HEALTHCARE_ACCESS_ENUM
- **App Name**: `HealthcareAccessEnum`
- **Values**: 
  - `GOVERNMENT_HOSPITALS = 1` ("Government Hospitals")
  - `PRIVATE_HOSPITALS = 2` ("Private Hospitals")
  - `CLINIC_DISPENSARIES = 3` ("Clinic and Dispensaries")
  - `OTHER = 4` ("Other")
- **Purpose**: Healthcare access types for member surveys
- **Referenced in Tables**: Member socioeconomic survey tables

## Type 91 - EMPLOYEE_ROLE_ENUM
- **App Name**: `EmployeeRoleEnum`
- **Values**: 
  - `PROMOTER = 1` ("Promoter")
  - `GROUP_ACCOUNTANT = 2` ("Group Accountant")
  - `CREDIT_OFFICER = 3` ("Credit Officer")
- **Purpose**: Employee roles in the organization
- **Referenced in Tables**: `employees`, role management tables

## Type 92 - APPROVAL_STATUS_ENUM
- **App Name**: `ApprovalStatusEnum`
- **Values**: 
  - `PASSED = 1` ("Passed")
  - `UNPASSED = 2` ("UnPassed")
  - `REJECTED = 3` ("Rejected")
- **Purpose**: Approval status for various transactions and applications
- **Referenced in Tables**: Approval workflow tables

## Type 93 - ENTITY_REFERENCE_ENUM
- **App Name**: `EntityReferenceEnum`
- **Values**: 
  - `MEMBER = 1` ("Member")
  - `SAVING_ACCOUNT = 2` ("Saving Account")
  - `DAILY_ACCOUNT = 3` ("Daily Account")
  - `FD_ACCOUNT = 4` ("FD Account")
  - `RECURRING_ACCOUNT = 5` ("Recurring Account")
  - `LOAN_ACCOUNT = 6` ("Loan Account")
  - `INVESTMENT_ACCOUNT = 7` ("Investment Account")
- **Purpose**: Entity types for reference in various operations
- **Referenced in Tables**: Cross-reference and audit tables

## Type 94 - CRUD_OPERATION_ENUM
- **App Name**: `CrudOperationEnum`
- **Values**: 
  - `ADD = 1` ("Add")
  - `MODIFY = 2` ("Modify")
  - `DELETE = 3` ("Delete")
- **Purpose**: CRUD operations for audit trail
- **Referenced in Tables**: Audit log and change tracking tables

## Type 95 - CONTACT_METHOD_ENUM
- **App Name**: `ContactMethodEnum`
- **Values**: 
  - `REMINDER = 1` ("Reminder")
  - `NOTICE_1 = 2` ("Notice 1")
  - `NOTICE_2 = 3` ("Notice 2")
  - `NOTICE_3 = 4` ("Notice 3")
  - `LEGAL_NOTICE = 5` ("Legal Notice")
  - `VISIT = 6` ("Visit")
  - `NAME = 6` ("Name")
  - `PHONE_CALL = 7` ("Phone Call")
  - `SMS = 8` ("S.M.S.")
  - `EMAIL = 9` ("E - mail")
- **Purpose**: Methods of contacting members for recovery/communication
- **Referenced in Tables**: Member contact and recovery tracking tables

## Type 96 - REPORT_FIELD_ENUM
- **App Name**: `ReportFieldEnum`
- **Values**: 
  - `MEMBERS_ID = 1` ("Members Id")
  - `EMPLOYEE_ID = 2` ("Employee Id")
  - `TOTAL = 5` ("Total")
  - `SR_NO = 7` ("Sr No")
- **Purpose**: Field types for report generation
- **Referenced in Tables**: Report configuration and generation tables

## Type 100 - INVESTMENT_BANK_CATEGORY_ENUM
- **App Name**: `InvestmentBankCategoryEnum`
- **Values**: 
  - `STATE_COOP_BANK = 1` ("State Co-Op Bank")
  - `DCC_BANK = 2` ("DCC Bank")
  - `A_GRADE_CIVIL_COOP_BANK = 3` ("\"A\" Grade Civil Co-Op Bank")
  - `A_GRADE_NATIONALIZE_BANK = 4` ("\"A\" Grade Nationalize or Regional Bank")
  - `OTHER_INVESTMENT = 5` ("Other Investment")
- **Purpose**: Categories of banks for investment purposes
- **Referenced in Tables**: Investment and bank relationship tables

---

## Implementation Notes

### Benefits of Converting to Enums

1. **Performance**: No database lookups for validation
2. **Type Safety**: Compile-time validation in TypeScript
3. **Code Clarity**: Self-documenting code with meaningful names
4. **Consistency**: Standardized values across the application
5. **Maintainability**: Centralized constant management
6. **IDE Support**: Better autocomplete and IntelliSense

### Usage Recommendations

1. **TypeScript Enum Example**:
```typescript
export enum SalutationEnum {
  MR = 1,
  MRS = 2,
  SHRIMATI = 3,
  MISS = 4,
  MASTER = 5,
  MS = 6
}
```

2. **Display Values**: Create separate mapping objects for display values if needed
3. **Validation**: Use these enums for form validation and API input validation
4. **Database Migration**: Gradually replace database lookups with enum validations
5. **Backward Compatibility**: Maintain database constants during transition period

### Key Design Patterns Identified

- **Member-Centric Design**: All financial products link to members
- **Double-Entry Compliance**: Transaction types support proper accounting
- **Multi-Tenant Architecture**: Organization isolation patterns
- **Product Flexibility**: Scheme-based configuration approach
- **Status Management**: Comprehensive status tracking across all entities
