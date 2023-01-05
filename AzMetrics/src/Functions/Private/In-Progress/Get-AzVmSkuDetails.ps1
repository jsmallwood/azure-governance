Function Get-AzVmSkuDetails
{
        param(
            [String] $Location,
            [Object] $PriceSheet,
            [Switch] $WindowsVms
        )

        begin {
            $objResult = @()
        }
        process {
            if(-not !($Location)) {
                $objSkus = Get-AzComputeResourceSku -ErrorAction Stop | Where { ($_.ResourceType -eq 'virtualMachines') -and ($_.LocationInfo.Location -eq $Location) -and ($_.Restrictions.ReasonCode -ne 'NotAvailableForSubscription')}
            } else {
                $objSkus = Get-AzComputeResourceSku -ErrorAction Stop | Where { ($_.ResourceType -eq 'virtualMachines') -and ($_.Restrictions.ReasonCode -ne 'NotAvailableForSubscription') }
            }

            if(-not !($objSkus)) {
                foreach($sku in $objSkus) {


                    $obj = [PSCustomObject] @{
                        Size = $sku.Size
                        Tier = $sku.Tier
                        Name = $sku.Name
                        Family = $sku.Family
                        MeterName = "$($sku.Size) Disks"
                    }

                    if(-not !($PriceSheet))
                    {
                        if ($WindowsVms)
                        {
                            $objPrice = $PriceSheet | Where-Object { (($_.'Meter category' -eq 'Virtual Machines') -and ($_.'Meter sub-category' -like '*Windows*')) -and ($_.'Meter name' -eq $sku.Size.Replace('_', ' ')) }
                        }
                        else
                        {
                            $objPrice = $PriceSheet | Where-Object { (($_.'Meter category' -eq 'Virtual Machines') -and ($_.'Meter sub-category' -notlike '*Windows*')) -and ($_.'Meter name' -eq $sku.Size.Replace('_', ' ')) }
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

                    $sku.LocationInfo | Get-Member -MemberType Property | % {
                        if($_.Name -eq 'Zones') {
                            $obj | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($sku.LocationInfo."$($_.Name)" -Join ",")
                        } else {
                            if($_.Name -ne 'ZoneDetails') {
                                $obj | Add-Member -MemberType NoteProperty -Name $_.Name -Value $sku.LocationInfo."$($_.Name)"

                            }
                        }
                    }

                    $sku.LocationInfo.ZoneDetails.Capabilities | % {
                        if(-not !($_.Name))
                        {
                            $obj | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
                        }
                    }

                    $objResult += $obj
                }
            }
        }
        end {
            return $objResult
        }
    }