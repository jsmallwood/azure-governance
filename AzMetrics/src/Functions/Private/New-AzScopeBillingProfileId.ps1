Function New-AzScopeBillingProfileId
{
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [String] $billingAccountId,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1)]
            [ValidateNotNullOrEmpty()]
            [String] $billingProfileId
    )

    begin {}
    process {
        $result = "providers/Microsoft.Billing/billingAccounts/$($billingAccountId)/billingProfiles/$($billingProfileId)"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeBillingAccountId