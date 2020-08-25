try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName = "Running Obsolete Commands"
$blockInfo = testBlockHeader $TestBlockName 
# ===== Covered Commands =====
# Add-SafeguardSessionSshAlgorithm
# Get-SafeguardSessionCertificate
# Get-SafeguardSessionContainerStatus
# Get-SafeguardSessionModuleStatus
# Get-SafeguardSessionModuleVersion
# Get-SafeguardSessionSshAlgorithms
# Invoke-SafeguardSessionsPing
# Invoke-SafeguardSessionsTelnet
# Remove-SafeguardSessionSshAlgorithm
# Reset-SafeguardSessionModule
# Set-SafeguardSessionSshAlgorithms
# Repair-SafeguardSessionModule
#

function testObsolete($cmd, $extraArgs1) {
   $cmd = "$cmd $(iif $extraArgs1 $extraArgs1 '')  -ErrorAction:SilentlyContinue -WarningAction:Continue"
   writeCallHeader "$cmd OBSOLETE"
   try { Invoke-Expression $cmd }
   catch {
      if ($_.Exception.ErrorCode -ne 60385) { badResult "$cmd" "Unexpected error" $_ }
      else { goodResult "$cmd" "Success" }
   }
}

# All of the following commands are *expected* to be obsolete and should only spit out
# a Warning (or 2) about that. If any other error comes out we'll squawk
testObsolete "Add-SafeguardSessionSshAlgorithm" "ServerSide Cipher 3des-cbc"

testObsolete "Get-SafeguardSessionCertificate" "-Type TimeStamping"

testObsolete "Get-SafeguardSessionContainerStatus"

testObsolete "Get-SafeguardSessionModuleStatus"

testObsolete "Get-SafeguardSessionModuleVersion"

testObsolete "Get-SafeguardSessionSshAlgorithms"

testObsolete "Get-SafeguardSessionContainerStatus"

testObsolete "Invoke-SafeguardSessionsPing" "-NetworkAddress 10.9.6.79" 

testObsolete "Invoke-SafeguardSessionsTelnet" "-NetworkAddress 10.9.6.79 -Port 22" 

testObsolete "Set-SafeguardSessionSshAlgorithms" "ServerSide Cipher" 

testObsolete "Remove-SafeguardSessionSshAlgorithm" "ServerSide Cipher 3des-cbc" 

testObsolete "Reset-SafeguardSessionModule"

testObsolete "Repair-SafeguardSessionModule"

testBlockHeader $TestBlockName  $blockInfo
