Function Export-Data
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
            [ValidateNotEmptyOrNull()]
            [string] $directory,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1)]
            [ValidateNotEmptyOrNull()]
            [string] $fileName,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=2)]
            [ValidateSet("json","csv","txt", "yaml", "xlsx", "xls")]
            [AllowEmptyString()]
            [AllowNull()]
            [string] $exportFormat = "csv",
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=3)]
            [AllowEmptyString()]
            [AllowNull()]
            [string] $dateFormat,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=4)]
            [switch] $includeDateInFileName,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=5)]
            $inputObject
    )

    begin 
    {
        #region Error Action Preference
        $errorAction = $PSBoundParameters["ErrorAction"]
        if(-not $errorAction) { $errorAction = $ErrorActionPreference }
        #endregion

        #region Bound Parameters
        $boundParameters = @{
            Verbose = $PSBoundParameters.ContainsKey("Verbose");
            Confirm = $PSBoundParameters.ContainsKey("Confirm");
            Debug = $PSBoundParameters.ContainsKey("Debug");
        }
        #endregion

        #region Variables

        if (!($dateFormat)) {
            $exportFile = "$($directory)\$($fileName)"
        } else {
            $datetime = (Get-Date).ToUniversalTime()

            if (-not !($dateFormat)) { $fileDate = $datetime.ToString($dateFormat) }

            if($includeDateInFileName) { $fileDate = $datetime.ToString("yyyy-MM-dd") }

            $exportFile = "$($directory)\$($fileDate) - $($fileName)"
        }
        #endregion

        try {
            Test-Path $directory @boundParameters -ErrorAction $errorAction
        } catch {
            try {
                New-Item $directory -ItemType Directory @boundParameters -ErrorAction $errorAction
            } catch {
                Write-Error $_
            }        
        }
    }
    process {
        try {
            Switch ($exportFormat)
            {
                "json" { $inputObject | ConvertTo-Json | Out-File "$exportFile.json" @boundParameters -ErrorAction $errorAction }
                "csv" { $inputObject | Export-Csv "$exportFile.csv" -NoTypeInformation @boundParameters -ErrorAction $errorAction }
                #"excel" { 
                default { write-host "export csv" }
            }
            return "File Export Successful: $($exportFile).$($exportFormat.ToLower())"
        } catch { Write-Error $_; "File Export Failed: $($exportFile).$($exportFormat.ToLower())" }
    }
    end { }
}

Function Get-AzRIRecommendations
{
    [CmdletBinding(
        ConfirmImpact="Medium",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=0)]
            [Alias("billingAccountName")]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $billingAccountId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=2)]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $subscriptionId,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=3)]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $resourceGroupName,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=4)]
            [ValidateSet("Single", "Shared")]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $reservationScope,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=5)]
            [ValidateSet("VirtualMachines", "SQLDatabases", "PostgreSQL", "ManagedDisk", "MySQL", "RedHat", "MariaDB", "RedisCache", "CosmosDB", "SqlDataWarehouse", "SUSELinux", "AppService", "BlockBlob", "AzureDataExplorer", "VMwareCloudSimple")]
            [AllowEmptyString()]
            [AllowNull()]
            [String] $resourceType,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=6)]
            [ValidateSet("Last7Days","Last30Days","Last60Days")]
            [AllowEmptyString()]
            [AllowNull()]
            [string] $lookBackPeriod,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=7)]
            [AllowEmptyString()]
            [AllowNull()]
            [string] $apiVersion,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=9)]
            [switch] $allResourceTypes,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=9)]
            [switch] $export
    )

    DynamicParam {
        if ($export) {
            # Need dynamic parameters for Template, Storage, Project Type
            # Set the dynamic parameters' name
            $paramExportDir = 'ExportDir' 
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 1
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            # Generate and set the ValidateSet
            #$ParameterValidateSet = (Get-PWProjectTemplates).Name 
            #$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
            # Add the ValidateSet to the attributes collection
            #$AttributeCollection.Add($ValidateSetAttribute) 
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($paramExportDir, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($paramExportDir, $RuntimeParameter) 

            # Set the dynamic parameters' name
            $paramExportFileName = 'ExportFileName'
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 2 
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute) 
            # Generate and set the ValidateSet 
            #$ParameterValidateSet = (Get-PWStorageAreaList).Name
            #$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
            # Add the ValidateSet to the attributes collection
            #$AttributeCollection.Add($ValidateSetAttribute)
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($paramExportFileName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($paramExportFileName, $RuntimeParameter)

            # Set the dynamic parameters' name
            $paramExportFormat = 'ExportFormat'
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 3 
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute) 
            # Generate and set the ValidateSet 
            #$ParameterValidateSet = (Get-PWStorageAreaList).Name
            #$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
            # Add the ValidateSet to the attributes collection
            #$AttributeCollection.Add($ValidateSetAttribute)
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($paramExportFormat, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($paramExportFormat, $RuntimeParameter)

            return $RuntimeParameterDictionary
        }
    }

    Begin {
        #region Error Action Preference
        $errorAction = $PSBoundParameters["ErrorAction"]
        if(-not $errorAction) { $errorAction = $ErrorActionPreference }
        #endregion

        #region Bound Parameters
        $boundParameters = @{
            Verbose = $PSBoundParameters.ContainsKey("Verbose");
            #Confirm = $PSBoundParameters.ContainsKey("Confirm");
            Debug = $PSBoundParameters.ContainsKey("Debug");
        }
        #endregion

        #region Default Variables
        if(!($apiVersion)) {
            $apiVersion = "2021-10-01"
        }

        $resourceTypes = @("VirtualMachines", "SQLDatabases", "PostgreSQL", "ManagedDisk", "MySQL", "RedHat", "MariaDB", "RedisCache", "CosmosDB", "SqlDataWarehouse", "SUSELinux", "AppService", "BlockBlob", "AzureDataExplorer", "VMwareCloudSimple")

        $baseFilter = "`$filter="
        #endregion

        # region Create Scope
            #region Scope Billing Account / Profile
            if (-not !($billingProfileId) -and -not !($billingAccountId))
            {
                $scope = New-ScopeBillingProfileId -billingAccountId (Get-AzBillingAccount -ExpandBillingProfile).Name -billingProfileId $billingProfileId
            } elseif (!($billingAccountId) -and -not !($billingProfileId)) {
                $scope = New-ScopeBillingProfileId -billingAccountId (Get-AzBillingAccount -ExpandBillingProfile).Name -billingProfileId $billingProfileId
            } elseif (-not !($billingAccountId) -and !($billingProfileId)) {
                $scope = New-ScopeBillingAccountId -billingAccountId $billingAccountId
            }
            #endregion

            #region Scope Subscription / Resource Group
            if (-not !($subscriptionId) -and -not !($resourceGroupName)) {
                $scope = New-ScopeResourceGroupName -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName
            } elseif (-not !($subscriptionId) -and !($resourceGroupName)) {
                $scope = New-ScopeSubscriptionId -subscriptionId $subscriptionId
            } elseif (!($subscriptionId) -and -not !($resourceGroupName)) {
                Write-Error "The SubscriptionId must be specified when using a ResourceGroupName"
            }
            #endregion

            #region Default Scope - Billing Account
            if(!($scope)) { $scope = New-ScopeBillingAccountId -billingAccountId (Get-AzBillingAccount -ExpandBillingProfile).Name }
            #endregion

        #endregion

        #region Create Filter
        if(-not !($reservationScope) -or -not !($resourceType) -or -not !($lookBackPeriod))
        {
            if (-not !($reservationScope) -and (!($resourceType) -or !($lookBackPeriod))) {
                $filter = "$($baseFilter)properties/scope eq '$reservationScope'"
            } elseif (-not !($reservationScope) -and -not !($resourceType) -and !($lookBackPeriod)) {
                $filter = "$($baseFilter)properties/scope eq '$reservationScope' AND properties/resourceType eq '$resourceType'"
            } elseif (-not !($reservationScope) -and !($resourceType) -and -not !($lookBackPeriod)) {
                $filter = "$($baseFilter)properties/scope eq '$reservationScope' AND properties/lookBackPeriod eq '$lookBackPeriod'"
            } elseif (!($reservationScope) -and -not !($resourceType) -and !($lookBackPeriod)) { 
                $filter = "$($baseFilter)properties/resourceType eq '$resourceType'"
            } elseif (!($reservationScope) -and -not !($resourceType) -and -not !($lookBackPeriod)) { 
                $filter = "$($baseFilter)properties/resourceType eq '$resourceType' AND properties/lookBackPeriod eq '$lookBackPeriod'"
            } elseif(!($reservationScope) -and !($resourceType) -and -not !($lookBackPeriod)) {
                $filter = "$($baseFilter)properties/lookBackPeriod eq '$lookBackPeriod'"
            } else {
                $filter = "$($baseFilter)properties/scope eq '$reservationScope' AND properties/resourceType eq '$resourceType' AND properties/lookBackPeriod eq '$lookBackPeriod'"
            }
        }
        #endregion

        #region Create Path

        if(!($reservationScope) -or !($resourceType) -or !($lookBackPeriod))
        {
            $path = "/$scope/providers/Microsoft.Consumption/reservationRecommendations?&api-version=$apiVersion"
        } else {
            $path = "/$scope/providers/Microsoft.Consumption/reservationRecommendations?$filter&api-version=$apiVersion"
        }
        #endregion
    }
    Process {

        if($allResourceTypes) {
            $result = @()
            foreach ($type in $resourceTypes)
            {
                if(-not !($reservationScope) -or -not !($lookBackPeriod))
                {
                    if(-not !($reservationScope) -and -not !($lookBackPeriod))
                    {
                        $filter = "$($baseFilter)properties/scope eq '$reservationScope' AND properties/resourceType eq '$type' AND properties/lookBackPeriod eq '$lookBackPeriod'"
                    } 
                    elseif (-not !($reservationScope) -and !($lookBackPeriod))
                    {
                        $filter = "$($baseFilter)properties/scope eq '$reservationScope' AND properties/resourceType eq '$type'"
                    }
                    elseif (!($reservationScope) -and -not !($lookBackPeriod))
                    {
                        $filter = "$($baseFilter)properties/resourceType eq '$type' AND properties/lookBackPeriod eq '$lookBackPeriod'"
                    }
                }
                else 
                {
                    $filter = "$($baseFilter)properties/resourceType eq '$type'"
                }

                $path = "/$scope/providers/Microsoft.Consumption/reservationRecommendations?$filter&api-version=$apiVersion"
                try {
                    $result += ((Invoke-AzRestMethod -Path $path -Method GET @boundParameters -ErrorAction $errorAction).Content | ConvertFrom-Json).value
                } catch { $result = $_ }
            }
        } else {
            try {
                $result = ((Invoke-AzRestMethod -Path $path -Method GET @boundParameters -ErrorAction $errorAction).Content | ConvertFrom-Json).value

            } Catch { $result = $_ }
        }

        Write-Verbose $path

        if ($export)
        {
                $format = $PSBoundParameters[$paramExportFormat]
                $dir = $PSBoundParameters[$paramExportDir]
                $file = $PSBoundParameters[$paramExportFileName]
                Try {
                Export-Data `
                    -inputObject $result `
                    -exportFormat $format `
                    -directory $dir `
                    -fileName $file `
                    -includeDateInFileName `
                    @boundParameters `
                    -ErrorAction $errorAction
                } Catch {
                    Write-Error $_
                }
            }

    }
    End { return $result }
}

$ExportPath = "$env:PSAzureExportDir\$($settings.ExportDir.Consumption.Reservations.Path)"

$ExportFileName = $settings.ExportFileName.Consumption.Reservations.Recommendations.Name

$objRecommendations = Get-AzRIRecommendations `
    -billingAccountId $settings.BillingAccountId `
    -reservationScope 'Single' `
    -lookBackPeriod Last7Days `
    -apiVersion $settings.ApiVersions.Billing `
    -allResourceTypes `
    -export `
    -exportFormat json `
    -exportDir $ExportPath `
    -exportFileName $ExportFileName `
    -verbose