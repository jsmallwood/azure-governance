
<#

This Function Handles both "List", and "List By Billing Profile"

https://docs.microsoft.com/en-us/rest/api/consumption/reservation-transactions


.example

Get-AzRITransactions -startDate (Get-Date).AddDays(-31) -EndDate (Get-Date) -Verbose

Get-AzRITransactions

Get-AzRITransactions -billingAccountId {billingAccountId} -billingProfileId {billingProfileId}

#>

Function Get-AzRITransactions
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
            Position=3)]
            [DateTime] $startDate,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=4)]
            [DateTime] $endDate
    )

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

        if(!($billingAccountId)) { $billingAccountId = (Get-AzBillingAccount -ExpandBillingProfile @boundParameters -ErrorAction $errorAction).Name }

        $ignoreFilter = $false

        #endregion

        #region Validate Dates

        if(!($startDate) -and !($endDate))
        {
            $ignoreFilter = $true
        } else {
            if(-not !($EndDate) -or -not !($StartDate))
            {
                $StartDate = (Get-Date).AddDays(-1)
                $EndDate = (Get-Date)
            }
            if($EndDate -and !($StartDate))
            {
                $StartDate = $EndDate.AddDays(-11)
            }
            if($StartDate -and !($EndDate))
            {
                $EndDate = $startDate.AddDays(1)
            }
        }
        #endregion


        #region Create Path Variable

        if($ignoreFilter -eq $true)
        {
            $path = "/providers/Microsoft.Billing/billingAccounts/$($billingAccountId)/providers/Microsoft.Consumption/reservationTransactions?api-version=$apiVersion"
        } else {
            [String] $startDate = $startDate.ToString("yyyy-MM-dd")
            [String] $endDate = $endDate.ToString("yyyy-MM-dd")

            $filter = "`$filter=properties/EventDate ge $startDate AND properties/EventDate le $endDate"

            $path = "/providers/Microsoft.Billing/billingAccounts/$($billingAccountId)/providers/Microsoft.Consumption/reservationTransactions?$filter&api-version=$apiVersion"
        } 

        #endregion
    }
    process {
        try {
            $result = ((Invoke-AzRestMethod -Path $path -Method GET @boundParameters -ErrorAction $errorAction).Content | ConvertFrom-Json).Value
        } Catch { $result = $_}
    }
    end { return $result }

}

#$objTransactions = Get-AzRITransactions -startDate (Get-Date).AddDays(-30) -endDate (Get-Date)

#$objTransactions