try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Users Tests"
$blockInfo = testBlockHeader $TestBlockName 9
# ===== Covered Commands =====
# Disable-SafeguardUser
# Edit-SafeguardUser
# Enable-SafeguardUser
# Find-SafeguardUser
# Get-SafeguardUser
# New-SafeguardUser
# Rename-SafeguardUser
# Set-SafeguardUserPassword
# Get-SafeguardDeletedUser
# Remove-SafeguardDeletedUser
# Restore-SafeguardDeletedUser

#
try {
   # this will throw an exception if the user can not be found or created
   $newUser = createUser $DATA.userUsername

   $getuser = Get-SafeguardUser -UserToGet $DATA.userUsername
   goodResult "Get-SafeguardUser" "Successfully got $($Data.userUserName)"

   Set-SafeguardUserPassword -Password $DATA.secUserPassword -UserToEdit $DATA.userUsername > $null
   goodResult "Set-SafeguardUserPassword" "$($newUser.Name) created"
   $newUser = Edit-SafeguardUser -UserToEdit $DATA.userUsername -EmailAddress $DATA.userEmail
   if (-not $newUser.EmailAddress.Contains($DATA.userEmail)) { badResult "Edit-SafeguardUser" "Email address failed" }
   else { goodResult "Edit-SafeguardUser" "successfully changed email to $($newUser.EmailAddress)" }

	try{
		$newUser = Disable-SafeguardUser -UserToEdit $newUser.Name
		goodResult "Disable-SafeguardUser" "User $($newUser.Name) Disabled is $($newUser.Disabled)"
	} catch {
		badResult "Disable-SafeguardUser" "User $($newUser.Name) "  $_
	}
	try{
		$newUser = Enable-SafeguardUser -UserToEdit $newUser.Name
		goodResult "Enable-SafeguardUser" "User $($newUser.Name) Disabled is $($newUser.Disabled)"
	} catch {
		badResult "Enable-SafeguardUser" "User $($newUser.Name) "  $_
	}
   
   try{
	$renamedUser = Rename-SafeguardUser -UserToEdit $newUser.Name -NewUserName $DATA.renamedUsername
	if ($renamedUser.Name -ne $newUser.Name) {
      goodResult "Rename-SafeguardUser" "User $($newUser.Name) renamed to $($renamedUser.Name)"
      $newUser = Rename-SafeguardUser -UserToEdit $renamedUser.Name -NewUserName $newUser.Name
      goodResult "Rename-SafeguardUser" "User $($renamedUser.Name) changed back to to $($newUser.Name)"
	}
	else {
		badResult "Rename-SafeguardUser" "User $($newUser.Name) NOT renamed"
	}
   } catch {
		badResult "Rename-SafeguardUser" "User $($newUser.Name) NOT renamed" $_
   }

   $foundUser = Find-SafeguardUser $Data.userUserName
   if ($foundUser) { goodResult "Find-SafeguardUser" "found $($Data.userUserName)" }
   else { badResult "Find-SafeguardUser" "DID NOT find $($Data.userUserName)" }

   # create a user to delete, restore, and remove
   $delResUser = createUser "delres_$($DATA.userUsername)"
   try{
		Remove-SafeguardUser $delResUser.Name > $null
		infoResult "Deleted User" "Successfully created and deleted user for testing Id=$($delResUser.Id) Name=$($delResUser.Name)"
	} catch{
		badResult "Remove-SafeguardUser" "Failed to remove user: '$($delResUser.Name)'." $_
	}
   try {
      $delUserList = (Get-SafeguardDeletedUser) | Where-Object {$_.Name -ieq "$($delResUser.Name)"}
      goodResult "Get-SafeguardDeletedUser" "Successfully retrieved $($delUserList.Count) deleted users"
   } catch {
      badResult "Get-SafeguardDeletedUser" "Failed to retrieve deleted user $($delResUser.Name)"
   }

   try {
      $restored = Restore-SafeguardDeletedUser -UserToRestore $delResUser.Id
      goodResult "Restore-SafeguardDeletedUser" "Successfully restored deleted user Id=$($delResUser.Id) Name=$($restored.Name), new Id=$($restored.Id)"
   } catch {
      badResult "Restore-SafeguardDeletedUser" "Failed to restore deleted user $($delResUser.Name)"
   }

   try {
      Remove-SafeguardUser $restored.Id > $null
      Remove-SafeguardDeletedUser -UserToDelete $restored.Id > $null
      goodResult "Remove-SafeguardDeletedUser" "Successfully purged deleted user Id=$($restored.Id) Name=$($restored.Name)"
   } catch {
      badResult "Remove-SafeguardDeletedUser" "Failed to purge deleted user Id=$($restored.Id) $($delResUser.Name)"
   }
} catch {
      badResult "Users general" "Unexpected error in Users test" $_
} finally {
   try { Remove-SafeguardUser -UserToDelete $DATA.userUsername > $null } catch {}
   try { Remove-SafeguardUser -UserToDelete $DATA.renamedUsername > $null } catch {}
   if ($delResUser) { try { Remove-SafeguardUser -UserToDelete $delResUser > $null } catch {} }
}

testBlockHeader $TestBlockName $blockInfo
