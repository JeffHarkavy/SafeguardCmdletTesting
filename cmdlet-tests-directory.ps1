try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Directory Tests"
$blockInfo = testBlockHeader $TestBlockName 22
# ===== Covered Commands =====
# Get-SafeguardDirectoryMigrationData
# Get-SafeguardDirectory
# New-SafeguardDirectory
# Edit-SafeguardDirectory
# Edit-SafeguardDirectoryAccount
# Find-SafeguardDirectoryAccount
# Get-SafeguardDirectoryAccount
# New-SafeguardDirectoryAccount
# New-SafeguardDirectoryAccountRandomPassword
# Set-SafeguardDirectoryAccountPassword
# Remove-SafeguardDirectory
# Remove-SafeguardDirectoryAccount
# Test-SafeguardDirectory
# Test-SafeguardDirectoryAccountPassword
# Invoke-SafeguardDirectoryAccountPasswordChange
# Sync-SafeguardDirectory
# Sync-SafeguardDirectoryAsset
#
# linked accounts only work when a directory is around so do those here, too
# Add-SafeguardUserLinkedAccount
# Get-SafeguardUserLinkedAccount
# Remove-SafeguardUserLinkedAccount
#

$directoryAdded = 0
$userAdded = 0
try {
   if ($DATA.requiredDNS -ne "") {
      $x0 = Get-SafeguardNetworkInterface "X0"
      if ($x0.DnsServers -contains $DATA.requiredDNS) {
         infoResult "Set-SafeguardNetworkInterface" "$($DATA.requiredDNS) already present in X0 DNS list"
      } else {
         try {
            Set-SafeguardNetworkInterface -Interface "X0" -DnsServers $(,$DATA.requiredDNS+$($x0.DnsServers))
            goodResult "Set-SafeguardNetworkInterface" "$DATA.requiredDNS added to X0 DNS Servers"
         } catch {
            badResult "Set-SafeguardNetworkInterface" "Unexpected error setting DNS $DATA.requiredDNS on X0" $_
            throw $_.Exception
         }
      }
   }

   # for password getting/setting the default password rule has to be a little beefier
   # adjust to fit, ymmv
   $passwordRule = Get-SafeguardAccountPasswordRule -PasswordRuleToGet "Macrocosm Password Rule" -AssetPartitionID -1
   if ($passwordRule.MinCharacters -ge 10 -and $passwordRule.MaxCharacters -ge 20) {
      infoResult "Get-SafeguardAccountPasswordRule" "Macrocosm Password Rule has Min=$($passwordRule.MinCharacters) Max=$($passwordRule.MaxCharacters) characters"
   } else {
      $passwordRule = Edit-SafeguardAccountPasswordRule -PasswordRuleToEdit "Macrocosm Password Rule" `
          -AssetPartitionID -1 `
          -MinCharacters (@($passwordRule.MinCharacters,10)|measure-object -Maximum).Maximum `
          -MaxCharacters (@($passwordRule.MaxCharacters,20)|measure-object -Maximum).Maximum
      infoResult "Edit-SafeguardAccountPasswordRule" "Macrocosm Password Rule updated to Min=$($passwordRule.MinCharacters) Max=$($passwordRule.MaxCharacters) characters"
   }

   try {
      Get-SafeguardDirectoryMigrationData $DATA.appliance
      goodResult "Get-SafeguardDirectoryMigrationData" "Success - results may be empty"
   } catch {
      badResult "Get-SafeguardDirectoryMigrationData" "Unexpected error getting getting migration data on $($DATA.appliance)" $_
   }

   try {
      $newDirectory = Get-SafeguardDirectory -DirectoryToGet $DATA.domainName
      goodResult "Get-SafeguardDirectory" "$($DATA.domainName) directory already exists"
   } catch {
      if ($_.Exception.Message -match "unable to find") {
         $newDirectory = New-SafeguardDirectory -ServiceAccountDomainName $DATA.domainName -ServiceAccountName $DATA.domainAdmin -ServiceAccountPassword $DATA.domainPassword
         $directoryAdded = 1
         goodResult "New-SafeguardDirectory" "$($DATA.domainName) successfully created"
      } else {
         badResult "Get-SafeguardDirectory" "Unexpected error getting directory $($DATA.domainName)" $_
         throw $_.Exception
      }
   }

   # TODO
   # This one keeps failing no matter what gets passed because something is looking for AssetPartitionId
   # which is not part of the directory object. So, leaving it here with exception handler and
   # letting it fail for the time being.
   try {
      $newDirectory = Edit-SafeguardDirectory -DirectoryToEdit $($DATA.domainName) -Description "New Description for $DATA.domainName"
      if ($newDirectory.Description -eq "New Description for $($DATA.domainName)") { goodResult "Edit-SafeguardDirectory" "Successfully edited" }
      else { badResult "Edit-SafeguardDirectory" "Edit failed" }
   } catch {
      badResult "Edit-SafeguardDirectory" "Unexpected error editing directory $($DATA.domainName)" $_
   }

   Test-SafeguardDirectory -DirectoryToTest $DATA.domainName
   goodResult "Test-SafeguardDirectory" "Successfully called test on directory $($DATA.domainName)"

   $existingAccounts = Get-SafeguardDirectoryAccount -DirectoryToGet $DATA.domainName -Fields Name
   goodResult "Get-SafeguardDirectoryAccount" "Found $($existingAccounts.Count) accounts"
   foreach ($acctname in $DATA.directoryAccounts.GetEnumerator()) {
      $found = Find-SafeguardAssetAccount -QueryFilter "AssetName eq '$($DATA.domainName)' and Name eq '$acctname'"
      if ($found) { infoResult "New-SafeguardDirectoryAccount" "$acctname already exists on $($DATA.domainName)" }
      else {
         try {
            $newacct = New-SafeguardDirectoryAccount -ParentDirectory $newDirectory -NewAccountName $acctname
            goodResult "New-SafeguardDirectoryAccount" "$acctName successfully created on $($DATA.domainName)"
         } catch {
            badResult "New-SafeguardDirectoryAccount" "Unexpected error creating $acctName on $($DATA.domainName)" $_
         }
      }
   }

   # TODO
   # Can't get this one to work no matter what
   # Keep it here and let it "fail" until i figure out wth is going on
   $diracct = Find-SafeguardDirectoryAccount $DATA.directoryAccounts[0]
   if ($diracct) { goodResult "Find-SafeguardDirectoryAccount" "Found directory account $($DATA.directoryAccounts[0])" }
   else { badResult "Find-SafeguardDirectoryAccount" "Did not find directory account $($DATA.directoryAccounts[0])" }

   $randpwd = New-SafeguardDirectoryAccountRandomPassword -DirectoryToUse $DATA.domainName -AccountToUse $DATA.directoryAccounts[0]
   if ($randpwd -ne "") { goodResult "New-SafeguardDirectoryAccountRandomPassword" "Random password for $($DATA.directoryAccounts[0]) $randpwd" }
   else { badResult "New-SafeguardDirectoryAccountRandomPassword" "Random password failed for $($DATA.directoryAccounts[0])" }

   $diracct = Get-SafeguardDirectoryAccount -DirectoryToGet $DATA.domainName -AccountToGet $DATA.directoryAccounts[0]
   $diracct.Description = "Edit description for $($DATA.domainName)\$($diracct.Name)"
   $diracct = Edit-SafeguardDirectoryAccount -AccountObject $diracct
   if ($diracct.Description -ne "") { goodResult "Edit-SafeguardDirectoryAccount" "Successful directory account edit for $($DATA.domainName)\$($diracct.Name)" }
   else { badResult "Edit-SafeguardDirectoryAccount" "Edit failed for $($DATA.domainName)\$($diracct.Name)" }

   $newpassword = $randpwd | ConvertTo-SecureString -AsPlainText -Force
   try {
      Set-SafeguardDirectoryAccountPassword -DirectoryToSet $DATA.domainName -AccountToSet $diracct -NewPassword $newpassword > $null
      goodResult "Set-SafeguardDirectoryAccountPassword" "Successfully set password on $($DATA.domainName)\$($diracct.Name)"
   } catch {
      badResult "Set-SafeguardDirectoryAccountPassword" "Set password failed on $($DATA.domainName)\$($diracct.Name)" $_
   }

   Invoke-SafeguardDirectoryAccountPasswordChange -DirectoryToUse $DATA.domainName -AccountToUse $DATA.directoryAccounts[0]
   goodResult "Invoke-SafeguardDirectoryAccountPasswordChange" "Successfully called change password on $($DATA.domainName)\$($DATA.directoryAccounts[0])"

   Test-SafeguardDirectoryAccountPassword -DirectoryToUse $DATA.domainName -AccountToUse $DATA.directoryAccounts[0]
   goodResult "Test-SafeguardDirectoryAccountPassword" "Successfully called test on $($DATA.domainName)\$($DATA.directoryAccounts[0])"

   Sync-SafeguardDirectory -DirectoryToSync $DATA.domainName
   goodResult "Sync-SafeguardDirectory" "Successfull called sync on directory $($DATA.domainName)"

   Sync-SafeguardDirectoryAsset -DirectoryAssetToSync $DATA.domainName
   goodResult "Sync-SafeguardDirectoryAsset" "Successfull called sync on directory asset $($DATA.domainName)"

   try {
      $newUser = createUser $DATA.userUsername
   }
   catch {
      # Not fatal, just skip the linked account tests if we don't have a user
      badresult "Add-SafeguardUserLinkedAccount" "$DATA.userUserName not created or available. Skipping LinkedAccount tests"
   }

   if ($newUser) {
      $linked = Add-SafeguardUserLinkedAccount -UserToSet $DATA.userUserName -DirectoryToAdd $DATA.domainName -AccountToAdd $DATA.directoryAccounts[0]
      if ($linked.Name -eq $DATA.directoryAccounts[0]) { goodResult "Add-SafeguardUserLinkedAccount" "Added Linked $($DATA.directoryAccounts[0]) account to $($DATA.userUserName)" }
      else { badResult "Add-SafeguardUserLinkedAccount" "Add linked account failed" }
      try {
         $linked = Get-SafeguardUserLinkedAccount -UserToGet $DATA.userUserName
         foreach ($acct in $linked) { goodResult "Get-SafeguardUserLinkedAccount" "User $($DATA.userUserName) linked account $($acct.Name)" }
      } catch {
         badResult "Get-SafeguardUserLinkedAccount" "Failed" $_
      }
      try {
         Remove-SafeguardUserLinkedAccount -UserToSet $DATA.userUserName -DirectoryToRemove $DATA.domainName -AccountToRemove $DATA.directoryAccounts[0] > $null
         goodResult "Remove-SafeguardUserLinkedAccount" "Successfully removed linked account from $($DATA.userUserName)"
      } catch {
         badResult "Remove-SafeguardUserLinkedAccount" "Failed" $_
      }
   }

   try {
      Remove-SafeguardDirectoryAccount -DirectoryToUse $DATA.domainName -AccountToDelete $DATA.directoryAccounts[2] > $null
      goodResult "Remove-SafeguardDirectoryAccount" "Successfully removed $($DATA.directoryAccounts[2]) from $($DATA.domainName)"
   } catch {
      badResult "Remove-SafeguardDirectoryAccount" "Failed" $_
   }

   try {
      $result = Remove-SafeguardDirectory -DirectoryToDelete $DATA.domainName
      goodResult "Remove-SafeguardDirectory" "Successfully removed directory $($DATA.domainName)"
   } catch {
      badResult "Remove-SafeguardDirectory" "Failed" $_
   }

} catch {
      badResult "Directory general" "Unexpected error in Directory test" $_
} finally {
   try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $DATA.domainName > $null } } catch {}
   try { if ($userAdded -eq 1) { Remove-SafeguardUser -UserToDelete $DATA.userUsername > $null } } catch {}
}

testBlockHeader $TestBlockName $blockInfo
