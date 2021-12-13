$StartDate = (Get-Date).AddDays(-1)
$EndDate = (Get-Date)

$params = @{
    StartDate = $StartDate
    EndDate = $EndDate
}

$params = $params + @{ Top = 10 }

Get-AzConsumptionUsageDetail @Params -IncludeMeterDetails