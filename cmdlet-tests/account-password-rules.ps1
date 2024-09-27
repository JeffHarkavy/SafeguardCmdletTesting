try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.AccountPasswordRules
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false
$script:pwdRuleName = "ps.NewPwdRule_001"
$script:copyPwdRuleName = "Copy $script:pwdRuleName"

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete $script:pwdRuleName -ErrorAction SilentlyContinue > $null } catch { }
   try { Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete "$script:copyPwdRuleName" -ErrorAction SilentlyContinue > $null } catch { }
}

try {
   $pwdRule = New-SafeguardAccountPasswordRule -Name $script:pwdRuleName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccountPasswordRule"; message = "successfully added $($pwdRule.Name)"; })

   $pwdRule = Edit-SafeguardAccountPasswordRule -AssetPartition -1 -PasswordRuleToEdit $script:pwdRuleName -Description "Description for $script:pwdRuleName"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAccountPasswordRule"; message = "successfully edited $($pwdRule.Name)  $($pwdRule.Description)"; })

   $pwdRule = Rename-SafeguardAccountPasswordRule -PasswordRuleToEdit $script:pwdRuleName -NewName "$script:copyPwdRuleName"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Rename-SafeguardAccountPasswordRule"; message = "successfully renamed $($script:pwdRuleName) to $($pwdRule.Name)"; })

   $pwdRule = Copy-SafeguardAccountPasswordRule -PasswordRuleToCopy "$script:copyPwdRuleName" -CopyName $script:pwdRuleName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Copy-SafeguardAccountPasswordRule"; message = "successfully copied to $($script:pwdRuleName)"; })

   Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete $script:pwdRuleName > $null
   Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete "$script:copyPwdRuleName" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardAccountPasswordRule"; message = "successfully deleted $script:pwdRuleName and $script:copyPwdRuleName"; })

   $script:completedSuccessfully = $true
}
catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error working with Account Password Rules"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}
