<#
.SYNOPSIS
    This function returns the metric
.DESCRIPTION
    The metric values are returned in Kilobytes.
.EXAMPLE
    C:\PS>
    Example of how to use this cmdlet
.EXAMPLE
    C:\PS>
    Another example of how to use this cmdlet
.PARAMETER InputObject
    Specifies the object to be processed.  You can also pipe the objects to this command.
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    AzMetrics
#>




Function Get-AzSubscriptions
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
        [ValidateNotNullOrEmpty()]
            [String[]] $Subscriptions
    )

    begin {
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

        $objResult = @()
    }
    process {
        if(-not !($Subscriptions))
        {
            try {
                $objSubscriptions = Get-AzSubscription @boundParameters -ErrorAction $errorAction| Where-Object { $_.State -eq "Enabled" }
            } catch {
                $objResult = $_
            }

            $Subscriptions | % {
                $varSubscription = $_
                $obj = ($objSubscriptions | Where-Object { $_.Name -eq $varSubscription })
                $objResult += $obj
            }
        }
        else
        {
            try {
                Get-AzSubscription @boundParameters -ErrorAction $errorAction | Where-Object { $_.State -eq "Enabled" } | % {
                    $objResult += $_
                }
            } Catch {
                $objResult = $_
            }
        }
    }
    end {
        return $objResult
    }
}

Export-ModuleMember -Function Get-AzSubscriptions