try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Asset Partition Tests"
$blockInfo = testBlockHeader $TestBlockName
# ===== Covered Commands =====
# Add-SafeguardAssetPartitionOwner
# Edit-SafeguardAssetPartition
# Enter-SafeguardAssetPartition
# Exit-SafeguardAssetPartition
# Find-SafeguardUser
# Get-SafeguardAssetPartitionOwner
# Get-SafeguardCurrentAssetPartition
# New-SafeguardAssetPartition
# New-SafeguardUser
# Remove-SafeguardAssetPartition
# Remove-SafeguardAssetPartitionOwner
# Remove-SafeguardUser
# 
try {
   $newPartitionName = "New Asset Partition"
   $newPartition = New-SafeguardAssetPartition -Name $newPartitionName
   goodResult "New-SafeguardAssetPartition" "partition created $($newPartition.name)"
   $newPartition = Edit-SafeguardAssetPartition -AssetPartitionToEdit $($newPartition.Name) -Description "Edited Asset partition description"
   goodResult "Edit-SafeguardAssetPartition" "partition edited $($newPartition.name)  Description '$($newPartition.Description)'"

   $partitionOwnerUser = Find-SafeguardUser $DATA.partitionOwnerUserName
   if (-not $partitionOwnerUser) {
      $partitionOwnerUser = New-SafeguardUser -NewUserName $DATA.partitionOwnerUserName -FirstName "Safeguard-ps" -LastName "PartitionOwner" -NoPassword -Provider -1
      infoResult "New-SafeguardUser" "$($partitionOwnerUser.UserName) user created for partition owner testing" $null
      $deletePartitionOwner = $true
   }
   else {
      infoResult "Find-SafeguardUser" "using existing $($partitionOwnerUser.UserName) user for partition owner testing" $null
      $deletePartitionOwner = $false
   }

   Add-SafeguardAssetPartitionOwner -AssetPartitionToEdit "$($newPartition.name)" -UserList $partitionOwnerUser.UserName > $null
   goodResult "Add-SafeguardAssetPartitionOwner" "$($newPartition.name) owner set to $($partitionOwnerUser.UserName)"
   Get-SafeguardAssetPartitionOwner -AssetPartitionToGet "$($newPartition.name)" | format-table

   Enter-SafeguardAssetPartition -AssetPartitionToEnter $newPartition.name > $null
   goodResult "Enter-SafeguardAssetPartition" "entered $($newPartition.name)"
   Get-SafeguardCurrentAssetPartition | format-table
   Exit-SafeguardAssetPartition > $null
   goodResult "Exit-SafeguardAssetPartition" "exited $($newPartition.name)"
   Get-SafeguardCurrentAssetPartition | format-table
   Remove-SafeguardAssetPartitionOwner -AssetPartitionToEdit "$($newPartition.name)" -UserList $partitionOwnerUser.UserName > $null
   goodResult "Remove-SafeguardAssetPartitionOwner" "$($newPartition.name) owner removed $($partitionOwnerUser.UserName)"
   Get-SafeguardAssetPartitionOwner -AssetPartitionToGet "$($newPartition.name)" | format-table

   if ($deletePartitionOwner) {
      Remove-SafeguardUser -UserToDelete $DATA.partitionOwnerUserName -ErrorAction:SilentlyContinue > $null
      infoResult "Remove-SafeguardUser" "- removed $($partitionOwnerUser.UserName)"
   }
   Remove-SafeguardAssetPartition -AssetPartitionToDelete "$($newPartition.name)" > $null
   goodResult "Remove-SafeguardAssetPartition" "$($newPartition.name) removed"
}
catch {
   badResult "general" "Error working with Asset Partitions" $_
} finally {
   if ($deletePartitionOwner) { try { Remove-SafeguardUser -UserToDelete $DATA.partitionOwnerUserName > $null} catch {} }
   try { Remove-SafeguardAssetPartition -AssetPartitionToDelete "$newPartitionName" > $null } catch { }
}

testBlockHeader $TestBlockName $blockInfo
