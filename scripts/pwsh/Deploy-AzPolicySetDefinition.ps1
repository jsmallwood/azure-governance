[CmdletBinding()]
param(
    [String] $RootPolicyFolder = "D:\github\azure-governance\policy\initiatives\definitions\tags",
    [String] $ManagementGroupName = 'a8b7290b-8363-4333-81d5-041ac3b2c81c',
    [Bool] $WritePolicySetDefinition = $false
)

#region Helper Functions
function New-WildCardSearchString
{
    param(
        [String] $String = $null
    )

    $fillerWords = ("a", "the", "of", "from", 'if')

    $string.Split(' ') | % {
        $word = $_
        if (!($fillerWords | Where-Object { $_ -eq $word } ))
        {
            if($searchString -eq "")
            {
                $searchString += $word
            } else {
                $searchString += "*$word"
            }
        } 
    }

    return $searchString

}

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

#region Policy Set Functions
function Get-AzPolicyDefinitionIds
{
    param (
        $policySetDefinition
    )

    $searchString = $null
    
    $builtInPolicies = (Get-AzPolicyDefinition -Builtin)
    $customPolicies = (Get-AzPolicyDefinition -Custom -ManagementGroupName $ManagementGroupName)

    foreach ($policy in $policySetDefinition.properties.policyDefinitions)
    {
        Write-host $policy.policyDefinitionReferenceId -ForegroundColor Blue
        $searchString = New-WildCardSearchString -String $policy.policyDefinitionReferenceId

        Write-Host "SearchString: $searchString" -ForegroundColor Magenta
        if ( $builtInPolicies | Where-Object {$_.Properties.DisplayName -like $searchString } )
        {
            $policyDefinitionId = ($builtInPolicies | Where-Object {$_.Properties.DisplayName -like $searchString }).PolicyDefinitionId
            if($policyDefinitionId.Count -gt 1) { $policyDefinitionId = $policyDefinitionId[0] }
        } else
        {
            $policyDefinitionId = ($customPolicies | Where-Object { $_.Properties.DisplayName -like $searchString }).PolicyDefinitionId
            if($policyDefinitionId.Count -gt 1) { $policyDefinitionId = $policyDefinitionId[0] }
        }

        Write-Host "Originial PolicyDefinitionReferenceId: $($policy.policyDefinitionReferenceId)" -ForegroundColor Green

        if($policy.groupNames)
        {
            $policy.policyDefinitionReferenceId = "$($policy.groupNames.Replace('Tag - ', '')) - $($policy.policyDefinitionReferenceId)"
        }
        Write-Host "New PolicyDefinitionReferenceId: $($policy.policyDefinitionReferenceId)" -ForegroundColor Cyan
        Write-Host "PolicyDefinitionId: $policyDefinitionId" -ForegroundColor Yellow
        Write-Host "PolicyDefinitionId Count: $($policyDefinitionId.count)" -ForegroundColor Red       

        $policyDefinitionId = $null
        $searchString = $null
    }

    return $policySetDefinition
}

function Deploy-AzPolicySetDefinition
{
    param (
        $Definition,
        [String] $ManagementGroupName
    )

    $policyDefinition = $Definition.properties.policyDefinitions | ConvertTo-Json -Depth 100
    $groupDefinition = $Definition.properties.policyDefinitionGroups | ConvertTo-Json -Depth 100
    $metadata = $Definition.properties.metadata | ConvertTo-Json -Depth 100
    $parameterDefinition = $Definition.properties.parameters | ConvertTo-Json -Depth 100

    if(!(Get-AzPolicySetDefinition -Name $Definition.properties.displayName -ManagementGroupName $ManagementGroupName))
    {
        New-AzPolicySetDefinition `
            -Name $Definition.properties.displayName `
            -DisplayName $Definition.properties.displayName `
            -Description $Definition.properties.description `
            -Metadata $metadata `
            -PolicyDefinition $policyDefinition `
            -Parameter $parameterDefinition `
            -GroupDefinition $groupDefinition `
            -ManagementGroupName $ManagementGroupName `
            -Verbose `
            -Debug
    } else {
        Set-AzPolicySetDefinition `
            -Name $Definition.properties.displayName `
            -DisplayName $Definition.properties.displayName `
            -Description $Definition.properties.description `
            -Metadata $metadata `
            -PolicyDefinition $policyDefinition `
            -Parameter $parameterDefinition `
            -GroupDefinition $groupDefinition `
            -ManagementGroupName $ManagementGroupName `
            -Verbose `
            -Debug

    }
}

function Write-AzPolicySetDefinition
{
    [CmdletBinding()]
    param(
        $Definition,
        $Directory,
        $FileName = 'policyset_deployed.json'
    )

    $Definition | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath "$($Directory)\$($FileName)" -Confirm
}
#endregion

#region Main
if(!($ManagementGroupName))
{
    $ManagementGroupName = Get-AzManagementGroupName
} else {
    $ManagementGroupName = Get-AzManagementGroupName -managementGroupName $ManagementGroupName
}

Get-ChildItem -LiteralPath $RootPolicyFolder -File -Recurse | `
    Where-Object { ($_.FullName -match '[sS]et') -or ($_.FullName -match '[iI]nitiative') } | % {
        if((($_.Name -match "[sS]et") -or ($_.Name -match "[iI]nitiative")) -and (($_.Name -notmatch "deployed") -and ($_.Name -notmatch "[pP]arameter") -and ($_.Name -notmatch "[dD]efinition")) -and ($_.Extension -eq '.json'))
        {
            $definitionFile = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json

            $definition = Get-AzPolicyDefinitionIds -policySetDefinition $definitionFile -builtInPolicies $builtInPolicies -customPolicies $customPolicies

            $fileName = $_.DirectoryName+"\"+$_.Name.Split('.')[0]+"_deployed."+$_.Name.Split('.')[1]
            $fileName
            Create-AzPolicySetDefinition -Definition $definition -ManagementGroupName $ManagementGroupName 
            
            if($WritePolicySetDefinition -eq $True)
            {
                Write-AzPolicySetDefinition -Definition $definition -Directory $_.DirectoryName
            }
        }
}
#endregion