try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.NetworkDiagnostics
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

try {
   $GLOBALS.writeCallHeader("Invoke-SafeguardClusterPing")
   Invoke-SafeguardClusterPing
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardClusterPing"; message = "Success"; })

   $GLOBALS.writeCallHeader("Invoke-SafeguardClusterThroughput")
   Invoke-SafeguardClusterThroughput -Megabytes 1
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardClusterThroughput"; message = "Success"; })

   $GLOBALS.writeCallHeader("Invoke-SafeguardMemberPing")
   Invoke-SafeguardMemberPing -TargetMember $DATA.appliance
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardMemberPing"; message = "Success"; })

   $GLOBALS.writeCallHeader("Invoke-SafeguardMemberThroughput")
   Invoke-SafeguardMemberThroughput -TargetMember $DATA.appliance
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardMemberThroughput"; message = "Success"; })

   $GLOBALS.writeCallHeader("Invoke-SafeguardPing")
   Invoke-SafeguardPing -NetworkAddress $($DATA.realArchiveServer.NetworkAddress)
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardPing"; message = "Success"; })

   $GLOBALS.writeCallHeader("Invoke-SafeguardTelnet")
   Invoke-SafeguardTelnet -NetworkAddress $($DATA.realArchiveServer.NetworkAddress) -Port 22
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardTelnet"; message = "Success"; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Network Diagnostics general"; message = "Unexpected error testing network diagnostic commands"; ex =$_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   $GLOBALS.testBlockHeader($script:blockInfo)
}
