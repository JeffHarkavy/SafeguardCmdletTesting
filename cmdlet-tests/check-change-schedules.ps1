try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.CheckChangeSchedules
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:changeScheduleName = "Change Schedule #1"
$script:checkScheduleName = "Check Schedule #1"
$script:copyChangeScheduleName = "Copy $script:changeScheduleName"
$script:copyCheckScheduleName = "Copy $script:checkScheduleName"

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$script:changeScheduleName" -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$script:copyChangeScheduleName" -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$script:checkScheduleName" -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$script:copyCheckScheduleName" -ErrorAction SilentlyContinue > $null } catch { }
}

try {
   $changeSchedule = New-SafeguardPasswordChangeSchedule -Name "$script:changeScheduleName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00")
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardPasswordChangeSchedule"; message = "successfully created $($changeSchedule.Name)"; })

   $changeSchedule = Edit-SafeguardPasswordChangeSchedule -ChangeScheduleToEdit "$script:changeScheduleName" -Description "Edited schedule desc" -Schedule (New-SafeguardScheduleDaily -StartTime "22:00")
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardPasswordChangeSchedule"; message = "successfully created $($changeSchedule.Name)  Description: $($changeSchedule.Description)"; })

   $copySchedule = Copy-SafeguardPasswordChangeSchedule -ChangeScheduleToCopy "$script:changeScheduleName" -CopyName "$script:copyChangeScheduleName"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Copy-SafeguardPasswordChangeSchedule"; message = "successfully copied $($changeSchedule.Name) to $($copySchedule.Name)"; })

   Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$($changeSchedule.Name)" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardPasswordChangeSchedule"; message = "successfully removed $($changeSchedule.Name)"; })

   $renamedSchedule = Rename-SafeguardPasswordChangeSchedule -ChangeScheduleToEdit $($copySchedule.Name) -NewName $($changeSchedule.Name)
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Rename-SafeguardPasswordChangeSchedule"; message = "successfully renamed $($changeSchedule.Name) to $($renamedSchedule.Name)"; })
      
   Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$($changeSchedule.Name)" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardPasswordChangeSchedule"; message = "successfully removed $($changeSchedule.Name)"; })

   $checkSchedule = New-SafeguardPasswordCheckSchedule -Name "$script:checkScheduleName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00")
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardPasswordCheckSchedule"; message = "successfully created $($checkSchedule.Name)"; })

   $checkSchedule = Edit-SafeguardPasswordCheckSchedule -CheckScheduleToEdit "$script:checkScheduleName" -Description "Edited schedule desc" -Schedule (New-SafeguardScheduleDaily -StartTime "22:00")
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardPasswordCheckSchedule"; message = "successfully created $($checkSchedule.Name)  Description: $($checkSchedule.Description)"; })

   $copySchedule = Copy-SafeguardPasswordCheckSchedule -CheckScheduleToCopy "$script:checkScheduleName" -CopyName "$script:copyCheckScheduleName"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Copy-SafeguardPasswordCheckSchedule"; message = "successfully copied $($checkSchedule.Name) to $($copySchedule.Name)"; })

   Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$($checkSchedule.Name)" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardPasswordCheckSchedule"; message = "successfully removed $($checkSchedule.Name)"; })

   $renamedSchedule = Rename-SafeguardPasswordCheckSchedule -CheckScheduleToEdit $($copySchedule.Name) -NewName $($checkSchedule.Name)
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Rename-SafeguardPasswordCheckSchedule"; message = "successfully renamed $($checkSchedule.Name) to $($checkSchedule.Name)"; })

   Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$($checkSchedule.Name)" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardPasswordCheckSchedule"; message = "successfully removed $($checkSchedule.Name)"; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error working with Check and Change Schedules"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

