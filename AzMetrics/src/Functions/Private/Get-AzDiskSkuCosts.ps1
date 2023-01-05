Function Get-AzDiskSkuCosts
{
    param(
        [String] $Location,
        [Object] $DiskSkus,
        [Object] $PriceSheet,
        [Object] $RetailPriceSheet
    )

    begin {

        $objResult = @()

        if(!($Location) ) { $Location = 'eastus2' }

        if(!($DiskSkus)) {

            $DiskSkus = Get-AzDiskSkus -Location $location
        }
    }

    process {



    $DiskSkus | % {
        if ($_.Size -ne 'U')
        {
            $Size = $_.Size
            $Redundancy = $_.Redundancy

            if($PriceSheet) {
                $objPrice = ($PriceSheet | Where-Object { ($_.'Meter name' -eq "$Size Disks") } | Sort-Object -Property 'Unit price' | Select-Object -First 1)
            }

            if($RetailPriceSheet) {
                $objRetailPrice = ($RetailPriceSheet | Where-Object { ($_.MeterName -eq "$Size Disks") -and ($_.skuName -like "*$($Redundancy)") } | Sort-Object -Property unitPrice | Select-Object -First 1)
            }

            if(-not !($objPrice))
            {
                $unitPrice = $objPrice.'Unit price'
                $location = $objPrice.'Meter region'
                $meterId = $objPrice.'Meter Id'

            } elseif (-not !($objRetailPrice)) {

                $unitPrice = $objRetailPrice.unitPrice
                $location = $objRetailPrice.armRegionName
                $meterId = $objRetailPrice.meterId
            }
            else
            {
                $unitPrice = $null
                $location = $null
                $meterId = $null
            }

            $obj = [PSCustomObject] @{
                Size = $_.Size
                Tier = $_.Tier
                Name = $_.Name
                Redundancy = $_.Redundancy
                Location = $_.Location
                MaxSizeGiB = $_.MaxSizeGiB
                MinSizeGiB = $_.MinSizeGiB
                MaxIOps = $_.MaxIOps
                MinIOps = $_.MinIOps
                MaxBandwidthMBps = $_.MaxBandwidthMBps
                MinBandwidthMBps = $_.MinBandwidthMBps
                MaxValueOfMaxShareds = $_.MaxValueOfMaxShares
                MaxBurstIops = $_.MaxBurstIops
                MaxBurstBandwidthMBps = $_.MaxBurstBandwidthMBps
                MaxBurstDurationInMin = $_.MaxBurstDurationInMin
                BurstCreditBucketSizeInIO = $_.BurstCreditBucketSizeInIO
                BurstCreditBucketSizeInGiB = $_.BurstCreditBucketSizeInGiB
                UnitPrice = $unitPrice
                MeterId = $meterId
            }

            $objResult += $obj
        }
    }

    }

    end { return $objResult }


}