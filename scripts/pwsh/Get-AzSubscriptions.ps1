    Function Get-AzSubscriptions
{
    param(
        [String[]] $Subscriptions
    )

    begin {
        $objResult = @()

        $objSubscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" } 
    }

    process {
        if(-not !($Subscriptions))
        {
            $Subscriptions | % {
                $varSubscription = $_
                $obj = ($objSubscriptions | Where-Object { $_.Name -eq $varSubscription })
                $objResult += $obj
            }
        } else 
        {
            Get-AzSubscription | Where-Object { $_.State -eq "Enabled" } | % {
                $objResult += $_
            }
        }
    }

    end {
        return $objResult
    }
}
