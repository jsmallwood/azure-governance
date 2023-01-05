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

FunFunction Get-AzBenefitRecommendations
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
        [String] $Term, # 1 or 3
        [Switch] $All,
        [Switch] $ExpandUsage,
        [Switch] $ExpandRecommendationDetails,
        [Switch] $Export,
        $ExportPath
    )

    Begin {
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

        $apiVersion = "2022-10-01"

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
            Default { $LookBackPeriod = "Last60Days" }
        }

        Switch ($Term)
        {
            1 { $Term = "P1Y" }
            3 { $Term = "P3Y" }
            Default { $Term = "P3Y" }
        }

        $objSubscriptions = Get-AzSubscription
    }

    process
    {
        if($Export)
        {
            $Date = (Get-Date)
            [string] $Date = "$($Date.Year)-$($Date.Month)-$($Date.Day)"

            try
            {
                $file = (Get-ChildItem -LiteralPath $ExportFile -ErrorAction Stop)

                if($file.Exists -and ($file.Length -gt 0))
                {
                    $continue = $false
                }
            } catch {
                $continue = $true
            }
        }

        If($All)
        {
            [String[]] "Single", "Shared" | % {
                $Scope = $_
                [String[]] "P1Y", "P3Y" | % {
                    $Term = $_

                    if($ExpandUsage -or $ExpandRecommendationDetails)
                    {
                        if($ExpandUsage -and -not $ExpandRecommendationDetails)
                        {
                            $filter = "properties/lookBackPeriod eq '$($LookBackPeriod)' AND properties/scope eq '$($Scope)' AND properties/term eq '$($Term)'&`$expand=properties/usage"
                        }
                        elseif($ExpandRecommendationDetails -and -not $ExpandUsage)
                        {
                            $filter = "properties/lookBackPeriod eq '$($LookBackPeriod)' AND properties/scope eq '$($Scope)' AND properties/term eq '$($Term)'&`$expand=properties/allRecommendationDetails"
                        }
                        else
                        {
                            $filter = "properties/lookBackPeriod eq '$($LookBackPeriod)' AND properties/scope eq '$($Scope)' AND properties/term eq '$($Term)'&`$expand=properties/usage,properties/allRecommendationDetails"
                        }

                    }
                    else
                    {
                        $filter = "properties/lookBackPeriod eq '$($LookBackPeriod)' AND properties/scope eq '$($Scope)' AND properties/term eq '$($Term)'"
                    }

                    try {
                        $uri = "https://management.azure.com/$($BillingScope)/providers/Microsoft.CostManagement/benefitRecommendations?`$filter=$($filter)&api-version=$($apiVersion)"
                        $request = (Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers @boundParameters -ErrorAction Stop).value
                    } catch {
                        Write-Error $_
                    }

                    foreach($r in $request)
                    {
                        $r | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value ($objSubscriptions | Where { $_.Id -eq $r.properties.subscriptionId }).Name

                        $result += $r
                    }

                    if(($Export) -and (-not !($ExportPath)) -and ($continue -eq $true))
                    {
                        if($request.Count -gt 0)
                        {
                            $ExportFile = "$($ExportPath)\$($Date)_ComputeSavingsPlanRecommendations_$($Scope)_$($Term).json"
                            $request | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ExportFile @boundParameters -ErrorAction $errorAction
                        }
                    }
                }

            }
        }
        else
        {
            try {
                $uri = "https://management.azure.com/$($BillingScope)/providers/Microsoft.CostManagement/benefitRecommendations?`$filter=$($filter)&api-version=$($apiVersion)"
                $request = (Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers @boundParameters -ErrorAction Stop).value
            } catch {
                Write-Error $_
            }

            foreach($r in $request)
            {
                $r | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value ($objSubscriptions | Where { $_.Id -eq $r.properties.subscriptionId }).Name
                $result += $r
            }
        }

        if(($Export) -and (-not !($ExportPath)) -and ($continue -eq $true))
        {
            if($request.Count -gt 0)
            {
                if($All)
                {
                    $ExportFile = "$($ExportPath)\$($Date)_ComputeSavingsPlanRecommendations.json"
                }
                else
                {
                    $ExportFile = "$($ExportPath)\$($Date)_ComputeSavingsPlanRecommendations_$($Scope)_$($Term).json"
                }
                $request | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ExportFile @boundParameters -ErrorAction $errorAction
            }
        }
    }

    end { return $result }
}

Export-ModuleMember -Function Get-AzBenefitRecommendations