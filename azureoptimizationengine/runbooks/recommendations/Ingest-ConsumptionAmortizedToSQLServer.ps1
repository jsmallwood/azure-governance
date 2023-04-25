$ErrorActionPreference = "Stop"

$cloudEnvironment = Get-AutomationVariable -Name "AzureOptimization_CloudEnvironment" -ErrorAction SilentlyContinue # AzureCloud|AzureChinaCloud
if ([string]::IsNullOrEmpty($cloudEnvironment))
{
    $cloudEnvironment = "AzureCloud"
}
$authenticationOption = Get-AutomationVariable -Name "AzureOptimization_AuthenticationOption" -ErrorAction SilentlyContinue # RunAsAccount|ManagedIdentity
if ([string]::IsNullOrEmpty($authenticationOption))
{
    $authenticationOption = "ManagedIdentity"
}

$sqlserver = Get-AutomationVariable -Name  "AzureOptimization_SQLServerHostname"
$sqlserverCredential = Get-AutomationPSCredential -Name "AzureOptimization_SQLServerCredential"
$SqlUsername = $sqlserverCredential.UserName
$SqlPass = $sqlserverCredential.GetNetworkCredential().Password
$sqldatabase = Get-AutomationVariable -Name  "AzureOptimization_SQLServerDatabase" -ErrorAction SilentlyContinue
if ([string]::IsNullOrEmpty($sqldatabase))
{
    $sqldatabase = "azureoptimization"
}
$ChunkSize = [int] (Get-AutomationVariable -Name  "AzureOptimization_SQLServerInsertSize" -ErrorAction SilentlyContinue)
if (-not($ChunkSize -gt 0))
{
    $ChunkSize = 900
}
$SqlTimeout = 120

$storageAccountSink = Get-AutomationVariable -Name  "AzureOptimization_StorageSink"
$storageAccountSinkRG = Get-AutomationVariable -Name  "AzureOptimization_StorageSinkRG"
$storageAccountSinkSubscriptionId = Get-AutomationVariable -Name  "AzureOptimization_StorageSinkSubId"
$storageAccountSinkContainer = Get-AutomationVariable -Name  "AzureOptimization_ConsumptionAmortizedContainer" -ErrorAction SilentlyContinue

Write-Output "$($storageAccountSinkContainer)"
if ([string]::IsNullOrEmpty($storageAccountSinkContainer)) {
    $storageAccountSinkContainer = "consumptionamortizedexports"
}
$StorageBlobsPageSize = [int] (Get-AutomationVariable -Name  "AzureOptimization_StorageBlobsPageSize" -ErrorAction SilentlyContinue)
if (-not($StorageBlobsPageSize -gt 0))
{
    $StorageBlobsPageSize = 1000
}

Write-Output "Logging in to Azure with $authenticationOption..."

switch ($authenticationOption) {
    "RunAsAccount" {
        $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
        Connect-AzAccount -ServicePrincipal -EnvironmentName $cloudEnvironment -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
        break
    }
    "ManagedIdentity" {
        Connect-AzAccount -Identity -EnvironmentName $cloudEnvironment
        break
    }
    "User" {
        $cred = Get-AutomationPSCredential –Name $authenticationCredential
        Connect-AzAccount -Credential $cred -EnvironmentName $cloudEnvironment
        break
    }
    Default {
        $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
        Connect-AzAccount -ServicePrincipal -EnvironmentName $cloudEnvironment -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
        break
    }
}

# get reference to storage sink
Write-Output "Getting reference to $storageAccountSink storage account (consumption actual exports sink)"
Select-AzSubscription -SubscriptionId $storageAccountSinkSubscriptionId
$sa = Get-AzStorageAccount -ResourceGroupName $storageAccountSinkRG -Name $storageAccountSink

$allblobs = @()

Write-Output "Getting blobs list..."
$continuationToken = $null
do
{
    $blobs = Get-AzStorageBlob -Container $storageAccountSinkContainer -MaxCount $StorageBlobsPageSize -ContinuationToken $continuationToken -Context $sa.Context | Sort-Object -Property LastModified
    if ($blobs.Count -le 0) { break }
    $allblobs += $blobs
    $continuationToken = $blobs[$blobs.Count -1].ContinuationToken;
}
While ($null -ne $continuationToken)

$SqlServerIngestControlTable = "SqlServerIngestControl"
$consumptionTable = "ConsumptionAmortized"

$tries = 0
$connectionSuccess = $false

do {
    $tries++
    try {
        $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$sqlserver,1433;Database=$sqldatabase;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=$SqlTimeout;")
        $Conn.Open()
        $Cmd=new-object system.Data.SqlClient.SqlCommand
        $Cmd.Connection = $Conn
        $Cmd.CommandTimeout = $SqlTimeout
        $Cmd.CommandText = "SELECT * FROM [dbo].[$SqlServerIngestControlTable] WHERE StorageContainerName = '$storageAccountSinkContainer' and SqlTableName = '$consumptionTable'"

        $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $sqlAdapter.SelectCommand = $Cmd
        $controlRows = New-Object System.Data.DataTable
        $sqlAdapter.Fill($controlRows) | Out-Null
        $connectionSuccess = $true
    }
    catch {
        Write-Output "Failed to contact SQL at try $tries."
        Write-Output $Error[0]
        Start-Sleep -Seconds ($tries * 20)
    }
} while (-not($connectionSuccess) -and $tries -lt 3)

if (-not($connectionSuccess))
{
    throw "Could not establish connection to SQL."
}

if ($controlRows.Count -eq 0)
{
    throw "Could not find a control row for $storageAccountSinkContainer container and $consumptionTable table."
}

$controlRow = $controlRows[0]
$lastProcessedLine = $controlRow.LastProcessedLine
$lastProcessedDateTime = $controlRow.LastProcessedDateTime.ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'fff'Z'")

$Conn.Close()
$Conn.Dispose()

Write-Output "Processing blobs modified after $lastProcessedDateTime (line $lastProcessedLine) and ingesting them into the Consumption SQL table..."

$newProcessedTime = $null

$unprocessedBlobs = @()

foreach ($blob in $allblobs) {
    $blobLastModified = $blob.LastModified.UtcDateTime.ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'fff'Z'")
    if ($lastProcessedDateTime -lt $blobLastModified -or `
        ($lastProcessedDateTime -eq $blobLastModified -and $lastProcessedLine -gt 0)) {
        Write-Output "$($blob.Name) found (modified on $blobLastModified)"
        $unprocessedBlobs += $blob
    }
}

$unprocessedBlobs = $unprocessedBlobs | Sort-Object -Property LastModified

Write-Output "Found $($unprocessedBlobs.Count) new blobs to process..."

foreach ($blob in $unprocessedBlobs) {
    $newProcessedTime = $blob.LastModified.UtcDateTime.ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'fff'Z'")
    Write-Output "About to process $($blob.Name)..."
    Get-AzStorageBlobContent -CloudBlob $blob.ICloudBlob -Context $sa.Context -Force
    $objCsv = Import-Csv -Path $blob.Name
    Write-Output "Blob contains $($objCsv.Count) results..."

    $linesProcessed = 0
    for ($i = 0; $i -lt $objCsv.Count; $i++)
    {
        Write-Output "Processing row $($i) of Blob $($Blob.Name)..."
        $currentObjectLines = $i+1
        if ($lastProcessedLine -lt $linesProcessed)
        {
        if(!($objCsv[$i].AccountName)) { $AccountName = $Null} Else { $AccountName = $objCsv[$i].AccountName }
        if(!($objCsv[$i].AccountOwnerId)) { $AccountOwnerId = $Null} Else { $AccountOwnerId = $objCsv[$i].AccountOwnerId }
        if(!($objCsv[$i].AdditionalInfo)) { $AdditionalInfo = ("{ }") } Else { $AdditionalInfo = $objCsv[$i].AdditionalInfo }
        if(!($objCsv[$i].BenefitId)) { $BenefitId = $Null} Else { $BenefitId = $objCsv[$i].BenefitId }
        if(!($objCsv[$i].BenefitName)) { $BenefitName = $Null } Else { $BenefitName = $objCsv[$i].BenefitName }
        if(!($objCsv[$i].BillingAccountId)) { $BillingAccountId = $Null } Else { $BillingAccountId = $objCsv[$i].BillingAccountId }
        if(!($objCsv[$i].BillingAccountName)) { $BillingAccountName = $Null } Else { $BillingAccountName = $objCsv[$i].BillingAccountName }
        if(!($objCsv[$i].BillingPeriodEndDate)) { $BillingPeriodEndDate = $null } Else { $BillingPeriodEndDate = $objCsv[$i].BillingPeriodEndDate }
        if(!($objCsv[$i].BillingPeriodStartDate)) { $BillingPeriodStartDate = $null } Else { $BillingPeriodStartDate = $objCsv[$i].BillingPeriodStartDate }
        if(!($objCsv[$i].BillingProfileId)) { $BillingProfileId = $Null } Else { $BillingProfileId = $objCsv[$i].BillingProfileId }
        if(!($objCsv[$i].BillingProfileName)) { $BillingProfileName = $Null } Else { $BillingProfileName = $objCsv[$i].BillingProfileName }
        if(!($objCsv[$i].ChargeType)) { $ChargeType = $Null } Else { $ChargeType = $objCsv[$i].ChargeType }
        if(!($objCsv[$i].ConsumedService)) { $ConsumedService = $Null } Else { $ConsumedService = $objCsv[$i].ConsumedService }
        if(!($objCsv[$i].CostAllocationRuleName)) { $CostAllocationRuleName = $Null } Else { $CostAllocationRuleName = $objCsv[$i].CostAllocationRuleName }
        if(!($objCsv[$i].Cost)) { $Cost = 0 } Else { $Cost = $objCsv[$i].Cost }
        if(!($objCsv[$i].CostInBillingCurrency)) { $Cost = 0 } Else { $Cost = $objCsv[$i].CostInBillingCurrency }
        if(!($objCsv[$i].BillingCurrencyCode)) { $Currency = $Null } Else { $Currency = $objCsv[$i].BillingCurrencyCode }
        if(!($objCsv[$i].BillingCurrency)) { $Currency = $Null } Else { $Currency = $objCsv[$i].BillingCurrency }
        if(!($objCsv[$i].Date)) { $Date = $null } Else { $Date = $objCsv[$i].Date }
        if(!($objCsv[$i].EffectivePrice)) { $EffectivePrice = 0 } Else { $EffectivePrice = $objCsv[$i].EffectivePrice }
        if(!($objCsv[$i].Frequency)) { $Frequency = $Null } Else { $Frequency = $objCsv[$i].Frequency }
        if(!($objCsv[$i].InvoiceId)) { $InvoiceId = $Null } Else { $InvoiceId = $objCsv[$i].InvoiceId }
        if(!($objCsv[$i].InvoiceSection)) { $InvoiceSection = $Null } Else { $InvoiceSection = $objCsv[$i].InvoiceSection }
        if(!($objCsv[$i].InvoiceSectionId)) { $InvoiceSectionId = $Null } Else { $InvoiceSectionId = $objCsv[$i].InvoiceSectionId }
        if(!($objCsv[$i].InvoiceSectionName)) { $InvoiceSectionName = $Null } Else { $InvoiceSectionName = $objCsv[$i].InvoiceSectionName }
        if(!($objCsv[$i].IsAzureCreditEligible)) { $IsAzureCreditEligible = $Null } Else { $IsAzureCreditEligible = $objCsv[$i].IsAzureCreditEligible }
        if(!($objCsv[$i].Location)) { $Location = $Null } Else { $Location = $objCsv[$i].Location }
        if(!($objCsv[$i].MeterCategory)) { $MeterCategory = $Null } Else { $MeterCategory = $objCsv[$i].MeterCategory }
        if(!($objCsv[$i].MeterId)) { $MeterId = $Null } Else { $MeterId = $objCsv[$i].MeterId }
        if(!($objCsv[$i].MeterName)) { $MeterName = $Null } Else { $MeterName = $objCsv[$i].MeterName }
        if(!($objCsv[$i].MeterRegion)) { $MeterRegion = $Null } Else { $MeterRegion = $objCsv[$i].MeterRegion }
        if(!($objCsv[$i].MeterSubCategory)) { $MeterSubCategory = $Null } Else { $MeterSubCategory = $objCsv[$i].MeterSubCategory }
        if(!($objCsv[$i].PayGPrice)) { $PayGPrice = 0 } Else { $PayGPrice = $objCsv[$i].PayGPrice }
        if(!($objCsv[$i].PricingModel)) { $PricingModel = 0 } Else { $PricingModel = $objCsv[$i].PricingModel }
        if(!($objCsv[$i].Product)) { $Product = $Null } Else { $Product = $objCsv[$i].Product }
        if(!($objCsv[$i].ProductId)) { $ProductId = $Null } Else { $ProductId = $objCsv[$i].ProductId }
        if(!($objCsv[$i].ProductOrderId)) { $ProductOrderId = $Null } Else { $ProductOrderId = $objCsv[$i].ProductOrderId }
        if(!($objCsv[$i].ProductOrderName)) { $ProductOrderName = $Null } Else { $ProductOrderName = $objCsv[$i].ProductOrderName }
        if(!($objCsv[$i].Provider)) { $Provider = $Null } Else { $Provider = $objCsv[$i].Provider }
        if(!($objCsv[$i].PublisherId)) { $PublisherId = $Null } Else { $PublisherId = $objCsv[$i].PublisherId }
        if(!($objCsv[$i].PublisherName)) { $PublisherName = $Null } Else { $PublisherName = $objCsv[$i].PublisherName }
        if(!($objCsv[$i].PublisherType)) { $PublisherType = $Null } Else { $PublisherType = $objCsv[$i].PublisherType }
        if(!($objCsv[$i].Quantity)) { $Quantity = 0 } Else { $Quantity = $objCsv[$i].Quantity }
        if(!($objCsv[$i].ReservationId)) { $ReservationId = $Null } Else { $ReservationId = $objCsv[$i].ReservationId }
        if(!($objCsv[$i].ReservationName)) { $ReservationName = $Null } Else { $ReservationName = $objCsv[$i].ReservationName }
        if(!($objCsv[$i].ResourceGroup)) { $ResourceGroup = $Null } Else { $ResourceGroup = $objCsv[$i].ResourceGroup }
        if(-not !($objCsv[$i].InstanceName)) { $ResourceId = $objCsv[$i].InstanceName; $ResourceName = $objCsv[$i].InstanceName.Split('/')[($objCsv[$i].InstanceName.Split('/').Count-1)] }
        if(!$ResourceId) { if(!($objCsv[$i].ResourceId)) { $ResourceId = $Null } else {$ResourceId = $objCsv[$i].ResourceId } }
        if(!($objCsv[$i].ResourceLocation)) { $ResourceLocation = $Null } Else { $ResourceLocation = $objCsv[$i].ResourceLocation }
        If(!$Location) { if(!($objCsv[$i].ResourceLocationNormalized)) { $Location = $Null } else {$Location = $objCsv[$i].ResourceLocationNormalized } }
        if(!$ResourceName) { if(!($objCsv[$i].ResourceName)) { $ResourceName = $Null } else {$ResourceName = $objCsv[$i].ResourceName } }
        if(!($objCsv[$i].RoundingAdjustment)) { $RoundingAdjustment = 0 } Else { $RoundingAdjustment = $objCsv[$i].RoundingAdjustment }
        if(!($objCsv[$i].ServiceFamily)) { $ServiceFamily = $Null } Else { $ServiceFamily = $objCsv[$i].ServiceFamily }
        if(!($objCsv[$i].ServiceInfo1)) { $ServiceInfo1 = $Null } Else { $ServiceInfo1 = $objCsv[$i].ServiceInfo1 }
        if(!($objCsv[$i].ServiceInfo2)) { $ServiceInfo2 = $Null } Else { $ServiceInfo2 = $objCsv[$i].ServiceInfo2 }
        if(!($objCsv[$i].ServicePeriodEndDate)) { $ServicePeriodEndDate = $null } Else { $ServicePeriodEndDate = $objCsv[$i].ServicePeriodEndDate }
        if(!($objCsv[$i].ServicePeriodStartDate)) { $ServicePeriodStartDate = $null } Else { $ServicePeriodStartDate = $objCsv[$i].ServicePeriodStartDate }
        if(!($objCsv[$i].SubscriptionGuid)) { $SubscriptionId = $Null } Else { $SubscriptionId = $objCsv[$i].SubscriptionGuid }
        if(!($objCsv[$i].SubscriptionName)) { $SubscriptionName = $Null } Else { $SubscriptionName = $objCsv[$i].SubscriptionName }
        if(!($objCsv[$i].Tags)) { $Tags = "{ }" } Else { $Tags = $objCsv[$i].Tags | ConvertTo-Json }
        if(!($objCsv[$i].Term)) { $Term = $Null } Else { $Term = $objCsv[$i].Term }
        if(!($objCsv[$i].UnitOfMeasure)) { $UnitOfMeasure = $Null } Else { $UnitOfMeasure = $objCsv[$i].UnitOfMeasure }
        if(!($objCsv[$i].UnitPrice)) { $UnitPrice = 0 } Else { $UnitPrice = $objCsv[$i].UnitPrice }

        $values = "'$($AccountName)', '$($AccountOwnerId)', '$($AdditionalInfo)', '$($BenefitId)', '$($BenefitName)', '$($BillingAccountId)', '$($BillingAccountName)', '$($BillingPeriodStartDate)',
        '$($BillingPeriodEndDate)', '$($BillingProfileId)', '$($BillingProfileName)', '$($ChargeType)',	'$($ConsumedService)', '$($CostAllocationRuleName)', '$($Cost)', '$($Currency)',
        '$($Date)', '$($EffectivePrice)', '$($Frequency)', '$($InvoiceId)', '$($InvoiceSection)', '$($InvoiceSectionId)', '$($InvoiceSectionName)', '$($IsAzureCreditEligible)', '$($Location)', '$($MeterCategory)',
        '$($MeterId)', '$($MeterName)', '$($MeterRegion)', '$($MeterSubCategory)', '$($PayGPrice)', '$($PreviousInvoiceId)', '$($PricingModel)', '$($Product)', '$($ProductId)', '$($ProductOrderId)',
        '$($ProductOrderName)', '$($Provider)', '$($PublisherId)', '$($PublisherName)', '$($PublisherType)', '$($Quantity)', '$($ReservationId)', '$($ReservationName)', '$($ResourceGroup)',
        '$($ResourceId)', '$($ResourceLocation)', '$($ResourceName)', '$($RoundingAdjustment)', '$($ServiceFamily)', '$($ServiceInfo1)', '$($ServiceInfo2)', '$($ServicePeriodEndDate)',
        '$($ServicePeriodStartDate)', '$($SubscriptionId)', '$($SubscriptionName)', '$($Tags)', '$($Term)', '$($UnitOfMeasure)', '$($UnitPrice)'"

        #$sqlStatement += "VALUES($($values))"

        $sqlStatement = "EXEC dbo.usp_InsertConsumptionAmortized $($values);"

        Write-Output "Inserting row $($i) of Blob $($Blob.Name) into Consumption Amortized Table..."
                    $Conn2 = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$sqlserver,1433;Database=$sqldatabase;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=$SqlTimeout;")
                $Conn2.Open()

                $Cmd=new-object system.Data.SqlClient.SqlCommand
                $Cmd.Connection = $Conn2
                $Cmd.CommandText = $sqlStatement
                $Cmd.CommandTimeout=30
                try
                {
                    $Cmd.ExecuteReader()
                }
                catch
                {
                    Write-Output "Failed statement: $sqlStatement"
                    throw
                }

                $Conn2.Close()

                $linesProcessed += $currentObjectLines
                Write-Output "Processed $linesProcessed lines..."
                if ($i -eq ($objCsv.Count - 1)) {
                    $lastProcessedLine = -1
                }
                else {
                    $lastProcessedLine = $linesProcessed - 1
                }

                $updatedLastProcessedLine = $lastProcessedLine
                $updatedLastProcessedDateTime = $lastProcessedDateTime
                if ($i -eq ($objCsv.Count - 1)) {
                    $updatedLastProcessedDateTime = $newProcessedTime
                }
                $lastProcessedDateTime = $updatedLastProcessedDateTime
                Write-Output "Updating last processed time / line to $($updatedLastProcessedDateTime) / $updatedLastProcessedLine"
                $sqlStatement = "UPDATE [$SqlServerIngestControlTable] SET LastProcessedLine = $updatedLastProcessedLine, LastProcessedDateTime = '$updatedLastProcessedDateTime' WHERE StorageContainerName = '$storageAccountSinkContainer'"
                $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$sqlserver,1433;Database=$sqldatabase;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=$SqlTimeout;")
                $Conn.Open()
                $Cmd=new-object system.Data.SqlClient.SqlCommand
                $Cmd.Connection = $Conn
                $Cmd.CommandText = $sqlStatement
                $Cmd.CommandTimeout=$SqlTimeout
                $Cmd.ExecuteReader()
                $Conn.Close()

            }
        else
        {
                $linesProcessed += $currentObjectLines
        }
    }
    Remove-Item -Path $blob.Name -Force
}

Write-Output "DONE"
