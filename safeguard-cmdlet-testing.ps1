# Gather any parameters into a single array
param([Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)][string[]] $allParameters)

$SCRIPT_PATH = (Split-Path $myInvocation.MyCommand.Path)
$BASE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($myInvocation.MyCommand.Name)
$collectedErrors = [System.Collections.ArrayList]@()
$knownVMTypes = @('vmware','hyperv')
# You may need to change these based on your shell color settings
$bgcolor = (get-host).ui.rawui.backgroundcolor
$COLORS = @{
   info      = @{back="$bgcolor"; fore="DarkBlue";};
   bad       = @{back="$bgcolor"; fore="Red";};
   good      = @{back="$bgcolor"; fore="DarkGreen";};
   highlight = @{back="$bgcolor"; fore="DarkRed";};
}

# just moving the "global" data to a separate file for maintainability
# (yes, it's powershell, everything is global)
. "$SCRIPT_PATH\harness-data.ps1"

# load up the harness functions
. "$SCRIPT_PATH\harness-functions.ps1"

$testBranch = "LTS"
if ($allParameters -contains "lts" -and $allParameters -contains "feature") {
   Write-Host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back "Can not specify both LTS and Feature"
   exit
} elseif ($allParameters -contains "lts" -or $allParameters -contains "feature") {
   $testBranch = iif ($allParameters -contains "lts") "LTS" "Feature"
   $allParameters = @($allParameters | Where-Object { $_ -ne "LTS" -and $_ -ne "Feature" })
}
setTestBranch $testBranch > $null

if ($allParameters -contains "log") {
   $DATA.createLog = $true
} elseif ($allParameters -contains "nolog") {
   $DATA.createLog = $false
}
$allParameters = @($allParameters | Where-Object { $_ -ne "log" -and $_ -ne "nolog" })

# List of tests that can be run (ok... hashmap)
#    Seq = order in which test will be run if > 1 test is specified
#    runTest = Y/N, will be filled in based on commandline parameters
#    inter = Y/N, test has prompting and/or may require human interaction
#    fileName = script of tests that will be dot-sourced when needed
#    description = yadda yadda describing the test. Include the text WIP in the description for files that aren't done yet.
$Tests = @{
   CheckHelp = @{
      Seq=1; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-help.ps1";
      description="Check to make sure all commands return help.";
   };
   NoParameter = @{
      Seq=2;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-noparameter.ps1";
      description="Runs commands that don't require parameters.";
   };
   Users = @{
      Seq=3;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-users.ps1";
      description="User related commands.";
   };
   Groups = @{
      Seq=4;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-groups.ps1";
      description="User group related commands.";
   };
   AssetsAndAccounts = @{
      Seq=5;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-assets-and-accounts.ps1";
      description="Assets, Accounts, and Asset/Account Groups.";
   };
   AccountPasswordRules = @{
      Seq=6;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-account-password-rules.ps1";
      description="Create, edit, and list account password rules.";
   };
   CheckChangeSchedules = @{
      Seq=7;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-check-change-schedules.ps1";
      description="Create, edit, and list check and change schedules.";
   };
   Directory = @{
      Seq=8;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-directory.ps1";
      description="Create, edit, and manipulate directory and directory accounts.";
   };
   AssetPartition = @{
      Seq=9;  runTest = "N"; inter="N";
      fileName = "cmdlet-tests-asset-partition.ps1";
      description="Create, edit, and manipulate partitions.";
   };
   PasswordProfile = @{
      Seq=10; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-password-profile.ps1";
      description="Create, edit, and list password profiles.";
   };
   NetworkDiagnostics = @{
      Seq=11; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-network-diagnostics.ps1";
      description="Run network diagnostic commands.";
   };
   NewSchedules = @{
      Seq=12; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-new-schedules.ps1";
      description="Schedule creation commands (not assigning schedules).";
   };
   EventSubscriptions = @{
      Seq=13; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-event-subscriptions.ps1";
      description="Test event subscription commands.";
   };
   Backups = @{
      Seq=14; runTest = "N"; inter="Y";
      fileName = "cmdlet-tests-backups.ps1";
      description="Backup related commands (not restore).";
   };
   Entitlement = @{
      Seq=15; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-entitlement.ps1";
      description="Entitlement & Access Policy creation.";
   };
   A2A = @{
      Seq=16; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-a2a.ps1";
      description="WIP. A2A configuration and use.";
   };
   Requests = @{
      Seq=17; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-requests.ps1";
      description="WIP. Request workflow.";
   };
   Cluster= @{
      Seq=18; runTest = "N"; inter="Y";
      fileName = "cmdlet-tests-cluster.ps1";
      description="Cluster operations. May require human interaction.";
   };
   Session= @{
      Seq=19; runTest = "N"; inter="Y";
      fileName = "cmdlet-tests-sps.ps1";
      description="Work with SPS Appliances. May require human interaction.";
   };
   Certificates = @{
      Seq=20; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-certificates.ps1";
      description="Csr, Certificates, and certification access.";
   };
   Identity = @{
      Seq=21; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-identity.ps1";
      description="Create, edit, and manipulate identity provider.";
   };
   Diagnostic= @{
      Seq=22; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-diagnostic.ps1";
      description="WIP. Appliance diagnostic packages.";
   };
   Starling = @{
      Seq=23; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-starling.ps1";
      description="WIP. Starling join 'n stuff";
   };
   Patch = @{
      Seq=24; runTest = "N"; inter="Y";
      fileName = "cmdlet-tests-patch.ps1";
      description="Tests patching commands. Requires human interaction.";
   };
   # Somebody has to be last, why not these 2?
   Miscellaneous = @{
      Seq=98; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-miscellaneous.ps1";
      description="All kinds of don't-fit-elsewhere type commands.";
   };
   ObsoleteCommands = @{
      Seq=99; runTest = "N"; inter="N";
      fileName = "cmdlet-tests-obsolete-commands.ps1";
      description="Test to make sure Obsolete commands return that they are, in fact, obsolete.";
   };
}
# These tests must be explicitly specified - they will not be included in an "all tests" run
# Also include any interactive tests and anything with WIP in the description.
$explicitTestKeys = (@("CheckHelp","ObsoleteCommands") + `
      ($Tests.GetEnumerator() | `
       Where-Object {$_.Value.Description -match "WIP" -or $_.Value.inter -eq "Y"} | `
       select-object -Expand Name)) | `
      Sort | Get-Unique

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

# Process the command line and either show help or set the list of tests to run
if ($allParameters -contains "help" -or $allParameters -contains "?") {
   showHelp
} elseif ($allParameters -contains "showdata") {
   showData
} elseif ($allParameters.Length -eq 0 -or $allParameters -contains "all") {
   foreach ($t in $Tests.GetEnumerator()) {
      $t.Value.runTest = iif ($explicitTestKeys -contains $t.Key) "N" "Y"
   }
} else {
   foreach ($p in $allParameters) {
      $matches = ($Tests.Keys -match "^$p")
      if ($Tests.Keys -contains $p) {
         $Tests[$p].runTest = "Y"
      } elseif ($matches.Count -eq 1) {
         $Tests[$matches[0]].runTest = "Y"
      } elseif ($matches.Count -gt 1) {
         Write-Host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back "$p is not a distinct test name. Could be any of: $($matches -join ' ')"
         $quit = $true
      } else {
         Write-Host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back "$p is not a recognized test name"
         $quit = $true
      }
   }
   if ($quit) { 
      showHelp
   }
}

write-host -NoNewLine "Running the following tests against "
write-host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back "Appliance=$($DATA.appliance), Others=[$($DATA.clusterReplicas -join ",")], User=$($DATA.userName), TestBranch=$testBranch"
foreach ($t in ($Tests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})) {
   write-host "   $($t.Key) $(iif ($t.Value.inter -eq "Y") " - May require human interaction" '')"
}
pause

try {
   if ($DATA.createLog) {
      startTranscribing
   }

   $fullRunInfo = testBlockHeader "begin" "All Test Blocks"

   sgConnect
   goodResult "Connect-Safeguard" "Success"

   writeCallHeader "Get-SafeguardVersion"
   $sgVersion = Get-SafeguardVersion
   goodResult "Get-SafeguardVersion" "Success"
   $sgVersion | format-table

   # Make sure to add any other known "vm" types
   $isVm = $knownVMTypes -contains $sgVersion.BuildPlatform
   $isLTS = $sgVersion.Minor -eq "0"
   writeCallHeader "Appliance Info"
   infoResult "isVm" $isVm
   infoResult "isLTS" $isLTS
   if ($isLTS -and $testBranch -eq "Feature" -and $Tests.Patch.runTest -eq "Y") {
      infoResult "Test Branch Check" "This is an LTS appliance. Do you want to patch it to a Feature build?"
      if ("Y" -ne (Read-Host "Enter Y to continue with patch tests on $($DATA.appliance)")) {
         exit
      }
   } elseif (($isLTS -and $testBranch -ne "LTS") -or (-not $isLTS -and $testBranch -ne "Feature")) {
      badResult "Test Branch Mismatch" "This is a $(iif $isLTS "LTS" "Feature") appliance and TestBranch is set to $testBranch"
      exit
   }

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
      Write-Host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back "===== Collected Errors ====="
      $collectedErrors | Write-Host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back
   }
   Write-Host ""

   if ($DATA.createLog) { Stop-Transcript }
}
