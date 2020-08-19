try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Commands that need to be tested by hand"
$blockInfo = testBlockHeader $TestBlockName
function quickBlock($cmd,$desc) {
   Write-Host -ForegroundColor $colors.highlight.fore -BackgroundColor $colors.highlight.back $cmd
   if ($desc) {
      Write-Host "  - $desc"
   }
   Write-Host
}
# === "Covered" but must be done manually ===
# Open-CsvInExcel
# Get-SafeguardSupportBundle
# Install-SafeguardDesktopClient
# Invoke-SafeguardApplianceFactoryReset
# Invoke-SafeguardApplianceReboot
# Invoke-SafeguardApplianceShutdown
# Update-SafeguardAccessToken
# Enable-SafeguardTls12Only
# Disable-SafeguardTls12Only
# New-SafeguardTestCertificatePki
# Repair-SafeguardSessionModule

quickBlock "Open-CsvInExcel -FilePath foo-bar.csv" "Best to run manually on a known CSV when Excel is known to be present"

quickBlock "Get-SafeguardSupportBundle -OutFile somefilename" "This can take a long time to process, so probably best to do manually"

quickBlock "Install-SafeguardDesktopClient" "not really a script-y kind of thing to do, may require user interaction in installer window?"

quickBlock "Invoke-SafeguardApplianceFactoryReset -Reason ""Give a reason here""" "!!! HARDWARE Only - beware!"

quickBlock "Invoke-SafeguardApplianceReboot -Reason ""Give a reason here"""

quickBlock "Invoke-SafeguardApplianceShutdown -Reason ""Give a reason here"""

quickBlock "Update-SafeguardAccessToken" "may require user password entry"

quickBlock "Enable-SafeguardTls12Only" "requires user interaction, use Get-SafeguardTls12OnlyStatus to see the current setting"

quickBlock "Disable-SafeguardTls12Only" "requires user interaction, use Get-SafeguardTls12OnlyStatus to see the current setting"

quickBlock "New-SafeguardTestCertificatePki -SubjectBaseDn ""OU=cmdletTesting,O=OneIdentityLLC,C=US"" -OutputDir ." "requires LOTS of user interaction. HINT - put your password in the clipboard. Ctrl-V is your friend."

quickBlock "Repair-SafeguardSessionModule" "requires user interaction. Obsolete."

testBlockHeader $TestBlockName $blockInfo

