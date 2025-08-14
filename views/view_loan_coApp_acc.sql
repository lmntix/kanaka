-- dbo.view_loan_coApp_acc source

ALTER VIEW dbo.view_loan_coApp_acc
AS
SELECT     dbo.members.members_id, dbo.members.full_name, dbo.sub_accounts.sub_accounts_id, dbo.sub_accounts.accounts_id, 
                      dbo.sub_accounts.sub_accounts_no, dbo.member_address_contact.address, dbo.city.name AS CityName, dbo.city.pin, 
                      dbo.member_address_contact.telephone
FROM         dbo.members INNER JOIN
                      dbo.member_address_contact ON dbo.members.members_id = dbo.member_address_contact.members_id INNER JOIN
                      dbo.city ON dbo.member_address_contact.city_id = dbo.city.city_id INNER JOIN
                      dbo.loan_co_applicant ON dbo.members.members_id = dbo.loan_co_applicant.members_id INNER JOIN
                      dbo.loan_accounts ON dbo.members.members_id = dbo.loan_accounts.members_id AND 
                      dbo.loan_co_applicant.loan_accounts_id = dbo.loan_accounts.loan_accounts_id INNER JOIN
                      dbo.sub_accounts ON dbo.loan_accounts.sub_accounts_id = dbo.sub_accounts.sub_accounts_id;