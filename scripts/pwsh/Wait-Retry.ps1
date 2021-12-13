Function Wait-Retry
{
    param(
        $command,
        $Retrycount = 2
    )

    begin {
        $Stoploop = $false
    } 
    process {
        do {
            try {
                Invoke-Expression -Command $Command -ErrorAction Stop
                Write-Host "Job completed"
                $Stoploop = $true
            }
            catch {
                if ($Retrycount -gt 3){
                    Write-Host "Could not send Information after 3 retrys."
                    $Stoploop = $true
                }
                else {
                    Write-Host "Could not send Information retrying in 30 seconds..."
                    Start-Sleep -Seconds 30
                    $Retrycount = $Retrycount + 1
                }
            }
        }
        While ($Stoploop -eq $false)

    }
}


# Wait-Retry -command "Login-AzAccount"