-- dbo.view_saving_joint_acc source

ALTER VIEW [dbo].[view_saving_joint_acc]
AS
SELECT     dbo.members.members_id, dbo.members.full_name, dbo.sub_accounts.sub_accounts_id, dbo.sub_accounts.accounts_id, 
                      dbo.sub_accounts.sub_accounts_no, dbo.saving_mode_op.mode_of_operation, dbo.member_address_contact.address, dbo.city.name AS CityName, 
                      dbo.member_address_contact.pin, dbo.member_address_contact.telephone
FROM         dbo.saving_joint_accounts INNER JOIN
                      dbo.saving_accounts ON dbo.saving_joint_accounts.saving_accounts_id = dbo.saving_accounts.saving_accounts_id INNER JOIN
                      dbo.members ON dbo.saving_joint_accounts.members_id = dbo.members.members_id INNER JOIN
                      dbo.sub_accounts ON dbo.saving_accounts.sub_accounts_id = dbo.sub_accounts.sub_accounts_id INNER JOIN
                      dbo.saving_mode_op ON dbo.saving_accounts.saving_accounts_id = dbo.saving_mode_op.saving_accounts_id INNER JOIN
                      dbo.member_address_contact ON dbo.members.members_id = dbo.member_address_contact.members_id INNER JOIN
                      dbo.city ON dbo.member_address_contact.city_id = dbo.city.city_id;