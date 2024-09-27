try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Backups
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false
$script:localBackupFilename = "cmdlet-test-sgbackup_$testBranch_$("{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f (Get-Date)).sgb"
$script:localBackupFilePath = "$($DATA.filePaths.backups)\$script:localBackupFilename"

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { if ( (Test-Path $script:localBackupFilePath -PathType Leaf)) { Remove-Item -Path $script:localBackupFilePath > $null } } catch {}
}

try {
   $sleepSeconds = 5
   $backups = Get-SafeguardBackup
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardBackup"; message = "Successful retrieved list of $($backups.Length) backups"; })
   $GLOBALS.formatTable(@{ output = $backups; properties = @{ Property = @("Id","CreatedOn","Size","Status"); }; })
   
   $newBackup = New-SafeguardBackup
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardBackup"; message = "Successfully started new safeguard backup id=$($newBackup.Id)"; })
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardBackup"; message = "Waiting for backup to complete"; })
   $secondsSlept = 0
   Write-Host -NoNewLine "Process duration (seconds) "
   while (("Complete","Archiving") -notcontains (Get-Safeguardbackup $newBackup.Id).Status) {
      Start-Sleep -seconds $sleepSeconds
      $secondsSlept += $sleepSeconds
      Write-Host "$secondsSlept ... " -NoNewLine
   }
   Write-Host "Complete"
   $newBackup = Get-SafeguardBackup $newBackup.Id
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardBackup"; message = "Backup complete, size=$($newBackup.Size), filename=$($newBackup.Filename)"; })

   Export-SafeguardBackup -BackupId $newBackup.Id -OutFile "$script:localBackupFilePath"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Export-SafeguardBackup"; message = "Downloaded backup to $script:localBackupFilePath"; })

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
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardArchiveServer"; message = "Successfully created Archive Server $($DATA.realArchiveServer.archSrvName) Id=$($archiveServer.Id)" ; })
         $createdArchiveServer = 1
      }

      Save-SafeguardBackupToArchive -BackupId $newBackup.Id -ArchiveServerId $archiveServer.Id
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Save-SafeguardBackupToArchive"; message = "Successfully archived backup to Archive Server $($DATA.realArchiveServer.archSrvName)" ; })
   } catch {
      if ($_ -match "That entity name is already in use") {
         # eh.  we tried.
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Save-SafeguardBackupToArchive"; message = "Successful-ish. Backup $($newBackup.FileName) already exists on $($DATA.realArchiveServer.archSrvName)" ; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Save-SafeguardBackupToArchive"; message = "Unexpected error"; ex = $_; })
      }
   } finally {
      if ($createdArchiveServer) { try{Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null} catch{} }
   }

   Remove-SafeguardBackup -BackupId $newBackup.Id > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardBackup"; message = "Successfully removed backup id=$($newBackup.Id)"; })

   Import-SafeguardBackup -BackupFile "$script:localBackupFilePath" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Import-SafeguardBackup"; message = "Upload started for $script:localBackupFilename"; })

   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Restore-SafeguardBackup"; message = "Do you want to restore using the backup you just made (possibly time-consuming)?"; })
   if ("Y" -eq (Read-Host "Enter Y to continue with backup restore tests on $($DATA.appliance)")) {
      $secondsSlept = 0
      Write-Host -NoNewLine "Process duration (seconds) "
      while (("Complete","Archiving") -notcontains (Get-Safeguardbackup $newBackup.Id).Status) {
         Start-Sleep -seconds $sleepSeconds
         $secondsSlept += $sleepSeconds
         Write-Host "$secondsSlept ... " -NoNewLine
      }
      Write-Host "Import Complete"

      try {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Restore-SafeguardBackup"; message = "Starting restore of $($newBackup.Id) to $($DATA.appliance)"; })
         Restore-SafeguardBackup -BackupId $newBackup.Id
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Restore-SafeguardBackup"; message = "Backup successfully restored"; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Restore-SafeguardBackup"; message = "Unexpected error restoring to $($DATA.appliance)"; ex = $_; })
      }

      # if all went well, the primary is readonly and needs to be enabled
      # if not, we'll get an error and recover (in theory).
      try {
         Enable-SafeguardClusterPrimary > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardClusterPrimary"; message = "Successfully enabled cluster"; })
      } catch {
         if ($_ -match "This action cannot be performed in the current appliance state") {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardClusterPrimary"; message = "Successful but does not apply to current appliance state"; })
         } else {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Enable-SafeguardClusterPrimary"; message = "Unexpected error"; ex = $_; })
         }
      }
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Backups general"; message = "Unexpected error in Backups tests"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

