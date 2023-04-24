$BillingScope = ""
$SQLServer = ""
$Database = ""
$MetricType = "actualcost" 
$LookBackInDays = 60

Function Get-AzAuthToken
{
    [CmdletBinding(
        ConfirmImpact="Low",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
        [String] $SubscriptionId
    )

    Begin {
            #region Error Action Preference
            $errorAction = $PSBoundParameters["ErrorAction"]
            if(-not $errorAction) { $errorAction = $ErrorActionPreference }
        #endregion

        #region Bound Parameters
            $boundParameters = @{
                Verbose = $PSBoundParameters.ContainsKey("Verbose");
                #Confirm = $PSBoundParameters.ContainsKey("Confirm");
                Debug = $PSBoundParameters.ContainsKey("Debug");
            }
        #endregion

        if($SubscriptionId) { Select-AzSubscription -Subscription $SubscriptionId @boundParameters -ErrorAction $errorAction}
    }

    Process {
        $context = Get-AzContext @boundParameters -ErrorAction $errorAction
        $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
        $azureRmProfileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
        $token = $azureRmProfileClient.AcquireAccessToken($context.Subscription.TenantId).AccessToken;
    }

    End {
        Return $token
    }
}

Function Get-AzUsageDetails
{
    [CmdletBinding(
        ConfirmImpact="Low",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
        [String] $BillingScope,
        [String] $StartDate,
        [String] $EndDate,
        [String] $MetricType
    )

    Begin {
            #region Error Action Preference
            $errorAction = $PSBoundParameters["ErrorAction"]
            if(-not $errorAction) { $errorAction = $ErrorActionPreference }
        #endregion

        #region Bound Parameters
            $boundParameters = @{
                Verbose = $PSBoundParameters.ContainsKey("Verbose");
                #Confirm = $PSBoundParameters.ContainsKey("Confirm");
                Debug = $PSBoundParameters.ContainsKey("Debug");
            }
        #endregion


            $apiVersion = "2023-03-01"
        $objResults = [System.Collections.ArrayList]::New()

            $Headers = @{
            'Content-Type' = 'Application/Json'
            'Authorization' = 'Bearer ' + (Get-AzAuthToken)
        }
            if(!$MetricType) { $MetricType = 'actualcost' }

        if((-not !($StartDate)) -and (-not !($EndDate)))
        {
            $Uri = "https://management.azure.com/$($BillingScope)/providers/Microsoft.Consumption/usageDetails?`$expand=properties/meterDetails,properties/additionalInfo`$filter=properties/usageStart ge '$($StartDate)' and properties/usageEnd le '$($EndDate)'`$metric=$($MetricType)&api-version=$($apiVersion)"
            
        } 
        else {
            $uri = "https://management.azure.com/$($BillingScope)/providers/Microsoft.Consumption/usageDetails?`$expand=properties/meterDetails,properties/additionalInfo`$metric=$($MetricType)&api-version=$($apiVersion)"
        }

    }

    Process {



        try {
            $Request = (Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -ErrorAction $errorAction)
            

            for($i=0; $i -lt $request.value.Count; $i++)
            {
                $item = $request.value[$i].properties
                $obj = [PSCustomObject] @{} 

                $props = ($item | Get-Member -MemberType NoteProperty | Select-Object -Property Name).Name

                for($p=0; $p -lt $props.Count; $p++)
                {
                    $prop = $props[$p].Substring(0,1).ToUpper()+$props[$p].Substring(1)

                    $obj | Add-Member -MemberType NoteProperty -Name $prop -Value $item."$($props[$p])"
                    Remove-Variable -Name prop
                }

                $obj | Add-Member -MemberType NoteProperty -Name Tags -Value $request.value[$i].tags

                $objResults += $obj

                Remove-Variable -Name obj
                Remove-Variable -Name item
                Remove-Variable -Name props
            } 
         
        } 
        catch {
            Write-Error $_
        }

        if($request.nextLink)
        {
            Do{
                try {
                    $Request = (Invoke-RestMethod -Method Get -Uri $Request.nextLink -Headers $Headers -ErrorAction $errorAction)
                    $Uri = $Request.nextLink

                    for($i=0; $i -lt $request.value.Count; $i++)
                    {
                        $item = $request.value[$i].properties
                        $obj = [PSCustomObject] @{} 

                        $props = ($item | Get-Member -MemberType NoteProperty | Select-Object -Property Name).Name

                        for($p=0; $p -lt $props.Count; $p++)
                        {
                            $prop = $props[$p].Substring(0,1).ToUpper()+$props[$p].Substring(1)

                            $obj | Add-Member -MemberType NoteProperty -Name $prop -Value $item."$($props[$p])"
                            Remove-Variable -Name prop
                        }
                        $objResults += $obj

                        Remove-Variable -Name obj
                        Remove-Variable -Name item
                        Remove-Variable -Name props
                    }

                } catch {
                    Write-Error $_
                }

            } Until (!($request.nextLink))
        }
    }

    End {
        Return $objResults
    }
}

Function Insert-AzUsageIntoSQL
{
    param(
        [String] $SQLServer,
        [String] $Database,
        [Object] $Object
    )


    begin{ 
        Try {
        $azureToken = Get-AzAccessToken -ResourceUrl https://database.windows.net
        $sql = Connect-DbaInstance -SqlInstance $SQLServer -Database $Database -AccessToken $azureToken -ErrorAction Stop
        } Catch {
            Return $_
    
        }
    }



    process {
    
        if(!($Object.AccountName)) { $AccountName = $Null} Else { $AccountName = $Object.AccountName }
        if(!($Object.AccountOwnerId)) { $AccountOwnerId = $Null} Else { $AccountOwnerId = $Object.AccountOwnerId }
        if(!($Object.AdditionalInfo)) { $AdditionalInfo = ("{ }") } Else { $AdditionalInfo = $Object.AdditionalInfo }
        if(!($Object.BenefitId)) { $BenefitId = $Null} Else { $BenefitId = $Object.BenefitId }
        if(!($Object.BenefitName)) { $BenefitName = $Null } Else { $BenefitName = $Object.BenefitName }
        if(!($Object.BillingAccountId)) { $BillingAccountId = $Null } Else { $BillingAccountId = $Object.BillingAccountId }
        if(!($Object.BillingAccountName)) { $BillingAccountName = $Null } Else { $BillingAccountName = $Object.BillingAccountName }

        if(!($Object.BillingPeriodEndDate)) { $BillingPeriodEndDate = $null } Else { $BillingPeriodEndDate = $Object.BillingPeriodEndDate }
        if(!($Object.BillingPeriodStartDate)) { $BillingPeriodStartDate = $null } Else { $BillingPeriodStartDate = $Object.BillingPeriodStartDate }

        if(!($Object.BillingProfileId)) { $BillingProfileId = $Null } Else { $BillingProfileId = $Object.BillingProfileId }
        if(!($Object.BillingProfileName)) { $BillingProfileName = $Null } Else { $BillingProfileName = $Object.BillingProfileName }
        if(!($Object.ChargeType)) { $ChargeType = $Null } Else { $ChargeType = $Object.ChargeType }
        if(!($Object.ConsumedService)) { $ConsumedService = $Null } Else { $ConsumedService = $Object.ConsumedService }
        if(!($Object.CostAllocationRuleName)) { $CostAllocationRuleName = $Null } Else { $CostAllocationRuleName = $Object.CostAllocationRuleName }
        if(!($Object.Cost)) { $Cost = 0 } Else { $Cost = $Object.Cost }
        if(!($Object.CostInBillingCurrency)) { $Cost = 0 } Else { $Cost = $Object.CostInBillingCurrency }
        if(!($Object.BillingCurrencyCode)) { $Currency = $Null } Else { $Currency = $Object.BillingCurrencyCode }
        if(!($Object.BillingCurrency)) { $Currency = $Null } Else { $Currency = $Object.BillingCurrency }

        if(!($Object.Date)) { $Date = $null } Else { $Date = $Object.Date }

        if(!($Object.EffectivePrice)) { $EffectivePrice = 0 } Else { $EffectivePrice = $Object.EffectivePrice }
        if(!($Object.Frequency)) { $Frequency = $Null } Else { $Frequency = $Object.Frequency }
        if(!($Object.InvoiceId)) { $InvoiceId = $Null } Else { $InvoiceId = $Object.InvoiceId }
        if(!($Object.InvoiceSection)) { $InvoiceSection = $Null } Else { $InvoiceSection = $Object.InvoiceSection }
        if(!($Object.InvoiceSectionId)) { $InvoiceSectionId = $Null } Else { $InvoiceSectionId = $Object.InvoiceSectionId }
        if(!($Object.InvoiceSectionName)) { $InvoiceSectionName = $Null } Else { $InvoiceSectionName = $Object.InvoiceSectionName }
        if(!($Object.IsAzureCreditEligible)) { $IsAzureCreditEligible = $Null } Else { $IsAzureCreditEligible = $Object.IsAzureCreditEligible }
        if(!($Object.Location)) { $Location = $Null } Else { $Location = $Object.Location }
        if(!($Object.MeterCategory)) { $MeterCategory = $Null } Else { $MeterCategory = $Object.MeterCategory }
        if(!($Object.MeterId)) { $MeterId = $Null } Else { $MeterId = $Object.MeterId }
        if(!($Object.MeterName)) { $MeterName = $Null } Else { $MeterName = $Object.MeterName }
        if(!($Object.MeterRegion)) { $MeterRegion = $Null } Else { $MeterRegion = $Object.MeterRegion }
        if(!($Object.MeterSubCategory)) { $MeterSubCategory = $Null } Else { $MeterSubCategory = $Object.MeterSubCategory }
        if(!($Object.PayGPrice)) { $PayGPrice = 0 } Else { $PayGPrice = $Object.PayGPrice }
        if(!($Object.PricingModel)) { $PricingModel = 0 } Else { $PricingModel = $Object.PricingModel }
        if(!($Object.Product)) { $Product = $Null } Else { $Product = $Object.Product }
        if(!($Object.ProductId)) { $ProductId = $Null } Else { $ProductId = $Object.ProductId }
        if(!($Object.ProductOrderId)) { $ProductOrderId = $Null } Else { $ProductOrderId = $Object.ProductOrderId }
        if(!($Object.ProductOrderName)) { $ProductOrderName = $Null } Else { $ProductOrderName = $Object.ProductOrderName }
        if(!($Object.Provider)) { $Provider = $Null } Else { $Provider = $Object.Provider }
        if(!($Object.PublisherId)) { $PublisherId = $Null } Else { $PublisherId = $Object.PublisherId }
        if(!($Object.PublisherName)) { $PublisherName = $Null } Else { $PublisherName = $Object.PublisherName }
        if(!($Object.PublisherType)) { $PublisherType = $Null } Else { $PublisherType = $Object.PublisherType }
        if(!($Object.Quantity)) { $Quantity = 0 } Else { $Quantity = $Object.Quantity }
        if(!($Object.ReservationId)) { $ReservationId = $Null } Else { $ReservationId = $Object.ReservationId }
        if(!($Object.ReservationName)) { $ReservationName = $Null } Else { $ReservationName = $Object.ReservationName }
        if(!($Object.ResourceGroup)) { $ResourceGroup = $Null } Else { $ResourceGroup = $Object.ResourceGroup }

        if(-not !($Object.InstanceName)) { $ResourceId = $Object.InstanceName; $ResourceName = $Object.InstanceName.Split('/')[($Object.InstanceName.Split('/').Count-1)] } 

        if(!$ResourceId) { if(!($Object.ResourceId)) { $ResourceId = $Null } else {$ResourceId = $Object.ResourceId } }

        if(!($Object.ResourceLocation)) { $ResourceLocation = $Null } Else { $ResourceLocation = $Object.ResourceLocation }
        If(!$Location) { if(!($Object.ResourceLocationNormalized)) { $Location = $Null } else {$Location = $Object.ResourceLocationNormalized } }

        if(!$ResourceName) { if(!($Object.ResourceName)) { $ResourceName = $Null } else {$ResourceName = $Object.ResourceName } }
        if(!($Object.RoundingAdjustment)) { $RoundingAdjustment = 0 } Else { $RoundingAdjustment = $Object.RoundingAdjustment }
        if(!($Object.ServiceFamily)) { $ServiceFamily = $Null } Else { $ServiceFamily = $Object.ServiceFamily }
        if(!($Object.ServiceInfo1)) { $ServiceInfo1 = $Null } Else { $ServiceInfo1 = $Object.ServiceInfo1 }
        if(!($Object.ServiceInfo2)) { $ServiceInfo2 = $Null } Else { $ServiceInfo2 = $Object.ServiceInfo2 }
        if(!($Object.ServicePeriodEndDate)) { $ServicePeriodEndDate = $null } Else { $ServicePeriodEndDate = $Object.ServicePeriodEndDate }
        if(!($Object.ServicePeriodStartDate)) { $ServicePeriodStartDate = $null } Else { $ServicePeriodStartDate = $Object.ServicePeriodStartDate }
        if(!($Object.SubscriptionGuid)) { $SubscriptionId = $Null } Else { $SubscriptionId = $Object.SubscriptionGuid }
        if(!($Object.SubscriptionName)) { $SubscriptionName = $Null } Else { $SubscriptionName = $Object.SubscriptionName }
        if(!($Object.Tags)) { $Tags = "{ }" } Else { $Tags = $Object.Tags | ConvertTo-Json }
        if(!($Object.Term)) { $Term = $Null } Else { $Term = $Object.Term }
        if(!($Object.UnitOfMeasure)) { $UnitOfMeasure = $Null } Else { $UnitOfMeasure = $Object.UnitOfMeasure }
        if(!($Object.UnitPrice)) { $UnitPrice = 0 } Else { $UnitPrice = $Object.UnitPrice }
    


        $values = "'$($AccountName)', '$($AccountOwnerId)', '$($AdditionalInfo)', '$($BenefitId)', '$($BenefitName)', '$($BillingAccountId)', '$($BillingAccountName)', '$($BillingPeriodStartDate)', 
    '$($BillingPeriodEndDate)', '$($BillingProfileId)', '$($BillingProfileName)', '$($ChargeType)',	'$($ConsumedService)', '$($CostAllocationRuleName)', '$($Cost)', '$($Currency)', 
    '$($Date)', '$($EffectivePrice)', '$($Frequency)', '$($InvoiceId)', '$($InvoiceSection)', '$($InvoiceSectionId)', '$($InvoiceSectionName)', '$($IsAzureCreditEligible)', '$($Location)', '$($MeterCategory)', 
    '$($MeterId)', '$($MeterName)', '$($MeterRegion)', '$($MeterSubCategory)', '$($PayGPrice)', '$($PreviousInvoiceId)', '$($PricingModel)', '$($Product)', '$($ProductId)', '$($ProductOrderId)', 
    '$($ProductOrderName)', '$($Provider)', '$($PublisherId)', '$($PublisherName)', '$($PublisherType)', '$($Quantity)', '$($ReservationId)', '$($ReservationName)', '$($ResourceGroup)', 
    '$($ResourceId)', '$($ResourceLocation)', '$($ResourceName)', '$($RoundingAdjustment)', '$($ServiceFamily)', '$($ServiceInfo1)', '$($ServiceInfo2)', '$($ServicePeriodEndDate)', 
    '$($ServicePeriodStartDate)', '$($SubscriptionId)', '$($SubscriptionName)', '$($Tags)', '$($Term)', '$($UnitOfMeasure)', '$($UnitPrice)'"

        Try {
            $sql | Invoke-DbaQuery -Database $Database -Query "EXEC dbo.usp_InsertUsageDetails $($values);" -Verbose -ErrorAction Stop
        } Catch { Write-Error $_ }

    }

    end { 
        
    }

}

for($i=1; $i -lt $LookBackInDays; $i++)
{
    [String] $StartDate = ((Get-Date).AddDays(-$i)).ToString("yyyy-MM-dd")
    [String] $EndDate = $StartDate

    $result = Get-AzUsageDetails -BillingScope $BillingScope -StartDate $StartDate -EndDate $EndDate 
    
    $result | % {
        Insert-AzUsageIntoSQL -SQLServer $SQLServer -Database $Database -Object $_
    }
}
