# Gather any parameters into a single array
param([Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)][string[]] $allParameters)

$SCRIPT_PATH = (Split-Path $myInvocation.MyCommand.Path)
$collectedErrors = [System.Collections.ArrayList]@()

# flags to run / not run a given block of tests
# add to this and create cmdlet-tests files as functionality gets added
# Default these all to "N" and cmdline processing will turn things on/off
# based on the list of tests passed in.
$Tests = @{
   CheckHelp =             @{Seq=1;  runTest = "N"; fileName = "cmdlet-tests-help.ps1";};
   NoParameter =           @{Seq=2;  runTest = "N"; fileName = "cmdlet-tests-noparameter.ps1";};
   Users =                 @{Seq=3;  runTest = "N"; fileName = "cmdlet-tests-users.ps1";};
   Groups =                @{Seq=4;  runTest = "N"; fileName = "cmdlet-tests-groups.ps1";};
   AssetsAndAccounts =     @{Seq=5;  runTest = "N"; fileName = "cmdlet-tests-assets-and-accounts.ps1";};
   AccountPasswordRules =  @{Seq=6;  runTest = "N"; fileName = "cmdlet-tests-account-password-rules.ps1";};
   CheckChangeSchedules =  @{Seq=7;  runTest = "N"; fileName = "cmdlet-tests-check-change-schedules.ps1";};
   Directory =             @{Seq=8;  runTest = "N"; fileName = "cmdlet-tests-directory.ps1";};
   AssetPartition =        @{Seq=9;  runTest = "N"; fileName = "cmdlet-tests-asset-partition.ps1";};
   PasswordProfile =       @{Seq=10; runTest = "N"; fileName = "cmdlet-tests-password-profile.ps1";};
   NetworkDiagnostics =    @{Seq=11; runTest = "N"; fileName = "cmdlet-tests-network-diagnostics.ps1";};
   NewSchedules =          @{Seq=12; runTest = "N"; fileName = "cmdlet-tests-new-schedules.ps1";};
   EventSubscriptions =    @{Seq=13; runTest = "N"; fileName = "cmdlet-tests-event-subscriptions.ps1";};
   Backups =               @{Seq=14; runTest = "N"; fileName = "cmdlet-tests-backups.ps1";};
   Entitlement =           @{Seq=15; runTest = "N"; fileName = "cmdlet-tests-entitlement.ps1";};
   A2A =                   @{Seq=16; runTest = "N"; fileName = "cmdlet-tests-a2a.ps1";};
   Requests =              @{Seq=17; runTest = "N"; fileName = "cmdlet-tests-requests.ps1";};
   Cluster=                @{Seq=18; runTest = "N"; fileName = "cmdlet-tests-cluster.ps1";};
   Certificates =          @{Seq=19; runTest = "N"; fileName = "cmdlet-tests-certificates.ps1";};
   Diagnostic=             @{Seq=20; runTest = "N"; fileName = "cmdlet-tests-diagnostic.ps1";};
   Starling =              @{Seq=21; runTest = "N"; fileName = "cmdlet-tests-starling.ps1";};
   Patch =                 @{Seq=22; runTest = "N"; fileName = "cmdlet-tests-patch.ps1";};
   Miscellaneous =         @{Seq=98; runTest = "N"; fileName = "cmdlet-tests-miscellaneous.ps1";};
   ObsoleteCommands =      @{Seq=99; runTest = "N"; fileName = "cmdlet-tests-obsolete-commands.ps1";};
}

# count of how many good/bad/info calls for summary at the end
$resultCounts = @{
   Good = 0;
   Bad = 0;
   Info = 0;
}

# just moving the "global" data to a separate file for maintainability
# (yes, it's powershell, everything is global)
. "$SCRIPT_PATH\harness-data.ps1"

# load up the harness functions
. "$SCRIPT_PATH\harness-functions.ps1"

# ========================================================================
#
#  Actual Start of Script logic
#
# ========================================================================

# Process the command line and either show help or set the list of tests to run
if ($allParameters -contains "help" -or $allParameters -contains "?") {
   showHelp
} elseif ($allParameters -contains "showdata") {
   showData
} elseif ($allParameters.Length -eq 0 -or $allParameters -contains "all") {
   foreach ($t in $Tests.GetEnumerator()) {
      $t.Value.runTest = "Y"
   }
} else {
   foreach ($p in $allParameters) {
      if ($Tests.Keys -contains $p) {
         $Tests[$p].runTest = "Y"
      } else {
         Write-Host -ForegroundColor Red -BackgroundColor Black "$p is not a recognized test name"
         $quit = $true
      }
   }
   if ($quit) { 
      showHelp
   }
}

write-host -NoNewLine "Running the following tests against "
write-host -ForegroundColor Red "Appliance=$($DATA.appliance), User=$($DATA.userName)"
foreach ($t in ($Tests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})) {
   write-host "   $($t.Key)"
}
pause

try {
   $fullRunInfo = testBlockHeader "begin" "All Test Blocks"

   Connect-Safeguard -Appliance $DATA.appliance -IdentityProvider $DATA.idProvider -Password $DATA.secPassword -Username $DATA.userName -Insecure
   goodResult "Connect-Safeguard" "Success"

   writeCallHeader "Get-SafeguardVersion"
   goodResult "Get-SafeguardVersion" "Success"
   $sgVersion = Get-SafeguardVersion
   $sgVersion | format-table
   # TODO Make sure to add any other known "vm" types
   $isVm = @('vmware','hyperv') -contains $sgVersion.BuildPlatform
   $isLTS = $sgVersion.Minor -eq "0"

   writeCallHeader "Test-SafeguardVersion - minimum 6.0"
   Test-SafeguardVersion -MinVersion 6.0
   goodResult "Test-SafeguardVersion" "Success"
 
   foreach ($t in ($Tests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})) {
      . "$SCRIPT_PATH\$($t.Value.fileName)"
   }
}
catch {
   Write-Host $_.Exception
   Write-Host $_.ScriptStackTrace
}
finally {
   Disconnect-Safeguard

   testBlockHeader "end" "All Test Blocks`nFinal Tally" $fullRunInfo 
   if ($resultCounts.Bad -gt 0) {
      Write-Host -ForegroundColor Red "===== Collected Errors ====="
      $collectedErrors | Write-Host -ForegroundColor Red
   }
}
