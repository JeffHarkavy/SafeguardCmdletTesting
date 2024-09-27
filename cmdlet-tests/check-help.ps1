try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.CheckHelp
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

# Runs all commands with a -? parameter and looks for output.
# Will only complain if a given command doesn't return some help.
# Note that if you're not verifying or updating the help hashes
# it's not really picky about *what's* returned, just as
# long as the call doesn't throw an exception for a missing command.
try {
   $Output = ""
   $Errors = @()
   $commands = (get-safeguardcommand).Name|sort
   $cmdCount = 0
   Write-Host "Processing " -Nonewline
   $NewHelpHashes = ""
   foreach ($commandName in $commands) {
      $cmd = $commandName + " -? | findstr  /b /i /r /c:""^ * $commandName"""
      $Output += "`n*** $cmd ***`n"
      try {
         $cmdOut = (invoke-expression $cmd) | Out-String
         if ($DATA.VerifyHelpHash -or $DATA.UpdateHelpHash) {
            $cmdHash = $GLOBALS.hashString($cmdOut -join " ")
            if ($DATA.UpdateHelpHash) {
              $GLOBALS.infoResult(@{ minVerbosity = 2; cmd = $null; message = "$($commandName): helpHash=$cmdHash"; })
              $NewHelpHashes += "  {0,-55} = `'{1}`';`n" -f "'$commandName'", $cmdHash
              $GLOBALS.resultCounts.Good++
            } elseif (!$DATA.CommandHelpHashes[$commandName] -or $DATA.CommandHelpHashes[$commandName] -ne $cmdHash) {
              $oldHash = $GLOBALS.emptyElse($DATA.CommandHelpHashes[$commandName], "missing/empty")
              $Errors += "***hash mismatch for $commandName - stored: $oldHash, actual: $cmdHash"
              $GLOBALS.resultCounts.Bad++
            }
         } else {
           $GLOBALS.resultCounts.Good++
         }
         $Output += $cmdOut
      } catch {
         $GLOBALS.resultCounts.Bad++
         $Errors += "***no command help for $commandName`n"
      }
      $cmdCount++
      if ($cmdCount % 25 -eq 0) {
         Write-Host -Nonewline $cmdCount
      } elseif ($cmdCount % 5 -eq 0) {
         Write-Host -NonewLine "."
      }
   }
   Write-Host
   if ($NewHelpHashes -ne "") {
      Write-Host ""
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = $null; message = "Updated help hash values follow. Copy and paste these to harness-helphash.ps1 to update the `$DATA.CommandHelpHashes values."; })
      Write-Host $NewHelpHashes
   } elseif ($Errors.Count -gt 0) {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Help"; message = "Errors encountered during help check`n$($Errors -join "`n")"; })
   } elseif ($DATA.VerifyHelpHash) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Help"; message = "All command help output matches expected hashes"; })
   } else {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Help"; message = "All commands returned help output"; })
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Help general"; message = "Unexpected error checking help output"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   $GLOBALS.testBlockHeader($script:blockInfo)
}

