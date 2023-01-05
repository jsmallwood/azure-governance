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

Function Get-AzManagedDiskThroughput
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
            # Composite Disk Write Bytes/sec
            $objWriteBytes = Get-AzManagedDiskWriteThroughput -ResourceId $ResourceId -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime @boundParameters -ErrorAction $errorAction

            # Composite Disk Read Bytes/sec
            $objReadBytes = Get-AzManagedDiskReadThroughput -ResourceId $ResourceId -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime @boundParameters -ErrorAction $errorAction
        } catch {
            return $_
        }

        $objResult = [PSCustomObject] @{
            ReadAvgTotal = $objReadBytes.AvgTotal
            ReadAvgMin = $objReadBytes.AvgMin
            ReadAvgMax = $objReadBytes.AvgMax
            WriteAvgTotal = $objWriteBytes.AvgTotal
            WriteAvgMin = $objWriteBytes.AvgMin
            WriteAvgMax = $objWriteBytes.AvgMax
            TotalAvg = $objReadBytes.AvgTotal + $objWriteBytes.AvgTotal
            WriteData = $objWriteBytes.Data
            WriteTimeSeries = $objWriteBytes.Timeseries
            ReadData = $objReadeBytes.Data
            ReadTimeSeries = $objReadBytes.Timeseries
            AggregationType = 'Average'
            Unit = $objMetric.Unit
            DataUnit = 'Bytes'
        }
    }
    end {
        return $objResult
    }
}

Export-ModuleMember -Function Get-AzManagedDiskThroughput