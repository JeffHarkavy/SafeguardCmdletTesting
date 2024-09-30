try {
    if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
 } catch {
    write-host "Not meant to be run as a standalone script" -ForegroundColor Red
    exit
 }

$GLOBALS.currentTest = $DATA.Tests.Time
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

try {
    $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Restore-SafeguardBackup"; message = "Do you want to set your SPP box back 30 days.?"; })
    if ("Y" -eq (Read-Host "Enter Y to continue with setting time -30 day on $($DATA.appliance). Note: no Y means set it to current time.")) {
        $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardTime"; message = "Warning: This will set your SPP box back 30 days and your user may be unable to stay authenticate while SPP changes the time to catch back up. The users token will expire as SPP jumps to catch up."; })
        Set-SafeguardTime -SystemTime (getTimestamp 3 (get-date).AddDays(-30))
        $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardTime"; message = "Successful reset Set-SafeguardTime" ; })
    }
    else{
        Set-SafeguardTime -SystemTime (getTimestamp 3)
        $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardTime"; message = "Successful reset Set-SafeguardTime"; })
    }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
    $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardTime"; message = "Unexpected error in Set-SafeguardTime"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   $GLOBALS.testBlockHeader($script:blockInfo)
} 
