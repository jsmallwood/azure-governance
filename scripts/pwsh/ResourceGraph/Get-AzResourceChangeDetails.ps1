Function Get-AzResourceChangeDetails
{
    param(
        [String] $ResourceId,
        [String] $ChangeId
    )
    
    begin {
        $apiVersion = "2018-09-01-preview"

        if($ChangeId -notmatch '\"')
        {
            $ChangeId = $ChangeId.Replace('"', '\"')
        }
        $path = "providers/Microsoft.ResourceGraph/resourceChangeDetails?api-version=$apiVersion"
    }
    process {
$payload = @"
{
    "resourceId": "$($ResourceId)",
    "changeId": "$($ChangeId)"
}
"@

        $objRequest = ((Invoke-AzRestMethod `
        -Path $path `
        -Method POST `
        -Payload $payload).Content | ConvertFrom-Json)
    }
    end { return $objRequest }

}