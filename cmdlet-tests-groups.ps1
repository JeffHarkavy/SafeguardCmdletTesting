try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
# ===== Covered Commands =====
# Add-SafeguardUserGroupMember
# Edit-SafeguardUserGroup
# Get-SafeguardAccountGroup
# Get-SafeguardAssetGroup
# Get-SafeguardUserGroup
# Get-SafeguardUserGroupMember
# New-SafeguardAccountGroup
# New-SafeguardAssetGroup
# New-SafeguardUserGroup
# Remove-SafeguardAssetGroup
# Remove-SafeguardAccountGroup
# Remove-SafeguardUserGroup
# Remove-SafeguardUserGroupMember
#
# n.b. - account/asset group member tests in separate file
#
writeCallHeader "Running Groups Tests"
try {
   $groupname = $userGroupName
   try {
      $userGroup = (Get-SafeguardUserGroup -GroupToGet "$groupname")[0]
      infoResult "Get-SafeguardUserGroup"  "$groupname already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $userGroup = New-SafeguardUserGroup -Name "$groupname"
         goodResult "New-SafeguardUserGroup"  "$($userGroup.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardUserGroup"  "Unexpected error fetching $groupname" $_.Exception
         throw $_.Exception
      }
   }
   $userGroup = Edit-SafeguardUserGroup -GroupToEdit "$groupname" -Description "Description for $groupname"
   goodResult "Edit-SafeguardUserGroup" "Successfully edited $($userGroup.Name) Description '$($userGroup.Description)'"

   $groupname = $assetGroupName
   try {
      $assetGroup = (Get-SafeguardAssetGroup -GroupToGet "$groupname")[0]
      infoResult "Get-SafeguardAssetGroup"  "$groupname already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $assetGroup = New-SafeguardAssetGroup -Name "$groupname" -Description "Description for $groupname"
         goodResult "New-SafeguardAssetGroup"  "$($assetGroup.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardAssetGroup"  "Unexpected error fetching $groupname"  $_.Exception
         throw $_.Exception
      }
   }

   $groupname = $accountGroupName
   try {
      $accountGroup = (Get-SafeguardAccountGroup -GroupToGet "$groupname")[0]
      infoResult "Get-SafeguardAccountGroup"  "$groupname already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $accountGroup = New-SafeguardAccountGroup -Name "$groupname" -Description "Description for $groupname"
         goodResult "New-SafeguardAccountGroup"  "$($accountGroup.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardAccountGroup"  "Unexpected error fetching $groupname"  $_.Exception
         throw $_.Exception
      }
   }

   try {
      try {
         New-SafeguardUser -NewUserName $userUsername -FirstName "Safeguard-ps" -LastName "User" -NoPassword -Provider -1 > $null
         $removeNewGroupUser = $true
      } catch {
         infoResult "New-SafeguardUser" "User $userUsername already exists for user group testing"
      }

      Add-SafeguardUserGroupMember -Group $userGroup.Name -UserList $userUsername > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).UserName
      if ($userUsername -in $groupMembers) {
         goodResult "Add-SafeguardUserGroupMember"  "$userUsername successfully added to $($userGroup.Name)"
      }
      else {
         badResult "Add-SafeguardUserGroupMember"  "$userUsername NOT found in $($userGroup.Name)"
      }

      Remove-SafeguardUserGroupMember -Group $userGroup.Name -UserList $userUsername > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).UserName
      if ($null -eq $groupMembers -or -not $userUsername -in $groupMembers) {
         goodResult "Remove-SafeguardUserGroupMember"  "$userUsername successfully removed from $($userGroup.Name)"
      }
      else {
         badResult "Remove-SafeguardUserGroupMember"  "$userUsername NOT found in $($userGroup.Name)"
      }

      Edit-SafeguardUserGroup -GroupToEdit $userGroup.Name -UserList $userUsername -Operation add > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).UserName
      if ($userUsername -in $groupMembers) {
         goodResult "Edit-SafeguardUserGroup"  "$userUsername successfully edited to add to $($userGroup.Name)"
      }
      else {
         badResult "Edit-SafeguardUserGroup"  "$userUsername NOT edited to add to $($userGroup.Name)"
      }

      Remove-SafeguardUserGroup -GroupToDelete "$userGroupName" > $null
      goodResult "Remove-SafeguardUserGroup" "Successfully removed $userGroupName"
   } catch {
      badResult "general"  "Error adding $userUserName to group $($userGroup.Name)" $_.Exception
   } 
} catch {
   badResult "Groups general"  "Unexpected error in Groups tests" $_.Exception
} finally {
   try { Remove-SafeguardUserGroup -GroupToDelete "$userGroupName" > $null } catch {}
   try { Remove-SafeguardAssetGroup -GroupToDelete "$assetGroupName" > $null } catch {}
   try { Remove-SafeguardAccountGroup -GroupToDelete "$accountGroupName" > $null } catch {}
   if ($removeNewGroupUser) { try { Remove-SafeguardUser -UserToDelete $userUsername > $null } catch {} }
}
