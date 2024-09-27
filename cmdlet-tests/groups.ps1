try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Groups
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:removeNewGroupUser = $false

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Remove-SafeguardUserGroup -GroupToDelete "$($DATA.userGroupName)" -ErrorAction SilentlyContinue > $null } catch {}
   try { Remove-SafeguardAssetGroup -GroupToDelete "$($DATA.assetGroupName)" -ErrorAction SilentlyContinue > $null } catch {}
   try { Remove-SafeguardAccountGroup -GroupToDelete "$($DATA.accountGroupName)" -ErrorAction SilentlyContinue > $null } catch {}
   if ($script:removeNewGroupUser) { try { Remove-SafeguardUser -UserToDelete $DATA.userUsername -ErrorAction SilentlyContinue > $null } catch {} }
}

try {
   $groupname = $DATA.userGroupName
   try {
      $userGroup = (Get-SafeguardUserGroup -GroupToGet "$groupname")[0]
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardUserGroup"; message = "$groupname already exists"; })
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $userGroup = New-SafeguardUserGroup -Name "$groupname"
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardUserGroup"; message = "$($userGroup.Name) successfully added"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardUserGroup"; message = "Unexpected error fetching $groupname"; ex = $_; })
         throw $_.Exception
      }
   }
   $userGroup = Edit-SafeguardUserGroup -GroupToEdit "$groupname" -Description "Description for $groupname"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardUserGroup"; message = "Successfully edited $($userGroup.Name) Description '$($userGroup.Description)'"; })

   $groupname = $DATA.assetGroupName
   try {
      $assetGroup = (Get-SafeguardAssetGroup -GroupToGet "$groupname")[0]
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAssetGroup"; message = "$groupname already exists"; })
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $assetGroup = New-SafeguardAssetGroup -Name "$groupname" -Description "Description for $groupname"
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAssetGroup"; message = "$($assetGroup.Name) successfully added"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardAssetGroup"; message = "Unexpected error fetching $groupname" ; ex = $_; })
         throw $_.Exception
      }
   }

   $groupname = $DATA.accountGroupName
   try {
      $accountGroup = (Get-SafeguardAccountGroup -GroupToGet "$groupname")[0]
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccountGroup"; message = "$groupname already exists"; })
   }
   catch {
      if ($_.Exception.Message -match "unable to find") {
         $accountGroup = New-SafeguardAccountGroup -Name "$groupname" -Description "Description for $groupname"
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccountGroup"; message = "$($accountGroup.Name) successfully added"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardAccountGroup"; message = "Unexpected error fetching $groupname" ; ex = $_; })
         throw $_.Exception
      }
   }

   try {
      try {
         New-SafeguardUser -NewUserName $DATA.userUsername -FirstName "Safeguard-ps" -LastName "User" -NoPassword -Provider -1 > $null
         $script:removeNewGroupUser = $true
      } catch {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardUser"; message = "User $($DATA.userUsername) already exists for user group testing"; })
      }

      Add-SafeguardUserGroupMember -Group $userGroup.Name -UserList $DATA.userUsername > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).Name
      if ($DATA.userUsername -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Add-SafeguardUserGroupMember"; message = "$($DATA.userUsername) successfully added to $($userGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Add-SafeguardUserGroupMember"; message = "$($DATA.userUsername) NOT found in $($userGroup.Name)"; })
      }

      Remove-SafeguardUserGroupMember -Group $userGroup.Name -UserList $DATA.userUsername > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).UserName
      if ($null -eq $groupMembers -or -not $DATA.userUsername -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardUserGroupMember"; message = "$($DATA.userUsername) successfully removed from $($userGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardUserGroupMember"; message = "$($DATA.userUsername) NOT found in $($userGroup.Name)"; })
      }

      Edit-SafeguardUserGroup -GroupToEdit $userGroup.Name -UserList $DATA.userUsername -Operation add > $null
      $groupMembers = (Get-SafeguardUserGroupMember -Group $userGroup.Name).Name
      if ($DATA.userUsername -in $groupMembers) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardUserGroup"; message = "$($DATA.userUsername) successfully edited to add to $($userGroup.Name)"; })
      }
      else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardUserGroup"; message = "$($DATA.userUsername) NOT edited to add to $($userGroup.Name)"; })
      }

      Remove-SafeguardUserGroup -GroupToDelete "$($DATA.userGroupName)" > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardUserGroup"; message = "Successfully removed $($DATA.userGroupName)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error adding $userUserName to group $($userGroup.Name)"; ex = $_; })
   } 

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Groups general"; message = "Unexpected error in Groups tests"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

