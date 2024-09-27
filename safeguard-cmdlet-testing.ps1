# Gather any parameters into a single array
param([Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)][string[]] $allParameters)

Write-Host "###############################################################################"
Write-Host "#                      Safeguard-ps Cmdlet Test Harness                       #"
Write-Host "###############################################################################"
Write-Host
$SCRIPT_PATH = (Split-Path $myInvocation.MyCommand.Path)
$BASE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($myInvocation.MyCommand.Name)

# "global" data and functions are in separate files for maintainability
# (yes, it's powershell, everything is global)
# harness-globals loads harness-data
. "$SCRIPT_PATH\harness-globals.ps1"

if ( -not $GLOBALS.initializeEnvironment($DATA.Tests)) {
   exit
}
pause

$knownVMTypes = @('vmware','hyperv')

# count of how many good/bad/info calls for summary at the end
$resultCounts = @{
   Good = 0;
   Bad = 0;
   Info = 0;
}

# ========================================================================
#
#  Actual Start of Script logic
#
# ========================================================================

try {
   if ($GLOBALS.createLog) {
      $GLOBALS.startTranscribing()
   }

   $fullRunInfo = $GLOBALS.testBlockHeader("All Test Blocks")

   $GLOBALS.sgConnect()
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Connect-Safeguard"; message = "Success"; })

   $GLOBALS.writeCallHeader("Get-SafeguardVersion")
   $sgVersion = Get-SafeguardVersion
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardVersion"; message = "Success"; })
   $GLOBALS.formatTable(@{ output = $sgVersion; })

   $isVm = $knownVMTypes -contains $sgVersion.BuildPlatform
   $isLTS = $sgVersion.Minor -eq "0"

   $GLOBALS.writeCallHeader("Appliance Info")
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "isVm"; message = $isVm; })
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "isLTS"; message = $isLTS; })
   if ( $global:testBranch -match "^other:") {
      if ($DATA.Tests.Patch.runTest -eq "Y" -or $DATA.Tests.Cluster.runTest -eq "Y") {
         $DATA.Tests.Patch.runTest = "N"
         $DATA.Tests.Cluster.runTest = "N"
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Test Branch Check"; message = "Skipping patch and cluster testing on 'Other' test branch"; })
      }
   } elseif ($isLTS -and $global:testBranch -eq "Feature" -and $DATA.Tests.Patch.runTest -eq "Y") {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Test Branch Check"; message = "This is an LTS appliance. Do you want to patch it to a Feature build?"; })
      if ("Y" -ne (Read-Host "Enter Y to continue with patch tests on $($DATA.appliance)")) {
         $DATA.Tests.Patch.runTest = "N"
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Patch Testing"; message = "Skipping patch testing from LTS to Feature"; })
      }
   } elseif (($isLTS -and $global:testBranch -ne "LTS") -or (-not $isLTS -and $global:testBranch -ne "Feature")) {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Test Branch Mismatch"; message = "This is a $(iif $isLTS "LTS" "Feature") appliance and TestBranch is set to $global:testBranch"; })
      exit
   }

   $GLOBALS.writeCallHeader("Test-SafeguardVersion - minimum 6.0")
   Test-SafeguardVersion -MinVersion 6.0
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardVersion"; message = "Success"; })

   foreach ($t in ($DATA.Tests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})) {
      . "$($t.Value.fileName)"
   }
}
catch {
   Write-Host $_.Exception
   Write-Host $_.ScriptStackTrace
}
finally {
   Disconnect-Safeguard

   $GLOBALS.testBlockHeader($fullRunInfo, $true)
   if ($GLOBALS.resultCounts.Bad -gt 0) {
      $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, "===== Collected Errors =====")
      $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, $GLOBALS.collectedErrors)
   }
   Write-Host ""

   if ($GLOBALS.createLog) { Stop-Transcript }
}
