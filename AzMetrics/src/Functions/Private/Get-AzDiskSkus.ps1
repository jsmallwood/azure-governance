Function Get-AzDiskSkus
{
    param(
        [String] $Location
    )

    begin {
        $result = @()
    }
    process {
        if(-not !($Location)) {
            $objSkus = Get-AzComputeResourceSku | Where { ($_.ResourceType -eq 'disks') -and ($_.LocationInfo.Location -eq $Location) }
        } else {
            $objSkus = Get-AzComputeResourceSku | Where { $_.ResourceType -eq 'disks' }
        }

        if(-not !($objSkus)) {
            foreach($sku in $objSkus)
            {
                if($sku.Name -match '_')
                {
                    $redundancy = $sku.Name.Split('_')[1]
                }
                else
                {
                    $redundancy = ''
                }

                $obj = [PSCustomObject] @{

                    Size = $sku.Size
                    Tier = $sku.Tier
                    Name = $sku.Name
                    Redundancy = $redundancy
                    MeterName = "$($sku.Size) Disks"
                }

                $sku.Capabilities | % {
                    $obj | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
                }

                $result += $obj
            }
        }
    }
    end {
        return $result
    }
}