CREATE  procedure [dbo].[AddBranch]
(@branch_id as int,
@name as nvarchar(300),
@address as nvarchar(300),
@reg_no as nvarchar(300),
@opening_balance datetime,
@weekly_off tinyint,
@logo as image='',
@note as nvarchar(300),
@version_info as nvarchar(1200),
@gst_in as nvarchar(1200)
 ) 
as insert into branch
(branch_id,[name],address,reg_no,opening_balance,weekly_off,logo,note,version_info,gst_in) values (@branch_id,@name,@address,@reg_no,@opening_balance,@weekly_off,@logo,@note,@version_info,@gst_in)
