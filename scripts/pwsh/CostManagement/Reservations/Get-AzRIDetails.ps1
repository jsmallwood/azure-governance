<#

supports "List", "List by Reservation Order", and "List by Reservation Order and Reservation"

https://docs.microsoft.com/en-us/rest/api/consumption/reservations-summaries


#>

Function Get-AzRISummariesAll
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param (
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=0)]
            [Alias("billingAccountName")]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $billingAccountId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1)]
            [Alias("billingProfileName")]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $billingProfileId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=2)]
            [AllowEmptyString()]
            [AllowNull()]
            [ValidateSet("daily", "monthly")]
            [String] $grain = "daily",
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=3)]
            [DateTime] $startDate,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=4)]
            [DateTime] $endDate,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=5)]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $reservationId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=6)]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $reservationOrderId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=9)]
            [switch] $export
    )


    
    DynamicParam {
        if ($export) {
            # Need dynamic parameters for Template, Storage, Project Type
            # Set the dynamic parameters' name
            $paramExportDir = 'ExportDir' 
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 1
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            # Generate and set the ValidateSet
            #$ParameterValidateSet = (Get-PWProjectTemplates).Name 
            #$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
            # Add the ValidateSet to the attributes collection
            #$AttributeCollection.Add($ValidateSetAttribute) 
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($paramExportDir, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($paramExportDir, $RuntimeParameter) 

            # Set the dynamic parameters' name
            $paramExportFileName = 'ExportFileName'
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 2 
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute) 
            # Generate and set the ValidateSet 
            #$ParameterValidateSet = (Get-PWStorageAreaList).Name
            #$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
            # Add the ValidateSet to the attributes collection
            #$AttributeCollection.Add($ValidateSetAttribute)
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($paramExportFileName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($paramExportFileName, $RuntimeParameter)

            # Set the dynamic parameters' name
            $paramExportFormat = 'ExportFormat'
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 3 
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute) 
            # Generate and set the ValidateSet 
            #$ParameterValidateSet = (Get-PWStorageAreaList).Name
            #$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
            # Add the ValidateSet to the attributes collection
            #$AttributeCollection.Add($ValidateSetAttribute)
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($paramExportFormat, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($paramExportFormat, $RuntimeParameter)

            return $RuntimeParameterDictionary
        }
    }


    begin
    {
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

        #region Default Variables
        $apiVersion = "2021-10-01"

        $baseFilter = "`$filter="

        if(!($grain)) { $grain = "daily" }
        #endregion


        #region Create Scope
            #region Scope Billing Account / Profile
            if (-not !($billingProfileId) -and -not !($billingAccountId))
            {
                $scope = New-ScopeBillingProfileId -billingAccountId (Get-AzBillingAccount -ExpandBillingProfile).Name -billingProfileId $billingProfileId
            } elseif (!($billingAccountId) -and -not !($billingProfileId)) {
                $scope = New-ScopeBillingProfileId -billingAccountId (Get-AzBillingAccount -ExpandBillingProfile).Name -billingProfileId $billingProfileId
            } elseif (-not !($billingAccountId) -and !($billingProfileId)) {
                $scope = New-ScopeBillingAccountId -billingAccountId $billingAccountId
            }
            #endregion

            #region Scope Subscription / Resource Group
            if(!($scope)) 
            {
                if (-not !($subscriptionId) -and -not !($resourceGroupName)) {
                    $scope = New-ScopeResourceGroupName -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName
                } elseif (-not !($subscriptionId) -and !($resourceGroupName)) {
                    $scope = New-ScopeSubscriptionId -subscriptionId $subscriptionId
                } elseif (!($subscriptionId) -and -not !($resourceGroupName)) {
                    Write-Error "The SubscriptionId must be specified when using a ResourceGroupName"
                }
            }
            #endregion

            #region Default Scope - Billing Account
            if(!($scope)) { $scope = New-ScopeBillingAccountId -billingAccountId (Get-AzBillingAccount -ExpandBillingProfile).Name }
            #endregion

        #endregion

        #region Create Filter Variable

            #region Create Filter for Start / End Date
            if(($grain -eq 'daily') -or -not !($billingProfileId))
            {
                if (!($startDate) -and !($endDate))
                {
                    $endDate = (Get-Date)
                    $startDate = $endDate.AddDays(-1)
                }

                if($EndDate -and !($StartDate))
                {
                    $StartDate = $EndDate.AddDays(-1)
                }

                if($StartDate -and !($EndDate))
                {
                    $EndDate = $StartDate.AddDays(1)
                }

                [String] $startDate = $startDate.ToString("yyyy-MM-dd")
                [String] $endDate = $endDate.ToString("yyyy-MM-dd")

                $dateFilter = "`$filter=properties/usageDate ge $($startDate) AND properties/usageDate le $($endDate)"
            }
            #endregion

            #region Create Filter for Daily / Monthly Grain
            if($grain -eq 'daily')
            {
                $grainFilter = "grain=daily"
            } 
            else {
                $grainFilter = "grain=monthly"
            }
            #endregion

            #region Create Filter for ReservationId / ReservationOrderId
                if(-not !($reservationOrderId) -or -not !($reservationId))
                {
                    if(-not !($reservationOrderId) -and -not !($reservationId))
                    {
                        $reservationFilter = "reservationId=$($reservationId)&reservationOrderId=$($reservationOrderId)"
                    } 
                    elseif (!($reservationOrderId) -and -not !($reservationId)) 
                    {
                        $reservationFilter = "reservationId=$($reservationId)"
                    }
                    else 
                    {
                        Write-Error "A ReservationId must be included when using a ReservationOrderId"
                    }
                }
            #endregion

            #region Combine Filters
            if(($grain -eq 'daily') -or -not !($billingProfileId))
            {
                if (($grain -eq 'daily') -or !($billingProfileId))
                {
                    $dateGrainfilter = "grain=daily&$dateFilter"
                } 
                else
                {
                    
                }
            }

            if($grain -eq 'monthly')
            {
                $dateGrainFilter = "grain=monthly"
            }

            if(-not !($reservationFilter))
            {
                $filter = "$dateGrainFilter&$reservationFilter"
            } else {
                $filter = $dateGrainFilter
            }
            #endregion

        #endregion

        #region Create Path Variable

            $path = "/$scope/providers/Microsoft.Consumption/reservationSummaries?$filter&api-version=$apiVersion"
            Write-Verbose $path
        #endregion
    }
    process {
        try {
            $result = ((Invoke-AzRestMethod -Path $path -Method GET @boundParameters -ErrorAction $errorAction).Content | ConvertFrom-Json).value
        } Catch { $result = $_}
    }
    end { return $result }

}


$objSummaries = Get-AzRISummariesAll -billingAccountId $settings.BillingAccountId -grain daily -startDate (Get-Date).AddDays(-30) -endDate (Get-Date).AddDays(-1) -Verbose

$objSummaries



$startDate = (Get-Date).AddDays(-7).ToUniversalTime()
$endDate = (Get-Date)

$endDate.ToString('yyyy-MM-dd')

$strStartDate = $startDate.ToString("yyyy-MM-dd")
$strEndDate = $endDate.ToString("yyyy-MM-dd")

$dateFilter = "`$filter=properties/usageDate ge 2021-11-01 AND properties/usageDate le 2021-11-18"

$dateFilter


# Works (date filter)
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationDetails?$dateFilter&api-version=2021-10-01"
$result = ((Invoke-AzRestMethod -Path $path -Method GET -Debug).Content | ConvertFrom-Json).Value
$result

# Works (Reservationid)
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationDetails?$dateFilter&reservationId=0d238a0d-3900-4923-8ce0-1f353de781a3&reservationOrderId=a7b9246a-a16e-4fcf-a341-654e2fcfdb2d&api-version=2021-10-01"
$result = ((Invoke-AzRestMethod -Path $path -Method GET -Debug).Content | ConvertFrom-Json).Value
$result



# Does Not Work (start date / end date)
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationDetails?startDate=2021-11-01&endDate=2021-11-18&api-version=2021-10-01"
$result = ((Invoke-AzRestMethod -Path $path -Method GET -Debug).Content | ConvertFrom-Json).Value
$result

# Does Not Work (no dates or filters)
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationDetails?api-version=2021-10-01"

$result = ((Invoke-AzRestMethod -Path $path -Method GET -Debug).Content | ConvertFrom-Json).Value
$result




$startDate = (Get-Date).AddDays(-7)
$endDate = (Get-Date).AddDays(-1)
[String] $startDate = $startDate.ToString("yyyy-MM-dd")
[String] $endDate = $endDate.ToString("yyyy-MM-dd")

$dateFilter = "`$filter=properties/usageDate ge $startDate AND properties/usageDate le $endDate"
#$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationSummaries?grain=daily&$dateFilter&api-version=2021-10-01"



# ReservationSummariesDailyWithBillingAccountId - WORKS!
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationSummaries?grain=daily&$dateFilter&api-version=2021-10-01"
$path

#ReservationSummariesDailyWithBillingProfileId - DOES NOT WORK! (Investigate Billing Account ID in the format #####:#####)
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/billingProfiles/264686/providers/Microsoft.Consumption/reservationSummaries?grain=daily&startDate=$startDate&endDate=$endDate&api-version=2021-10-01"


# ReservationSummariesMonthlyWithBillingAccountId - DOES NOT WORK! (Wants Usage Dates)
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationSummaries?grain=monthly&api-version=2021-10-01"

# ReservationSummariesMonthlyWithBillingProfileId - DOES NOT WORK (Investigate Billing Account ID in the format #####:#####)
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/billingProfiles/264686/providers/Microsoft.Consumption/reservationSummaries?grain=monthly&api-version=2021-10-01"

# ReservationSummariesMonthlyWithBillingProfileIdReservationId
$path = "/providers/Microsoft.Billing/billingAccounts/76871537/providers/Microsoft.Consumption/reservationSummaries?grain=monthly&reservationId=$reservationId&reservationOrderId=$reservationOrderId&api-version=2021-10-01"

$result = ((Invoke-AzRestMethod -Path $path -Method GET -Debug).Content | ConvertFrom-Json).Value

$result[0]

# Billing Accounts List
$resultAccountList = ((Invoke-AzRestMethod -Path '/providers/Microsoft.Billing/billingAccounts?api-version=2019-10-01-preview' -Method get).Content | ConvertFrom-Json).Value

$resultAccountList

# Billing Accounts List Expanded
$resultAccountListExpand = ((Invoke-AzRestMethod -Path '/providers/Microsoft.Billing/billingAccounts?api-version=2019-10-01-preview&$expand=billingProfiles' -Method get -Debug).Content | ConvertFrom-Json).Value

$resultAccountListExpand
$resultAccountListExpand.Properties.





$resultAccountList = ((Invoke-AzRestMethod -Path '/providers/Microsoft.Billing/billingAccounts?api-version=2019-10-01-preview' -Method get).Content | ConvertFrom-Json).Value

$resultAccountList




$resultProfiles = ((Invoke-AzRestMethod -Path '/providers/Microsoft.Billing/billingAccounts/providers/Microsoft.Billing/billingAccounts/76871537/billingProfiles?api-version=2019-10-01-preview' -Method GET -Debug).Content | ConvertFrom-Json).Value

$resultProfiles


$objAzBillingAccount = Get-AzBillingAccount

$objAzBillingAccountExpanded = Get-AzBillingAccount -ExpandBillingProfile


Get-AzBillingAccount -ExpandBillingProfile

Get-AzBillingProfile `
    -BillingAccountName $objBillingAccount `
    -Name $billingProfileName