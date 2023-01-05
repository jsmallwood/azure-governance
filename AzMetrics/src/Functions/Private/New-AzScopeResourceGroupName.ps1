Function New-AzScopeResourceGroupName
{
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotNullOrEmpty()]
            [String] $resourceGroupName
    )

    begin {}
    process {
        $result = "subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
    }
    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScopeResourceGroupName