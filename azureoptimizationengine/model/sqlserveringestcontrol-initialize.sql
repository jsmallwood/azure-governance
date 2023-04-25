IF NOT EXISTS (SELECT * FROM [dbo].[SqlServerIngestControl] WHERE StorageContainerName = 'recommendationsexports')
BEGIN
    INSERT INTO [dbo].[SqlServerIngestControl] 
    VALUES 
        ('recommendationsexports', '1901-01-01T00:00:00Z', -1, 'Recommendations')
END

IF NOT EXISTS (SELECT * FROM [dbo].[SqlServerIngestControl] WHERE StorageContainerName = 'consumptionactualexports')
BEGIN
    INSERT INTO [dbo].[SqlServerIngestControl] 
    VALUES 
        ('consumptionactualexports', '1901-01-01T00:00:00Z', -1, 'ConsumptionActual')
END

IF NOT EXISTS (SELECT * FROM [dbo].[SqlServerIngestControl] WHERE StorageContainerName = 'consumptionamortizedexports')
BEGIN
    INSERT INTO [dbo].[SqlServerIngestControl] 
    VALUES 
        ('consumptionamortizedexports', '1901-01-01T00:00:00Z', -1, 'ConsumptionAmortized')
END
