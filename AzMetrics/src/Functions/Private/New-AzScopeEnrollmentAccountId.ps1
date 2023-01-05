Function New-AzScopeEnrollmentAccountId
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
            [String] $enrollmentAccountId
    )

    begin {}
    process {
        $result = "providers/Microsoft.Billing/billingAccounts/$($billingAccountId)/enrollmentAccounts/$($enrollmentAccountId)"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeEnrollmentAccountId