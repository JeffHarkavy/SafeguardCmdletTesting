try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.PasswordProfile
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:pwdProfileName = "New Password Profile"
$script:copyPwdProfileName = "Copy New Password Profile"
$script:pwdRuleName = "ps.profile.NewPwdRule_001"
$script:checkSchedName = "profile.Check1"
$script:changeSchedName = "profile.Change1"

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Remove-SafeguardPasswordProfile -ProfileToDelete "$script:pwdProfileName" -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardPasswordProfile -ProfileToDelete "$script:copyPwdProfileName" -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardAccountPasswordRule "$script:pwdRuleName" -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardPasswordCheckSchedule "$script:checkSchedName" -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardPasswordChangeSchedule "$script:changeSchedName" -ErrorAction SilentlyContinue > $null } catch { }
}

try {
   $pwdProfile = New-SafeguardPasswordProfile -Name "$script:pwdProfileName" `
      -PasswordRuleToSet (New-SafeguardAccountPasswordRule -AssetPartition -1 -Name $script:pwdRuleName) `
      -CheckScheduleToSet (New-SafeguardPasswordCheckSchedule -Name "$script:checkSchedName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00")) `
      -ChangeScheduleToSet (New-SafeguardPasswordChangeSchedule -Name "$script:changeSchedName"  -Schedule (New-SafeguardScheduleDaily -StartTime "12:00"))
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardPasswordProfile"; message = "rule created $($pwdProfile.name)  pwdRule=$($pwdProfile.AccountPasswordRule.Name)  chkSched=$($pwdProfile.CheckSchedule.Name)  changeSched=$($pwdProfile.ChangeSchedule.Name)"; })

   $pwdProfile = Edit-SafeguardPasswordProfile -ProfileToEdit "$script:pwdProfileName" -Description "New description for $script:pwdProfileName"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardPasswordProfile"; message = "successfully edited $($pwdProfile.name)  Desc=$($pwdProfile.Description)"; })

   $copyPwdProfile = Copy-SafeguardPasswordProfile -ProfileToCopy "$($pwdProfile.Name)" -CopyName "$script:copyPwdProfileName"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Copy-SafeguardPasswordProfile"; message = "successfully copied $($pwdProfile.name) to $($copyPwdProfile.Name)"; })

   Remove-SafeguardPasswordProfile -ProfileToDelete "$script:pwdProfileName" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardPasswordProfile"; message = "successfully removed $($pwdProfile.name)"; })

   $renamedPwdProfile = Rename-SafeguardPasswordProfile -ProfileToEdit "$($copyPwdProfile.Name)" -NewName "$script:pwdProfileName"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Rename-SafeguardPasswordProfile"; message = "successfully renamed $($copyPwdProfile.name) to $($renamedPwdProfile.Name)"; })

   Remove-SafeguardPasswordProfile -ProfileToDelete "$script:pwdProfileName" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardPasswordProfile"; message = "successfully removed $($pwdProfile.name)"; })

   Remove-SafeguardAccountPasswordRule "$script:pwdRuleName" > $null
   Remove-SafeguardPasswordCheckSchedule "$script:checkSchedName" > $null
   Remove-SafeguardPasswordChangeSchedule "$script:changeSchedName" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Removed"; message = "AccountPasswordRule and Check and Change schedules"; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error working with Password Profiles"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

