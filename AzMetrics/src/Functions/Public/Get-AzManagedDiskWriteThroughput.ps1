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

Function Get-AzManagedDiskWriteThroughput
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

        #region Initialize Variables
            $data = @()
            $timeseries = @()
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
            $objMetric = Get-AzMetric -ResourceId $ResourceId -MetricName 'Composite Disk Write Bytes/sec' -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime @boundParameters -ErrorAction $errorAction
        } catch {
            return $_
        }

        $objMetric.Data | ForEach-Object { $data += $_.Average }
        $objMetric.Data | ForEach-Object { $timeseries += $_.Average }

        $dataAvg = ($data | Measure-Object -Average).Average
        $timeseriesAvg = ($timeseries | Measure-Object -Average).Average

        if( ($dataAvg) -eq ($timeseriesAvg) )
        {
            $avg = $dataAvg
            $avgUsed = 'data'
        } elseif ($dataAvg -gt $timeseriesAvg) {
            $avg = $dataAvg
            $avgUsed = 'data'
        } else {
            $avg = $timeseriesAvg
            $avgUsed = 'timeseries'
        }

        if($avgUsed -eq 'data') { $avgMax = ($data | Measure-Object -Maximum).Maximum } else { $avgMax = ($timeseries | Measure-Object -Maximum).Maximum }

        if($avgUsed -eq 'data') { $avgMin = ($data | Measure-Object -Minimum).Minimum } else { $avgMin = ($timeseries | Measure-Object -Minimum).Minimum }

        $objResult = [PSCustomObject] @{
            AvgTotal = $avg
            AvgMin = $avgMin
            AvgMax = $avgMax
            DataAvg = $dataAvg
            TimeSeriesAvg = $timeseriesAvg
            Data = $data
            TimeSeries = $timeseries
            AggregationType = 'Average'
            Unit = $objMetric.Unit
            DataUnit = 'Bytes'
        }

    }
    end {
        return $objResult
    }
}

Export-ModuleMember -Function Get-AzManagedDiskWriteThroughput