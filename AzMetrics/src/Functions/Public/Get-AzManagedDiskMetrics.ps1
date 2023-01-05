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

Function Get-AzManagedDiskMetrics
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

            Try {

            $objDiskIOPs = Get-AzManagedDiskIOPs -ResourceId $ResourceId -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime -ErrorAction $errorAction
            $objDiskThroughput = Get-AzManagedDiskThroughput -ResourceId $ResourceId -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime -ErrorAction $errorAction
            $objDiskBurstIOPs = Get-AzManagedDiskBurstIOPS -ResourceId $ResourceId -TimeGrain $TimeGrain -StartTime $StartTime -EndTime $EndTime -ErrorAction $errorAction

            $obj = [PSCustomObject] @{ }

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsAvgTotal(Bps)" -Value $objDiskIOPs.TotalAvg

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgTotal(Bps)" -Value $objDiskIOPs.ReadAvgTotal
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgMin(Bps)" -Value $objDiskIOPs.ReadAvgMin
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgMax(Bps)" -Value $objDiskIOPs.ReadAvgMax

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgTotal(Bps)" -Value $objDiskIOPs.WriteAvgTotal
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgMin(Bps)" -Value $objDiskIOPs.WriteAvgMin
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgMax(Bps)" -Value $objDiskIOPs.WriteAvgMax

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsAvgTotal(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskIOPs.TotalAvg -Precision 4).Value

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgTotal(KiBps)" -Value (Convert-Size -From Byte -To KiB  -Value $objDiskIOPs.ReadAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgMin(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskIOPs.ReadAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgMax(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskIOPs.ReadAvgMax -Precision 4).Value

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgTotal(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskIOPs.WriteAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgMin(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskIOPs.WriteAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgMax(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskIOPs.WriteAvgMax -Precision 4).Value

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsAvgTotal(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskIOPs.TotalAvg -Precision 4).Value

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgTotal(MiBps)" -Value (Convert-Size -From Byte -To MiB  -Value $objDiskIOPs.ReadAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgMin(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskIOPs.ReadAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsReadAvgMax(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskIOPs.ReadAvgMax -Precision 4).Value

            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgTotal(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskIOPs.WriteAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgMin(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskIOPs.WriteAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "IOPsWriteAvgMax(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskIOPs.WriteAvgMax -Precision 4).Value


            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputAvgTotal(Bps)" -Value $objDiskThroughput.TotalAvg

            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgTotal(Bps)" -Value $objDiskThroughput.ReadAvgTotal
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgMin(Bps)" -Value $objDiskThroughput.ReadAvgMin
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgMax(Bps)" -Value $objDiskThroughput.ReadAvgMax


            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgTotal(Bps)" -Value $objDiskThroughput.WriteAvgTotal
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgMin(Bps)" -Value $objDiskThroughput.WriteAvgMin
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgMax(Bps)" -Value $objDiskThroughput.WriteAvgMax


            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputAvgTotal(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskThroughput.TotalAvg -Precision 4).Value

            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgTotal(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskThroughput.ReadAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgMin(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskThroughput.ReadAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgMax(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskThroughput.ReadAvgMax -Precision 4).Value


            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgTotal(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskThroughput.WriteAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgMin(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskThroughput.WriteAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgMax(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskThroughput.WriteAvgMax -Precision 4).Value


            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputAvgTotal(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskThroughput.TotalAvg -Precision 4).Value

            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgTotal(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskThroughput.ReadAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgMin(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskThroughput.ReadAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputReadAvgMax(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskThroughput.ReadAvgMax -Precision 4).Value


            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgTotal(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskThroughput.WriteAvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgMin(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskThroughput.WriteAvgMin -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "ThroughputWriteAvgMax(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskThroughput.WriteAvgMax -Precision 4).Value



            $obj | Add-Member -MemberType NoteProperty -Name "BurstIOPsAvg(Bps)" -Value $objDiskBurstIOPs.AvgTotal
            $obj | Add-Member -MemberType NoteProperty -Name "BurstIOPsAvg(KiBps)" -Value (Convert-Size -From Byte -To KiB -Value $objDiskBurstIOPs.AvgTotal -Precision 4).Value
            $obj | Add-Member -MemberType NoteProperty -Name "BurstIOPsAvg(MiBps)" -Value (Convert-Size -From Byte -To MiB -Value $objDiskBurstIOPs.AvgTotal -Precision 4).Value
            #$obj | Add-Member -MemberType NoteProperty -Name "BurstIOPsAvgMin" -Value $objDiskBurstIOPs.AvgMin
            #$obj | Add-Member -MemberType NoteProperty -Name "BurstIOPsAvgMax" -Value $objDiskBurstIOPs.AvgMax


            #$obj | Add-Member -MemberType NoteProperty -Name "ResourceId" -Value $ResourceId
            } Catch {
                $obj = $_
            }
    }
    end {
        return $obj
    }
}

Export-ModuleMember -Function Get-AzManagedDiskMetrics