try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

# TODO
#Get-SafeguardPasswordHistory
#Invoke-SafeguardAssetAccountSshKeyChange
#Test-SafeguardAssetAccountSshKey

$GLOBALS.currentTest = $DATA.Tests.AssetsAndAccounts
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false
$script:asset = $null
function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   if ($script:asset) {
      try {
         Remove-SafeguardAsset -AssetToDelete $script:asset -ErrorAction SilentlyContinue > $null
      } catch {
        # Trying to remove accounts or systems with pending access request actions will
        # throw an error, so try it with force.
        if ($_ -match "is referenced by") {
           try { Invoke-SafeguardMethod core DELETE "Assets/$($script:asset.id)?forceDelete=true" -ErrorAction SilentlyContinue > $null } catch {}
        } else {
          $GLOBALS.warningResult(@{ minVerbosity = 1; cmd = "Cleanup"; message = "Exception trying to remove Assets/$($script:asset.id)."; ex = $_; })
       }
      }
   }

   try { Remove-SafeguardAssetGroup -GroupToDelete "$($DATA.assetGroupName)" -ErrorAction SilentlyContinue > $null } catch {}
   try { Remove-SafeguardAccountGroup -GroupToDelete "$($DATA.accountGroupName)" -ErrorAction SilentlyContinue > $null } catch {}
}

try {
   try {
      $script:asset = Get-SafeguardAsset -AssetToGet "$($DATA.assetName)"
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAsset"; message = "Asset $($DATA.assetName) already exists"; })
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $script:asset = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
            -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
            -AcceptSshHostKey -PrivilegeElevationCommand "sudo"
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAsset"; message = "$($asset.Name) successfully added"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardAsset"; message = "Unexpected error fetching Asset $($DATA.assetName)"; ex = $_; })
         throw $_.Exception
      }
   }
   $asset = Edit-SafeguardAsset -AssetToEdit $DATA.assetName -Description "Description for $($DATA.assetName)"
   if (-not $asset.Description -contains "Description for $($DATA.assetName)") {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardAsset"; message = "failed for $($DATA.assetName)"; })
   }

   $found = Find-SafeguardAsset $DATA.assetName
   if ($found) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAsset"; message = "found $($DATA.assetName)"; }) }
   else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardAsset"; message = "DID NOT find $($DATA.assetName)"; }) }

   try {
      $asset = Invoke-SafeguardAssetSshHostKeyDiscovery -Asset $DATA.assetname -AcceptSshHostKey
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardAssetSshHostKeyDiscovery"; message = "Discovered and accepted ssh host key on $($DATA.assetName)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardAssetSshHostKeyDiscovery"; message = "Failure to discover ssh host key on $($DATA.assetName)"; ex = $_; })
   }

   try {
      foreach ($acctname in $DATA.assetAccounts.GetEnumerator()) {
         $found = Find-SafeguardAssetAccount -QueryFilter "Asset.Name eq '$($DATA.assetName)' and Name eq '$acctname'"
         if ($found) { $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAssetAccount"; message = "$acctname already exists on $($DATA.assetName)"; }) }
         else {
            try {
               $newacct = New-SafeguardAssetAccount -ParentAsset $DATA.assetName -NewAccountName $acctname
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAssetAccount"; message = "$acctName successfully created on $($DATA.assetName)"; })
            } catch {
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardAssetAccount"; message = "Unexpected error creating $acctName on $($DATA.assetName)"; ex = $_; })
            }
         }
      }

      $deleteAccountName = $DATA.assetAccounts[0] + "_delete"
      $assetAccount = New-SafeguardAssetAccount -ParentAsset "$($DATA.assetName)" -NewAccountName "$deleteAccountName"
      Remove-SafeguardAssetAccount -AssetToUse $DATA.assetName -AccountToDelete "$deleteAccountName" > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAssetAccount"; message = "$($assetAccount.Name)_deleteme successfully added and removed"; })
   }
   catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Unexpected error creating Asset Accounts on $($DATA.assetName)"; ex = $_; })
   }
   $assetAccount = Get-SafeguardAssetAccount -AccountToGet "$($DATA.assetAccounts[0])" -AssetToGet "$($DATA.assetName)"
   $assetAccount = Edit-SafeguardAssetAccount -AssetToEdit $DATA.assetName -AccountToEdit $DATA.assetAccounts[0] -Description "Description for $($DATA.assetName)\$($DATA.assetAccounts[0])"
   if (-not $assetAccount.Description -contains "Description for") {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardAssetAccount"; message = "failed for $($DATA.assetName)\$($DATA.assetAccounts[0])"; })
   }

   try {
      $found = Find-SafeguardAssetAccount $DATA.assetAccounts[0]
      if ($found) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAssetAccount"; message = "found $($DATA.assetAccounts[0])"; }) }
      else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardAssetAccount"; message = "DID NOT find $($DATA.assetAccounts[0])"; }) }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardAssetAccount"; message = "failed for $($DATA.assetName)\$($DATA.assetAccounts[0])"; })
   }

   try {
      Test-SafeguardAsset -AssetToTest $DATA.assetName
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardAsset"; message = "Successfully tested asset $($DATA.assetName) (pass or fail)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Test-SafeguardAsset"; message = "failed for $($DATA.assetName)"; })
   }

   try {
      $randpwd = New-SafeguardAssetAccountRandomPassword -AssetToUse $DATA.assetName -AccountToUse $DATA.assetAccounts[0]
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAssetAccountRandomPassword"; message = "Successfully created password for $($DATA.assetName)\$($DATA.assetAccounts[0]) $randpwd"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardAssetAccountRandomPassword"; message = "failed for $($DATA.assetName)\$($DATA.assetAccounts[0])"; })
   }

   if (!$randpwd) {
      $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAssetAccountPassword"; message = "No random password was generated in previous step"; })
   } else {
      $newpassword = $randpwd | ConvertTo-SecureString -AsPlainText -Force
      try {
         Set-SafeguardAssetAccountPassword -AssetToSet $DATA.assetName -AccountToSet $DATA.assetAccounts[0] -NewPassword $newpassword > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAssetAccountPassword"; message = "Successfully set password on $($DATA.assetName)\$($DATA.assetAccounts[0])"; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardAssetAccountPassword"; message = "Set password failed on $($DATA.assetName)\$($DATA.assetAccounts[0])"; ex = $_; })
      }
   }

   try {
      Invoke-SafeguardAssetAccountPasswordChange -AssetToUse $DATA.assetName -AccountToUse $DATA.assetAccounts[0]
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardAssetAccountPasswordChange"; message = "Successfully called change password on $($DATA.assetName)\$($DATA.assetAccounts[0])"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Invoke-SafeguardAssetAccountPasswordChange"; message = "Failed on $($DATA.assetName)\$($DATA.assetAccounts[0])"; ex = $_; })
   }

   try {
      Test-SafeguardAssetAccountPassword -AssetToUse $DATA.assetName -AccountToUse $DATA.assetAccounts[0]
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardAssetAccountPassword"; message = "Successfully called test on $($DATA.assetName)\$($DATA.assetAccounts[0])"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Test-SafeguardAssetAccountPassword"; message = "Failed on $($DATA.assetName)\$($DATA.assetAccounts[0])"; ex = $_; })
   }

   try {
      # create some password history to retrieve
      if ($randpwd) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAssetAccountPassword"; message = "Creating some password history for Get-SafeguardPasswordHistory"; })
         $newpassword = "$randpwd 1234" | ConvertTo-SecureString -AsPlainText -Force
         Set-SafeguardAssetAccountPassword -AssetToSet $DATA.assetName -AccountToSet $DATA.assetAccounts[0] -NewPassword $newpassword > $null
         $newpassword = "$randpwd 2345" | ConvertTo-SecureString -AsPlainText -Force
         Set-SafeguardAssetAccountPassword -AssetToSet $DATA.assetName -AccountToSet $DATA.assetAccounts[0] -NewPassword $newpassword > $null
      }

      $results = Get-SafeguardPasswordHistory -AccountToGet $DATA.assetAccounts[0] -stdout
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardPasswordHistory"; message = "Successfully retrived password history on $($DATA.assetName)\$($DATA.assetAccounts[0])"; })
      $GLOBALS.formatTable(@{ output = ($results -split "`r`n"); })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardPasswordHistory"; message = "Failed on $($DATA.assetName)\$($DATA.assetAccounts[0])"; ex = $_; })
   }

   try {
      try {
         $assetGroup = (Get-SafeguardAssetGroup -GroupToGet "$($DATA.assetGroupName)")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $assetGroup = New-SafeguardAssetGroup -Name "$($DATA.assetGroupName)" -Description "Description for $($DATA.assetGroupName)"
         }
         else {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardAssetGroup"; message = "Unexpected error fetching $($DATA.assetGroupName)" ; ex = $_; })
            throw $_.Exception
         }
      }
      Add-SafeguardAssetGroupMember -Group $assetGroup.Name -AssetList $asset.Name > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($asset.Name -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Add-SafeguardAssetGroupMember"; message = "$($asset.Name) successfully added to $($assetGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Add-SafeguardAssetGroupMember"; message = "$($asset.Name) NOT found in $($assetGroup.Name)"; })
      }

      Remove-SafeguardAssetGroupMember -Group $assetGroup.Name -AssetList $asset.Name > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($null -eq $groupMembers -or -not $asset.Name -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAssetGroupMember"; message = "$($asset.Name) successfully removed to $($assetGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardAssetGroupMember"; message = "$($asset.Name) NOT removed from $($assetGroup.Name)"; })
      }

      Edit-SafeguardAssetGroup -GroupToEdit $assetGroup.Name -AssetList $asset.Name -Operation add > $null
      $groupMembers = (Get-SafeguardAssetGroupMember -Group $assetGroup.Name).Name
      if ($asset.Name -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAssetGroup"; message = "$($asset.Name) successfully edited to add to $($assetGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardAssetGroup"; message = "$($asset.Name) NOT successfully edited to add to $($assetGroup.Name)"; })
      }
   }
   catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Asset Group"; message = "Error adding $($asset.Name) to group $($assetGroup.Name)"; ex = $_; })
   } finally {
      Remove-SafeguardAssetGroup -GroupToDelete "$($DATA.assetGroupName)" > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAssetGroup"; message = "Successfully removed $($DATA.assetGroupName)"; })
   }

   try {
      $dynoAssetGroupName = "Dynamic_$($DATA.assetGroupName)"
      try {
         $dynoAssetGroup = Get-SafeguardDynamicAssetGroup -GroupToGet $dynoAssetGroupName
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDynamicAssetGroup"; message = "$dynoAssetGroupName already exists"; })
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $dynoAssetGroup = New-SafeguardDynamicAssetGroup -Name "$dynoAssetGroupName" -Description "Description for $dynoAssetGroupName" -GroupingRule "$($DATA.dynamicAssetGroupRule)"
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardDynamicAccountGroup"; message = "Successfully created Dynamic Asset Group $dynoAssetGroupName"; })
         } else {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDynamicAssetGroup"; message = "Unexpected error fetching $dynoAssetGroupName" ; ex = $_; })
            throw $_.Exception
         }
      }
      $dynoAssetGroup = Edit-SafeguardDynamicAssetGroup -GroupToEdit "$dynoAssetGroupName" -Description "Edited Description for $dynoAssetGroupName" -GroupingRule "$($DATA.dynamicAssetGroupRule)"
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardDynamicAssetGroup"; message = "Successfully edited $dynoAssetGroupName Description='$($dynoAssetGroup.Description)'"; })

      $results = Get-SafeguardAssetGroupMember -Group $dynoAssetGroupName
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAssetGroupMember"; message = "Dynamic Asset Group $dynoAssetGroupName members"; })
      $GLOBALS.formatTable(@{ output = $results; properties = @{ Property = @("Id","Name","NetworkAddress","AssetPartitionName"); }; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Dynamic Asset Group"; message = "Error working with Dynamic Asset Groups"; ex = $_; })
   } finally {
      Remove-SafeguardAssetGroup -GroupToDelete "$dynoAssetGroupName" > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAssetGroup"; message = "Successfully removed $dynoAssetGroupName"; })
   }

   try {
      try {
         $accountGroup = (Get-SafeguardAccountGroup -GroupToGet "$($DATA.accountGroupName)")[0]
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $accountGroup = New-SafeguardAccountGroup -Name "$($DATA.accountGroupName)" -Description "Description for $($DATA.accountGroupName)"
         }
         else {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardAccountGroup"; message = "Unexpected error fetching $($DATA.accountGroupName)" ; ex = $_; })
            throw $_.Exception
         }
      }

      $acct = "$($asset.Name)\$($assetAccount.Name)"
      Add-SafeguardAccountGroupMember -Group $accountGroup.Name -AccountList $acct > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($assetAccount.Name -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Add-SafeguardAccountGroupMember"; message = "$($assetAccount.Name) successfully added to $($accountGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Add-SafeguardAccountGroupMember"; message = "$($assetAccount.Name) NOT found in $($accountGroup.Name)"; })
      }

      Remove-SafeguardAccountGroupMember -Group $accountGroup.Name -AccountList $acct > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($null -eq $groupMembers -or -not $assetAccount.Name -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAccountGroupMember"; message = "$($assetAccount.Name) successfully removed to $($accountGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardAccountGroupMember"; message = "$($assetAccount.Name) NOT removed from $($accountGroup.Name)"; })
      }

      Edit-SafeguardAccountGroup -GroupToEdit $accountGroup.Name -AccountList $acct  -Operation add > $null
      $groupMembers = (Get-SafeguardAccountGroupMember -Group $accountGroup.Name).Name
      if ($assetAccount.Name -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAccountGroup"; message = "$($assetAccount.Name) successfully edited to add to $($accountGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardAccountGroup"; message = "$($assetAccount.Name) NOT successfully edited to add to $($accountGroup.Name)"; })
      }
   }
   catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Account Group"; message = "Error adding $($assetAccount.Name) to group $($accountGroup.Name)"; ex = $_; })
   } finally {
      Remove-SafeguardAccountGroup -GroupToDelete "$($DATA.accountGroupName)" > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAccountGroup"; message = "Successfully removed $($DATA.accountGroupName)"; })
   }

   try {
      $dynoAccountGroupName = "Dynamic_$($DATA.accountGroupName)"
      try {
         $dynoAccountGroup = Get-SafeguardDynamicAccountGroup -GroupToGet $dynoAccountGroupName
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDynamicAccountGroup"; message = "$dynoAccountGroupName already exists"; })
      } catch {
         if ($_.Exception.Message -match "unable to find") {
            $dynoAccountGroup = New-SafeguardDynamicAccountGroup -Name "$dynoAccountGroupName" -Description "Description for $dynoAccountGroupName" -GroupingRule "$($DATA.dynamicAccountGroupRule)"
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardDynamicAccountGroup"; message = "Successfully created Dynamic Account Group $dynoAccountGroupName"; })
         } else {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDynamicAccountGroup"; message = "Unexpected error fetching $dynoAccountGroupName" ; ex = $_; })
            throw $_.Exception
         }
      }

      # This currently errors out, so catch it separately for now but don't propagate the exception
      try {
         $dynoAccountGroup = Edit-SafeguardDynamicAccountGroup -GroupToEdit "$dynoAccountGroupName" -Description "Edited Description for $dynoAccountGroupName" -GroupingRule "$($DATA.dynamicAccountGroupRule)"
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardDynamicAccountGroup"; message = "Successfully edited $dynoAccountGroupName Description='$($dynoAccountGroup.Description)'"; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardDynamicAccountGroup"; message = "Failed $dynoAccountGroupName"; ex = $_; })
      }

      $results = Get-SafeguardAccountGroupMember -Group $dynoAccountGroupName
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccountGroupMember"; message = "Dynamic Account Group $dynoAccountGroupName members"; })
      $GLOBALS.formatTable(@{ output = $results; properties = @{ Property = @("Id","Name",@{label="AssetName";e={$_.Asset.Name}}); }; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Dynamic Account Group"; message = "Error working with Dynamic Account Groups"; ex = $_; })
   } finally {
      Remove-SafeguardAccountGroup -GroupToDelete "$dynoAccountGroupName" > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAccountGroup"; message = "Successfully removed $dynoAccountGroupName"; })
   }

   # create a assets and accounts to delete, restore, and remove
   $delResAsset = New-SafeguardAsset -DisplayName "delres_$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
      -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
      -AcceptSshHostKey
   $delResAccount = New-SafeguardAssetAccount -ParentAsset $delResAsset.Name -NewAccountName "delres_account"
   Remove-SafeguardAssetAccount -AccountToDelete $delResAccount.Id > $null
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Deleted Account"; message = "Successfully created and deleted account for testing Id=$($delResAccount.Id) Name=$($delResAsset.Name)\$($delResAccount.Name)"; })

   try {
      $delAssetAccountList = (Get-SafeguardDeletedAssetAccount) | Where-Object {$_.Name -ieq "$($delResAccount.Name)"}
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDeletedAssetAccount"; message = "Successfully retrieved $($delAssetAccountList.Count) deleted accounts"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDeletedAssetAccount"; message = "Failed to retrieve deleted account $($delResAccount.Name)"; })
   }

   try {
      $restored = Restore-SafeguardDeletedAssetAccount -AccountToRestore $delResAccount.Id
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Restore-SafeguardDeletedAssetAccount"; message = "Successfully restored deleted account Id=$($delResAccount.Id) Name=$($delResAsset.Name)\$($restored.Name), new Id=$($restored.Id)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Restore-SafeguardDeletedAssetAccount"; message = "Failed to restore deleted user $($delResAccount.Name)"; })
   }

   try {
      Remove-SafeguardAssetAccount -AccountToDelete $restored.Id > $null
      Remove-SafeguardDeletedAssetAccount -AccountToDelete $restored.Id > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardDeletedAssetAccount"; message = "Successfully purged deleted account Id=$($restored.Id) Name=$($delResAsset.Name)\$($restored.Name)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardDeletedAssetAccount"; message = "Failed to purge deleted user Id=$($restored.Id) $($delResAsset.Name)\$($restored.Name)"; })
   }

   Remove-SafeguardAsset $delResAsset.Name > $null
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Deleted Asset"; message = "Successfully created and deleted asset for testing Id=$($delResAsset.Id) Name=$($delResAsset.Name)"; })

   try {
      $delAssetList = (Get-SafeguardDeletedAsset) | Where-Object {$_.Name -ieq "$($delResAsset.Name)"}
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDeletedAsset"; message = "Successfully retrieved $($delAssetList.Count) deleted users"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDeletedAsset"; message = "Failed to retrieve deleted user $($delResAsset.Name)"; })
   }

   try {
      $restored = Restore-SafeguardDeletedAsset -AssetToRestore $delResAsset.Id
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Restore-SafeguardDeletedAsset"; message = "Successfully restored deleted user Id=$($delResAsset.Id) Name=$($restored.Name), new Id=$($restored.Id)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Restore-SafeguardDeletedAsset"; message = "Failed to restore deleted user $($delResAsset.Name)"; })
   }

   try {
      Remove-SafeguardAsset $restored.Id > $null
      Remove-SafeguardDeletedAsset -AssetToDelete $restored.Id > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardDeletedAsset"; message = "Successfully purged deleted user Id=$($restored.Id) Name=$($restored.Name)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardDeletedAsset"; message = "Failed to purge deleted user Id=$($restored.Id) $($delResAsset.Name)"; })
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Assets and Accounts general"; message = "Unexpected error in Assets, Accounts, and Groups tests"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

