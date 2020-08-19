try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Check Help Function for all commands"
$blockInfo = testBlockHeader $TestBlockName
# Runs all commands with a -? parameter and looks for output.
# Will only complain if a given command doesn't return some help.
# Note that it's not really picky about *what's* returned, just as
# long as the call doesn't throw an exception for a missing command.
try {
   $Output = ""
   $Errors = ""
   foreach ($commandName in (get-safeguardcommand).Name|sort) {
      $cmd = $commandName + " -? | findstr  /b /i /r /c:""^ * $commandName"""
      $Output += "`n*** $cmd ***`n"
      try {
         $Output += (invoke-expression $cmd) | Out-String
      } catch {
         $Errors += "***no command help for $commandName`n"
      }
   }
   if ($Errors -ne "") {
      badResult "Help" "$Errors"
   } else {
      goodResult "Help" "All commands returned help output"
   }
} catch {
   badResult "Help general" "Unexpected error checking help output" $_
}
testBlockHeader $TestBlockName $blockInfo
