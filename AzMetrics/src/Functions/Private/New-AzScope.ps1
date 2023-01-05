Function New-AzScope
{
    param (
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            [String] $resourceGroupName,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            $subscriptionId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            $managementGroupId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            $billingAccountId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            $billingProfileId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            $invoiceSectionId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            $departmentId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true)]
            $enrollmentId
    )

    begin {
        [string] $result = $null

        if(!($billingAccountId) -and !($billingProfileId) -and !($subscriptionId) -and !($resourceGroupName) -and !($managementGroupId) -and !($departmentId) -and !($enrollmentId) -and !($invoiceSectionId))
        {
            Write-Error -Exception "A Parameter must be defined."
            break
        }
    }

    process {
        if(-not !($billingAccountId))
        {
            if(-not !($billingProfileId))
            {
                $result = New-AzScopeBillingProfileId -billingAccountId $billingAccountId -billingProfileId $billingProfileId
            } elseif (-not !($invoiceSectionId)) {
                $result = New-AzScopeInvoiceSectionId -billingAccountId $billingAccountId -invoiceSectionId $invoiceSectionId
            } elseif (-not !($departmentId)) {
                $result = New-AzScopeDepartmentId -billingAccountId $billingAccountId -departmentId $departmentId
            } elseif (-not !($enrollmentId)) {
                $result = New-AzScopeEnrollmentId -billingAccountId $billingAccountId -enrollmentId $enrollmentId
            } else {
                $result = New-AzScopeBillingAccountId -billingAccountId $billingAccountId
            }
        }
        else {
            if(-not !($subscriptionId) -and !($resourceGroupName))
            {
                $result = New-AzScopeSubscriptionId -subscriptionId $subscriptionId
            } elseif(-not !($subscriptionId) -and -not !($resourceGroupName)) {
                $result = New-AzScopeResourceGroupName -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName
            } else {
                if(-not !($managementGroupId))
                {
                    $result = New-AzScopeManagementGroupId -managementGroupId $managementGroupId
                }
            }
        }
    }

    end {
        return $result
    }
}

Export-ModuleMember -Function New-AzScope