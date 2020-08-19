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
#
try {
   # this will throw an exception if the user can not be found or created
   $newUser = createUser $DATA.userUsername

   $getuser = Get-SafeguardUser -UserToGet $DATA.userUsername
   goodResult "Get-SafeguardUser" "Successfully got $($Data.userUserName)"

   Set-SafeguardUserPassword -Password $DATA.secUserPassword -UserToEdit $DATA.userUsername > $null
   goodResult "Set-SafeguardUserPassword" "$($newUser.UserName) created"
   $newUser = Edit-SafeguardUser -UserToEdit $DATA.userUsername -EmailAddress $DATA.userEmail
   if (-not $newUser.EmailAddress.Contains($DATA.userEmail)) { badResult "Edit-SafeguardUser" "Email address failed" }
   else { goodResult "Edit-SafeguardUser" "successfully changed email to $($newUser.EmailAddress)" }

   $newUser = Disable-SafeguardUser -UserToEdit $newUser.UserName
   goodResult "Disable-SafeguardUser" "User $($newUser.UserName) Disabled is $($newUser.Disabled)"
   $newUser = Enable-SafeguardUser -UserToEdit $newUser.UserName
   goodResult "Enable-SafeguardUser" "User $($newUser.UserName) Disabled is $($newUser.Disabled)"

   $renamedUser = Rename-SafeguardUser -UserToEdit $newUser.UserName -NewUserName $DATA.renamedUsername
   if ($renamedUser.UserName -ne $newUser.UserName) {
      goodResult "Rename-SafeguardUser" "User $($newUser.UserName) renamed to $($renamedUser.UserName)"
      $newUser = Rename-SafeguardUser -UserToEdit $renamedUser.UserName -NewUserName $newUser.UserName
      goodResult "Rename-SafeguardUser" "User $($renamedUser.UserName) changed back to to $($newUser.UserName)"
   }
   else {
      badResult "Rename-SafeguardUser" "User $($newUser.UserName) NOT renamed"
   }

   $foundUser = Find-SafeguardUser $Data.userUserName
   if ($foundUser) { goodResult "Find-SafeguardUser" "found $($Data.userUserName)" }
   else { badResult "Find-SafeguardUser" "DID NOT find $($Data.userUserName)" }
} catch {
      badResult "Users general" "Unexpected error in Users test" $_
} finally {
   try { Remove-SafeguardUser -UserToDelete $DATA.userUsername > $null } catch {}
   try { Remove-SafeguardUser -UserToDelete $DATA.renamedUsername > $null } catch {}
}

testBlockHeader $TestBlockName $blockInfo
