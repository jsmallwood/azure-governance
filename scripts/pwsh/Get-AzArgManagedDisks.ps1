Function Get-AzArgManagedDisks
{
    param(
        $Subscriptions,
        $ARGPageSize = 1000
    )

    begin
    {
        $objResult = @()
        if(!($Subscriptions))
        {
            Try {
                $Subscriptions = Get-AzSubscription  -ErrorAction Stop | Where-Object { $_.State -eq "Enabled" } | ForEach-Object { "$($_.Id)" }
            } Catch {
                Write-Host $_
                break
            }
        }

$argQuery = @"
resources
| where ['type'] =~ "Microsoft.Compute/disks"
| where name notcontains "replica"
| where properties.diskState =~ 'Attached'
| extend PerformanceTier = sku.tier
| extend skuName = sku.name
| extend DiskSizeGB = properties.diskSizeGB
| extend DiskThroughput = properties.diskMBpsReadWrite
| extend DiskIOPS = properties.diskIOPSReadWrite
| extend skuSize = properties.tier
| extend CreationOption = properties.creationData.createOption
| extend PurchasePlanName = properties.purchasePlan.name
| extend PurchasePlanPublisher = properties.purchasePlan.publisher
| extend PurchasePlanProduct = properties.purchasePlan.product
| sort by subscriptionId, name
| project Name = name, OSType = properties.storageProfile.osDisk.osType, OSName = properties.extended.instanceView.osName, OSVersion = properties.extended.instanceView.osVersion, Location = location, ResourceGroup = resourceGroup, SubscriptionId = subscriptionId, ManagedBy = managedBy, PerformanceTier, skuName, skuSize, DiskSizeGB, DiskThroughput, DiskIOPS, CreationOption, PurchasePlanName, PurchasePlanProduct, PurchasePlanPublisher, id
"@
    }

    process {
        $resultsSoFar = 0
        do {
            if ($resultsSoFar -eq 0) {
                $result = Search-AzGraph -Query $argQuery -First $ARGPageSize -Subscription $Subscriptions
            }
            else {
                $result = Search-AzGraph -Query $argQuery -First $ARGPageSize -Skip $resultsSoFar -Subscription $Subscriptions
            }
            if ($result -and $result.GetType().Name -eq "PSResourceGraphResponse") {
                $result = $result.Data
            }
            $resultsCount = $result.Count
            $resultsSoFar += $resultsCount
            $objResult += $result

        } while ($resultsCount -eq $ARGPageSize)
    }
    end {
        return $objResult
    }


    }
