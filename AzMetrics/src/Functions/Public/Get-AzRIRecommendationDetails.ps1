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

Function Get-AzRIRecommendations
{
    [CmdletBinding(
        ConfirmImpact="Low",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
        [String] $BillingScope,
        [String] $Scope, # Single, Shared
        [Int] $LookbackPeriodInDays, # 7, 30, 60
        [String] $ResourceType, # 1 or 3
        [Switch] $All,
        [Switch] $Export,
        $ExportPath
    )

    begin {
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

        $apiVersion = "2021-10-01"

        $result = @()

        $Headers = @{
            'Content-Type' = 'Application/Json'
            'Authorization' = 'Bearer ' + (Get-AzAuthToken)
        }

        Switch ($LookbackPeriodInDays)
        {
            7 { $LookBackPeriod = "Last7Days" }
            30 { $LookBackPeriod = "Last30Days" }
            60 { $LookBackPeriod = "Last60Days" }
            Default { $LookBackPeriod = "Last7Days" }
        }

        $objSubscriptions = Get-AzSubscription

        [String[]] $ResourceTypes = 'VirtualMachines', 'SQLDatabases', 'PostgreSQL', 'ManagedDisk', 'MySQL', 'RedHat', 'MariaDB', 'RedisCache', 'CosmosDB', 'SqlDataWarehouse', 'SUSELinux', 'AppService', 'BlockBlob', 'AzureDataExplorer', 'VMwareCloudSimple'

        $Date = (Get-Date)
        [string] $Date = "$($Date.Year)-$($Date.Month)-$($Date.Day)"
    }

    process
    {
        If($All)
        {
            [String[]] 'VirtualMachines', 'SQLDatabases', 'PostgreSQL', 'ManagedDisk', 'MySQL', 'RedHat', 'MariaDB', 'RedisCache', 'CosmosDB', 'SqlDataWarehouse', 'SUSELinux', 'AppService', 'BlockBlob', 'AzureDataExplorer', 'VMwareCloudSimple' | % {
                $ResourceType = $_
                [String[]] "Single", "Shared" | % {
                    $Scope = $_

                    $filter = "properties/lookBackPeriod eq '$($LookBackPeriod)' AND properties/scope eq '$($Scope)' AND properties/resourceType eq '$($ResourceType)'"

                    $uri = "https://management.azure.com/$($BillingScope)/providers/Microsoft.Consumption/reservationRecommendations?`$filter=$($filter)&api-version=$($apiVersion)"
                    try {
                        $request = (Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers @boundParameters -ErrorAction Stop).value
                    } catch {
                        Write-Error $_
                    }

                    foreach($r in $request)
                    {
                        $r.properties | Add-Member -MemberType NoteProperty -Name subscriptionName -Value ($objSubscriptions | Where { $_.Id -eq $r.properties.subscriptionId }).Name

                        $result += $r
                    }

                    if(($Export) -and (-not !($ExportPath)))
                    {
                        if($request.Count -gt 0)
                        {
                            $ExportFile = "$($ExportPath)\$($Date)_ReservationRecommendations_$($ResourceType)_$($Scope).json"
                            $request | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ExportFile @boundParameters -ErrorAction $errorAction
                        }
                    }
                }
            }
        }
        else
        {
            $filter = "properties/lookBackPeriod eq '$($LookBackPeriod)' AND properties/scope eq '$($Scope)' AND properties/resourceType eq '$($ResourceType)'"

            $uri = "https://management.azure.com/$($BillingScope)/providers/Microsoft.Consumption/reservationRecommendations?`$filter=$($filter)&api-version=$($apiVersion)"
                    try {
                        $request = (Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers @boundParameters -ErrorAction Stop).value
                    } catch {
                        Write-Error $_
                    }

                    foreach($r in $request)
                    {
                        $r.properties | Add-Member -MemberType NoteProperty -Name subscriptionName -Value ($objSubscriptions | Where { $_.Id -eq $r.properties.subscriptionId }).Name

                        $result += $r
                    }

                    if(($Export) -and (-not !($ExportPath)))
                    {
                        if($request.Count -gt 0)
                        {
                            $ExportFile = "$($ExportPath)\$($Date)_ReservationRecommendations_$($ResourceType)_$($Scope).json"
                            $request | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ExportFile @boundParameters -ErrorAction $errorAction
                        }
                    }

        }

    }

    end { return $result }
}


Export-ModuleMember -Function Get-AzRIRecommendations