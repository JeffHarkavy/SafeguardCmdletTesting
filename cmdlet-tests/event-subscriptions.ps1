try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.EventSubscriptions
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:subscriptionId = ""
$script:removeAsset = $false

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   if ($script:subscriptionId) { try { Remove-SafeguardEventSubscription -SubscriptionId $script:subscriptionId -ErrorAction SilentlyContinue > $null} catch {} }
   try { if ($script:removeAsset) {Remove-SafeguardAsset -AssetToDelete $DATA.assetName -ErrorAction SilentlyContinue > $null} } catch {}
}

try {
   $eventAsset = Find-SafeguardAsset -SearchString "$($DATA.assetName)"
   if (-not $eventAsset) {
      $eventAsset = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform "Ubuntu 20.04 x86_64" -NetworkAddress "1.2.3.4" `
         -ServiceAccountCredentialType Password -ServiceAccountName funcacct -ServiceAccountPassword $DATA.secUserPassword `
         -NoSshHostKeyDiscovery
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardAsset"; message = "$($eventAsset.Name) added for event subscription. Will be removed when done."; })
      $script:removeAsset = $true
   } else {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAsset"; message = "Using existing $($DATA.assetName) for event subscription"; })
   }
   $subscription = New-SafeguardEventSubscription -ObjectTypeToSubscribe Asset -ObjectIdToSubscribe $eventAsset.Name -SubscriptionEvent AssetCreated
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardEventSubscription"; message = "Successfully created event Subscription Id=$($subscription.Id)"; })
   $script:subscriptionId = $subscription.Id

   $subscription = Edit-SafeguardEventSubscription -SubscriptionId $script:subscriptionId -Description "Edited subscription description"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardEventSubscription"; message = "Successfully edited event Subscription Description '$($subscription.Description)'"; })

   try {
      $getSubscription = Get-SafeguardEventSubscription -SubscriptionId $subscription.Id
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardEventSubscription"; message = "Successfully retrieved Subscription Id=$script:subscriptionId"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardEventSubscription"; message = "Did NOT retrieve subscription Id=$script:subscriptionId"; ex = $_; })
   }

   $findSubscription = Find-SafeguardEventSubscription -SearchString edited
   if ($findSubscription) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardEventSubscription"; message = "Successfully found event Subscription Id=$($findSubscription.Id)'"; })
   } else {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardEventSubscription"; message = "Did NOT find subscription Id=$script:subscriptionId"; })
   }
   Remove-SafeguardEventSubscription -SubscriptionId $subscriptionID > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardEventSubscription"; message = "Successfully removed event Subscription Id=$($subscription.Id)'"; })

   $local:categories = Get-SafeguardEventCategory
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardEventCategory"; message = "Successfully retrieved event categories"; })
   $GLOBALS.formatTable(@{ output = $local:categories; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Event Subscription general"; message = "Unexpected error testing Event Subscriptions" ; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

