try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName = "Running Password Profile Creation Tests"
$blockInfo = testBlockHeader $TestBlockName
# ===== Covered Commands =====
# Copy-SafeguardPasswordProfile
# Edit-SafeguardPasswordProfile
# New-SafeguardAccountPasswordRule
# New-SafeguardPasswordProfile
# New-SafeguardScheduleDaily
# Remove-SafeguardAccountPasswordRule
# Remove-SafeguardPasswordChangeSchedule
# Remove-SafeguardPasswordCheckSchedule
# Remove-SafeguardPasswordProfile
# Rename-SafeguardPasswordProfile
#
try {
   $pwdProfileName = "New Password Profile"
   $copyPwdProfileName = "Copy New Password Profile"
   $pwdRuleName = "ps.profile.NewPwdRule_001"
   $checkSchedName = "profile.Check1"
   $changeSchedName = "profile.Change1"

   $pwdProfile = New-SafeguardPasswordProfile -Name "$pwdProfileName" `
      -PasswordRuleToSet (New-SafeguardAccountPasswordRule -AssetPartition -1 -Name $pwdRuleName) `
      -CheckScheduleToSet (New-SafeguardPasswordCheckSchedule -Name "$checkSchedName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00")) `
      -ChangeScheduleToSet (New-SafeguardPasswordChangeSchedule -Name "$changeSchedName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00"))
   goodResult "New-SafeguardPasswordProfile"  "rule created $($pwdProfile.name)  pwdRule=$($pwdProfile.AccountPasswordRule.Name)  chkSched=$($pwdProfile.CheckSchedule.Name)  changeSched=$($pwdProfile.ChangeSchedule.Name)"

   $pwdProfile = Edit-SafeguardPasswordProfile -ProfileToEdit "$pwdProfileName" -Description "New description for $pwdProfileName"
   goodResult "Edit-SafeguardPasswordProfile"  "successfully edited $($pwdProfile.name)  Desc=$($pwdProfile.Description)"

   $copyPwdProfile = Copy-SafeguardPasswordProfile -ProfileToCopy "$($pwdProfile.Name)" -CopyName "$copyPwdProfileName"
   goodResult "Copy-SafeguardPasswordProfile"  "successfully copied $($pwdProfile.name) to $($copyPwdProfile.Name)"

   Remove-SafeguardPasswordProfile -ProfileToDelete "$pwdProfileName" > $null
   goodResult "Remove-SafeguardPasswordProfile"  "successfully removed $($pwdProfile.name)"

   $renamedPwdProfile = Rename-SafeguardPasswordProfile -ProfileToEdit "$($copyPwdProfile.Name)" -NewName "$pwdProfileName"
   goodResult "Rename-SafeguardPasswordProfile"  "successfully renamed $($copyPwdProfile.name) to $($renamedPwdProfile.Name)"

   Remove-SafeguardPasswordProfile -ProfileToDelete "$pwdProfileName" > $null
   goodResult "Remove-SafeguardPasswordProfile"  "successfully removed $($pwdProfile.name)"

   Remove-SafeguardAccountPasswordRule "$pwdRuleName" > $null
   Remove-SafeguardPasswordCheckSchedule "$checkSchedName" > $null
   Remove-SafeguardPasswordChangeSchedule "$changeSchedName" > $null
   goodResult "Removed"  "AccountPasswordRule and Check and Change schedules"
}
catch {
   badResult "general"  "Error working with Password Profiles" $_
} finally {
   try { Remove-SafeguardPasswordProfile -ProfileToDelete "$pwdProfileName" > $null } catch { }
   try { Remove-SafeguardPasswordProfile -ProfileToDelete "$copyPwdProfileName" > $null } catch { }
   try { Remove-SafeguardAccountPasswordRule "$pwdRuleName" > $null } catch { }
   try { Remove-SafeguardPasswordCheckSchedule "$checkSchedName" > $null } catch { }
   try { Remove-SafeguardPasswordChangeSchedule "$changeSchedName" > $null } catch { }
}

testBlockHeader $TestBlockName $blockInfo
