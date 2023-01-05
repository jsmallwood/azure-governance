Function Get-AzUltraDiskCost
{
    param(
        [int] $SizeGB,
        [int] $MaxIOPs,
        [int] $MaxThroughputMBps,
        [int] $HoursPerMonth,
        [Boolean] $CurrentMonth
    )

    Begin {
        $objHourlyPricePerGiB = 0.000164
        $objHourlyPricePerIOP = 0.000068
        $objHourlyPricePerMBps = 0.000479

        if(($CurrentMonth -eq $false) -and !($HoursPerMonth))
        {
            $HoursPerMonth = 730
        }

        if($CurrentMonth -eq $true)
        {
            $firstDay = (Get-Date)
            $lastDay = ($firstDay).AddMonths(1).AddSeconds(-1)
            $daysInMonth = [DateTime]::DaysInMonth($firstDay.Year, $firstDay.Month)
            $HoursPerMonth = $daysInMonth * 24
        }
    }

    Process {

        $objCostStorage = ($SizeGB * $objHourlyPricePerGiB) * $HoursPerMonth
        $objCostIOPs = ($MaxIOPs * $objHourlyPricePerIOP) * $HoursPerMonth
        $objCostThroughput = ($MaxThroughputMBps * $objHourlyPricePerMBps) * $HoursPerMonth

        $obj = [PSCustomObject] @{
            StorageCost = $objCostStorage
            IOPsCost = $objCostIOPs
            ThroughputCost = $objCostThroughput
            TotalCost = $objCostStorage + $objCostIOPs + $objCostThroughput
        }
    }

    End {
        return $obj
    }
}