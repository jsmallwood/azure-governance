/****** Object:  StoredProcedure [dbo].[GetCostRecommendations]    Script Date: 2/7/2023 2:19:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetCostRecommendations]
    AS BEGIN
        SET NOCOUNT ON;  
        SELECT * FROM [dbo].[Recommendations] R
        WHERE Category = 'Cost' AND GeneratedDate > GETDATE()-365 AND NOT EXISTS (
            SELECT * FROM [dbo].[Filters]
            WHERE FilterType IN ('Snooze', 'Dismiss') AND 
                  IsEnabled = 1 AND 
                  (FilterEndDate IS NULL OR FilterEndDate > GETDATE()) AND 
                  RecommendationSubTypeId = R.RecommendationSubTypeId AND 
                  (InstanceId IS NULL OR R.InstanceId LIKE '%' + InstanceId + '%') AND
                  (InstanceName IS NULL OR R.InstanceName LIKE '%' + InstanceName + '%')
        )  
    END
GO

