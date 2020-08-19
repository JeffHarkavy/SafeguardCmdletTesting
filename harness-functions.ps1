# ############################################################################
# You may need to change these based on your shell color settings
# ############################################################################
$bgcolor = (get-host).ui.rawui.backgroundcolor
$COLORS = @{
   info      = @{back="$bgcolor"; fore="DarkBlue";};
   bad       = @{back="$bgcolor"; fore="Red";};
   good      = @{back="$bgcolor"; fore="DarkGreen";};
   highlight = @{back="$bgcolor"; fore="DarkRed";};
}

# Maybe someday ps will get the ternary operator, but until then...
Function iif($If, $Right, $Wrong) { If ($If) {$Right} Else {$Wrong} }

# Writes begin/end header blocks for groups of tests
#
# $hdrText             - Some type of descriptive text to include, typically the name
#                        of the block of tests
# $startInfo is null   - indicates a BEGIN block will be written and
#                        $startInfo object will be created and returned
# $startInfo is Int    - Same as null, indicates begin of test block and
#                        indicates the number of expected tests
# $startInfo is object - pass the startInfo block back to indicate END of
#                        the test block
#
# returns - for a "begin" header it returns a startInfo object which must
#           be passed in when writing the "end" header
function testBlockHeader($hdrText,$startInfo) {
   $time = get-date
   $newInfo = $null
   if ($null -eq $startInfo -or $startInfo.GetType().Name -eq "Int32") {
      $newInfo = @{
         startTime = $time;
         startGood = $resultCounts.Good + 0; 
         startBad = $resultCounts.Bad + 0;
         expected = $startInfo;
      }
      $doReturn = $true
      $beginOrEnd = "BEGIN"
   } else {
      $beginOrEnd = "END"
   }
   $blockline = "+==========================================================================+"
   $fmt = "| {0,-" + ($blockline.Length - 3) + "}|"
   $hdrText = "$beginOrEnd $hdrText"
   $stamp = "{0:MM}-{0:dd}-{0:yyyy} {0:HH}:{0:mm}:{0:ss}.{0:fff}" -f ($time)
   write-host ""
   write-host $blockline
   foreach ($ln in $hdrText.Split([Environment]::NewLine)) {
      $padding = (([Math]::Max(0, $blockline.Length / 2) - [Math]::Floor($ln.Length / 2)) - 1)
      write-host ("|{0}{1}{2}|" -f (' ' * $padding), $ln, (' ' * ($padding-($hdrText.Length %2))))
   }
   write-host ("$fmt" -f $stamp)
   if ($newInfo.expected) {
     write-host -ForegroundColor $COLORS.info.fore -BackgroundColor $COLORS.good.back ("$fmt" -f ("Expected: $($newInfo.expected)"))
   }
   if ('end' -eq $beginOrEnd) {
      $span = New-Timespan -Start $startInfo.startTime -End $time
      write-host ("$fmt" -f ("Elapsed: $($span.TotalSeconds) seconds"))
      if ($startInfo.expected) {
        write-host -ForegroundColor $COLORS.info.fore -BackgroundColor $COLORS.good.back ("$fmt" -f ("Expected: $($startInfo.expected)"))
      }
      write-host -ForegroundColor $COLORS.good.fore -BackgroundColor $COLORS.good.back ("$fmt" -f ("Good: $($($resultCounts.Good) - $($startInfo.startGood))"))
      write-host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back ("$fmt" -f ("Bad: $($($resultCounts.Bad) - $($startInfo.startBad))"))
   }
   write-host $blockline
 
   if ($doReturn) {return $newInfo}
}

# simpler header used to flag some individual tests
function writeCallHeader($cmd) {
   write-host "`n--------------------------------------------------"
   foreach ($l in $cmd.Split([Environment]::NewLine)) {
      write-host "-- $l"
   }
   write-host "--------------------------------------------------"
}

# good/info/bad result writers
# $cmd - command / test name
# $str - extra information
# $ex  - optional exception that was thrown for an error situation.
#        Will pull script line number and message for output
function goodResult($cmd, $str) {
   Write-Host -ForegroundColor $COLORS.good.fore -BackgroundColor $COLORS.good.back "$($cmd) : $($str)"
   $resultCounts.Good++
}

function infoResult($cmd, $str) {
   Write-Host -ForegroundColor $COLORS.info.fore -BackgroundColor $COLORS.info.back "$($cmd) : $($str)"
}

function badResult($cmd, $str, $ex) {
   $exMsg = ""
   if ($null -ne $ex.Exception) {
      $exMsg = " - L:$($ex.InvocationInfo.ScriptLineNumber) $($ex.Exception.Message)"
   }
   $outputLine = "$($cmd) : $($str)$($exMsg)"
   Write-Host -ForegroundColor $COLORS.bad.fore -BackgroundColor $COLORS.bad.back $outputLine
   $collectedErrors.Add($outputLine) > $null
   $resultCounts.Bad++
}

function showHelp {
   Write-Host -ForegroundColor $COLORS.good.fore -BackgroundColor $COLORS.good.back "
--- Running Selected or All tests ---
  - Invoke with argument of showdata to see current values used across all tests
  - Invoke with no arguments or the single argument all to run all commands.
  - Some tests are not included in the ""all commands"" run and must be specifically requested.
    These tests can be run individually or pass ""allexplicit"" to run all of them at once.
  - Invoke with a space-delimited list of test names to run individual tests.
    Test names do not have to be exact, but must be non-ambiguous.
  - Pass LTS or Feature to change test targets. Tests LTS branch by default.
  - Pass Log or NoLog to turn transcript logging on or off (default is Off)

  Valid test names are (in order of execution): "
  (($Tests.GetEnumerator() | Where-Object {$explicitTestKeys -notcontains $_.Key}) | Sort {$_.Value.Seq}) | `
     foreach-object { 
        Write-Host -ForegroundColor $COLORS.highlight.fore -BackgroundColor $COLORS.highlight.back `
        ('    {0,-20} - {1}' -f $_.Key,$_.Value.Description + (iif ($_.Value.inter -eq "Y") " (1)" "") + (iif ($_.Value.description -match "WIP") " (2)" ""))
     }
  Write-Host ""
  Write-Host -ForegroundColor $COLORS.good.fore -BackgroundColor $COLORS.good.back "  The following tests must be individually requested or ""allexplicit"" must be specified:"
  (($Tests.GetEnumerator() | Where-Object {$explicitTestKeys -contains $_.Key}) | Sort {$_.Value.Seq}) | `
     foreach-object { 
        Write-Host -ForegroundColor $COLORS.highlight.fore -BackgroundColor $COLORS.highlight.back `
        ('    {0,-20} - {1}' -f $_.Key,$_.Value.Description + (iif ($_.Value.inter -eq "Y") " (1)" "") + (iif ($_.Value.description -match "WIP") " (2)" ""))
     }
  Write-Host ""
  Write-Host "    (1) - Test may require human interaction."
  Write-Host "    (2) - Work-In-Progress. May not do much yet."
  Write-Host ""

  exit
}

# Writes out current values of the $DATA hashtable
function showData {
   $spacing = (write-output ("`n{0,32}" -f " "))

   Write-Host -ForegroundColor $COLORS.good.fore -BackgroundColor $COLORS.good.back ("`n{0,-30}  {1}" -f "--- Name ---","--- Value ---")
   foreach ($k in ($DATA.GetEnumerator() | Sort {$_.Key})) {
      Write-Host -NoNewLine -ForegroundColor $COLORS.good.fore -BackgroundColor $COLORS.good.back ('{0,-30}= ' -f $k.Key)
      if ($null -eq $k.Value) {
         Write-Host -ForegroundColor $COLORS.highlight.fore -BackgroundColor $COLORS.highlight.back "null"
         continue
      }
      $tname = $k.Value.GetType().Name
      if ($tname -ieq "hashtable") {
         # break out the pieces of the hashtable. no, it's not recursive so if
         # the hash has another hash or an array ... tough.
         Write-Host -ForegroundColor $COLORS.highlight.fore -BackgroundColor $COLORS.highlight.back ("@{{$($spacing)  {0};$spacing}}" -f (($k.Value.Keys|foreach {"${_}: $($k.Value[$_])"}) -join ";$spacing  "))
      } elseif ($tname -match "\[\]$") {
         # join the members of the array in a CSV list inside brackets
         Write-Host -ForegroundColor $COLORS.highlight.fore -BackgroundColor $COLORS.highlight.back ('[{0}]' -f ($k.Value -join ', '))
      } else {
         # just print whatever's there. Things like SecureStrings will just print the type name.
         Write-Host -ForegroundColor $COLORS.highlight.fore -BackgroundColor $COLORS.highlight.back ('{0}' -f $k.Value)
      }
   }
   Write-Host ""

   exit
}

# Create a user and return the object.
# Assumes connect has already been done.
function createUser($uname) {
   try {
      $user = Find-SafeguardUser $uname
      if ($user) {
         infoResult "Find-SafeguardUser" "$($user.UserName) already exists"
      } else {
         $user = New-SafeguardUser -NewUserName $uname -FirstName "Safeguard-ps" -LastName "User" -NoPassword -Provider -1
         goodResult "New-SafeguardUser" "$($user.UserName) created"
      }
   }
   catch {
      badResult "createUser" "Unexpected error fetching or creating $uname" $_.Exception
      throw $_.Exception
   }

   return $user
}

# Not strictly necessary, but it does make working from the command line a little easier
function sgConnect($appliance,$getToken) {
   $appliance = iif ($null -eq $appliance) $DATA.appliance $appliance
   if ($getToken) {
      $token = Connect-Safeguard -Appliance $appliance -IdentityProvider $DATA.idProvider -Password $DATA.secPassword -Username $DATA.userName -Insecure -NoSessionVariable
      infoResult "Recevied Access Token" $appliance
      return $token
   } else {
      Connect-Safeguard -Appliance $appliance -IdentityProvider $DATA.idProvider -Password $DATA.secPassword -Username $DATA.userName -Insecure
      infoResult "Connected to" $appliance
   }
}

function setTestBranch($branch) {
   if ($branch -ieq "LTS") {
      $DATA.appliance = $DATA.applianceLTS
      $DATA.clusterPrimary = $DATA.clusterPrimaryLTS;
      $DATA.clusterReplicas = $DATA.clusterReplicasLTS;
      $DATA.clusterSession = $DATA.clusterSessionLTS;
   } else {
      $DATA.appliance = $DATA.applianceFeature
      $DATA.clusterPrimary = $DATA.clusterPrimaryFeature;
      $DATA.clusterReplicas = $DATA.clusterReplicasFeature;
      $DATA.clusterSession = $DATA.clusterSessionFeature;
   }

   foreach ($dir in $DATA.outputPaths.GetEnumerator()) {
      if (-not (Test-Path $dir.Value -PathType Container)) {
         New-Item -Path $dir.Value -ItemType Directory > $null
      }
   }

   return $DATA.appliance
}

function formatSgVersion($v,$includeBuild) {
   return $v.Major.toString() + "." + `
          $v.Minor.toString() + "." + `
          (iif $v.ServicePack $v.ServicePack $v.Revision).toString() + `
          (iif $includeBuild ("." + (iif $v.HotfixLevel $v.HotfixLevel $v.Build).toString()) "");
}

function startTranscribing {
   if ($DATA.createLog -eq $true) {
      if (-not (Test-Path $DATA.outputPaths.logs -PathType Container)) {
         New-Item -Path $DATA.outputPaths.logs -ItemType Directory > $null
      }

      while ((Get-ChildItem "$($DATA.outputPaths.logs)\*.log").Count -ge $DATA.maxLogs) {
         infoResult "Removing Log" "$(Get-ChildItem "$($DATA.outputPaths.logs)\*.log" | Sort CreationTime | Select -First 1)"
         Get-ChildItem "$($DATA.outputPaths.logs)\*.log" | Sort CreationTime | Select -Last 1 | Remove-Item
      }

      Start-Transcript -Path "$($DATA.outputPaths.logs + $DATA.logName)"

   }
   return $DATA.createLogs
}
