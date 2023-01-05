Function Get-AzManagedDiskSkus
{
    <#
        Required Modules
            - Az.Account
            - Az.Compute
    #>

    [CmdletBinding(
        ConfirmImpact="Low",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]
        param(
            [Parameter(Mandatory=$false,
                ValueFromPipeline=$true,
                Position=0)]
                [ValidateNotNullOrEmpty()]
                [String] $Location,
            [Parameter(Mandatory=$false,
                ValueFromPipeline=$true,
                Position=1)]
                [ValidatePattern("((\d{3,4})([pP]|[dD]))")]
                [String] $OfferId,
            [Parameter(Mandatory=$false,
                ValueFromPipeline=$true,
                Position=2)]
                [ValidateSet("Consumption", "DevTestConsumption", "Reservation")]
                [String] $ConsumptionType,
            [Parameter(Mandatory=$true,
                ValueFromPipeline=$true,
                Position=3)]
                [ValidateNotNullOrEmpty()]
                [Object] $PriceSheet
        )

        begin {
            $objResult = @()
            if(!($Location)) { $GetLocation }
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
                    [system.gc]::Collect()

                    if($GetLocation)
                    {
                        $Location = $sku.locations
                    }

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


                    if(-not !($PriceSheet))
                    {
                        if(($PriceSheet | Get-Member -MemberType NoteProperty).Name.Contains('Meter region'))
                        {
                            #Write-Host "EA"
                            if($Location -notmatch '\s')
                            {
                                Switch ($Location.ToLower())
                                {
                                    "eastus" { $varLocation = 'US East' }
                                    "eastus2" { $varLocation = 'US East 2' }
                                    "centralus" { $varLocation = 'US Central' }
                                }
                            }

                            if(!($OfferId))
                            {
                                $objPrice = $PriceSheet | Where-Object { (($_.'Meter category' -eq 'Storage') -and ($_.'Meter sub-category' -like '*Managed Disks*')) -and ($_.'Meter name' -eq "$($sku.Size) Disks") } | Sort-Object -Property 'Unit price' | Select-Object -First 1
                            }
                            else
                            {
                                $objPrice = $PriceSheet | Where-Object { (($_.'Meter category' -eq 'Storage') -and ($_.'Meter sub-category' -like '*Managed Disks*')) -and ($_.'Meter name' -eq "$($sku.Size) Disks") -and ($_.'Offer Id' -eq $OfferId) } | Sort-Object -Property 'Unit price' | Select-Object -First 1
                            }
                        }

                        if(($PriceSheet | Get-Member -MemberType NoteProperty).Name.Contains('armRegionName'))
                        {
                            if($Location -match '\s')
                            {
                                Switch ($Location.ToLower())
                                {
                                    "us east" { $Location = 'eastus' }
                                    "us east 2" { $Location = 'eastus2' }
                                    "us central" { $Location = 'centralus' }
                                }
                            }

                            #Write-Host "Retail"
                            if(!($ConsumptionType))
                            {
                                $objPrice = $PriceSheet | Where { ($_.armRegionName -eq $Location) -and ($_.productName -like "*Managed Disks*") -and ($_.meterName -notlike "*Mounts*") -and ($_.skuName -eq "$($sku.Size) $($redundancy)") }
                            }
                            else
                            {
                                $objPrice = $PriceSheet | Where { ($_.armRegionName -eq $Location) -and ($_.productName -like "*Managed Disks*") -and ($_.meterName -notlike "*Mounts*") -and ($_.skuName -eq "$($sku.Size) $($redundancy)") }
                            }
                        }

                        if(-not !($objPrice))
                        {
                        $obj | Add-Member -MemberType NoteProperty -Name MeterId -Value $objPrice.'Meter ID'
                        $obj | Add-Member -MemberType NoteProperty -Name MeterSubCategory -Value $objPrice.'Meter sub-category'
                        $obj | Add-Member -MemberType NoteProperty -Name UnitPrice -Value $objPrice.'Unit price'
                        }
                        else
                        {
                            $obj | Add-Member -MemberType NoteProperty -Name MeterId -Value ''
                            $obj | Add-Member -MemberType NoteProperty -Name MeterSubCategory -Value ''
                            $obj | Add-Member -MemberType NoteProperty -Name UnitPrice -Value ''
                        }
                    }
                    else
                    {
                        $obj | Add-Member -MemberType NoteProperty -Name MeterId -Value ''
                        $obj | Add-Member -MemberType NoteProperty -Name MeterSubCategory -Value ''
                        $obj | Add-Member -MemberType NoteProperty -Name UnitPrice -Value ''
                    }

                    $sku.Capabilities | % {
                        $obj | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
                    }


                    $objResult += $obj

                    Remove-Variable -Name obj
                    Remove-Variable -Name objPrice

                    if($GetLocation)
                    {
                        Remove-Variable -Name $Location
                    }
                }
            }
        }
        end {
            return $objResult
        }
    }