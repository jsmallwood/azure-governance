[CmdletBinding()]
param(
    [String] $RootPolicyFolder,
    [String] $ManagementGroupName,
    [Bool] $RemoveExistingCustomPolicies = $False,
    [Bool] $RemoveAllPolicies = $True
)

#region PolicyDef class is used to store hash table of policy varaiables
class PolicyDef {
    [string]$PolicyName
    [string]$PolicyDisplayName
    [string]$PolicyDescription
    [string]$PolicyMode
    [string]$PolicyMetaData
    [string]$PolicyRule
    [string]$PolicyParameters
}
#endregion

#region get management group name function
function Get-AzManagementGroupName
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $False)]
        [AllowNull()]
        [AllowEmptyString()]
        [String] $managementGroupName = 'Tenant Root Group'
    )
    Try {
        $rootMG = Get-AzManagementGroup -ErrorAction Stop | Where-Object {($_.DisplayName -eq 'Tenant Root Group')}

        if (($managementGroupName -eq 'Tenant Root Group') -or ($managementGroupName -eq $null) -or ($managementGroupName -eq '')) {
            $name = $rootMG.Name
        } else {
            (Get-AzManagementGroup -GroupId $rootMG.Name -Expand -Recurse -ErrorAction Stop).Children | % {
                if (($_.Type -match 'managementGroups') -and (($_.Name -eq $managementGroupName) -or ($_.DisplayName -eq $managementGroupName)))
                { 
                    $name = $_.Name 
                }
            }
        }
        return $name
    } Catch {
        Write-Error $_
    }
}
#endregion

#region Remove Custom Policies
function Remove-CustomPolicies {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
            [String[]] $Policies,
        [Parameter(Mandatory = $false)]
            [String] $ManagementGroupName,
        [Parameter(Mandatory = $false)]
            [String] $SubscriptionId,
        [Parameter(Mandatory = $true)]
            [Bool] $All = $True
    )

    if(!($ManagementGroupName) -and !($SubscriptionId))
    {
        $ManagementGroupName = Get-AzManagementGroupName 
    }

    if ($All -eq $true)
    {
        if($SubscriptionId)
        {
            Get-AzPolicyDefinition -Custom -ManagementGroupName $managementGroupName | % { Remove-AzPolicyDefinition -Name $_.Name -SubscriptionId $SubscriptionId -Force }
        } else {
            Get-AzPolicyDefinition -Custom -ManagementGroupName $managementGroupName | % { Remove-AzPolicyDefinition -Name $_.Name -ManagementGroupName $ManagementGroupName -Force }
        }      
    }


    <#
    if ($Policies)
    {
        $Policies | % {
            Get-AzPolicyDefinition -
            
        }
    #>

}
#endregion

#region get modified policy function
function Get-ModifiedPolicies {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)][string[]]$modifiedPolicies,
        [Parameter(Mandatory = $true)][string]$rootDir
    )

    $policyList = @()

    foreach ($modifiedPolicy in $modifiedPolicies) {

        #Write-Host "##[debug] File path: .$rootDir."
        #Write-Host "##[debug] File path: .$modifiedPolicy."

        $filePath = $rootDir+ "/" + $modifiedPolicy + "azurepolicy.json"

        #Write-Host "##[debug] File path: $filePath"

        $azurePolicy = Get-Content $filePath | ConvertFrom-Json

        #Write-Host "##[debug] Policy $($azurePolicy.properties.displayName)"

        #declare new policyDef object
        $policy = New-Object -TypeName PolicyDef

        #set variables
        $policy.PolicyName = $azurePolicy.properties.displayName
        $policy.PolicyDisplayName = $azurePolicy.properties.displayName
        $policy.PolicyDescription = $azurePolicy.properties.description
        $policy.PolicyMode = $azurePolicy.properties.mode
        $policy.PolicyMetadata = $azurePolicy.properties.metadata | ConvertTo-Json -Depth 100
        $policy.PolicyRule = $azurePolicy.properties.policyRule | ConvertTo-Json -Depth 100
        $policy.PolicyParameters = $azurePolicy.properties.parameters | ConvertTo-Json -Depth 100
        $policyList += $policy
    }

    return $policyList
}
#endregion

#region get policy function
function Get-Policies {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)][string]$rootDir
    )

    $policyList = @()

    $policyFiles = Get-ChildItem -LiteralPath $rootDir -Filter *.json -Recurse -File

    foreach ($file in $policyFiles) 
    {
        if(($file.Name -eq 'policy.json') -or ($file.Name -eq 'azurepolicy.json'))
        {
            $azurePolicy = Get-Content -LiteralPath $file.FullName | ConvertFrom-Json

            #declare new policyDef object
            $policy = New-Object -TypeName PolicyDef

            #set variables
            $policy.PolicyName = $azurePolicy.properties.displayName
            $policy.PolicyDisplayName = $azurePolicy.properties.displayName
            $policy.PolicyDescription = $azurePolicy.properties.description
            $policy.PolicyMode = $azurePolicy.properties.mode
            $policy.PolicyMetadata = $azurePolicy.properties.metadata | ConvertTo-Json -Depth 100
            $policy.PolicyRule = $azurePolicy.properties.policyRule | ConvertTo-Json -Depth 100
            $policy.PolicyParameters = $azurePolicy.properties.parameters | ConvertTo-Json -Depth 100
            $policyList += $policy
        }
    }

    return $policyList
}
#endregion

#region add policy function
function Add-Policies {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)][PolicyDef[]]$policies,
        [Parameter(Mandatory = $false)][String]$managementGroupName
    )

    #Write-Host "##[section] Gathering all policies in Azure..."
    #$azurePolicyDefinitions = Get-AzPolicyDefinition

    Write-Host "##[section] Creating Policy Definitions..."
    $policyDefList = @()
    foreach ($policy in $Policies) {
        write-host $policy.PolicyDisplayName
        $createPolicy = @{
            "Name" = $policy.PolicyName
            "Policy" = $policy.PolicyRule
            "Parameter" = $policy.PolicyParameters
            "DisplayName" = $policy.PolicyDisplayName
            "Description" = $policy.PolicyDescription
            "Metadata" = $policy.PolicyMetadata
            "Mode" = $policy.PolicyMode
        }

        if ($managementGroupName) {
            $mgObject = @{"ManagementGroupName" = $managementGroupName}
            
            $createPolicy += $mgObject
        }

        $policyName = $createPolicy.DisplayName

        #Write-Host "##[debug] The following policy is being created/updated:"

        #Write-Host ($createPolicy | Out-String)

        #New-AzPolicyDefinition @createPolicy -Verbose

        Try {
            #if(!($azPolicyDefinitions | Where-Object { $_.Properties.DisplayName -eq $policyName}))
            #{
                New-AzPolicyDefinition @createPolicy -Verbose -ErrorAction Stop
                Write-Host "##[debug] Policy definition for $policyName was created..."
            #} else {
            #    Set-AzPolicyDefinition @createPolicy -Verbose -ErrorAction Stop
            #    Write-Host "##[debug] Policy definition for $policyName was updated..."
            #}
        } Catch { 
            Write-Error $_
            Write-Host "##[debug] Policy definition for $policyName failed..."
        }

    }
}
#endregion

#region create policy definition function
Function Create-PolicyDef
{
    param (
        [Parameter(Mandatory=$true)][string]$rootFolder,
        [Parameter(Mandatory=$false)][AllowEmptyString()][string]$managementGroupName = "",
        [Parameter(Mandatory=$false)][string[]]$modifiedPolicies
    )

    #Write-Host "##[section]Formatting list of policy folders..."

    if(!($managementGroupName))
    {
        $managementGroupName = Get-ManagementGroupName
    } else {
        $managementGroupName = Get-ManagementGroupName -managementGroupName $managementGroupName
    }


    if(!($modifiedPolicies)) {
        $policies = Get-Policies -rootDir $rootFolder

    } else {
        $policies = Get-ModifiedPolicies -modifiedPolicies $modifiedPolicies `
                             -rootDir $rootFolder
    }

    #Write-Host "    ##[debug] Names:" $policies.PolicyName
    Write-Host "    ##[debug] Count:" $policies.count

    Write-Host "##[section] Executing create policy..."

    $policyDefinitions = Add-Policies -Policies $policies -ManagementGroupName $managementGroupName

}
#endregion

#region Main
if(!($ManagementGroupName))
{
    $ManagementGroupName = Get-AzManagementGroupName
} else {
    $ManagementGroupName = Get-AzManagementGroupName -managementGroupName $ManagementGroupName
}

if($RemoveExistingPolicies -eq $true) { Remove-CustomPolicies -All:$RemoveAllPolicies -ManagementGroupName $ManagementGroupName }

$policyList = Get-Policies -rootDir $RootPolicyFolder

Add-Policies -Policies $policyList -managementGroupName $ManagementGroupName
#endregion
