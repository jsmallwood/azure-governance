Function New-AzScopeBillingAccountId
{
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [String] $billingAccountId
    )

    begin {}
    process {
        $result = "providers/Microsoft.Billing/billingAccounts/$($billingAccountId)"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeBillingAccountId