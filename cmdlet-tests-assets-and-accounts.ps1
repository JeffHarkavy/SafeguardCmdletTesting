try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Assets, Accounts, and Groups Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# ===== Covered Commands =====
# Add-SafeguardAccountGroupMember
# Add-SafeguardAssetGroupMember
# Edit-SafeguardAccountGroup
# Edit-SafeguardAsset
# Edit-SafeguardAssetAccount
# Edit-SafeguardAssetGroup
# Find-SafeguardAsset
# Find-SafeguardAssetAccount
# Get-SafeguardAccountGroupMember
# Get-SafeguardAsset
# Get-SafeguardAssetAccount
# Get-SafeguardAssetGroupMember
# New-SafeguardAsset
# New-SafeguardAssetAccount
# Remove-SafeguardAccountGroupMember
# Remove-SafeguardAssetAccount
# Remove-SafeguardAssetGroupMember
# 
# TODO - stubbed code
#Invoke-SafeguardAssetAccountPasswordChange
#Invoke-SafeguardAssetSshHostKeyDiscovery
#New-SafeguardAssetAccountRandomPassword
#Set-SafeguardAssetAccountPassword
#Test-SafeguardAsset
#Test-SafeguardAssetAccountPassword

try {
   try {
      $asset = Get-SafeguardAsset -AssetToGet "$($DATA.assetName)"
      infoResult "Get-SafeguardAsset" "Asset $($DATA.assetName) already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $asset = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform "Ubuntu 18.04 LTS x86_64" -NetworkAddress "1.2.3.4" `
            -ServiceAccountCredentialType Password -ServiceAccountName funcacct -ServiceAccountPassword $DATA.secUserPassword `
            -NoSshHostKeyDiscovery
         goodResult "New-SafeguardAsset" "$($asset.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardAsset" "Unexpected error fetching Asset $($DATA.assetName)"  $_.Exception
         throw $_.Exception
      }
   }
   $asset = Edit-SafeguardAsset -AssetToEdit $DATA.assetName -Description "Description for $assetname"
   if (-not $asset.Description -contains "Description for $($DATA.assetName)") {
      badResult "Edit-SafeguardAsset" "failed for $($DATA.assetName)"
   }

   $found = Find-SafeguardAsset $DATA.assetName
   if ($found) { goodResult "Find-SafeguardAsset" "found $($DATA.assetName)" }
   else { badResult "Find-SafeguardAsset" "DID NOT find $($DATA.assetName)" }

   try {
      $assetAccount = New-SafeguardAssetAccount -ParentAsset "$($DATA.assetName)" -NewAccountName "$($DATA.assetAccountName)"
      goodResult "New-SafeguardAssetAccount" "$($assetAccount.Name) successfully added"

      $deleteAccountName = $DATA.assetAccountName + "_delete"
      $assetAccount = New-SafeguardAssetAccount -ParentAsset "$($DATA.assetName)" -NewAccountName "$deleteAccountName"
      Remove-SafeguardAssetAccount -AssetToUse $DATA.assetName -AccountToDelete "$deleteAccountName" > $null
      goodResult "Remove-SafeguardAssetAccount" "$($assetAccount.Name)_deleteme successfully added and removed"
   }
   catch {
      if ($_.Exception.ErrorCode -eq 50002) {
         infoResult "New-SafeguardAssetAccount" "Asset Account $($DATA.assetName)/$($DATA.assetAccountName) already exists"
      }
      else {
         badResult "general" "Unexpected error creating Asset Account $($DATA.assetName)/$($DATA.assetAccountName)"  $_.Exception
         throw $_.Exception
      }
   }
   $assetAccount = Get-SafeguardAssetAccount -AccountToGet "$($DATA.assetAccountName)" -AssetToGet "$($DATA.assetName)"
   $assetAccount = Edit-SafeguardAssetAccount -AssetToEdit $DATA.assetName -AccountToEdit $DATA.assetAccountName -Description "Description for $assetname/$($DATA.assetAccountName)"
   if (-not $assetAccount.Description -contains "Description for") {
      badResult "Edit-SafeguardAssetAccount" "failed for $($DATA.assetName)/$($DATA.assetAccountName)"
   }

   $found = Find-SafeguardAssetAccount $DATA.assetAccountName
   if ($found) { goodResult "Find-SafeguardAssetAccount" "found $($DATA.assetAccountName)" }
   else { badResult "Find-SafeguardAssetAccount" "DID NOT find $($DATA.assetAccountName)" }

   try {
      try {
         $assetGroup = (Get-SafeguardAssetGroup -GroupToGet "$($DATA.assetGroupName)")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $assetGroup = New-SafeguardAssetGroup -Name "$($DATA.assetGroupName)" -Description "Description for $($DATA.assetGroupName)"
         }
         else {
            badResult "Get-SafeguardAssetGroup" "Unexpected error fetching $($DATA.assetGroupName)"  $_.Exception
            throw $_.Exception
         }
      }
      Add-SafeguardAssetGroupMember -Group $assetGroup.Name -AssetList $asset.Name > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($asset.Name -in $groupMembers) {
         goodResult "Add-SafeguardAssetGroupMember" "$($asset.Name) successfully added to $($assetGroup.Name)"
      }
      else {
         badResult "Add-SafeguardAssetGroupMember" "$($asset.Name) NOT found in $($assetGroup.Name)"
      }

      Remove-SafeguardAssetGroupMember -Group $assetGroup.Name -AssetList $asset.Name > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($null -eq $groupMembers -or -not $asset.Name -in $groupMembers) {
         goodResult "Remove-SafeguardAssetGroupMember" "$($asset.Name) successfully removed to $($assetGroup.Name)"
      }
      else {
         badResult "Remove-SafeguardAssetGroupMember" "$($asset.Name) NOT removed from $($assetGroup.Name)"
      }

      Edit-SafeguardAssetGroup -GroupToEdit $assetGroup.Name -AssetList $asset.Name -Operation add > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($asset.Name -in $groupMembers) {
         goodResult "Edit-SafeguardAssetGroup" "$($asset.Name) successfully edited to add to $($assetGroup.Name)"
      }
      else {
         badResult "Edit-SafeguardAssetGroup" "$($asset.Name) NOT successfully edited to add to $($assetGroup.Name)"
      }
   }
   catch {
      badResult "general" "Error adding $($asset.Name) to group $($assetGroup.Name)" $_.Exception
   }

   try {
      try {
         $accountGroup = (Get-SafeguardAccountGroup -GroupToGet "$($DATA.accountGroupName)")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $accountGroup = New-SafeguardAccountGroup -Name "$($DATA.accountGroupName)" -Description "Description for $($DATA.accountGroupName)"
         }
         else {
            badResult "Get-SafeguardAccountGroup" "Unexpected error fetching $($DATA.accountGroupName)"  $_.Exception
            throw $_.Exception
         }
      }

      $acct = "$($asset.Name)\$($assetAccount.Name)"
      Add-SafeguardAccountGroupMember -Group $accountGroup.Name -AccountList $acct > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($assetAccount.Name -in $groupMembers) {
         goodResult "Add-SafeguardAccountGroupMember" "$($assetAccount.Name) successfully added to $($accountGroup.Name)"
      }
      else {
         badResult "Add-SafeguardAccountGroupMember" "$($assetAccount.Name) NOT found in $($accountGroup.Name)"
      }

      Remove-SafeguardAccountGroupMember -Group $accountGroup.Name -AccountList $acct > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($null -eq $groupMembers -or -not $assetAccount.Name -in $groupMembers) {
         goodResult "Remove-SafeguardAccountGroupMember" "$($assetAccount.Name) successfully removed to $($accountGroup.Name)"
      }
      else {
         badResult "Remove-SafeguardAccountGroupMember" "$($assetAccount.Name) NOT removed from $($accountGroup.Name)"
      }

      Edit-SafeguardAccountGroup -GroupToEdit $accountGroup.Name -AccountList $acct  -Operation add > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($assetAccount.Name -in $groupMembers) {
         goodResult "Edit-SafeguardAccountGroup" "$($assetAccount.Name) successfully edited to add to $($accountGroup.Name)"
      }
      else {
         badResult "Edit-SafeguardAccountGroup" "$($assetAccount.Name) NOT successfully edited to add to $($accountGroup.Name)"
      }
   }
   catch {
      badResult "general" "Error adding $($assetAccount.Name) to group $($accountGroup.Name)" $_.Exception
   }
} catch {
   badResult "Groups general" "Unexpected error in Assets, Accounts, and Groups tests" $_.Exception
} finally {
   try { Remove-SafeguardAsset -AssetToDelete "$($DATA.assetName)" > $null } catch {}
   try { Remove-SafeguardAssetGroup -GroupToDelete "$($DATA.assetGroupName)" > $null } catch {}
   try { Remove-SafeguardAccountGroup -GroupToDelete "$($DATA.accountGroupName)" > $null } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo
