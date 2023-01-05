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


Function Retry-Command
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [scriptblock] $ScriptBlock,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1)]
            [int] $RetryCount = 3,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=2)]
            [int] $TimeoutInSecs = 10,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=3)]
            [int] $BackoffTimerInSecs = 10,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=4)]
            [string] $SuccessMessage = "Command executed successfuly!",
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=5)]
            [string] $FailureMessage = "Failed to execute the command"
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

    }

    process {
        $Success = $False
        $Attempt = 1
        $Flag = $true

        do {
            try {
                $PreviousPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                Invoke-Command -ScriptBlock $ScriptBlock -OutVariable Result -ErrorVariable varError @boundParameters
                $ErrorActionPreference = $PreviousPreference

                # flow control will execute the next line only if the command in the scriptblock executed without any errors
                # if an error is thrown, flow control will go to the 'catch' block
                Write-Verbose "$SuccessMessage `n"
                $Success = $true
                $Flag = $false
            }
            catch {
                if ($Attempt -gt $RetryCount) {
                    Write-Verbose "$FailureMessage! Total retry attempts: $RetryCount"
                    Write-Verbose "[Error Message] $($_.exception.message) `n"
                    $Flag = $false
                }
                else {
                    Write-Verbose "[$Attempt/$RetryCount] $FailureMessage. Retrying in $TimeoutInSecs seconds..."
                    Start-Sleep -Seconds $TimeoutInSecs
                    $TimeoutInSecs = $TimeoutInSecs + $BackoffTimerInSecs
                    $Attempt = $Attempt + 1
                }
            }
        }
        While ($Flag)
    }

    end {
        if($Success -eq $true)
        {
            return $Result
        } else {
            return $varError
        }
    }
}

Export-ModuleMember -Function Retry-Command