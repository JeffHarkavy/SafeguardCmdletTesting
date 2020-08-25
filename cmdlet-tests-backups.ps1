try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Backups Tests"
$blockInfo = testBlockHeader $TestBlockName
# === COVERED COMMANDS ===
# Get-SafeguardBackup
# Export-SafeguardBackup
# Import-SafeguardBackup
# Remove-SafeguardBackup
# New-SafeguardBackup
# Restore-SafeguardBackup
# Save-SafeguardBackupToArchive

try {
   $sleepSeconds = 5
   $localBackupFilename = "cmdlet-test-sgbackup_$testBranch_$("{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f (Get-Date)).sgb"
   $localBackupFilePath = "$($DATA.outputPaths.backups)\$localBackupFilename"
   $backups = Get-SafeguardBackup
   goodResult "Get-SafeguardBackup" "Successfull retrieved list of $($backups.Length) backups"
   ($backups) | Format-Table -Property Id,CreatedOn,Size,Status
   
   $newBackup = New-SafeguardBackup
   goodResult "New-SafeguardBackup" "Successfully started new safeguard backup id=$($newBackup.Id)"
   infoResult "New-SafeguardBackup" "Waiting for backup to complete"
   $secondsSlept = 0
   while ((Get-Safeguardbackup $newBackup.Id).Status -ne "Complete") {
      Start-Sleep -seconds $sleepSeconds
      $secondsSlept += $sleepSeconds
      Write-Host "$secondsSlept ... " -NoNewLine
   }
   Write-Host "Complete"
   $newBackup = Get-SafeguardBackup $newBackup.Id
   infoResult "New-SafeguardBackup" "Backup complete, size=$($newBackup.Size), filename=$($newBackup.Filename)"

   Export-SafeguardBackup -BackupId $newBackup.Id -OutFile "$localBackupFilePath"
   goodResult "Export-SafeguardBackup" "Downloaded backup to $localBackupFilePath"

   try {
      $createdArchiveServer = 0
      $archiveServer = Invoke-SafeguardMethod core GET ArchiveServers -Parameters @{filter="Name ieq '$($DATA.realArchiveServer.archSrvName)'"}

      if ($archiveServer.Count -eq 0) {
         $archiveServer = New-SafeguardArchiveServer -DisplayName $DATA.realArchiveServer.archSrvName `
           -NetworkAddress $DATA.realArchiveServer.NetworkAddress `
           -TransferProtocol $DATA.realArchiveServer.TransferProtocol `
           -Port $DATA.realArchiveServer.Port `
           -StoragePath $DATA.realArchiveServer.StoragePath `
           -ServiceAccountCredentialType $DATA.realArchiveServer.ServiceAccountCredentialType `
           -ServiceAccountName $DATA.realArchiveServer.ServiceAccountName `
           -ServiceAccountPassword $DATA.realArchiveServer.ServiceAccountPassword `
           -AcceptSshHostKey
         goodResult "New-SafeguardArchiveServer" "Successfully created Archive Server $($DATA.realArchiveServer.archSrvName) Id=$($archiveServer.Id)" 
         $createdArchiveServer = 1
      }

      Save-SafeguardBackupToArchive -BackupId $newBackup.Id -ArchiveServerId $archiveServer.Id
      goodResult "Save-SafeguardBackupToArchive" "Successfully archived backup to Archive Server $($DATA.realArchiveServer.archSrvName)" 
   } catch {
      if ($_ -match "That entity name is already in use") {
         # eh.  we tried.
         goodResult "Save-SafeguardBackupToArchive" "Successful-ish. Backup $($newBackup.FileName) already exists on $($DATA.realArchiveServer.archSrvName)" 
      } else {
         badResult "Save-SafeguardBackupToArchive" "Unexpected error" $_
      }
   } finally {
      if ($createdArchiveServer) { try{Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null} catch{} }
   }

   Remove-SafeguardBackup -BackupId $newBackup.Id > $null
   goodResult "Remove-SafeguardBackup" "Successfully removed backup id=$($newBackup.Id)"

   Import-SafeguardBackup -BackupFile "$localBackupFilePath" > $null
   goodResult "Import-SafeguardBackup" "Upload started for $localBackupFilename"

   infoResult "Restore-SafeguardBackup" "Do you want to restore using the backup you just made (possibly time-consuming)?"
   if ("Y" -eq (Read-Host "Enter Y to continue with backup restore tests on $($DATA.appliance)")) {
      $secondsSlept = 0
      while ((Get-Safeguardbackup $newBackup.Id).Status -ne "Complete") {
         Start-Sleep -seconds $sleepSeconds
         $secondsSlept += $sleepSeconds
         Write-Host "$secondsSlept ... " -NoNewLine
      }
      Write-Host "Import Complete"

      try {
         infoResult "Restore-SafeguardBackup" "Starting restore of $($newBackup.Id) to $($DATA.appliance)"
         Restore-SafeguardBackup -BackupId $newBackup.Id
         goodResult "Restore-SafeguardBackup" "Backup successfully restored"
      } catch {
         badResult "Restore-SafeguardBackup" "Unexpected error restoring to $($DATA.appliance)" $_
      }

      # if all went well, the primary is readonly and needs to be enabled
      # if not, we'll get an error and recover (in theory).
      try {
         Enable-SafeguardClusterPrimary > $null
         goodResult "Enable-SafeguardClusterPrimary" "Successfully enabled cluster"
      } catch {
         if ($_ -match "This action cannot be performed in the current appliance state") {
            goodResult "Enable-SafeguardClusterPrimary" "Successful but does not apply to current appliance state"
         } else {
            badResult "Enable-SafeguardClusterPrimary" "Unexpected error" $_
         }
      }
   }

} catch {
   badResult "Backups general" "Unexpected error in Backups tests" $_
} finally {
}

testBlockHeader $TestBlockName $blockInfo
