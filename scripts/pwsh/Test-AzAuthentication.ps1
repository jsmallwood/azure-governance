Function Test-AzAuthentication
{
    Begin { }
    Process { 
        Try {
            Get-AzSubscription -ErrorAction Stop | Out-Null
            Write-Verbose 'Azure Authentication was Successful!' -Verbose
            $success = $true
        } Catch {
            Write-ErrorMessage 'Error: Azure Authentication has failed!'
            Write-Warning -Message 'Please login now.'
            Write-Host ''
            $success = (Retry-Command -ScriptBlock { Login-AzAccount } -TimeoutInSecs 5)
        } Finally {
            If ($success -eq $true) 
            { 
                Get-AzSubscription | % {
                    Try 
                    {
                        Get-AzSubscription -SubscriptionId $_.SubscriptionId -ErrorAction Stop | Set-AzContext -ErrorAction Stop
                    }
                    Catch { }     

                }
            } 
            Else 
            { 
                Write-ErrorMessage 'Error: Azure Authentication has failed!' 
                Write-Warning -Message 'Please try to rerun the script.'
                $breakScript = $true
            }
        }
    }
    End {
        If ($breakScript -eq $true) { Break }
    }
}