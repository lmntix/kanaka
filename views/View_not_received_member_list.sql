-- dbo.View_not_received_member_list source

ALTER VIEW dbo.View_not_received_member_list
AS
SELECT     dbo.demand_head.members_id, dbo.demand_head.demand_list_id, dbo.recovery_list.recovery_list_id
FROM         dbo.recovery_list INNER JOIN
                      dbo.recovery_head ON dbo.recovery_list.recovery_list_id = dbo.recovery_head.recovery_list_id RIGHT OUTER JOIN
                      dbo.demand_head ON dbo.recovery_list.demand_list_id = dbo.demand_head.demand_list_id AND 
                      dbo.recovery_head.members_id = dbo.demand_head.members_id;