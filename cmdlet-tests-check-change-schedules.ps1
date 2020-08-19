try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Check and Change Schedule Creation Tests"
$blockInfo = testBlockHeader $TestBlockName
# ===== Covered Commands =====
# Copy-SafeguardPasswordChangeSchedule
# Copy-SafeguardPasswordCheckSchedule
# Edit-SafeguardPasswordChangeSchedule
# Edit-SafeguardPasswordCheckSchedule
# New-SafeguardPasswordChangeSchedule
# New-SafeguardPasswordCheckSchedule
# New-SafeguardScheduleDaily
# Remove-SafeguardPasswordChangeSchedule
# Remove-SafeguardPasswordCheckSchedule
# Rename-SafeguardPasswordChangeSchedule
# Rename-SafeguardPasswordCheckSchedule
#
try {
   $changeScheduleName = "Change Schedule #1"
   $checkScheduleName = "Check Schedule #1"
   $copyChangeScheduleName = "Copy $changeScheduleName"
   $copyCheckScheduleName = "Copy $checkScheduleName"

   $changeSchedule = New-SafeguardPasswordChangeSchedule -Name "$changeScheduleName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00")
   goodResult "New-SafeguardPasswordChangeSchedule"  "successfully created $($changeSchedule.Name)"

   $changeSchedule = Edit-SafeguardPasswordChangeSchedule -ChangeScheduleToEdit "$changeScheduleName" -Description "Edited schedule desc" -Schedule (New-SafeguardScheduleDaily -StartTime "22:00")
   goodResult "Edit-SafeguardPasswordChangeSchedule"  "successfully created $($changeSchedule.Name)  Description: $($changeSchedule.Description)"

   $copySchedule = Copy-SafeguardPasswordChangeSchedule -ChangeScheduleToCopy "$changeScheduleName" -CopyName "$copyChangeScheduleName"
   goodResult "Copy-SafeguardPasswordChangeSchedule"  "successfully copied $($changeSchedule.Name) to $($copySchedule.Name)"

   Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$($changeSchedule.Name)" > $null
   goodResult "Remove-SafeguardPasswordChangeSchedule"  "successfully removed $($changeSchedule.Name)"

   $renamedSchedule = Rename-SafeguardPasswordChangeSchedule -ChangeScheduleToEdit $($copySchedule.Name) -NewName $($changeSchedule.Name)
   goodResult "Rename-SafeguardPasswordChangeSchedule"  "successfully renamed $($changeSchedule.Name) to $($renamedSchedule.Name)"
      
   Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$($changeSchedule.Name)" > $null
   goodResult "Remove-SafeguardPasswordChangeSchedule"  "successfully removed $($changeSchedule.Name)"

   $checkSchedule = New-SafeguardPasswordCheckSchedule -Name "$checkScheduleName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00")
   goodResult "New-SafeguardPasswordCheckSchedule"  "successfully created $($checkSchedule.Name)"

   $checkSchedule = Edit-SafeguardPasswordCheckSchedule -CheckScheduleToEdit "$checkScheduleName" -Description "Edited schedule desc" -Schedule (New-SafeguardScheduleDaily -StartTime "22:00")
   goodResult "Edit-SafeguardPasswordCheckSchedule"  "successfully created $($checkSchedule.Name)  Description: $($checkSchedule.Description)"

   $copySchedule = Copy-SafeguardPasswordCheckSchedule -CheckScheduleToCopy "$checkScheduleName" -CopyName "$copyCheckScheduleName"
   goodResult "Copy-SafeguardPasswordCheckSchedule"  "successfully copied $($checkSchedule.Name) to $($copySchedule.Name)"

   Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$($checkSchedule.Name)" > $null
   goodResult "Remove-SafeguardPasswordCheckSchedule"  "successfully removed $($checkSchedule.Name)"

   $renamedSchedule = Rename-SafeguardPasswordCheckSchedule -CheckScheduleToEdit $($copySchedule.Name) -NewName $($checkSchedule.Name)
   goodResult "Rename-SafeguardPasswordCheckSchedule"  "successfully renamed $($checkSchedule.Name) to $($checkSchedule.Name)"

   Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$($checkSchedule.Name)" > $null
   goodResult "Remove-SafeguardPasswordCheckSchedule"  "successfully removed $($checkSchedule.Name)"
} catch {
   badResult "general"  "Error working with Check and Change Schedules" $_
} finally {
   try { Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$changeScheduleName" > $null } catch { }
   try { Remove-SafeguardPasswordChangeSchedule -ChangeScheduleToDelete "$copyChangeScheduleName" > $null } catch { }
   try { Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$checkScheduleName" > $null } catch { }
   try { Remove-SafeguardPasswordCheckSchedule -CheckScheduleToDelete "$copyCheckScheduleName" > $null } catch { }
}

testBlockHeader $TestBlockName $blockInfo
