#https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks-faq
Function Get-EmpheralSkus
{
[CmdletBinding()]
param([Parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [string]$Location,
      [Parameter(Mandatory=$true)]
      [long]$OSImageSizeInGB
      )
begin { }
process {
$result = Get-EphemeralSupportedVMSku -OSImageSizeInGB $OSImageSizeInGB -Location $Location | Format-Table
}
end
{
return $result
}
}

Function HasSupportEphemeralOSDisk([object[]] $capability)
{
    return $capability | where { $_.Name -eq "EphemeralOSDiskSupported" -and $_.Value -eq "True"}
}

Function Get-MaxTempDiskAndCacheSize([object[]] $capabilities)
{
    $MaxResourceVolumeGB = 0;
    $CachedDiskGB = 0;

    $objResult = New-Object -TypeName PSCustomObject

    foreach($capability in $capabilities)
    {
        if ($capability.Name -eq "MaxResourceVolumeMB")
        {

            $MaxResourceVolumeGB = [int]($capability.Value / 1024)
            $objResult = Add-Member -MemberType NoteProperty -Name MaxResourceVolumeGB -Value $MaxResourceVolumeGB
        }

        if ($capability.Name -eq "CachedDiskBytes")
        {
            $CachedDiskGB = [int]($capability.Value / (1024 * 1024 * 1024))
            $objResult = Add-Member -MemberType NoteProperty -Name CachedDiskGB -Value $CachedDiskGB
        }
    }

    return $objResult #($MaxResourceVolumeGB, $CachedDiskGB)
}

Function Get-EphemeralSupportedVMSku
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false)]
        [long]$OSImageSizeInGB,
        [Parameter(Mandatory=$true)]
        [string]$Location
    )

    $VmSkus = Get-AzComputeResourceSku $Location | Where-Object { $_.ResourceType -eq "virtualMachines" } #-and (HasSupportEphemeralOSDisk $_.Capabilities) -ne $null }

    $Response = @()
    foreach ($sku in $VmSkus)
    {
        ($MaxResourceVolumeGB, $CachedDiskGB) = Get-MaxTempDiskAndCacheSize $sku.Capabilities

        $Response += New-Object PSObject -Property @{
            ResourceSKU = $sku.Size
            TempDiskPlacement = @{ $true = "NOT SUPPORTED"; $false = "SUPPORTED"}[$MaxResourceVolumeGB -lt $OSImageSizeInGB]
            CacheDiskPlacement = @{ $true = "NOT SUPPORTED"; $false = "SUPPORTED"}[$CachedDiskGB -lt $OSImageSizeInGB]
        };
    }

    return $Response
}

#$Location = 'eastus2'

#$VmSkus = Get-AzComputeResourceSku $Location | Where-Object { $_.ResourceType -eq "virtualMachines" }


#Get-MaxTempDiskAndCacheSize -Capabilities $VmSkus[0].Capabilities