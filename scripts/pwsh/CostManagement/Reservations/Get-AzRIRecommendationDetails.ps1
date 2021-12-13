<#

https://docs.microsoft.com/en-us/rest/api/consumption/reservation-recommendation-details/get

#>


Function Get-AzRIRecommendationDetails
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
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
            [String] $subscriptionId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=3)]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $resourceGroupName,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=4)]
            [ValidateNotNullOrEmpty()]
            [String] $product,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=5)]
            [AllowNull()]
            [String] $region = 'eastus2',
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=6)]
            [ValidateSet("P1Y","P3Y","P5Y")]
            [AllowNull()]
            [String] $term = "P1Y",
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=7)]
            [ValidateSet("Last7Days","Last30Days","Last60Days")]
            [AllowNull()]
            [string] $lookBackPeriod = "Last7Days"
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

        #region Import Helper Functions
        try {
            Get-ChildItem -LiteralPath "$env:PSAzureScriptPath\.helpers" @boundParameters -ErrorAction $errorAction | % { . $_.FullName }
        } catch {
            Write-Error "Failed to location helper functions. Please add the helpers.ps1 file to the script root directory."
        }
        #endregion

        #region Default Variables
        if(!($apiVersion)) {
            #$apiVersion = "2021-10-01"
            $apiVersion = "2019-10-01"
        }

        #endregion

        #region Create Filter
        #if(!($reservationScope)) { $reservationScope = "properties/scope eq 'Single'" } else { $reservationScope = "properties/scope eq '$reservationScope'" }
        #if(!($lookBackPeriod)) { $lookBackPeriod = "properties/lookBackPeriod eq Last7Days" } else { $lookBackPeriod = "properties/lookBackPeriod eq '$lookBackPeriod'" }

        #$filter = "filter=$($reservationScope) AND $($lookBackPeriod)"

        #$resourceType = "SqlDatabases"
        #if(!($resourceType)) { $filter = "$filter AND properties/resourceType eq 'VirtualMachines'" } else { $filter = "$filter AND properties/resourceType eq '$resourceType'" }
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
            if (-not !($subscriptionId) -and -not !($resourceGroupName)) {
                $scope = New-ScopeResourceGroupName -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName
            } elseif (-not !($subscriptionId) -and !($resourceGroupName)) {
                $scope = New-ScopeSubscriptionId -subscriptionId $subscriptionId
            } elseif (!($subscriptionId) -and -not !($resourceGroupName)) {
                Write-Error "The SubscriptionId must be specified when using a ResourceGroupName"
            }
            #endregion

            #region Default Scope - Billing Account
            if(!($subscriptionId) -and !($resourceGroupName) -and !($billingProfileId) -and !($billingAccountId)) { $scope = New-ScopeBillingAccountId -billingAccountId (Get-AzBillingAccount -ExpandBillingProfile).Name }
            #endregion

        #endregion


        #region Create Filter
        $filter = "region=$region&term=$term&lookBackPeriod=$lookBackPeriod&product=$product"
        #endregion

        #region Create Path
        #$path = "/$scope/providers/Microsoft.Consumption/reservationRecommendations?$filter&api-version=$apiVersion"

        $path = "/$scope/providers/Microsoft.Consumption/reservationRecommendationDetails?api-version=$apiVersion&$filter"
        #endregion

        Write-Verbose $path
    }
    Process {
        try {
            $result = ((Invoke-AzRestMethod -Path $path -Method GET @boundParameters -ErrorAction $errorAction).Content | ConvertFrom-Json).value
            #$result = (Invoke-AzRestMethod -Path $path -Method GET @boundParameters -ErrorAction $errorAction).Content
        } Catch { $result = $_}
    }
    End { return $result }
}
