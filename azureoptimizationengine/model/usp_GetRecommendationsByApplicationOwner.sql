/****** Object:  StoredProcedure [dbo].[GetRecommendationsByApplicationOwner]    Script Date: 2/7/2023 2:18:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetRecommendationsByApplicationOwner]
    AS BEGIN
        SET NOCOUNT ON;  
        SELECT SubscriptionName, JSON_VALUE(Tags, '$.ApplicationOwner') as ApplicationOwner, Category, Impact, RecommendationDescription, RecommendationAction, InstanceName, ResourceGroup, RecommendationSubTypeId FROM [dbo].[Recommendations] R
        WHERE GeneratedDate > GETDATE()-365 AND NOT EXISTS (
            SELECT * FROM [dbo].[Filters]
            WHERE FilterType IN ('Snooze', 'Dismiss') AND 
                IsEnabled = 1 AND 
                (FilterEndDate IS NULL OR FilterEndDate > GETDATE()) AND 
                    RecommendationSubTypeId = R.RecommendationSubTypeId AND 
                    (InstanceId IS NULL OR R.InstanceId LIKE '%' + InstanceId + '%') AND
                    (InstanceName IS NULL OR R.InstanceName LIKE '%' + InstanceName + '%')
                )  
        ORDER BY SubscriptionName, ApplicationOwner, Category, Impact, RecommendationAction, RecommendationDescription, InstanceName, ResourceGroup
    END
GO

