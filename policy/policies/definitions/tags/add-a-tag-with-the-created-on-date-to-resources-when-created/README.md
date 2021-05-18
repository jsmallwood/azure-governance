# Add a Tag CreatedOnDate when Resources are created

Adds a CreatedOnDate tag and value when any resource is created or updated. This policy works on both Resources and Resource Groups.

## Deploy with PowerShell

````powershell
$definition = New-AzPolicyDefinition -Name "AddCreatedOnDateTag" -DisplayName "Add a Tag CreatedOnDate when Resources are created" -description "Adds a CreatedOnDate tag and value when any resource is created or updated." -Policy 'policy.rules.json' -Parameter 'policy.parameters.json' -Mode All
$definition

$assignment = New-AzPolicyAssignment -Name <assignmentname> -Scope <scope>  -tagName <tagName> -tagValue <tagValue> -PolicyDefinition $definition
$assignment 
````