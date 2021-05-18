#Requires -Modules Az.Accounts, Az.Resources

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