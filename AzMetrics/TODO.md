# Analyze Virtual Machine Rightsizing

## Parameters

- [] Subscription
- [] ResourceGroup
- [] VmName
- [] ExportDir
- [] ExportFilename

## Import CSV Files

- [] Azure Usage
- [] Azure Enrollment Pricesheet
- [] Azure Virtual Machine SKUs
- [] CloudHealth File Systems
- [] CloudHealth Virtual Machine Metrics
- [] Export File

## Initialize Static Variables

- [] Azure Resource Graph Page Size
- [] Date Time
- [] IP Address Regex

## Initialize Variables

- [] Drive Letters
- [] Results
- [] Get Subscriptions
- [] Get Virtual Machine(s)
- [] Get OS Disk(s)
- [] Get Data Disk(s)

## Get Virtual Machine

1. Get Virtual Machine Tags
2. Get Virtual Machine Current SKU
3. Get Virtual Machine Metrics from CloudHealth

- [] Max CPU %
- [] Avg CPU %
- [] Max Memory (%)
- [] Avg Memory (%)

- []

4. Get Virtual Machine Metrics from Azure (CSV)

- []

## Get Virtual Machine SKUs (Get-AzVmSkus.ps1)

1. Get Virtual Machine SKUs
2. Write Function to Get Ephermeral Disk Supported Skus
3. Write Function to get Temp Disk supported skus
4. Write Function to add price to skus


## Get OS Disk

1. Get File System Data From CloudHealth for C:\
2. Get Disk Metrics from Azure (CSV)

- [] Get-AzVmOsDiskBandwdithConsumedPercentage (MAX)
- [] Get-AzVmOsDiskIOPsConsumedPercentage (AVG)
- [] Get-AzVmOsDiskIOPsConsumedPercentage (MAX)
- [] Get-AzVmOsDiskIOPsConsumedPercentage (AVG)
- [] Get-AzVmOsDiskQueueDepth (MAX)
- [] Get-AzVmOsDiskQueueDepth (AVG)

## Get Data Disks

1. Get File System Data from CloudHealth for Drive

2. Get Disk Metrics from Azure (CSV)







# Custom Functions

### Get File System



Get Virtual Machine
- Get All Disks
    - Get All Disk Metrics

Get VM Sku

Get VM Metrics

Compare Total IOPS to VM Sku Max IOPs

