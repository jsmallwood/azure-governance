/****** Object:  StoredProcedure [dbo].[GetRecommendations]    Script Date: 2/7/2023 2:18:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetRecommendations]   
    AS BEGIN
        SET NOCOUNT ON;  
        SELECT * FROM [dbo].[Recommendations] R
        WHERE GeneratedDate > GETDATE()-365 AND NOT EXISTS (
            SELECT * FROM [dbo].[Filters]
            WHERE FilterType IN ('Snooze', 'Dismiss') AND 
                  IsEnabled = 1 AND 
                  R.GeneratedDate > FilterStartDate AND
                  (FilterEndDate IS NULL OR FilterEndDate > GETDATE()) AND 
                  RecommendationSubTypeId = R.RecommendationSubTypeId AND 
                  (InstanceId IS NULL OR R.InstanceId LIKE '%' + InstanceId + '%')
        )  
    END

GO

