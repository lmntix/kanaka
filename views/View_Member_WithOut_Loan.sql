-- dbo.View_Member_WithOut_Loan source

ALTER VIEW View_Member_WithOut_Loan AS SELECT DISTINCT(members.members_id) AS members_id, members.full_name AS full_name FROM members LEFT OUTER JOIN loan_accounts ON members.members_id = loan_accounts.members_id WHERE members.members_id NOT IN (SELECT members_id FROM loan_accounts AS loan_accounts WHERE status IN(1,2,3)) OR loan_accounts.members_id IS NULL;