
#required Parameters
$tagName = 'CostCenter'

#region Optional Parameters
$billingScopeName = ''
$billingScopeId = ''
[string[]] $contactEmails = 'jason@azure-demos.com', 'jason.l.smallwood@gmail.com'
$roleDefinition = 'Cost Management Reader'

$Location = 'East US2'
#[switch] $includeApplicationOwner
#[switch] $includeBusinessOwner
#[switch] $includeStakeholders

$amount = '1000'
$firstThreshold = "75"
$secondThreshold = "90"
$thirdThreshold = "100"
$timeGrain = "Monthly"
$thresholdType = "Actual"

$startDate = "$((Get-Date).ToUniversalTime().Month)/01/$((Get-Date).ToUniversalTime().Year)"
$endDate = "$((Get-Date).ToUniversalTime().Month)/01/$((Get-Date).AddYears(3).ToUniversalTime().Year)"



begin {

#region Create Contact Emails if Null
<#
if(!($contactEmails))
{
    try {
        
    } catch {

    }
}
#>

<#
    Grab all Cost Management Reader E-mail Addresses
#>
<#
if (-not !($roleDefinition))
{
    Get-AzRoleAssignment -RoleDefinitionName $roleDefinition
}

#>

#endregion


#region Create Billing Scope Object

$objBillingScope = Get-AzBillingAccount -ExpandBillingProfile
$objBillingScope.Name
#endregion

#region Create Management Group Object
Try {
    If (($mgmtGroupName -eq 'Tenant Root Group') -or !($mgmtGroupName))
    {
        $objMgmtGroup = Get-AzManagementGroup | Where { $_.DisplayName -eq 'Tenant Root Group' } 
    } Else {
        $objMgmtGroup = Get-AzManagementGroup | Where { $_.DisplayName -eq $mgmtGroupName } 
    }
} Catch {
    Write-Error $_
}
#endregion

# API Version
$apiVersion = '2021-10-01'

}
#endregion


for($i=0; $i -le $contactEmails.Count-1; $i++)
{
    if ($i -eq 0)
    {
        $payloadContactEmails = "[ `"$($contactEmails[$i])`", "
        write-host "i = 0"
        write-host $payloadContactEmails
        sleep -Seconds 3
    }

    elseif (($i -gt 0) -and ($i -lt $contactEmails.Count-1))
    {
        write-host "i gt 0 and lt count"
        $payloadContactEmails += " `"$($contactEmails[$i])`", "
        write-host $payloadContactEmails
        sleep -Seconds 3

    } elseif ($i -eq $contactEmails.Count-1) {
        $payloadContactEmails += " `"$($contactEmails[$i])`" ] "
        write-host $payloadContactEmails
        sleep -Seconds 3
    }
}


#process {

$objTagValues = (Get-AzTag -Name $tagName).Values.Name

foreach ($tagValue in $objTagValues)
{

$payload = @" 
{
    "properties": {
        "category": "Cost",
        "amount": "$amount",
        "timeGrain": "$timeGrain",
        "timePeriod": {
            "startDate": "$startDate",
            "endDate": "$endDate"
        },
        "filter": {
            "tags": {
                        "name": "$tagName",
                        "operator": "In",
                        "values": [ "$tagValue" ]
                    }
                },
                "notifications": {
                    "NotificationForExceededBudget1": {
                        "enabled": true,
                        "operator": "GreaterThan",
                        "threshold": "$firstThreshold",
                        "contactEmails": $payloadContactEmails,
                        "thresholdType": "$thresholdType"
                    },
                    "NotificationForExceededBudget2": {
                        "enabled": true,
                        "operator": "GreaterThan",
                        "threshold": "$secondThreshold",
                        "contactEmails": $payloadContactEmails,
                        "thresholdType": "$thresholdType"
                    },
                    "NotificationForExceededBudget3": {
                        "enabled": true,
                        "operator": "GreaterThan",
                        "threshold": "$thirdThreshold",
                        "contactEmails": $payloadContactEmails,
                        "thresholdType": "$thresholdType"
                    },
                    "NotificationForForecastedBudget": {
                        "enabled": true,
                        "operator": "GreaterThan",
                        "threshold": "120",
                        "contactEmails": $payloadContactEmails,
                        "thresholdType": "Forecasted"
                    }
                }
    }
}
"@

$payload

#$jsonPayload = $payload | ConvertTo-Json -Depth 10

$scope = "/providers/Microsoft.Billing/billingAccounts/$($objBillingScope.Name)"

$path = "$scope/providers/Microsoft.Consumption/budgets/$tagName-$tagValue`?api-version=$apiVersion"

Invoke-AzRestMethod -Method PUT -Path $path -Payload $payload -Debug

}
