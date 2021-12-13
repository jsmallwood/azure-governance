Function Get-NewResources
{
    param(
        [String] $WorkspaceName,
        [String] $WorkspaceResourceGroupName
    )

    $query = @"
workspace("$($WorkspaceName)").AzureActivity
| where TimeGenerated > ago(1d)
| where ActivityStatus == "Succeeded" and OperationNameValue has "/write"
| where OperationName !has "tags" and OperationName !has "policy" and OperationName !has "locks"
| extend auth = todynamic(Authorization)
| extend props = todynamic(Properties)
| where auth.action !has "tags" and props.statusCode == "Created"
| project TimeGenerated, OperationName, OperationNameValue, Level, ActivityStatus, ActivitySubstatusValue, ResourceProvider, ResourceProviderValue, Resource, ResourceGroup, SubscriptionId, Caller, ResourceId, Scope = auth.scope, ServiceRequestId = props.serviceRequestId, EventDataId, OperationId, CorrelationId, TenantId, EventSubmissionTimestamp
"@

$objWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WorkspaceResourceGroupName -Name $WorkspaceName

$results = Invoke-AzOperationalInsightsQuery -Workspace $objWorkspace -Query $query

return $results

}