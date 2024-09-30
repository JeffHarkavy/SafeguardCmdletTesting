try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Directory
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:directoryAdded = 0
$script:userAdded = 0

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { if ($script:directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $DATA.domainName -ErrorAction SilentlyContinue > $null } } catch {}
   try { if ($script:userAdded -eq 1) { Remove-SafeguardUser -UserToDelete $DATA.basicUser.userName -ErrorAction SilentlyContinue > $null } } catch {}
}

try {
   if ($DATA.requiredDNS -ne "") {
      $x0 = Get-SafeguardNetworkInterface "X0"
      if ($x0.DnsServers -contains $DATA.requiredDNS) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardNetworkInterface"; message = "$($DATA.requiredDNS) already present in X0 DNS list"; })
      } else {
         try {
            Set-SafeguardNetworkInterface -Interface "X0" -DnsServers $(,$DATA.requiredDNS+$($x0.DnsServers))
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardNetworkInterface"; message = "$DATA.requiredDNS added to X0 DNS Servers"; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardNetworkInterface"; message = "Unexpected error setting DNS $DATA.requiredDNS on X0"; ex = $_; })
            throw $_.Exception
         }
      }
   }

   # for password getting/setting the default password rule has to be a little beefier
   # adjust to fit, ymmv
   $passwordRule = Get-SafeguardAccountPasswordRule -PasswordRuleToGet "Macrocosm Password Rule" -AssetPartitionID -1
   if ($passwordRule.MinCharacters -ge 10 -and $passwordRule.MaxCharacters -ge 20) {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccountPasswordRule"; message = "Macrocosm Password Rule has Min=$($passwordRule.MinCharacters) Max=$($passwordRule.MaxCharacters) characters"; })
   } else {
      $passwordRule = Edit-SafeguardAccountPasswordRule -PasswordRuleToEdit "Macrocosm Password Rule" `
          -AssetPartitionID -1 `
          -MinCharacters (@($passwordRule.MinCharacters,10)|measure-object -Maximum).Maximum `
          -MaxCharacters (@($passwordRule.MaxCharacters,20)|measure-object -Maximum).Maximum
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAccountPasswordRule"; message = "Macrocosm Password Rule updated to Min=$($passwordRule.MinCharacters) Max=$($passwordRule.MaxCharacters) characters"; })
   }

   try {
      Get-SafeguardDirectoryMigrationData $DATA.appliance
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDirectoryMigrationData"; message = "Success - results may be empty"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDirectoryMigrationData"; message = "Unexpected error getting getting migration data on $($DATA.appliance)"; ex = $_; })
   }

   try {
      $newDirectory = Get-SafeguardDirectory -DirectoryToGet $DATA.domainName
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDirectory"; message = "$($DATA.domainName) directory already exists"; })
   } catch {
      if ($_.Exception.Message -match "unable to find") {
         $newDirectory = New-SafeguardDirectory -ServiceAccountDomainName $DATA.domainName -ServiceAccountName $DATA.domainAdmin -ServiceAccountPassword $DATA.domainPassword
         $script:directoryAdded = 1
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardDirectory"; message = "$($DATA.domainName) successfully created"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDirectory"; message = "Unexpected error getting directory $($DATA.domainName)"; ex = $_; })
         throw $_.Exception
      }
   }

   try {
      $newDirectory = Edit-SafeguardDirectory -DirectoryToEdit $($DATA.domainName) -Description "New Description for $($DATA.domainName)"
      $newDirectory
      if ($newDirectory.Description -eq "New Description for $($DATA.domainName)") { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardDirectory"; message = "Successfully edited"; }) }
      else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardDirectory"; message = "Edit failed"; }) }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardDirectory"; message = "Unexpected error editing directory $($DATA.domainName)"; ex = $_; })
      throw $_.Exception
   }

   Test-SafeguardDirectory -DirectoryToTest $DATA.domainName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardDirectory"; message = "Successfully called test on directory $($DATA.domainName)"; })

   $existingAccounts = Get-SafeguardDirectoryAccount -DirectoryToGet $DATA.domainName -Fields Name
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDirectoryAccount"; message = "Found $($existingAccounts.Count) accounts"; })
   foreach ($acctname in $DATA.directoryAccounts.GetEnumerator()) {
      $found = Find-SafeguardAssetAccount -QueryFilter "Asset.Name eq '$($DATA.domainName)' and Name eq '$acctname'"
      if ($found) { $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardDirectoryAccount"; message = "$acctname already exists on $($DATA.domainName)"; }) }
      else {
         try {
            $newacct = New-SafeguardDirectoryAccount -ParentDirectory $newDirectory -NewAccountName $acctname
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardDirectoryAccount"; message = "$acctName successfully created on $($DATA.domainName)"; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardDirectoryAccount"; message = "Unexpected error creating $acctName on $($DATA.domainName)"; ex = $_; })
         }
      }
   }

   # TODO
   # Can't get this one to work no matter what
   # Keep it here and let it "fail" until i figure out wth is going on
   $diracct = Find-SafeguardDirectoryAccount $DATA.directoryAccounts[0]
   if ($diracct) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardDirectoryAccount"; message = "Found directory account $($DATA.directoryAccounts[0])"; }) }
   else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardDirectoryAccount"; message = "Did not find directory account $($DATA.directoryAccounts[0])"; }) }

   $randpwd = New-SafeguardDirectoryAccountRandomPassword -DirectoryToUse $DATA.domainName -AccountToUse $DATA.directoryAccounts[0]
   if ($randpwd -ne "") { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardDirectoryAccountRandomPassword"; message = "Random password for $($DATA.directoryAccounts[0]) $randpwd"; }) }
   else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardDirectoryAccountRandomPassword"; message = "Random password failed for $($DATA.directoryAccounts[0])"; }) }

   $diracct = Get-SafeguardDirectoryAccount -DirectoryToGet $DATA.domainName -AccountToGet $DATA.directoryAccounts[0]
   $diracct.Description = "Edit description for $($DATA.domainName)\$($diracct.Name)"
   $diracct = Edit-SafeguardDirectoryAccount -AccountObject $diracct
   if ($diracct.Description -ne "") { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardDirectoryAccount"; message = "Successful directory account edit for $($DATA.domainName)\$($diracct.Name)"; }) }
   else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardDirectoryAccount"; message = "Edit failed for $($DATA.domainName)\$($diracct.Name)"; }) }

   $newpassword = $randpwd | ConvertTo-SecureString -AsPlainText -Force
   try {
      Set-SafeguardDirectoryAccountPassword -DirectoryToSet $DATA.domainName -AccountToSet $diracct -NewPassword $newpassword > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardDirectoryAccountPassword"; message = "Successfully set password on $($DATA.domainName)\$($diracct.Name)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardDirectoryAccountPassword"; message = "Set password failed on $($DATA.domainName)\$($diracct.Name)"; ex = $_; })
   }

   Invoke-SafeguardDirectoryAccountPasswordChange -DirectoryToUse $DATA.domainName -AccountToUse $DATA.directoryAccounts[0]
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardDirectoryAccountPasswordChange"; message = "Successfully called change password on $($DATA.domainName)\$($DATA.directoryAccounts[0])"; })

   Test-SafeguardDirectoryAccountPassword -DirectoryToUse $DATA.domainName -AccountToUse $DATA.directoryAccounts[0]
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardDirectoryAccountPassword"; message = "Successfully called test on $($DATA.domainName)\$($DATA.directoryAccounts[0])"; })

   Sync-SafeguardDirectory -DirectoryToSync $DATA.domainName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Sync-SafeguardDirectory"; message = "Successful called sync on directory $($DATA.domainName)"; })

   Sync-SafeguardDirectoryAsset -DirectoryAssetToSync $DATA.domainName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Sync-SafeguardDirectoryAsset"; message = "Successful called sync on directory asset $($DATA.domainName)"; })

   try {
      $newUser = $GLOBALS.createUser($DATA.basicUser.userName).newUser
   }
   catch {
      # Not fatal, just skip the linked account tests if we don't have a user
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Add-SafeguardUserLinkedAccount"; message = "$DATA.basicUser.userName not created or available. Skipping LinkedAccount tests"; })
   }

   if ($newUser) {
      $linked = Add-SafeguardUserLinkedAccount -UserToSet $DATA.basicUser.userName -DirectoryToAdd $DATA.domainName -AccountToAdd $DATA.directoryAccounts[0]
      if ($linked.Name -eq $DATA.directoryAccounts[0]) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Add-SafeguardUserLinkedAccount"; message = "Added Linked $($DATA.directoryAccounts[0]) account to $($DATA.basicUser.userName)"; }) }
      else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Add-SafeguardUserLinkedAccount"; message = "Add linked account failed"; }) }
      try {
         $linked = Get-SafeguardUserLinkedAccount -UserToGet $DATA.basicUser.userName
         foreach ($acct in $linked) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardUserLinkedAccount"; message = "User $($DATA.basicUser.userName) linked account $($acct.Name)"; }) }
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardUserLinkedAccount"; message = "Failed"; ex = $_; })
      }
      try {
         Remove-SafeguardUserLinkedAccount -UserToSet $DATA.basicUser.userName -DirectoryToRemove $DATA.domainName -AccountToRemove $DATA.directoryAccounts[0] > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardUserLinkedAccount"; message = "Successfully removed linked account from $($DATA.basicUser.userName)"; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardUserLinkedAccount"; message = "Failed"; ex = $_; })
      }
   }

   try {
      Remove-SafeguardDirectoryAccount -DirectoryToUse $DATA.domainName -AccountToDelete $DATA.directoryAccounts[2] > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardDirectoryAccount"; message = "Successfully removed $($DATA.directoryAccounts[2]) from $($DATA.domainName)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardDirectoryAccount"; message = "Failed"; ex = $_; })
   }

   try {
      $result = Remove-SafeguardDirectory -DirectoryToDelete $DATA.domainName
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardDirectory"; message = "Successfully removed directory $($DATA.domainName)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardDirectory"; message = "Failed"; ex = $_; })
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Directory general"; message = "Unexpected error in Directory test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

