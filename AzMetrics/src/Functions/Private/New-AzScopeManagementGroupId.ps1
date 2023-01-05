Function New-AzScopeManagementGroupId
{
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [String] $managementGroupId
    )

    begin {}
    process {
        $result = "providers/Microsoft.Management/managementGroups/$($managementGroupId)"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeManagementGroupId