﻿param (
    [String] $FileName = "RetailPriceSheet",
    [String] $ExportFileType = "json"
)

#region Import Configuration Files
    $config = New-PowerConfig
    $config | Add-PowerConfigJsonSource -Path 'C:\Users\A006TSO\OneDrive - Blue Cross and Blue Shield of Rhode Island\Documents\Azure\Scripts\Configurations\export.json' | Out-Null
    $settings = $config | Get-PowerConfig
#endregion

#region Set Variables
    $ExportPath = "$($settings.ExportPath.RetailPriceSheet.Path)\$($FileName)"
#endregion



#region Export
Switch ($ExportFileType)
{
    "json" { $objRetailPrices | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$($ExportPath).json" }
    "csv" { $objRetailPrices | Export-Csv -Path -LiteralPath "$($ExportPath).csv" -NoTypeInformation }
}
#endregion