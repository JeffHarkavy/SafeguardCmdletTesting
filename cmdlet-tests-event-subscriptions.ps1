try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Event Subscription Creation Tests"
# ===== Covered Commands =====
# Edit-SafeguardEventSubscription
# Find-SafeguardAsset
# Find-SafeguardEventSubscription
# Get-SafeguardEventSubscription
# New-SafeguardAsset
# New-SafeguardEventSubscription
# Remove-SafeguardAsset
# Remove-SafeguardEventSubscription
#
$blockInfo = testBlockHeader "begin" $TestBlockName
try {
   $removeAsset = $false

   $eventAsset = Find-SafeguardAsset -SearchString "$assetName"
   if ($null -eq $eventAsset -or $eventAsset.Length -eq 0) {
      $eventAsset = New-SafeguardAsset -DisplayName "$assetName" -Platform "Ubuntu 20.04 x86_64" -NetworkAddress "1.2.3.4" `
         -ServiceAccountCredentialType Password -ServiceAccountName funcacct -ServiceAccountPassword $secUserPassword `
         -NoSshHostKeyDiscovery
      infoResult "New-SafeguardAsset"  "$($eventAsset.Name) added for event subscription. Will be removed when done."
      $removeAsset = $true
   } else {
      infoResult "Find-SafeguardAsset"  "Using existing $assetName for event subscription"
   }
   $subscription = New-SafeguardEventSubscription -ObjectTypeToSubscribe Asset -ObjectIdToSubscribe $eventAsset.Name -SubscriptionEvent AssetCreated
   goodResult "New-SafeguardEventSubscription" "Successfully created event Subscription Id=$($subscription.Id)"
   $subscriptionId = $subscription.Id

   $subscription = Edit-SafeguardEventSubscription -SubscriptionId $subscriptionId -Description "Edited subscription description"
   goodResult "Edit-SafeguardEventSubscription" "Successfully edited event Subscription Description '$($subscription.Description)'"

   try {
      $getSubscription = Get-SafeguardEventSubscription -SubscriptionId $subscription.Id
      goodResult "Get-SafeguardEventSubscription" "Successfully retrieved Subscription Id=$subscriptionId"
   } catch {
      badResult "Get-SafeguardEventSubscription" "Did NOT retrieve subscription Id=$subscriptionId" $_.Exception
   }

   $findSubscription = Find-SafeguardEventSubscription -SearchString edited
   if ($null -ne $subscription -or $findSubscription.Length -eq 0) {
      goodResult "Find-SafeguardEventSubscription" "Successfully found event Subscription Id=$($findSubscription.Id)'"
   } else {
      badResult "Find-SafeguardEventSubscription" "Did NOT find subscription Id=$subscriptionId"
   }
   Remove-SafeguardEventSubscription -SubscriptionId $subscriptionID > $null
   goodResult "Remove-SafeguardEventSubscription" "Successfully removed event Subscription Id=$($subscription.Id)'"
} catch {
   badResult "Event Subscription general" "Unexpected error testing Event Subscriptions"  $_.Exception
} finally {
   if ($subscriptionId) { try { Remove-SafeguardEventSubscription -SubscriptionId $subscriptionId > $null} catch {} }
   try { if ($removeAsset) {Remove-SafeguardAsset -AssetToDelete $assetName > $null} } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo
