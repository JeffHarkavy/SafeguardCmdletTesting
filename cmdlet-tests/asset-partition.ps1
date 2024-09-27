try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.AssetPartition
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   if ($deletePartitionOwner) { try { Remove-SafeguardUser -UserToDelete $DATA.partitionOwnerUserName -ErrorAction SilentlyContinue > $null} catch {} }
   try { Remove-SafeguardAssetPartition -AssetPartitionToDelete "$newPartitionName" -ErrorAction SilentlyContinue > $null } catch { }
}

try {
   $newPartitionName = "New Asset Partition"
   $newPartition = New-SafeguardAssetPartition -Name $newPartitionName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAssetPartition"; message = "partition created $($newPartition.name)"; })
   $newPartition = Edit-SafeguardAssetPartition -AssetPartitionToEdit $($newPartition.Name) -Description "Edited Asset partition description"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAssetPartition"; message = "partition edited $($newPartition.name)  Description '$($newPartition.Description)'"; })

   $partitionOwnerUser = Find-SafeguardUser $DATA.partitionOwnerUserName
   if (-not $partitionOwnerUser) {
      $partitionOwnerUser = New-SafeguardUser -NewUserName $DATA.partitionOwnerUserName -FirstName "Safeguard-ps" -LastName "PartitionOwner" -NoPassword -Provider -1
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardUser"; message = "$($partitionOwnerUser.UserName) user created for partition owner testing"; })
      $deletePartitionOwner = $true
   }
   else {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Find-SafeguardUser"; message = "using existing $($partitionOwnerUser.UserName) user for partition owner testing"; })
      $deletePartitionOwner = $false
   }

   Add-SafeguardAssetPartitionOwner -AssetPartitionToEdit "$($newPartition.name)" -UserList $partitionOwnerUser.Name > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Add-SafeguardAssetPartitionOwner"; message = "$($newPartition.name) owner set to $($partitionOwnerUser.Name)"; })
   $result = Get-SafeguardAssetPartitionOwner -AssetPartitionToGet "$($newPartition.name)"
   $GLOBALS.formatTable(@{ output = $result; })

   Enter-SafeguardAssetPartition -AssetPartitionToEnter $newPartition.name > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enter-SafeguardAssetPartition"; message = "entered $($newPartition.name)"; })
   $GLOBALS.formatTable(@{ output = (Get-SafeguardCurrentAssetPartition); })

   Exit-SafeguardAssetPartition > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Exit-SafeguardAssetPartition"; message = "exited $($newPartition.name)"; })
   $GLOBALS.formatTable(@{ output = (Get-SafeguardCurrentAssetPartition); })

   Remove-SafeguardAssetPartitionOwner -AssetPartitionToEdit "$($newPartition.name)" -UserList $partitionOwnerUser.Name > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAssetPartitionOwner"; message = "$($newPartition.name) owner removed $($partitionOwnerUser.Name)"; })
   $GLOBALS.formatTable(@{ output = (Get-SafeguardAssetPartitionOwner -AssetPartitionToGet "$($newPartition.name)"); })

   if ($deletePartitionOwner) {
      Remove-SafeguardUser -UserToDelete $DATA.partitionOwnerUserName -ErrorAction:SilentlyContinue > $null
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardUser"; message = "- removed $($partitionOwnerUser.Name)"; })
   }
   Remove-SafeguardAssetPartition -AssetPartitionToDelete "$($newPartition.name)" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAssetPartition"; message = "$($newPartition.name) removed"; })

   $script:completedSuccessfully = $true
}
catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error working with Asset Partitions"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

