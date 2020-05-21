try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
writeCallHeader "Check Help Function for all commands"
# Runs all commands with a -? parameter and looks for output.
# Will only complain if a given command doesn't return some help.
# Note that it's not really picky about *what's* returned, just as
# long as the call doesn't throw an exception for a missing command.
try {
   $collectedOutput = ""
   $collectedErrors = ""
   foreach ($commandName in (get-safeguardcommand).Name|sort) {
      $cmd = $commandName + " -? | findstr  /b /i /r /c:""^ * $commandName"""
      $collectedOutput += "`n*** $cmd ***`n"
      try {
         $collectedOutput += (invoke-expression $cmd) | Out-String
      } catch {
         $collectedErrors += "***no command help for $commandName`n"
      }
   }
   if ($collectedErrors -ne "") {
      badResult "Help" "$collectedErrors"
   } else {
      goodResult "Help" "All commands returned help output"
   }
} catch {
   badResult "Help general" "Unexpected error checking help output" $_.Exception
}
