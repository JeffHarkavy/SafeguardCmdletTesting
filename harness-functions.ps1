if ($null -eq $GLOBALS) {
  Write-Host -ForegroundColor Red "Must process harness-globals.ps1 first!"
  exit
}

# write colored output using hashes from the GLOBALS.COLORS object
$GLOBALS | Add-Member -MemberType ScriptMethod -Name writeHostColor -Value {
  param($color, $message, $nonewline)
  $color = ifIsNull $color @{ForegroundColor=$GLOBALS.fgcolor; BackgroundColor=$GLOBALS.bgcolor;}
  $nonewline = ifIsNull $nonewline $false
  if ($message -is [Array]) {
     ($message | join "`n") | Write-Host @color 
  } else {
     $message | Write-Host -NoNewLine:($nonewline) @color
  }
};

# Writes begin/end header blocks for groups of tests
#
# $startInfo is String - Indicates a BEGIN block will be written using the provided
#                        text as the block name. $startInfo object will be created and returned
# $startInfo is null   - Indicates a BEGIN block will be written using the current
#                        test block name. $startInfo object will be created and returned
# $startInfo is object - pass the startInfo block back to indicate END of
#                        the test block
#
# returns - for a "begin" header it returns a startInfo object which must
#           be passed in when writing the "end" header. for an "end" header
#           there is nothing returned
$GLOBALS | Add-Member -MemberType ScriptMethod -Name testBlockHeader -Value {
   param($startInfo, $final)
   $final = ifIsNull $final $false

   if ($null -eq $startInfo) {
      $hdrText = ifIsNull $GLOBALS.currentTest.TestBlockName "Start Test"
      $startInfo = $null
   } elseif ($startInfo.GetType().Name -eq "String") {
      $hdrText = $startInfo
      $startInfo = $null
   } else {
      $hdrText = $startInfo.blockName
   }

   $currentTime = get-date
   if ($null -eq $startInfo) {
      $startInfo = @{
         startTime = $currentTime;
         startGood = $GLOBALS.resultCounts.Good + 0; 
         startBad = $GLOBALS.resultCounts.Bad + 0;
         startWarning = $GLOBALS.resultCounts.Warning + 0;
         startSkipped = $GLOBALS.resultCounts.Skipped + 0;
         expected = ifIsNull $GLOBALS.currentTest.testCount 0;
         blockName = $hdrText;
      }
      $doReturn = $true
      $beginOrEnd = "BEGIN"
   } else {
      $beginOrEnd = "END"
   }
   $blockline =      "+==========================================================================+"
   $blockseparator = "+--------------------------------------------------------------------------+"
   $fmt = "| {0,-" + ($blockline.Length - 3) + "}|"
   $hdrText = "$beginOrEnd $($startInfo.blockName)"
   $stamp = getTimestamp 2 $currentTime
   write-host ""
   write-host $blockline
   foreach ($ln in $hdrText.Split([Environment]::NewLine)) {
      $padding = (([Math]::Max(0, $blockline.Length / 2) - [Math]::Floor($ln.Length / 2)) - 1)
      write-host ("|{0}{1}{2}|" -f (' ' * $padding), $ln, (' ' * ($padding-($hdrText.Length %2))))
   }
   write-host $blockseparator
   write-host ("$fmt" -f $stamp)
   if ($startInfo.expected) {
     write-host $blockseparator
     $GLOBALS.writeHostColor($GLOBALS.COLORS.info, ("$fmt" -f ("Expected: $($startInfo.expected)")))
   }
   if ('end' -eq $beginOrEnd) {
      $span = New-Timespan -Start $startInfo.startTime -End $currentTime
      if ($span.TotalSeconds -le 100) {
         $elapsed = "$($span.TotalSeconds) seconds"
      } else {
         $elapsed = "{0:HH:mm:ss.fff}" -f ([datetime]$span.Ticks)
      }
      write-host ("$fmt" -f ("Elapsed: $elapsed"))
      write-host $blockseparator
      if ($startInfo.expected) {
        $GLOBALS.writeHostColor($GLOBALS.COLORS.info, ("$fmt" -f ("Expected: $($startInfo.expected)")))
      }
      $GLOBALS.writeHostColor($GLOBALS.COLORS.info, ("$fmt" -f ("Skipped: $($($GLOBALS.resultCounts.Skipped) - $($startInfo.startSkipped))")))
      $GLOBALS.writeHostColor($GLOBALS.COLORS.good, ("$fmt" -f ("Good: $($($GLOBALS.resultCounts.Good) - $($startInfo.startGood))")))
      $GLOBALS.writeHostColor($GLOBALS.COLORS.warning, ("$fmt" -f ("Warning: $($($GLOBALS.resultCounts.Warning) - $($startInfo.startWarning))")))
      $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, ("$fmt" -f ("Bad: $($($GLOBALS.resultCounts.Bad) - $($startInfo.startBad))")))
      if ($final -and $GLOBALS.createLog) {
         $GLOBALS.writeHostColor($GLOBALS.COLORS.info, ("$fmt" -f "Transcript: logs/$($DATA.logName) "))
      }

      $GLOBALS.currentTest = $null
   }
   write-host $blockline
 
   if ($doReturn) {return $startInfo}
};

# simpler header used to flag some individual tests
$GLOBALS | Add-Member -MemberType ScriptMethod -Name writeCallHeader -Value {
   param($cmd, $color)

   $cmd = iif $($cmd -eq "cleanup") "$($GLOBALS.currentTest.TestBlockName) Cleanup" $cmd
   $GLOBALS.writeHostColor($color, "`n--------------------------------------------------");
   foreach ($l in $cmd.Split("`n")) {
      $GLOBALS.writeHostColor($color, "-- $l");
   }
   $GLOBALS.writeHostColor($color, "--------------------------------------------------");
};

# good/info/bad/warning/skip result writers all accept a hash of argument properties
#
# minVerbosity - minimum verbosity setting for writing. 0 or $null will always write.
#                Even if we don't write an error because of verbosity settings the
#                global resultCounts will still be updated and, in the case of "bad",
#                the error will still be collected for display at the end.
# cmd       - command / test name. If $null is passed it will default to the current test short name
# str       - message
# extra     - extra information (e.g., command output)
# ex        - optional exception that was thrown for an error situation.
#             Will pull script line number and message for output,
# skipCount - number of tests being skipped for skipResult call (default == 1). Ignored
#             for all others.
# timing    - A hash table of {startTime=X; endTime=Y} that will include an "Elapsed" message
#             in the output. If endTime is null the current time will be used.
$GLOBALS | Add-Member -MemberType ScriptMethod -Name goodResult -Value {
   param ($argHash)
   $GLOBALS.resultWriter($GLOBALS.buildRwHash($argHash, $GLOBALS.COLORS.good, "SUCCESS"))
   $GLOBALS.resultCounts.Good++
}

$GLOBALS | Add-Member -MemberType ScriptMethod -Name skipResult -Value {
   param ($argHash)
   $GLOBALS.resultWriter($GLOBALS.buildRwHash($argHash, $GLOBALS.COLORS.warning, "WARNING"))
   $GLOBALS.resultCounts.Skipped += (ifIsNull $skipCount 1)
}

$GLOBALS | Add-Member -MemberType ScriptMethod -Name warningResult -Value {
   param ($argHash)
   $GLOBALS.resultWriter($GLOBALS.buildRwHash($argHash, $GLOBALS.COLORS.warning, "WARNING"))
   $GLOBALS.resultCounts.Warning++
}

$GLOBALS | Add-Member -MemberType ScriptMethod -Name infoResult -Value {
   param ($argHash)
   $GLOBALS.resultWriter($GLOBALS.buildRwHash($argHash, $GLOBALS.COLORS.info, "INFO"))
}

$GLOBALS | Add-Member -MemberType ScriptMethod -Name badResult -Value {
   param ($argHash)
   $rwHash = $GLOBALS.buildRwHash($argHash, $GLOBALS.COLORS.bad, "FAIL")
   $GLOBALS.resultWriter($rwHash)

   $GLOBALS.collectedErrors.Add("$(ifIsNull $GLOBALS.currentTest.TestBlockName "No Current Test") : $($rwHash.cmd) : $($rwHash.message)") > $null
   $GLOBALS.resultCounts.Bad++
};

# a worker for populating extra information in the argHash passed to the *Result calls
$GLOBALS | Add-Member -MemberType ScriptMethod -Name buildRwHash -Value {
   param($argHash, $colors, $messageType)

   $exMsg = ""
   if ($null -ne $argHash.ex.Exception) {
      $exMsg = " - L:$($argHash.ex.InvocationInfo.ScriptLineNumber) $($argHash.ex.Exception.Message)"
   }

   $argHash.colors = ifIsNull $argHash.colors $colors
   $argHash.messageType = ifIsNull $argHash.messageType $messageType
   $argHash.message += $exMsg
   # use HH:mm:ss if you'd rather display it as 24-hour time
   $argHash.message = $argHash.message -replace '%time%', (Get-Date -format 'hh:mm:ss tt')

   $argHash.cmd = ifIsNull $argHash.cmd $GLOBALS.currentTest.TestBlockShortName
   return $argHash
}

# a worker function for the result output writers
$GLOBALS | Add-Member -MemberType ScriptMethod -Name resultWriter -Value {
   param ($parm)
   $cmd = ifIsNull $parm.cmd $GLOBALS.currentTest.TestBlockShortName
   $colors = $parm.colors

   $elapsed = ""
   if ($null -ne $parm.timing -and $null -ne $parm.timing.startTime) {
      $span = New-Timespan -Start $parm.timing.startTime -End (ifIsNull $parm.timing.endTime (Get-Date))
      $elapsed = " (Elapsed $("{0:HH:mm:ss.fff}" -f ([datetime]$span.Ticks)))"
   }
   $message = "$cmd : $($parm.messageType.toUpper())$($elapsed) : $($parm.message)"

   if ($GLOBALS.Verbosity -ge (ifIsNull $parm.minVerbosity -1)) {
      Write-Host @colors "$message"
      if ($null -ne $parm.extra) {
         if ($parm.extra -is [Array]) {
            ($parm.extra | join "`n") | Write-Host @colors 
         } else {
            Write-Host @colors "$($parm.extra)"
         }
      }
   }
};

# A common Format-Table output for result sets
# Default number of rows to output is $DATA.defaultFormatTableLineCount
# $maxLines > 0  - show first X lines
# $maxLines < 0  - show last X lines
# $maxLines == 0 - show all lines
# $GLOBALS.Verbosity s/b set to 2 to show default table output
$GLOBALS | Add-Member -MemberType ScriptMethod -Name formatTable -Value {
   param ($argHash)
   $argHash.minVerbosity = ifIsNull $argHash.minVerbosity 2

   if ($GLOBALS.Verbosity -ge $arghash.minVerbosity -and $null -ne $arghash.output) {
      $argHash.maxLines = ifIsNull $argHash.maxLines $DATA.defaultFormatTableLineCount
      $propertySplat = ifIsNull $arghash.properties @{ Property='*'; }

      $arghash.maxLines = ifIsNull $arghash.maxLines $DATA.defaultFormatTableLineCount
      if ($arghash.maxLines -eq 0) {
         $arghash.output | Format-Table @propertySplat
      } elseif ($arghash.maxLines -gt 0) {
         if ($arghash.output.count -gt $arghash.maxLines) {
            $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Showing first $($arghash.maxLines) of $($arghash.output.Count) lines")
         }
         $arghash.output | Select -First $arghash.maxLines | Format-Table @propertySplat
      } else {
         $arghash.maxLines *= -1
         if ($arghash.output.count -gt $arghash.maxLines) {
            $GLOBALS.writeHostColor($null, "Showing last $($arghash.maxLines) of $($arghash.output.Count) lines")
         }
         $arghash.output | Select -Last $arghash.maxLines | Format-Table @propertySplat
      }
   }
};

# Displays the script help and exits
$GLOBALS | Add-Member -MemberType ScriptMethod -Name showHelp -Value {
   param ($commandsOnly = $false)
   function testDesc($test) {
      return $test.Description + (iif ($test.interactive -eq "Y") " (1)" "") + (iif ($test.description -match "WIP") " (2)" "")
   }

   if (!$commandsOnly) {
      $GLOBALS.writeHostColor($GLOBALS.COLORS.white, "`
   --- Running Selected or All tests ---`
     - Invoke with argument of showdata to see current values used across all tests`
     - Invoke with no arguments or the single argument all to run all commands.`
     - Some tests are not included in the ""all commands"" run and must be specifically requested.`
       These tests can be run individually or pass ""allexplicit"" to run all of them at once.`
     - Invoke with a space-delimited list of test names to run individual tests.`
       Test names are matched 'begins with' the test name entered.
     - Pass LTS or Feature or Other:ipaddress to change test targets. Tests LTS branch by default.`
       Other will not test patch or cluster.`
     - Pass Log or NoLog to turn transcript logging on or off (default is Off)");
  }

  $GLOBALS.writeHostColor($GLOBALS.COLORS.good, "`n  Valid test names are (in order of execution, test counts are approximate): ")
  $local:header = '    {0,-20} {1,5}  {2}' -f "Test Name","Count","Description`n"
  $local:header += '    {0,-20} {1,5}  {2}' -f $('='*20),$('='*5),$('='*50)

  $GLOBALS.writeHostColor($GLOBALS.COLORS.white, $local:header)
  (($DATA.tests.GetEnumerator() | Where-Object {$explicitTestKeys -notcontains $_.Key}) | Sort {$_.Value.Seq}) | `
     foreach-object {
        $GLOBALS.writeHostColor($GLOBALS.COLORS.white, ('    {0,-20} {1,5}  {2}' -f $_.Key,(iif $_.Value.testCount $_.Value.testCount 'n/a'),(testDesc $_.Value)))
     }
  Write-Host ""

  $GLOBALS.writeHostColor($GLOBALS.COLORS.good, "  The following tests must be individually requested or ""allexplicit"" must be specified:")
  $GLOBALS.writeHostColor($GLOBALS.COLORS.white, $local:header)
  (($DATA.tests.GetEnumerator() | Where-Object {$explicitTestKeys -contains $_.Key}) | Sort {$_.Value.Seq}) | `
     foreach-object {
        $GLOBALS.writeHostColor($GLOBALS.COLORS.white, ('    {0,-20} {1,5}  {2}' -f $_.Key,(iif $_.Value.testCount $_.Value.testCount 'n/a'),(testDesc $_.Value)))
     }
  Write-Host ""
  Write-Host "    (1) - Test may require human interaction."
  Write-Host "    (2) - Work-In-Progress. May not do much yet."
  Write-Host ""
};

# Writes out current values of the $DATA hashtable and exits
$GLOBALS | Add-Member -MemberType ScriptMethod -Name showData -Value {
   $spacing = (write-output ("`n{0,32}" -f " "))

   $GLOBALS.writeHostColor($GLOBALS.COLORS.good, ("`n{0,-30}  {1}" -f "--- Name ---","--- Value ---"))
   foreach ($k in ($DATA.GetEnumerator() | Sort {$_.Key})) {
      Write-Host -NoNewLine @COLORS_good ('{0,-30}= ' -f $k.Key)
      if ($null -eq $k.Value) {
         $GLOBALS.writeHostColor($GLOBALS.COLORS.highlight, "null")
         continue
      }
      $tname = $k.Value.GetType().Name
      if ($tname -ieq "hashtable") {
         # break out the pieces of the hashtable. no, it's not recursive so if
         # the hash has another hash or an array ... tough.
         $GLOBALS.writeHostColor($GLOBALS.COLORS.highlight, ("@{{$($spacing)  {0};$spacing}}" -f (($k.Value.Keys|foreach {"${_}: $($k.Value[$_])"}) -join ";$spacing  ")))
      } elseif ($tname -match "\[\]$") {
         # join the members of the array in a CSV list inside brackets
         $GLOBALS.writeHostColor($GLOBALS.COLORS.highlight, ('[{0}]' -f ($k.Value -join ', ')))
      } else {
         # just print whatever's there. Things like SecureStrings will just print the type name.
         $GLOBALS.writeHostColor($GLOBALS.COLORS.highlight, ('{0}' -f $k.Value))
      }
   }
   Write-Host ""
};

# Create a user and return the object.
# Assumes connect has already been done.
$GLOBALS | Add-Member -MemberType ScriptMethod -Name createUser -Value {
   param ($userInput)

   $local:uname = ""
   $local:isNew = $true
   $local:newUser = $null
   try {
      if ($userInput.GetType().Name -eq "String") {
         $local:uname = $userInput
      } else {
         $local:uname = $userInput.UserName
      }
      $local:newUser = Find-SafeguardUser -QueryFilter "Name ieq '$local:uname'"
      if ($local:newUser) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Find-SafeguardUser"; message = "$($local:newUser.Name) already exists"; })
         $local:isNew = $false
      } else {
         if ($userInput.GetType().Name -eq "String") {
            $local:newUser = New-SafeguardUser -NewUserName $local:uname -FirstName "Safeguard-ps" -LastName "User" -NoPassword -Provider -1
         } else {
            $local:newUser = New-SafeguardUser -NewUserName $userInput.UserName -FirstName $userInput.FirstName -LastName $userInput.LastName -Password $userInput.SecPassword -Provider $userInput.IdProvider
         }
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardUser"; message = "$($local:newUser.Name) created"; })
      }
   }
   catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "createUser"; message = "Unexpected error fetching or creating $local:uname"; ex =$_.Exception; })
      throw $_.Exception
   }

   return @{isNew = $local:isNew; newUser = $local:newUser}
};

# Since we do this in more than one place...
$GLOBALS | Add-Member -MemberType ScriptMethod -Name createArchiveServer -Value {
   param($quiet = $false)

   $archiveServer = New-SafeguardArchiveServer -DisplayName $DATA.realArchiveServer.DisplayName `
     -NetworkAddress $DATA.realArchiveServer.NetworkAddress `
     -TransferProtocol $DATA.realArchiveServer.TransferProtocol `
     -Port $DATA.realArchiveServer.Port `
     -StoragePath $DATA.realArchiveServer.StoragePath `
     -ServiceAccountCredentialType $DATA.realArchiveServer.ServiceAccountCredentialType `
     -ServiceAccountName $DATA.realArchiveServer.ServiceAccountName `
     -ServiceAccountPassword $DATA.realArchiveServer.ServiceAccountPassword `
     -AcceptSshHostKey

   if (!$quiet) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardArchiveServer"; message = "Successfully created Archive Server $($DATA.realArchiveServer.DisplayName) Id=$($archiveServer.Id)"; })
   }

   return $archiveServer
}

$GLOBALS | Add-Member -MemberType ScriptMethod -Name createAsset -Value {
   param($quiet = $false, $assetName = "")

   $assetSplat = $GLOBALS.deepClone($DATA.asset)
   $assetSplat.DisplayName = ifIsNullOrEmpty $assetName $assetSplat.DisplayName
   $asset = New-SafeguardAsset @assetSplat

   if (!$quiet) {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAsset"; message = "successfully asset $($DATA.displayName)"; })
   }

   return $asset
}

# Not strictly necessary, but it does make working from the command line a little easier
$GLOBALS | Add-Member -MemberType ScriptMethod -Name sgConnect -Value {
   param ($appliance,$user,$getToken)

   $appliance = ifIsNull $appliance $DATA.appliance
   #default to the user to the super-user defined in $DATA unless told otherwise
   $user = ifIsNull $user $DATA.superUser

   if ($getToken) {
      $token = Connect-Safeguard -Appliance $appliance -IdentityProvider $user.idProvider -Password $user.secPassword -Username $user.userName -Insecure -NoSessionVariable
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Recevied Access Token for user $($user.UserName)"; message = $appliance; })
      return $token
   } else {
      Connect-Safeguard -Appliance $appliance -IdentityProvider $user.idProvider -Password $user.secPassword -Username $user.userName -Insecure
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Connected to"; message = $appliance; })
   }
};

# Sets harness-wide variables to point at either the LTS or Feature branch appliances
$GLOBALS | Add-Member -MemberType ScriptMethod -Name setTestBranch -Value {
   param ($branch)

   if ($branch -ieq "LTS") {
      $DATA.appliance = $DATA.applianceLTS
      $DATA.clusterPrimary = $DATA.clusterPrimaryLTS;
      $DATA.clusterReplicas = $DATA.clusterReplicasLTS;
      $DATA.clusterSession = $DATA.clusterSessionLTS;
   } elseif ($branch -ieq "feature") {
      $DATA.appliance = $DATA.applianceFeature
      $DATA.clusterPrimary = $DATA.clusterPrimaryFeature;
      $DATA.clusterReplicas = $DATA.clusterReplicasFeature;
      $DATA.clusterSession = $DATA.clusterSessionFeature;
   } elseif ($branch -match "^other:(?<address>.*)") {
      $DATA.appliance = $Matches.address
      $DATA.clusterPrimary = $DATA.appliance;
      $DATA.clusterReplicas = @();
      $DATA.clusterSession = @();
   }

   # Make sure all the various filePaths directories exist
   foreach ($dir in $DATA.filePaths.GetEnumerator()) {
      if (-not (Test-Path $dir.Value -PathType Container)) {
         New-Item -Path $dir.Value -ItemType Directory > $null
      }
   }

   return $DATA.appliance
};

# What it says.
$GLOBALS | Add-Member -MemberType ScriptMethod -Name formatSgVersion -Value {
   param ($v,$includeBuild)

   return $v.Major.toString() + "." + `
          $v.Minor.toString() + "." + `
          (iif $v.ServicePack $v.ServicePack $v.Revision).toString() + `
          (iif $includeBuild ("." + (iif $v.HotfixLevel $v.HotfixLevel $v.Build).toString()) "");
};

# If users wants output logged this will start a transcript in the logs directory.
# It will only keep the most recent "maxLogs" (see harness-data.ps1), including the
# one being started.
$GLOBALS | Add-Member -MemberType ScriptMethod -Name startTranscribing -Value {

   if ($GLOBALS.createLog -eq $true) {
      if (-not (Test-Path $DATA.filePaths.logs -PathType Container)) {
         New-Item -Path $DATA.filePaths.logs -ItemType Directory > $null
      }

      while ((Get-ChildItem "$($DATA.filePaths.logs)\$($BASE_NAME)_*.log").Count -ge $DATA.maxLogs) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Removing Log"; message = "$(Get-ChildItem "$($DATA.filePaths.logs)\*.log" | Sort CreationTime | Select -First 1)"; })
         Get-ChildItem "$($DATA.filePaths.logs)\*.log" | Sort CreationTime | Select -Last 1 | Remove-Item
      }

      Start-Transcript -Path "$($DATA.filePaths.logs + $DATA.logName)"
   }

   return $GLOBALS.createLog
};

# For any test blocks that cause Write-Progress bars to be displayed
# (e.g., patch and cluster) this can be used to make the progress bar
# stand out a little more.
# Call it with no arguments at the head of the test block to set the
# progress bar to $COLORS.progress and it will return the current colors
# as a hashmap {bg="color";fg="color"}
# Call it from the test's "finally" block or cleanup function with that
# hashmap to reset colors back to what they were.
$GLOBALS | Add-Member -MemberType ScriptMethod -Name setProgressBarColors -Value {
   param ($oldvalues)

   if ($null -eq $oldvalues) {
      $oldvalues = @{ bg = $host.privatedata.ProgressBackgroundColor; fg = $host.privatedata.ProgressForegroundColor; }

      if ($null -ne $COLORS.progress) {
         $host.privatedata.ProgressBackgroundColor = $COLORS.progress.back;
         $host.privatedata.ProgressForegroundColor = $COLORS.progress.fore;
      }

      return $oldvalues
   } elseif ($oldvalues.bg -and $oldvalues.fg) {
      $host.privatedata.ProgressBackgroundColor = $oldvalues.bg;
      $host.privatedata.ProgressForegroundColor = $oldvalues.fg;
   }
};

# Reduces an object to a simple MD5 hash. Not intended to be crypto secure,
# just for comparing objects.
$GLOBALS | Add-Member -MemberType ScriptMethod -Name hashString -Value {
   param ($string)

   $stringAsStream = [System.IO.MemoryStream]::new()
   $writer = [System.IO.StreamWriter]::new($stringAsStream)
   $writer.write($string)
   $writer.Flush()
   $stringAsStream.Position = 0
   $result = (Get-FileHash -Algorithm MD5 -InputStream $stringAsStream).Hash

   return $result
}

# Returns deep clone of an object
$GLOBALS | Add-Member -MemberType ScriptMethod -Name deepClone -Value {
    param($InputObject)

    return [System.Management.Automation.PsSerializer]::Deserialize([System.Management.Automation.PsSerializer]::Serialize($InputObject))
}

# Does what it says. Process the command line and initializes environment for
# a run of tests.
$GLOBALS | Add-Member -MemberType ScriptMethod -Name initializeEnvironment -Value {
   param($whichTests)
   $whichTests = ifIsNull $whichTests $DATA.Tests

   if ($null -eq $allParameters -or $allParameters.Count -eq 0) {
      $allParameters = @("all")
   } else {
      $allParameters =  ($allParameters | ForEach { [Regex]::Escape($_) })
   }

   if ($allParameters -contains "all" -and $allParameters -contains "allexplicit") {
      $GLOBALS.writeHostColor($GLOBALS.COLORS.highlight, "ALLEXPLICIT takes precedence over ALL. Only ALLEXPLICIT will be run.")
   }

   $GLOBALS.testBranch = "LTS"
   if (($allParameters -match "^(lts|(other:)|feature)").length -gt 1) {
      $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, "Can not specify more than one of: LTS, Feature, Other")
      exit
   } elseif ($allParameters -contains "lts" -or $allParameters -contains "feature") {
      $GLOBALS.testBranch = iif ($allParameters -contains "lts") "LTS" "Feature"
   } elseif ($allParameters -match "^other:.+") {
      $GLOBALS.testBranch = $allParameters -match "^other:"
   }
   $GLOBALS.setTestBranch($GLOBALS.testBranch) > $null

   if ($allParameters -contains "log") {
      $GLOBALS.createLog = $true
   } elseif ($allParameters -contains "nolog") {
      $GLOBALS.createLog = $false
   }
   $allParameters = @($allParameters | Where-Object { @("log","nolog","lts","feature") -notcontains $_ -and $_ -notmatch "^other:" })

   # These tests must be explicitly specified in the command line or the "allexplicit" command must be entered.
   # They will not be included in a normal "all tests" run.
   # Also include any interactive tests and anything with WIP in the description.
   $explicitTestKeys = (($whichTests.GetEnumerator() | `
          Where-Object {$_.Value.Description -match "WIP" -or $_.Value.interactive -eq "Y" -or $_.Value.explicitTest -eq "Y"} | `
          select-object -Expand Name)) | `
         Sort | Get-Unique

   if ($allParameters -contains "help" -or $allParameters -contains "?" -or $allParameters -contains "testnames") {
      # do the work and bail
      $GLOBALS.showHelp(($allParameters -contains "testnames"))
      return $false
   }
  
   if ($allParameters -contains "showdata") {
      # ditto
      $GLOBALS.showData()
      return $false
   }

   if ($allParameters -contains "updatehelp") {
      $DATA.UpdateHelpHash = $true
   }

   if ($allParameters -contains "verifyhelp") {
      $DATA.VerifyHelpHash = $true
   }

   if ($allParameters -match "^verbosity=") {
      if (($allParameters -match "^verbosity=[0-9]")[0] -match '=([0-9]*)') {
         $verbosity = [int]$matches[1]
         $GLOBALS.Verbosity = iif $($verbosity -gt 3) 3 $verbosity
      }
      $allParameters = @($allParameters | Where-Object { $_ -notmatch '^verbosity=' })
   }

   if ($allParameters -match "^batch=") {
      if (($allParameters -match "^batch=[0-9]")[0] -match '=([0-9]*)') {
         $batch = [int]$matches[1]
         $GLOBALS.asyncBatchNumber = iif $($batch -gt 9) 9 $batch
         if ($GLOBALS.asyncBatchNumber -eq 0) {
            $GLOBALS.asyncBatchSuffix = ""
         } else {
            $GLOBALS.asyncBatchSuffix = "_B_$($GLOBALS.asyncBatchNumber)"
            $DATA.logName = "$($BASE_NAME)_transcript_batch#$($GLOBALS.asyncBatchNumber)_$(getTimestamp 1).log";
         }
      }
      $allParameters = @($allParameters | Where-Object { $_ -notmatch '^batch=' })
   }
   $allParameters = @($allParameters | Where-Object { @("verifyhelp","updatehelp","log","nolog","logcommands") -notcontains $_ -and $_ -notmatch "^([0-9]+)$" })

   # clean up logs directory
   $p = iif $($GLOBALS.asyncBatchSuffix) "_batch#$($GLOBALS.asyncBatchNumber)" ""
   foreach ($logPattern in ("$($DATA.filePaths.logs)*commands${p}*.log","$($DATA.filePaths.logs)*transcript${p}*.log")) {
      while ((Get-ChildItem $logPattern).Count -ge $DATA.maxLogs) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = $null; message = "Removing Log"; extra = "$(Get-ChildItem $logPattern | Sort CreationTime | Select -First 1)"; })
         Get-ChildItem $logPattern | Sort CreationTime | Select -Last 1 | Remove-Item
      }
   }


   if ($DATA.VerifyHelpHash -or $DATA.UpdateHelpHash) {
      $allParameters += "checkhelp"
   }

   # Process the command line and either show help or set the list of tests to run
   if ($allParameters -contains "allexplicit") {
      foreach ($t in $whichTests.GetEnumerator()) {
         $t.Value.runTest = iif $($explicitTestKeys -contains $t.Key) "Y" "N"
      }
   } elseif ($allParameters.Count -eq 0 -or $allParameters -contains "all") {
      foreach ($t in $whichTests.GetEnumerator()) {
         $t.Value.runTest = iif $($explicitTestKeys -contains $t.Key) "N" "Y"
      }
   } else {
      # Try to find commands based on a partial match of what they entered vs. the
      # beginning of the test name, but make sure it only matches one command e.g.,
      # "misc" will find only "Miscellaneous" but "asset" finds both
      # "AssetsAndAccounts" and "AssetPartition".
      $quit = $false
      foreach ($p in $allParameters.GetEnumerator() | Where-Object {$_ -ne ""}) {
         $matches = ($whichTests.Keys -match "^$p")
         if ($whichTests.Keys -contains $p) {
            if ($whichTests[$p].fileName -ne "") {
               $whichTests[$p].runTest = "Y"
            } else {
               $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, "The $p command test has no file associated with it yet.")
            }
         } elseif ($matches.Count -ge 1) {
            if ($matches.Count -gt 1) {
               $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Multiple matches for $p found. Adding $($matches -join ",")")
            }
            $matches | ForEach {
               if ($whichTests[$_].fileName -ne "") {
                  $whichTests[$_].runTest = "Y"
               } else {
                  $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, "The $_ command test has no file associated with it yet.")
               }
            }
         } else {
            $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, "$([Regex]::Unescape($p)) is not a recognized test name")
            $commandsOnly = $true
            $quit = $true
         }
      }
      if ($quit) { 
         if ($commandsOnly) { Read-Host "Press Enter to see a list of command names" > $null }
         $GLOBALS.showHelp($commandsOnly)
         return $false
      }
   }

   $commandsToRun = ($whichTests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})
   if ($commandsToRun.Count -eq 0) {
      $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, "No commands were chosen to run")
      return $false
   }

   # If Manual is the only thing being run there's no need to go through anything else
   if ($commandsToRun.Count -eq 1 -and $DATA.Tests.Manual.runTest -eq "Y") {
      . "$($DATA.Tests.Manual.fileName)"
      return $false
   }

   # Show the user the tests that are about to be run and give them
   # one last chance to bail
   write-host -NoNewLine "Current Settings"
   $fmt = '{0,-15} = {1}'
   $GLOBALS.writeHostColor($GLOBALS.COLORS.bad, "`
      $("$fmt" -f "Appliance", $($DATA.Appliance))`
      $("$fmt" -f "SPS Appliance", $($DATA.clusterSession[0]))`
      $("$fmt" -f "Admin User", $($DATA.superUser.userName))`
      $("$fmt" -f "Feature Version", $($DATA.FeatureVersion))`
      $("$fmt" -f "LTS Version", $($DATA.LTSVersion))`
      $("$fmt" -f "Verbosity", $($GLOBALS.Verbosity))`
      $("$fmt" -f "VerifyHelpHash", $($DATA.VerifyHelpHash))`
      $("$fmt" -f "UpdateHelpHash", $($DATA.UpdateHelpHash))`
      $("$fmt" -f "Log", $(iif $GLOBALS.createLog "$($DATA.filePaths.logs)$($DATA.logName)" "Disabled"))`
   ")
   write-host "Running the following tests (test counts are approximate)"
   $totalTestCount = 0
   foreach ($t in $commandsToRun) {
      $line = "   $($t.Key)" `
         + (iif $($t.Value.testCount) " ($($t.Value.testCount) tests) " " ") `
         + (iif $($t.Value.interactive -eq "Y") " - May require human interaction" "") `
         + (iif ($t.Value.description -match "WIP") " - WIP. May not do much yet." "")
      write-host $line
      $totalTestCount += $t.Value.testCount
   }
   if ($totalTestCount -gt 0) {
      Write-Host "Total test count (est) = $totalTestCount"
   }
   write-host

   return $true
};

