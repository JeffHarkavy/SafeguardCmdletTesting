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
      write-host ("$fmt" -f ("Good: $($resultCounts.Good - $startInfo.startGood)")) -ForegroundColor DarkGreen
      write-host ("$fmt" -f ("Bad: $($resultCounts.Bad - $startInfo.Bad)")) -ForegroundColor Red
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
   Write-Host "$($cmd) : $($str)" -ForegroundColor DarkGreen
   $resultCounts.Good++
}
function infoResult($cmd, $str) {
   Write-Host "$($cmd) : $($str)" -ForegroundColor DarkBlue
   $resultCounts.Info++
}
function badResult($cmd, $str, $exception) {
   $exMsg = ""
   if ($null -ne $exception) {
      $exMsg = " - $($exception.Message)"
   }
   $outputLine = "$($cmd) : $($str)$($exMsg)"
   Write-Host $outputLine  -ForegroundColor Red
   $collectedErrors.Add($outputLine) > $null
   $resultCounts.Bad++
}
function showHelp {
   Write-Host "
--- Running Selected or All tests ---
  Invoke with no arguments or the single argument all to run all commands.
  Invoke with a space-delimited list of test names to run individual tests.
  Valid test names are (in order of execution): "
  (($Tests.GetEnumerator() | Sort {$_.Value.Seq})).Name | foreach-object {'      {0}' -f $_}  
  exit
}
