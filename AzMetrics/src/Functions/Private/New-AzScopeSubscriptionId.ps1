Function New-AzScopeSubscriptionId
{
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [String] $subscriptionId
    )

    begin {}
    process {
        $result = "subscriptions/$subscriptionId"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeSubscriptionId