try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

# TODO
#Get-SafeguardUserPreference
#Remove-SafeguardUserPreference
#Set-SafeguardUserPreference

$GLOBALS.currentTest = $DATA.Tests.Users
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:delResUser = $GLOBALS.createUser("delres_$($DATA.userUsername)").newUser

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Remove-SafeguardUser -UserToDelete $DATA.userUsername -ErrorAction SilentlyContinue > $null } catch {}
   try { Remove-SafeguardUser -UserToDelete $DATA.renamedUsername -ErrorAction SilentlyContinue > $null } catch {}
   try { Remove-SafeguardUser -UserToDelete $script:delResUser -ErrorAction SilentlyContinue > $null } catch {}
}

try {
   # this will throw an exception if the user can not be found or created
   $newUser = $GLOBALS.createUser($DATA.userUsername).newUser

   $getuser = Get-SafeguardUser -UserToGet $DATA.userUsername
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardUser"; message = "Successfully got $($Data.userUserName)"; })

   Set-SafeguardUserPassword -Password $DATA.secUserPassword -UserToEdit $DATA.userUsername > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardUserPassword"; message = "$($newUser.Name) created"; })
   $newUser = Edit-SafeguardUser -UserToEdit $DATA.userUsername -EmailAddress $DATA.userEmail
   if (-not $newUser.EmailAddress.Contains($DATA.userEmail)) { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardUser"; message = "Email address failed"; }) }
   else { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardUser"; message = "successfully changed email to $($newUser.EmailAddress)"; }) }

   $newUser = Disable-SafeguardUser -UserToEdit $newUser.Name
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Disable-SafeguardUser"; message = "User $($newUser.Name) Disabled is $($newUser.Disabled)"; })
   $newUser = Enable-SafeguardUser -UserToEdit $newUser.Name
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardUser"; message = "User $($newUser.Name) Disabled is $($newUser.Disabled)"; })

   $renamedUser = Rename-SafeguardUser -UserToEdit $newUser.Name -NewUserName $DATA.renamedUsername
   if ($renamedUser.Name -ne $newUser.Name) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Rename-SafeguardUser"; message = "User $($newUser.Name) renamed to $($renamedUser.Name)"; })
      $newUser = Rename-SafeguardUser -UserToEdit $renamedUser.Name -NewUserName $newUser.Name
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Rename-SafeguardUser"; message = "User $($renamedUser.Name) changed back to to $($newUser.Name)"; })
   }
   else {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Rename-SafeguardUser"; message = "User $($newUser.Name) NOT renamed"; })
   }

   $foundUser = Find-SafeguardUser $Data.userUserName
   if ($foundUser) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardUser"; message = "found $($Data.userUserName)"; }) }
   else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardUser"; message = "DID NOT find $($Data.userUserName)"; }) }

   # create a user to delete, restore, and remove
   Remove-SafeguardUser $script:delResUser.Name > $null
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Deleted User"; message = "Successfully created and deleted user for testing Id=$($script:delResUser.Id) Name=$($script:delResUser.Name)"; })

   try {
      $delUserList = (Get-SafeguardDeletedUser) | Where-Object {$_.Name -ieq "$($script:delResUser.Name)"}
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDeletedUser"; message = "Successfully retrieved $($delUserList.Count) deleted users"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDeletedUser"; message = "Failed to retrieve deleted user $($script:delResUser.Name)"; })
   }

   try {
      $restored = Restore-SafeguardDeletedUser -UserToRestore $script:delResUser.Id
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Restore-SafeguardDeletedUser"; message = "Successfully restored deleted user Id=$($script:delResUser.Id) Name=$($restored.Name), new Id=$($restored.Id)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Restore-SafeguardDeletedUser"; message = "Failed to restore deleted user $($script:delResUser.Name)"; })
   }

   try {
      Remove-SafeguardUser $restored.Id > $null
      Remove-SafeguardDeletedUser -UserToDelete $restored.Id > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardDeletedUser"; message = "Successfully purged deleted user Id=$($restored.Id) Name=$($restored.Name)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardDeletedUser"; message = "Failed to purge deleted user Id=$($restored.Id) $($script:delResUser.Name)"; })
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Users general"; message = "Unexpected error in Users test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

