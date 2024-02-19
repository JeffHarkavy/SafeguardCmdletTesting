try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Groups Tests"
$blockInfo = testBlockHeader $TestBlockName 8
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
try {
   $groupname = $DATA.userGroupName
   try {
      $userGroup = (Get-SafeguardUserGroup -GroupToGet "$groupname")[0]
      infoResult "Get-SafeguardUserGroup" "$groupname already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $userGroup = New-SafeguardUserGroup -Name "$groupname"
         goodResult "New-SafeguardUserGroup" "$($userGroup.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardUserGroup" "Unexpected error fetching $groupname" $_
         throw $_.Exception
      }
   }
   $userGroup = Edit-SafeguardUserGroup -GroupToEdit "$groupname" -Description "Description for $groupname"
   goodResult "Edit-SafeguardUserGroup" "Successfully edited $($userGroup.Name) Description '$($userGroup.Description)'"

   $groupname = $DATA.assetGroupName
   try {
      $assetGroup = (Get-SafeguardAssetGroup -GroupToGet "$groupname")[0]
      infoResult "Get-SafeguardAssetGroup" "$groupname already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $assetGroup = New-SafeguardAssetGroup -Name "$groupname" -Description "Description for $groupname"
         goodResult "New-SafeguardAssetGroup" "$($assetGroup.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardAssetGroup" "Unexpected error fetching $groupname"  $_
         throw $_.Exception
      }
   }

   $groupname = $DATA.accountGroupName
   try {
      $accountGroup = (Get-SafeguardAccountGroup -GroupToGet "$groupname")[0]
      infoResult "Get-SafeguardAccountGroup" "$groupname already exists"
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $accountGroup = New-SafeguardAccountGroup -Name "$groupname" -Description "Description for $groupname"
         goodResult "New-SafeguardAccountGroup" "$($accountGroup.Name) successfully added"
      }
      else {
         badResult "Get-SafeguardAccountGroup" "Unexpected error fetching $groupname"  $_
         throw $_.Exception
      }
   }

   try {
      try {
         New-SafeguardUser -NewUserName $DATA.userUsername -FirstName "Safeguard-ps" -LastName "User" -NoPassword -Provider -1 > $null
         $removeNewGroupUser = $true
      } catch {
         infoResult "New-SafeguardUser" "User $($DATA.userUsername) already exists for user group testing"
      }

      Add-SafeguardUserGroupMember -Group $userGroup.Name -UserList $DATA.userUsername > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).Name
      if ($DATA.userUsername -in $groupMembers) {
         goodResult "Add-SafeguardUserGroupMember" "$($DATA.userUsername) successfully added to $($userGroup.Name)"
      }
      else {
         badResult "Add-SafeguardUserGroupMember" "$($DATA.userUsername) NOT found in $($userGroup.Name)"
      }

      Remove-SafeguardUserGroupMember -Group $userGroup.Name -UserList $DATA.userUsername > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).UserName
      if ($null -eq $groupMembers -or -not $DATA.userUsername -in $groupMembers) {
         goodResult "Remove-SafeguardUserGroupMember" "$($DATA.userUsername) successfully removed from $($userGroup.Name)"
      }
      else {
         badResult "Remove-SafeguardUserGroupMember" "$($DATA.userUsername) NOT found in $($userGroup.Name)"
      }

      Edit-SafeguardUserGroup -GroupToEdit $userGroup.Name -UserList $DATA.userUsername -Operation add > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).Name
      if ($DATA.userUsername -in $groupMembers) {
         goodResult "Edit-SafeguardUserGroup" "$($DATA.userUsername) successfully edited to add to $($userGroup.Name)"
      }
      else {
         badResult "Edit-SafeguardUserGroup" "$($DATA.userUsername) NOT edited to add to $($userGroup.Name)"
      }

      Remove-SafeguardUserGroup -GroupToDelete "$($DATA.userGroupName)" > $null
      goodResult "Remove-SafeguardUserGroup" "Successfully removed $($DATA.userGroupName)"
   } catch {
      badResult "general" "Error adding $userUserName to group $($userGroup.Name)" $_
   } 
} catch {
   badResult "Groups general" "Unexpected error in Groups tests" $_
} finally {
   try { Remove-SafeguardUserGroup -GroupToDelete "$($DATA.userGroupName)" > $null } catch {}
   try { Remove-SafeguardAssetGroup -GroupToDelete "$($DATA.assetGroupName)" > $null } catch {}
   try { Remove-SafeguardAccountGroup -GroupToDelete "$($DATA.accountGroupName)" > $null } catch {}
   if ($removeNewGroupUser) { try { Remove-SafeguardUser -UserToDelete $DATA.userUsername > $null } catch {} }
}

testBlockHeader $TestBlockName $blockInfo
