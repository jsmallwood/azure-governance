Function Invoke-AzArgQuery
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$true,
        SupportsShouldProcess=$true,
        PositionalBinding=$true
    )]

    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [String] $Query,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1)]
            [ValidateNotNullOrEmpty()]
            [Object] $Subscription,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=2)]
            [ValidateNotNullOrEmpty()]
            [Int] $PageSize

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

        if(!($Subscription)) { $Subscriptions = Get-AzSubscription @boundParameters -ErrorAction $errorAction | Where-Object { ($_.State -eq "Enabled") -and ($_.Name -ne 'Access to Azure Active Directory') } | ForEach-Object { "$($_.Id)"} }

        if(!($PageSize)) { $ARGPageSize = 1000 } Else { $ARGPageSize = $PageSize }
    }

    Process {
        $result = [System.Collections.ArrayList]@()

        $resultsSoFar = 0
        do
        {
            if ($resultsSoFar -eq 0)
            {
                $queryResults = Search-AzGraph -Query $Query -First $ARGPageSize -Subscription $subscriptions @boundParameters -ErrorAction $errorAction
            }
            else
            {
                $queryResults = Search-AzGraph -Query $Query -First $ARGPageSize -Skip $resultsSoFar -Subscription $subscriptions @boundParameters -ErrorAction $errorAction
            }
            if ($queryResults -and $queryResults.GetType().Name -eq "PSResourceGraphResponse")
            {
                $queryResults = $queryResults.Data
            }
            $resultsCount = $queryResults.Count
            $resultsSoFar += $resultsCount
            $result += $queryResults
            Remove-Variable -Name queryResults

        } while ($resultsCount -eq $ARGPageSize)
    }

    End {
        Return $result
    }
}
