Function Get-AzResourceGraphChange
{
    param(
        [String] $ResourceId,
        [String] $StartDate,
        [String] $EndDate
    )

    begin {
        $apiVersion = "2018-09-01-preview"

        $startDate = (Get-Date ).AddDays(-14).ToString("yyyy-MM-ddT00:00:00.000Z")
        $endDate = (Get-Date ).ToString("yyyy-MM-ddT00:00:00.000Z")
    }
    process {
    $payload = @"
{
    "resourceId": "$($resourceId)",
    "interval": {
        "start": "$($startDate)",
        "end": "$($endDate)"
    },
    "fetchPropertyChanges": true
}
"@

        $objRequest = ((Invoke-AzRestMethod `
            -Path "providers/Microsoft.ResourceGraph/resourceChanges?api-version=$apiVersion" `
            -Method POST `
            -Payload $payload).Content | ConvertFrom-Json).changes

        $arrResults = @()

        $objResource = Get-AzResource -ResourceId $resourceId

        $objResult = New-Object PSObject
        $objResult | Add-Member -MemberType NoteProperty -Name ResourceName -Value $objResource.Name
        $objResult | Add-Member -MemberType NoteProperty -Name ResourceGroupName -Value $objResource.ResourceGroupName
        $objResult | Add-Member -MemberType NoteProperty -Name Location -Value $objResource.Location
        $objResult | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $ResourceId.Split('/')[2]
        $objResult | Add-Member -MemberType NoteProperty -Name ResourceId -Value $ResourceId
        $objResult | Add-Member -MemberType NoteProperty -Name ChangeId -Value $objRequest.changeId
        $objResult | Add-Member -MemberType NoteProperty -Name ChangeType -Value $objRequest.changeType
        $objResult | Add-Member -MemberType NoteProperty -Name beforeSnapshotTimestamp -Value $objRequest.beforeSnapshot.timestamp
        $objResult | Add-Member -MemberType NoteProperty -Name afterSnapshotTimestamp -Value $objRequest.afterSnapshot.timestamp

        $objRequest.propertyChanges | % {
            if(($_.propertyName -cnotmatch "properties.provisioningState") -and ($_.propertyName -cnotmatch "etag"))
            {
                $arrResults += $_
            }
        }

        $objResult | Add-Member -MemberType NoteProperty -Name propertyChanges -Value $arrResults
    }
    end { return $objResult }
}

#Get-AzResourceGraphChange -ResourceId "/subscriptions/3cb73621-3ced-487e-b153-06a31f462ac5/resourcegroups/rg-eus2-poc-psphere-001/providers/Microsoft.Network/privateEndpoints/pec-steu2pshpherepython"

