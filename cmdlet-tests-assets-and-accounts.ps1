try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
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
writeCallHeader "Running Assets, Accounts, and Groups Tests"
# TODO - stubbed code
#Invoke-SafeguardAssetAccountPasswordChange
#Invoke-SafeguardAssetSshHostKeyDiscovery
#New-SafeguardAssetAccountRandomPassword
#Set-SafeguardAssetAccountPassword
#Test-SafeguardAsset
#Test-SafeguardAssetAccountPassword
try {
   try {
      $asset = Get-SafeguardAsset -AssetToGet "$assetName"
      infoResult "Get-SafeguardAsset"  "Asset $assetName already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $asset = New-SafeguardAsset -DisplayName "$assetName" -Platform "Ubuntu 20.04 x86_64" -NetworkAddress "1.2.3.4" `
            -ServiceAccountCredentialType Password -ServiceAccountName funcacct -ServiceAccountPassword $secUserPassword `
            -NoSshHostKeyDiscovery
         goodResult "New-SafeguardAsset"  "$($asset.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardAsset"  "Unexpected error fetching Asset $assetName"  $_.Exception
         throw $_.Exception
      }
   }
   $asset = Edit-SafeguardAsset -AssetToEdit $assetName -Description "Description for $assetname"
   if (-not $asset.Description -contains "Description for $assetName") {
      badResult "Edit-SafeguardAsset"  "failed for $assetName"
   }

   $found = Find-SafeguardAsset $assetName
   if ($null -ne $found) {
      goodResult "Find-SafeguardAsset"  "found $assetName"
   }
   else {
      badResult "Find-SafeguardAsset"  "DID NOT find $assetName"
   }

   try {
      $assetAccount = New-SafeguardAssetAccount -ParentAsset "$assetName" -NewAccountName "$assetAccountName"
      goodResult "New-SafeguardAssetAccount"  "$($assetAccount.Name) successfully added"

      $deleteAccountName = $assetAccountName + "_delete"
      $assetAccount = New-SafeguardAssetAccount -ParentAsset "$assetName" -NewAccountName "$deleteAccountName"
      Remove-SafeguardAssetAccount -AssetToUse $assetName -AccountToDelete "$deleteAccountName" > $null
      goodResult "Remove-SafeguardAssetAccount"  "$($assetAccount.Name)_deleteme successfully added and removed"
   }
   catch {
      if ($_.Exception.ErrorCode -eq 50002) {
         infoResult "New-SafeguardAssetAccount"  "Asset Account $assetName/$assetAccountName already exists"
      }
      else {
         badResult "general"  "Unexpected error creating Asset Account $assetName/$assetAccountName"  $_.Exception
         throw $_.Exception
      }
   }
   $assetAccount = Get-SafeguardAssetAccount -AccountToGet "$assetAccountName" -AssetToGet "$assetName"
   $assetAccount = Edit-SafeguardAssetAccount -AssetToEdit $assetName -AccountToEdit $assetAccountName -Description "Description for $assetname/$assetAccountName"
   if (-not $assetAccount.Description -contains "Description for") {
      badResult "Edit-SafeguardAssetAccount"  "failed for $assetName/$assetAccountName"
   }

   $found = Find-SafeguardAssetAccount $assetAccountName
   if ($null -ne $found) {
      goodResult "Find-SafeguardAssetAccount"  "found $assetAccountName"
   }
   else {
      badResult "Find-SafeguardAssetAccount"  "DID NOT find $assetAccountName"
   }

   try {
      try {
         $assetGroup = (Get-SafeguardAssetGroup -GroupToGet "$groupname")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $assetGroup = New-SafeguardAssetGroup -Name "$groupname" -Description "Description for $groupname"
         }
         else {
            badResult "Get-SafeguardAssetGroup"  "Unexpected error fetching $groupname"  $_.Exception
            throw $_.Exception
         }
      }
      Add-SafeguardAssetGroupMember -Group $assetGroup.Name -AssetList $asset.Name > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($asset.Name -in $groupMembers) {
         goodResult "Add-SafeguardAssetGroupMember"  "$($asset.Name) successfully added to $($assetGroup.Name)"
      }
      else {
         badResult "Add-SafeguardAssetGroupMember"  "$($asset.Name) NOT found in $($assetGroup.Name)"
      }

      Remove-SafeguardAssetGroupMember -Group $assetGroup.Name -AssetList $asset.Name > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($null -eq $groupMembers -or -not $asset.Name -in $groupMembers) {
         goodResult "Remove-SafeguardAssetGroupMember"  "$($asset.Name) successfully removed to $($assetGroup.Name)"
      }
      else {
         badResult "Remove-SafeguardAssetGroupMember"  "$($asset.Name) NOT removed from $($assetGroup.Name)"
      }

      Edit-SafeguardAssetGroup -GroupToEdit $assetGroup.Name -AssetList $asset.Name -Operation add > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($asset.Name -in $groupMembers) {
         goodResult "Edit-SafeguardAssetGroup"  "$($asset.Name) successfully edited to add to $($assetGroup.Name)"
      }
      else {
         badResult "Edit-SafeguardAssetGroup"  "$($asset.Name) NOT successfully edited to add to $($assetGroup.Name)"
      }
   }
   catch {
      badResult "general"  "Error adding $($asset.Name) to group $($assetGroup.Name)" $_.Exception
   }

   try {
      try {
         $accountGroup = (Get-SafeguardAccountGroup -GroupToGet "$groupname")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $accountGroup = New-SafeguardAccountGroup -Name "$groupname" -Description "Description for $groupname"
         }
         else {
            badResult "Get-SafeguardAccountGroup"  "Unexpected error fetching $groupname"  $_.Exception
            throw $_.Exception
         }
      }

      $acct = "$($asset.Name)\$($assetAccount.Name)"
      Add-SafeguardAccountGroupMember -Group $accountGroup.Name -AccountList $acct > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($assetAccount.Name -in $groupMembers) {
         goodResult "Add-SafeguardAccountGroupMember"  "$($assetAccount.Name) successfully added to $($accountGroup.Name)"
      }
      else {
         badResult "Add-SafeguardAccountGroupMember"  "$($assetAccount.Name) NOT found in $($accountGroup.Name)"
      }

      Remove-SafeguardAccountGroupMember -Group $accountGroup.Name -AccountList $acct > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($null -eq $groupMembers -or -not $assetAccount.Name -in $groupMembers) {
         goodResult "Remove-SafeguardAccountGroupMember"  "$($assetAccount.Name) successfully removed to $($accountGroup.Name)"
      }
      else {
         badResult "Remove-SafeguardAccountGroupMember"  "$($assetAccount.Name) NOT removed from $($accountGroup.Name)"
      }

      Edit-SafeguardAccountGroup -GroupToEdit $accountGroup.Name -AccountList $acct  -Operation add > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($assetAccount.Name -in $groupMembers) {
         goodResult "Edit-SafeguardAccountGroup"  "$($assetAccount.Name) successfully edited to add to $($accountGroup.Name)"
      }
      else {
         badResult "Edit-SafeguardAccountGroup"  "$($assetAccount.Name) NOT successfully edited to add to $($accountGroup.Name)"
      }
   }
   catch {
      badResult "general" "Error adding $($assetAccount.Name) to group $($accountGroup.Name)" $_.Exception
   }
} catch {
   badResult "Groups general"  "Unexpected error in Assets, Accounts, and Groups tests" $_.Exception
} finally {
   try { Remove-SafeguardAsset -AssetToDelete "$assetName" > $null } catch {}
   try { Remove-SafeguardAssetGroup -GroupToDelete "$assetGroupName" > $null } catch {}
   try { Remove-SafeguardAccountGroup -GroupToDelete "$accountGroupName" > $null } catch {}
}
