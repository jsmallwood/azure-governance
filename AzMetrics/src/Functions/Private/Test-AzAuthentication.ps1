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


Function Test-AzAuthentication
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]
    param()

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

    }
    process {
        Try {
            Get-AzSubscription @boundParameters -ErrorAction $errorAction | Out-Null
            Write-Verbose 'Azure Authentication was Successful!' -Verbose
            $success = $true
        } Catch {
            Write-ErrorMessage 'Error: Azure Authentication has failed!'
            Write-Warning -Message 'Please login now.'
            Write-Host ''
            $success = (Retry-Command -ScriptBlock { Login-AzAccount } -TimeoutInSecs 5 @boundParameters -ErrorAction $errorAction)
        } Finally {
            If ($success -eq $true)
            {
                Get-AzSubscription @boundParameters -ErrorAction $errorAction | % {
                    Try
                    {
                        Get-AzSubscription -SubscriptionId $_.SubscriptionId  @boundParameters -ErrorAction $errorAction | Set-AzContext  @boundParameters -ErrorAction $errorAction
                    }
                    Catch { }

                }
            }
            Else
            {
                Write-ErrorMessage 'Error: Azure Authentication has failed!'
                Write-Warning -Message 'Please try to rerun the script.'
                $breakScript = $true
            }
        }
    }
    End {
        If ($breakScript -eq $true) { Break }
    }
}

Export-ModuleMember -Function Test-AzAuthentication