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

Function Get-AzVmNetworkTotalBytes
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [String] $ResourceId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1)]
            [ValidateNotNullOrEmpty()]
            [Timespan] $TimeGrain,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=2)]
            [DateTime] $StartTime,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=3)]
            [DateTime] $EndTime
    )

    begin {

        Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

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

        #region Validate Parameters and Set Defaults if required
        if(!($StartTime))
        {
            [TimeSpan] $TimeGrain = "00:05:00"
        }

        if(!($TimeGrain))
        {
            [DateTime] $StartTime = (Get-Date).AddDays(-30)
        }

        if(!($EndTime))
        {
            [Datetime] $EndTime = (Get-Date)
        }
        #endregion
    }

    process {

        try {
            # Disk Write Operations/sec
            $objInBytes = Get-AzVmNetworkInTotalBytes -ResourceId $ResourceId -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime @boundParameters -ErrorAction $errorAction

            # Disk Read Operations/sec
            $objOutBytes = Get-AzVmNetworkOutTotalBytes -ResourceId $ResourceId -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime @boundParameters -ErrorAction $errorAction
        } catch {
            return $_
        }
        # Return IOPs
        $objResult = [PSCustomObject] @{
            Total = $objInBytes.Total + $objOutBytes.Total
            Average = $objInBytes.Average + $objOutBytes.Average
            Maximum = $objInBytes.Maximum + $objOutBytes.Maximum
            Minuimum = $objInBytes.Minimum + $objOutBytes.Minimum
            InAvg = $objInBytes.Average
            InMax = $objInBytes.Maximum
            InMin = $objInBytes.Minimum
            InTotal = $objInBytes.Total
            OutAvg = $objOutBytes.Average
            OutMax = $objOutBytes.Maximum
            OutMin = $objOutBytes.Minimum
            OutTotal = $objOutBytes.Total
            Unit = 'Bytes'
        }
    }
    end {
        return $objResult
    }
}

Export-ModuleMember -Function Get-AzVmNetworkTotalBytes