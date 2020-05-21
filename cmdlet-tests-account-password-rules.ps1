try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
# ===== Covered Commands =====
# Copy-SafeguardAccountPasswordRule
# Edit-SafeguardAccountPasswordRule
# New-SafeguardAccountPasswordRule
# Remove-SafeguardAccountPasswordRule
# Rename-SafeguardAccountPasswordRule
#
writeCallHeader "Running Account Password Rules Tests"
try {
   $pwdRuleName = "ps.NewPwdRule_001"
   $copyPwdRuleName = "Copy $pwdRuleName"
   $pwdRule = New-SafeguardAccountPasswordRule -Name $pwdRuleName
   goodResult "New-SafeguardAccountPasswordRule"  "successfully added $($pwdRule.Name)"

   $pwdRule = Edit-SafeguardAccountPasswordRule -AssetPartition -1 -PasswordRuleToEdit $pwdRuleName -Description "Description for $pwdRuleName"
   goodResult "Edit-SafeguardAccountPasswordRule"  "successfully edited $($pwdRule.Name)  $($pwdRule.Description)"

   $pwdRule = Rename-SafeguardAccountPasswordRule -PasswordRuleToEdit $pwdRuleName -NewName "$copyPwdRuleName"
   goodResult "Rename-SafeguardAccountPasswordRule"  "successfully renamed $($pwdRuleName) to $($pwdRule.Name)"

   $pwdRule = Copy-SafeguardAccountPasswordRule -PasswordRuleToCopy "$copyPwdRuleName" -CopyName $pwdRuleName
   goodResult "Copy-SafeguardAccountPasswordRule"  "successfully copied to $($pwdRuleName)"

   Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete $pwdRuleName > $null
   Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete "$copyPwdRuleName" > $null
   goodResult "Remove-SafeguardAccountPasswordRule"  "successfully deleted $pwdRuleName and $copyPwdRuleName"
}
catch {
   badResult "general"  "Error working with Account Password Rules" $_.Exception
} finally {
   try { Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete $pwdRuleName > $null } catch { }
   try { Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete "$copyPwdRuleName" > $null } catch { }
}
