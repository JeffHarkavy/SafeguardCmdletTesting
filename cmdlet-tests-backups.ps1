try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Backups Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# TODO - stubbed code
#Restore-SafeguardBackup
#Save-SafeguardBackupToArchive

# === COVERED COMMANDS ===
#Get-SafeguardBackup
#Export-SafeguardBackup
#Import-SafeguardBackup
#Remove-SafeguardBackup
#New-SafeguardBackup

try {
   $sleepSeconds = 5
   $localBackupFilename = "cmdlet-test-sgbackup.sgb"
   $localBackupFilePath = "$SCRIPT_PATH\$localBackupFilename"
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

   Remove-SafeguardBackup -BackupId $newBackup.Id > $null
   goodResult "Remove-SafeguardBackup" "Successfully removed backup id=$($newBackup.Id)"

   Import-SafeguardBackup -BackupFile "$localBackupFilePath" > $null
   goodResult "Import-SafeguardBackup" "Upload started for $localBackupFilename"

} catch {
   badResult "Backups general" "Unexpected error in Backups tests" $_.Exception
} finally {
}

testBlockHeader "end" $TestBlockName $blockInfo
