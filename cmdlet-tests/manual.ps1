try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Manual
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

function quickBlock($cmd,$desc) {
   $GLOBALS.writeHostColor($GLOBALS.COLORS.highlight, $cmd)
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

quickBlock "Open-CsvInExcel -FilePath foo-bar.csv" "Best to run manually on a known CSV when Excel is known to be present"

quickBlock "Get-SafeguardSupportBundle -OutFile somefilename" "This can take a long time to process, so probably best to do manually"

quickBlock "Get-SafeguardSupportBundleQuickGlance -OutFile somefilename" "This can take a long time to process, so probably best to do manually"

quickBlock "Install-SafeguardDesktopClient" "not really a script-y kind of thing to do, may require user interaction in installer window?"

quickBlock "Invoke-SafeguardApplianceFactoryReset -Reason ""Give a reason here""" "!!! HARDWARE Only - beware!"

quickBlock "Invoke-SafeguardApplianceReboot -Reason ""Give a reason here"""

quickBlock "Invoke-SafeguardApplianceShutdown -Reason ""Give a reason here"""

quickBlock "Update-SafeguardAccessToken" "may require user password entry"

quickBlock "Enable-SafeguardTls12Only" "requires user interaction, use Get-SafeguardTls12OnlyStatus to see the current setting"

quickBlock "Disable-SafeguardTls12Only" "requires user interaction, use Get-SafeguardTls12OnlyStatus to see the current setting"

quickBlock "New-SafeguardTestCertificatePki -SubjectBaseDn ""OU=cmdletTesting,O=OneIdentityLLC,C=US"" -OutputDir ." "requires LOTS of user interaction. HINT - put your password in the clipboard. Ctrl-V is your friend."

$GLOBALS.testBlockHeader($script:blockInfo)

