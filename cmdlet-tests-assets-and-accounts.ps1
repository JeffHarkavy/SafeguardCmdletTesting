try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Assets, Accounts, and Groups Tests"
$blockInfo = testBlockHeader $TestBlockName 24
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
# Invoke-SafeguardAssetAccountPasswordChange
# Invoke-SafeguardAssetSshHostKeyDiscovery
# New-SafeguardAssetAccountRandomPassword
# Set-SafeguardAssetAccountPassword
# Test-SafeguardAsset
# Test-SafeguardAssetAccountPassword
# Edit-SafeguardDynamicAccountGroup
# Edit-SafeguardDynamicAssetGroup
# Get-SafeguardDynamicAccountGroup
# Get-SafeguardDynamicAssetGroup
# New-SafeguardDynamicAccountGroup
# New-SafeguardDynamicAssetGroup
# Get-SafeguardDeletedAsset
# Get-SafeguardDeletedAssetAccount
# Remove-SafeguardDeletedAsset
# Remove-SafeguardDeletedAssetAccount
# Restore-SafeguardDeletedAsset
# Restore-SafeguardDeletedAssetAccount
# 

try {
   try {
      $asset = Get-SafeguardAsset -AssetToGet "$($DATA.assetName)"
      infoResult "Get-SafeguardAsset" "Asset $($DATA.assetName) already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $asset = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
            -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
            -AcceptSshHostKey
         goodResult "New-SafeguardAsset" "$($asset.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardAsset" "Unexpected error fetching Asset $($DATA.assetName)"  $_
         throw $_.Exception
      }
   }
   $asset = Edit-SafeguardAsset -AssetToEdit $DATA.assetName -Description "Description for $($DATA.assetName)"
   if (-not $asset.Description -contains "Description for $($DATA.assetName)") {
      badResult "Edit-SafeguardAsset" "failed for $($DATA.assetName)"
   }

   $found = Find-SafeguardAsset $DATA.assetName
   if ($found) { goodResult "Find-SafeguardAsset" "found $($DATA.assetName)" }
   else { badResult "Find-SafeguardAsset" "DID NOT find $($DATA.assetName)" }

   $asset = Invoke-SafeguardAssetSshHostKeyDiscovery -Asset $DATA.assetname -AcceptSshHostKey
   goodResult "Invoke-SafeguardAssetSshHostKeyDiscovery" "Discovered and accepted ssh host key on $($DATA.assetName)"

   
   try {
      foreach ($acctname in $DATA.assetAccounts.GetEnumerator()) {
         $found = Find-SafeguardAssetAccount -QueryFilter "Asset.Name eq '$($DATA.assetName)' and Name eq '$acctname'"
         if ($found) { infoResult "New-SafeguardDirectoryAccount" "$acctname already exists on $($DATA.assetName)" }
         else {
            try {
               $newacct = New-SafeguardAssetAccount -ParentAsset $DATA.assetName -NewAccountName $acctname
               goodResult "New-SafeguardAssetAccount" "$acctName successfully created on $($DATA.assetName)"
            } catch {
               badResult "New-SafeguardAssetAccount" "Unexpected error creating $acctName on $($DATA.assetName)" $_
            }
         }
      }

      $deleteAccountName = $DATA.assetAccounts[0] + "_delete"
      $assetAccount = New-SafeguardAssetAccount -ParentAsset "$($DATA.assetName)" -NewAccountName "$deleteAccountName"
      Remove-SafeguardAssetAccount -AssetToUse $DATA.assetName -AccountToDelete "$deleteAccountName" > $null
      goodResult "Remove-SafeguardAssetAccount" "$($assetAccount.Name)_deleteme successfully added and removed"
   }
   catch {
      badResult "general" "Unexpected error creating Asset Accounts on $($DATA.assetName)"  $_
   }
   $assetAccount = Get-SafeguardAssetAccount -AccountToGet "$($DATA.assetAccounts[0])" -AssetToGet "$($DATA.assetName)"
   $assetAccount = Edit-SafeguardAssetAccount -AssetToEdit $DATA.assetName -AccountToEdit $DATA.assetAccounts[0] -Description "Description for $($DATA.assetName)\$($DATA.assetAccounts[0])"
   if (-not $assetAccount.Description -contains "Description for") {
      badResult "Edit-SafeguardAssetAccount" "failed for $($DATA.assetName)\$($DATA.assetAccounts[0])"
   }
   $found = Find-SafeguardAssetAccount $DATA.assetAccounts[0]
   if ($found) { goodResult "Find-SafeguardAssetAccount" "found $($DATA.assetAccounts[0])" }
   else { badResult "Find-SafeguardAssetAccount" "DID NOT find $($DATA.assetAccounts[0])" }
   Test-SafeguardAsset -AssetToTest $DATA.assetName
   goodResult "Test-SafeguardAsset" "Successfully tested assed $($DATA.assetName) (pass or fail)"

   $randpwd = New-SafeguardAssetAccountRandomPassword -AssetToUse $DATA.assetName -AccountToUse $DATA.assetAccounts[0]
   goodResult "New-SafeguardAssetAccountRandomPassword" "Successfully created password for $($DATA.assetName)\$($DATA.assetAccounts[0]) $randpwd"

   $newpassword = $randpwd | ConvertTo-SecureString -AsPlainText -Force
   try {
      Set-SafeguardAssetAccountPassword -AssetToSet $DATA.assetName -AccountToSet $DATA.assetAccounts[0] -NewPassword $newpassword > $null
      goodResult "Set-SafeguardAssetAccountPassword" "Successfully set password on $($DATA.assetName)\$($DATA.assetAccounts[0])"
   } catch {
      badResult "Set-SafeguardAssetAccountPassword" "Set password failed on $($DATA.assetName)\$($DATA.assetAccounts[0])" $_
   }

   try {
      Invoke-SafeguardAssetAccountPasswordChange -AssetToUse $DATA.assetName -AccountToUse $DATA.assetAccounts[0]
      goodResult "Invoke-SafeguardAssetAccountPasswordChange" "Successfully called change password on $($DATA.assetName)\$($DATA.assetAccounts[0])"
   } catch {
      badResult "Invoke-SafeguardAssetAccountPasswordChange" "Failed on $($DATA.assetName)\$($DATA.assetAccounts[0])" $_
   }

   try {
      Test-SafeguardAssetAccountPassword -AssetToUse $DATA.assetName -AccountToUse $DATA.assetAccounts[0]
      goodResult "Test-SafeguardAssetAccountPassword" "Successfully called test on $($DATA.assetName)\$($DATA.assetAccounts[0])"
   } catch {
      badResult "Test-SafeguardAssetAccountPassword" "Failed on $($DATA.assetName)\$($DATA.assetAccounts[0])" $_
   }

   try {
      try {
         $assetGroup = (Get-SafeguardAssetGroup -GroupToGet "$($DATA.assetGroupName)")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $assetGroup = New-SafeguardAssetGroup -Name "$($DATA.assetGroupName)" -Description "Description for $($DATA.assetGroupName)"
         }
         else {
            badResult "Get-SafeguardAssetGroup" "Unexpected error fetching $($DATA.assetGroupName)"  $_
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
      badResult "Asset Group" "Error adding $($asset.Name) to group $($assetGroup.Name)" $_
   } finally {
      Remove-SafeguardAssetGroup -GroupToDelete "$($DATA.assetGroupName)" > $null
      goodResult "Remove-SafeguardAssetGroup" "Successfully removed $($DATA.assetGroupName)"
   }

   try {
      $dynoAssetGroupName = "Dynamic_$($DATA.assetGroupName)"
      try {
         $dynoAssetGroup = Get-SafeguardDynamicAssetGroup -GroupToGet $dynoAssetGroupName
         infoResult "Get-SafeguardDynamicAssetGroup" "$dynoAssetGroupName already exists"
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $dynoAssetGroup = New-SafeguardDynamicAssetGroup -Name "$dynoAssetGroupName" -Description "Description for $dynoAssetGroupName" -GroupingRule "$($DATA.dynamicAssetGroupRule)"
            goodResult "New-SafeguardDynamicAccountGroup" "Successfully created Dynamic Asset Group $dynoAssetGroupName"
         } else {
            badResult "Get-SafeguardDynamicAssetGroup" "Unexpected error fetching $dynoAssetGroupName"  $_
            throw $_.Exception
         }
      }
      $dynoAssetGroup = Edit-SafeguardDynamicAssetGroup -GroupToEdit "$dynoAssetGroupName" -Description "Edited Description for $dynoAssetGroupName" -GroupingRule "$($DATA.dynamicAssetGroupRule)"
      goodResult "Edit-SafeguardDynamicAssetGroup" "Successfully edited $dynoAssetGroupName Description='$($dynoAssetGroup.Description)'"

      infoResult "Get-SafeguardAssetGroupMember" "Dynamic Asset Group $dynoAssetGroupName members"
      Get-SafeguardAssetGroupMember -Group $dynoAssetGroupName | Format-Table
   } catch {
      badResult "Dynamic Asset Group" "Error working with Dynamic Asset Groups" $_
   } finally {
      Remove-SafeguardAssetGroup -GroupToDelete "$dynoAssetGroupName" > $null
      goodResult "Remove-SafeguardAssetGroup" "Successfully removed $dynoAssetGroupName"
   }

   try {
      try {
         $accountGroup = (Get-SafeguardAccountGroup -GroupToGet "$($DATA.accountGroupName)")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $accountGroup = New-SafeguardAccountGroup -Name "$($DATA.accountGroupName)" -Description "Description for $($DATA.accountGroupName)"
         }
         else {
            badResult "Get-SafeguardAccountGroup" "Unexpected error fetching $($DATA.accountGroupName)"  $_
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
      badResult "Account Group" "Error adding $($assetAccount.Name) to group $($accountGroup.Name)" $_
   } finally {
      Remove-SafeguardAccountGroup -GroupToDelete "$($DATA.accountGroupName)" > $null
      goodResult "Remove-SafeguardAccountGroup" "Successfully removed $($DATA.accountGroupName)"
   }

   try {
      $dynoAccountGroupName = "Dynamic_$($DATA.accountGroupName)"
      try {
         $dynoAccountGroup = Get-SafeguardDynamicAccountGroup -GroupToGet $dynoAccountGroupName
         infoResult "Get-SafeguardDynamicAccountGroup" "$dynoAccountGroupName already exists"
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $dynoAccountGroup = New-SafeguardDynamicAccountGroup -Name "$dynoAccountGroupName" -Description "Description for $dynoAccountGroupName" -GroupingRule "$($DATA.dynamicAccountGroupRule)"
            goodResult "New-SafeguardDynamicAccountGroup" "Successfully created Dynamic Account Group $dynoAccountGroupName"
         } else {
            badResult "Get-SafeguardDynamicAccountGroup" "Unexpected error fetching $dynoAccountGroupName"  $_
            throw $_.Exception
         }
      }

      # This currently errors out, so catch it separately for now but don't propagate the exception
      try {
         $dynoAccountGroup = Edit-SafeguardDynamicAccountGroup -GroupToEdit "$dynoAccountGroupName" -Description "Edited Description for $dynoAccountGroupName" -GroupingRule "$($DATA.dynamicAccountGroupRule)"
         goodResult "Edit-SafeguardDynamicAccountGroup" "Successfully edited $dynoAccountGroupName Description='$($dynoAccountGroup.Description)'"
      } catch {
         badResult "Edit-SafeguardDynamicAccountGroup" "Failed $dynoAccountGroupName" $_
      }

      infoResult "Get-SafeguardAccountGroupMember" "Dynamic Account Group $dynoAccountGroupName members"
      Get-SafeguardAccountGroupMember -Group $dynoAccountGroupName | Format-Table
   } catch {
      badResult "Dynamic Account Group" "Error working with Dynamic Account Groups" $_
   } finally {
      Remove-SafeguardAccountGroup -GroupToDelete "$dynoAccountGroupName" > $null
      goodResult "Remove-SafeguardAccountGroup" "Successfully removed $dynoAccountGroupName"
   }

   # create a assets and accounts to delete, restore, and remove
   $delResAsset = New-SafeguardAsset -DisplayName "delres_$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
      -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
      -AcceptSshHostKey
   $delResAccount = New-SafeguardAssetAccount -ParentAsset $delResAsset.Name -NewAccountName "delres_account"
   Remove-SafeguardAssetAccount -AccountToDelete $delResAccount.Id > $null
   infoResult "Deleted Account" "Successfully created and deleted account for testing Id=$($delResAccount.Id) Name=$($delResAsset.Name)\$($delResAccount.Name)"

   try {
      $delAssetAccountList = (Get-SafeguardDeletedAssetAccount) | Where-Object {$_.Name -ieq "$($delResAccount.Name)"}
      goodResult "Get-SafeguardDeletedAssetAccount" "Successfully retrieved $($delAssetAccountList.Count) deleted accounts"
   } catch {
      badResult "Get-SafeguardDeletedAssetAccount" "Failed to retrieve deleted account $($delResAccount.Name)"
   }

   try {
      $restored = Restore-SafeguardDeletedAssetAccount -AccountToRestore $delResAccount.Id
      goodResult "Restore-SafeguardDeletedAssetAccount" "Successfully restored deleted account Id=$($delResAccount.Id) Name=$($delResAsset.Name)\$($restored.Name), new Id=$($restored.Id)"
   } catch {
      badResult "Restore-SafeguardDeletedAssetAccount" "Failed to restore deleted user $($delResAccount.Name)"
   }

   try {
      Remove-SafeguardAssetAccount -AccountToDelete $restored.Id > $null
      Remove-SafeguardDeletedAssetAccount -AccountToDelete $restored.Id > $null
      goodResult "Remove-SafeguardDeletedAssetAccount" "Successfully purged deleted account Id=$($restored.Id) Name=$($delResAsset.Name)\$($restored.Name)"
   } catch {
      badResult "Remove-SafeguardDeletedAssetAccount" "Failed to purge deleted user Id=$($restored.Id) $($delResAsset.Name)\$($restored.Name)"
   }

   Remove-SafeguardAsset $delResAsset.Name > $null
   infoResult "Deleted Asset" "Successfully created and deleted asset for testing Id=$($delResAsset.Id) Name=$($delResAsset.Name)"

   try {
      $delAssetList = (Get-SafeguardDeletedAsset) | Where-Object {$_.Name -ieq "$($delResAsset.Name)"}
      goodResult "Get-SafeguardDeletedAsset" "Successfully retrieved $($delAssetList.Count) deleted users"
   } catch {
      badResult "Get-SafeguardDeletedAsset" "Failed to retrieve deleted user $($delResAsset.Name)"
   }

   try {
      $restored = Restore-SafeguardDeletedAsset -AssetToRestore $delResAsset.Id
      goodResult "Restore-SafeguardDeletedAsset" "Successfully restored deleted user Id=$($delResAsset.Id) Name=$($restored.Name), new Id=$($restored.Id)"
   } catch {
      badResult "Restore-SafeguardDeletedAsset" "Failed to restore deleted user $($delResAsset.Name)"
   }

   try {
      Remove-SafeguardAsset $restored.Id > $null
      Remove-SafeguardDeletedAsset -AssetToDelete $restored.Id > $null
      goodResult "Remove-SafeguardDeletedAsset" "Successfully purged deleted user Id=$($restored.Id) Name=$($restored.Name)"
   } catch {
      badResult "Remove-SafeguardDeletedAsset" "Failed to purge deleted user Id=$($restored.Id) $($delResAsset.Name)"
   }
} catch {
   badResult "Assets and Accounts general" "Unexpected error in Assets, Accounts, and Groups tests" $_
} finally {
   try { Remove-SafeguardAsset -AssetToDelete "$($DATA.assetName)" > $null } catch {}
   try { Remove-SafeguardAssetGroup -GroupToDelete "$($DATA.assetGroupName)" > $null } catch {}
   try { Remove-SafeguardAccountGroup -GroupToDelete "$($DATA.accountGroupName)" > $null } catch {}
}

testBlockHeader $TestBlockName $blockInfo
