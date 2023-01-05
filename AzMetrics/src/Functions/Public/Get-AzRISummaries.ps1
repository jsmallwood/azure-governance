Function Get-AzRISummaries
{
    [CmdletBinding(
        ConfirmImpact="Low",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
        [String] $Scope,
        [Int] $LookbackPeriodInDays = 1,
        [String] $Grain = "Daily", # Daily or Monthly
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

        $apiVersion = "2021-10-01"

        $result = @()

        $Headers = @{
            'Content-Type' = 'Application/Json'
            'Authorization' = 'Bearer ' + (Get-AzAuthToken)
        }
    }

    process {
       for($i=0; $i -le $LookBackPeriodInDays; $i++)
        {
            $StartDate = (Get-Date).AddDays(-$i-1)
            $EndDate = (Get-Date).AddDays(-$i)
            $StartDate = "$($StartDate.Year)-$($StartDate.Month)-$($StartDate.Day)"
            $EndDate = "$($EndDate.Year)-$($EndDate.Month)-$($EndDate.Day)"

            $ExportFile = "$($ExportPath)\$($StartDate)_to_$($EndDate)_ReservationSummaries_$($Grain).json"

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

            try {
                $uri = "https://management.azure.com/$($Scope)/providers/Microsoft.Consumption/reservationSummaries?grain=$($Grain)&startDate=$($StartDate)&endDate=$($EndDate)&api-version=$($apiVersion)"
                $request = (Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers @boundParameters -ErrorAction Stop).value
            } catch {
                Write-Error $_
            }

            foreach($r in $request)
            {
                $result += $r
            }

            if(($Export) -and (-not !($ExportPath)) -and ($continue -eq $true))
            {
                if($request.Count -gt 0)
                {
                    $request | ConvertTo-Json | Set-Content -LiteralPath $ExportFile @boundParameters -ErrorAction $errorAction
                }
            }
        }
    }

    end { return $result }
}

Export-ModuleMember -Function Get-AzRISummaries