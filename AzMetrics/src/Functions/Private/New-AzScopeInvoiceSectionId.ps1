Function New-AzScopeInvoiceSectionId
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
            [String] $invoiceSectionId
    )

    begin {}
    process {
        $result = "providers/Microsoft.Billing/billingAccounts/$($billingAccountId)/invoiceSections/$($invoiceSectionId)"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeInvoiceSectionId