try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.ObsoleteCommands
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

function testObsolete($cmd, $extraArgs1) {
   $cmd = "$cmd $(iif $extraArgs1 $extraArgs1 '')  -ErrorAction:SilentlyContinue -WarningAction:Continue"
   $GLOBALS.writeCallHeader("$cmd OBSOLETE")
   try { Invoke-Expression $cmd -ErrorAction SilentlyContinue }
   catch {
      # PS 5 and 7 have ever-so-slightly different errors
      if ($_ -match "not recognized as (a|the) name") { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "$cmd"; message = "Success"; }) }
      elseif ($_.Exception.ErrorCode -ne 60385) { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "$cmd"; message = "Unexpected error"; ex = $_; }) }
      else { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "$cmd"; message = "Success"; }) }
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

$GLOBALS.testBlockHeader($script:blockInfo)
