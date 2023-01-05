Function New-AzScopeDepartmentId
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
            [String] $departmentId
    )

    begin {}
    process {
        $result = "providers/Microsoft.Billing/billingAccounts/$($billingAccountId)/departments/$($departmentId)"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeDepartmentId