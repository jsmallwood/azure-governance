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

Function Get-AzVmMemoryAvailableBytes
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

            [String[]] $AggregationTypes = "Average", "Maximum", "Minimum"
        #endregion

        #region Validate Parameters and Set Defaults if required
        if(!($StartTime))
        {
            [TimeSpan] $TimeGrain = "00:15:00"
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

        $objResult = [PSCustomObject] @{
            TimeGrain = [String] $TimeGrain
            StartTime = $StartTime.ToString()
            EndTime = $EndTime.ToString()
            MetricName = "Available Memory Bytes"
            Unit = 'Bytes'
        }

        $AggregationTypes | % {
            $Aggregation = $_
            try {
                $objMetric = Get-AzMetric -ResourceId $ResourceId -MetricName 'Available Memory Bytes' -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime -AggregationType $Aggregation

                $data = @()

                if($Aggregation -eq 'Average')
                {
                    $objMetric.Data | ForEach-Object { $data += $_.Average }
                    $value = ($data | Measure-Object -Average).Average
                    $objResult | Add-Member -MemberType NoteProperty -Name Average -Value $value
                }

                if($Aggregation -eq 'Maximum')
                {
                    $objMetric.Data | ForEach-Object { $data += $_.Maximum }
                    $value = ($data | Measure-Object -Maximum).Maximum
                    $objResult | Add-Member -MemberType NoteProperty -Name Maximum -Value $value
                }

                if($Aggregation -eq 'Minimum')
                {
                    $objMetric.Data | ForEach-Object { $data += $_.Minimum }
                    $value = ($data | Measure-Object -Minimum).Minimum
                    $objResult| Add-Member -MemberType NoteProperty -Name Minimum -Value $value
                }

            } catch {
               return $_
            }
        }

        $objResult | Add-Member -MemberType NoteProperty -Name ResourceId -Value $ResourceId

    }
    end {
        return $objResult
    }
}

Export-ModuleMember -Function Get-AzVmMemoryAvailableBytes