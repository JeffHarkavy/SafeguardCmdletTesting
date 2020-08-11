function testBlockHeader($startOrEnd,$hdrText,$startInfo) {
   $time = get-date
   if ($null -eq $startInfo) {
      $startInfo = @{
         startTime = $time;
         startGood = $resultCounts.Good; 
         startBad = $resultCounts.Bad;
      }
      $doReturn = $true
   }
   $blockline = "+==========================================================================+"
   $fmt = "| {0,-" + ($blockline.Length - 3) + "}|"
   $hdrText = $startorEnd.ToUpper() + " " + $hdrText
   $stamp = "{0:MM}-{0:dd}-{0:yyyy} {0:HH}:{0:mm}:{0:ss}.{0:fff}" -f ($time)
   write-host ""
   write-host $blockline
   foreach ($ln in $hdrText.Split([Environment]::NewLine)) {
      $padding = (([Math]::Max(0, $blockline.Length / 2) - [Math]::Floor($ln.Length / 2)) - 1)
      write-host ("|{0}{1}{2}|" -f (' ' * $padding), $ln, (' ' * ($padding-($hdrText.Length %2))))
   }
   write-host ("$fmt" -f $stamp)
   if ('end' -eq $startOrEnd) {
      $span = New-Timespan -Start $startInfo.startTime -End $time
      write-host ("$fmt" -f ("Elapsed: $($span.TotalSeconds) seconds"))
      write-host -ForegroundColor DarkGreen ("$fmt" -f ("Good: $($resultCounts.Good - $startInfo.startGood)"))
      write-host -ForegroundColor Red ("$fmt" -f ("Bad: $($resultCounts.Bad - $startInfo.Bad)"))
   }
   write-host $blockline
 
   if ($doReturn) {return $startInfo}
}

function writeCallHeader($cmd) {
   write-host "`n--------------------------------------------------"
   foreach ($l in $cmd.Split([Environment]::NewLine)) {
      write-host "-- $l"
   }
   write-host "--------------------------------------------------"
}

function goodResult($cmd, $str) {
   Write-Host -ForegroundColor DarkGreen "$($cmd) : $($str)"
   $resultCounts.Good++
}

function infoResult($cmd, $str) {
   Write-Host -ForegroundColor DarkBlue "$($cmd) : $($str)"
   $resultCounts.Info++
}

function badResult($cmd, $str, $exception) {
   $exMsg = ""
   if ($null -ne $exception) {
      $exMsg = " - $($exception.Message)"
   }
   $outputLine = "$($cmd) : $($str)$($exMsg)"
   Write-Host -ForegroundColor Red $outputLine
   $collectedErrors.Add($outputLine) > $null
   $resultCounts.Bad++
}

function showHelp {
   Write-Host -ForegroundColor DarkGreen "
--- Running Selected or All tests ---
  Invoke with argument of showdata to see current values used across all tests
  Invoke with no arguments or the single argument all to run all commands.
  Invoke with a space-delimited list of test names to run individual tests.
  Valid test names are (in order of execution): "
  (($Tests.GetEnumerator() | Sort {$_.Value.Seq})).Name | foreach-object {Write-Host -ForegroundColor DarkRed ('      {0}' -f $_)}  
   Write-Host ""

  exit
}

function showData {
   Write-Host -ForegroundColor DarkGreen ("`n{0,-30}  {1}" -f "--- Name ---","--- Value ---")
   foreach ($k in ($DATA.GetEnumerator() | Sort {$_.Key})) {
      $tname = $k.Value.GetType().Name
      Write-Host -NoNewLine -ForegroundColor DarkGreen ('{0,-30}= ' -f $k.Key)
      if ($tname -ieq "hashtable") {
         # break out the pieces of the hashtable. no, it's not recursive so if
         # the hash has another hash or an array ... tough.
         Write-Host -ForegroundColor DarkRed ('@{{ {0} }}' -f (($k.Value.Keys|foreach {"${_}:$($k.Value[$_])"}) -join ", "))
      } elseif ($tname -match "\[\]$") {
         # join the members of the array in a CSV list inside brackets
         Write-Host -ForegroundColor DarkRed ('[{0}]' -f ($k.Value -join ', '))
      } else {
         # just print whatever's there. Things like SecureStrings will just print the type name.
         Write-Host -ForegroundColor DarkRed ('{0}' -f $k.Value)
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
