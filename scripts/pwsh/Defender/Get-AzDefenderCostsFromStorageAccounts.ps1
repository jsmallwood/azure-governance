Import-Module Az
function GetDataFromAPI{

    param
    (
        [Parameter(Mandatory)]
        [string]$request,

        [Parameter(Mandatory)]
        [Hashtable]$headers
    )

    try {
        Write-Host "Requesting data from API"
        $response = Invoke-WebRequest $request -Headers $headers -TimeoutSec 120
        Write-Host "Request returned status code of: $($response.StatusCode)"
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException]
    {
        $attempts = 0
        while ($response.StatusCode -ne 200 && $attempts -lt 3)
        {
            $response = Invoke-WebRequest $request -Headers $headers -TimeoutSec 120
            $attempts++
            Write-Host "Attempt to get data from API failed with error $($_.Exception.Message). Trying call again"
        }
    }
    return $response
}

$currentTime = Get-Date
Write-Host "Script start time = $($currentTime.DateTime)"

$startDate = (get-date (get-date).addDays(-1) -UFormat "%F")
$endDate = Get-Date -UFormat "%F"
Write-Host "Getting Data from $startDate to $endDate."
$subscriptions = Get-AzSubscription
$storageAccountTotalCostsArray =@()
$top = 3000

foreach ($id in $subscriptions.Id) {
    $filteredList =@()

    Select-AzSubscription -SubscriptionId $id
    $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
        $headers =@{
            Authorization="Bearer $($token.Token)"
        }

        $request = "https://management.azure.com/subscriptions/$($id)/providers/Microsoft.Consumption/usageDetails?`$expand=meterDetails,additionalProperties&`$filter=properties/usageEnd ge '$($startDate)' AND properties/usageEnd le '$($endDate)' &`$top=$($top)&api-version=2019-01-01"

        $response = GetDataFromAPI -request $request -headers $headers
        $convertedListing = $response.Content | ConvertFrom-Json
        $recordsReturned = $convertedListing.value.Count
        $filteredList += $convertedListing.value | where-object {$_.properties.product -eq "Azure Defender for Storage - Standard Transactions"}

        while ($convertedListing.value.Count -eq $top)
        {
            $response = GetDataFromAPI -request $convertedListing.nextLink -headers $headers
            $convertedListing = $response.Content | ConvertFrom-Json
            $recordsReturned = $convertedListing.value.Count + $recordsReturned
            $filteredList = $filteredList + $convertedListing.value | where-object {$_.properties.product -eq "Azure Defender for Storage - Standard Transactions"}
        }

        $cost = 0

        foreach ($entry in $filteredList)
        {
            $cost = [math]::Round($entry.properties.pretaxCost, 2)
            $costObject = New-Object PSObject -property @{cost=$cost; storageAccountName=$entry.properties.instanceName; subscription=$entry.properties.subscriptionName}
            if ($costObject.cost -gt 0)
            {
                $storageAccountTotalCostsArray+=$costObject
            }
         }
         Write-Host "Subscription $($convertedListing.Value[0].properties.subscriptionName) returned $($filteredList.Count) entries with an Azure Defender Cost"
}

    $storageAccountTotalCostsArray| ConvertTo-csv |out-file costs.csv

    $currentTime = Get-Date
    Write-Host "Script end time = $($currentTime.DateTime)"

