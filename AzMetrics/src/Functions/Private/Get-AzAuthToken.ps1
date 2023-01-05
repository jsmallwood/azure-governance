Function Get-AzAuthToken
{
    [CmdletBinding(
        ConfirmImpact="Low",
        DefaultParameterSetName=$null,
        HelpUri=$null,
        SupportsPaging=$false,
        PositionalBinding=$true
    )]

    param(
        [String] $SubscriptionId
    )

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

        if($SubscriptionId) { Select-AzSubscription -Subscription $SubscriptionId @boundParameters -ErrorAction $errorAction}
    }

    Process {
        $context = Get-AzContext @boundParameters -ErrorAction $errorAction
        $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
        $azureRmProfileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
        $token = $azureRmProfileClient.AcquireAccessToken($context.Subscription.TenantId).AccessToken;
    }

    End {
        Return $token
    }
}