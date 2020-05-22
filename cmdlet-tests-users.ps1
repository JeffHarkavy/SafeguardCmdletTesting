try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName = "Running Users Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
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
   try {
      $newUser = Get-SafeguardUser -UserToGet $userUsername
      infoResult "Get-SafeguardUser"  "$($newUser.UserName) already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $newUser = New-SafeguardUser -NewUserName $userUsername -FirstName "Safeguard-ps" -LastName "User" -NoPassword -Provider -1
         goodResult "New-SafeguardUser"  "$($newUser.UserName) created"
      }
      else {
         badResult "New-SafeguardUser"  "Unexpected error fetching $($newUser.UserName)" $_.Exception
         throw $_.Exception
      }
   }
   Set-SafeguardUserPassword -Password $secUserPassword -UserToEdit $userUsername > $null
   goodResult "Set-SafeguardUserPassword"  "$($newUser.UserName) created"
   $newUser = Edit-SafeguardUser -UserToEdit $userUsername -EmailAddress $userEmail
   if (-not $newUser.EmailAddress.Contains($userEmail)) { badResult "Edit-SafeguardUser"  "Email address failed" }
   else { goodResult "Edit-SafeguardUser"  "successfull changed email to $($newUser.EmailAddress)" }

   $newUser = Disable-SafeguardUser -UserToEdit $newUser.UserName
   goodResult "Disable-SafeguardUser"  "User $($newUser.UserName) Disabled is $($newUser.Disabled)"
   $newUser = Enable-SafeguardUser -UserToEdit $newUser.UserName
   goodResult "Enable-SafeguardUser"  "User $($newUser.UserName) Disabled is $($newUser.Disabled)"

   $renamedUser = Rename-SafeguardUser -UserToEdit $newUser.UserName -NewUserName $renamedUsername
   if ($renamedUser.UserName -ne $newUser.UserName) {
      goodResult "Rename-SafeguardUser"  "User $($newUser.UserName) renamed to $($renamedUser.UserName)"
      $newUser = Rename-SafeguardUser -UserToEdit $renamedUser.UserName -NewUserName $newUser.UserName
      goodResult "Rename-SafeguardUser"  "User $($renamedUser.UserName) changed back to to $($newUser.UserName)"
   }
   else {
      badResult "Rename-SafeguardUser"  "User $($newUser.UserName) NOT renamed"
   }

   $foundUser = Find-SafeguardUser $userUserName
   if ($null -ne $foundUser) {
      goodResult "Find-SafeguardUser"  "found $($newUser.UserName)"
   }
   else {
      badResult "Find-SafeguardUser"  "DID NOT find $($newUser.UserName)"
   }
} catch {
      badResult "Users general" "Unexpected error in Users test" $_.Exception
} finally {
   try { Remove-SafeguardUser -UserToDelete $userUsername > $null } catch {}
   try { Remove-SafeguardUser -UserToDelete $renamedUsername > $null } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo
