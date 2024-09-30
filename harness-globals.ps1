# data is defined in a separate file to try and make maintenance and updates a little easier
# also, so it can be dot-sourced in from the command line for development and testing
if ($GLOBALS) { Remove-Variable -Scope Global GLOBALS }

# Simpler to add these as true global function rather than adding to the $GLOBALS object.
# Powershell 7 introduced the ternary operator (bool ? truestuff : falsestuff) and null
# coalesce ($x ?? "ifnullvalue"), but since safeguard-ps can work with PS 5.1 (for now)
# we'll keep these handy.
Function iif($If, $Right, $Wrong) { If ($If) {$Right} Else {$Wrong} }
Function ifIsNull($value, $isnullvalue) { If ($null -eq $value) {$isnullvalue} Else {$value} }
Function ifIsNullOrEmpty($value, $alternative) { If ($null -eq $value -or "" -eq $value) { $alternative } Else { $value } }

# for common timestamping
# formatType 1 == for file names
#            2 == log output
#            3 == for time tests
Function getTimestamp($formatType = 1, $currentTime = $null) {
   $currentTime = ifIsNull $currentTime (Get-Date) $currentTime
   if ($formatType -eq 1) {
      return "{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f ($currentTime)
   } elseif ($formatType -eq 2) {
      return "{0:MM}-{0:dd}-{0:yyyy} {0:HH}:{0:mm}:{0:ss}.{0:fff}" -f ($currentTime)
   } elseif ($formatType -eq 3) {
      return $currentTime.toString("yyyy-MM-ddTHH:mm:ss.fffZ")
   }

   # Just to have some form of fallback for formatType
   return "{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f ($currentTime)
}

$SCRIPT_PATH = ifIsNull $SCRIPT_PATH (Get-Location).Path

$GLOBALS = @{
   # array to collect all the errors for a re-reporting at the end of the run
   collectedErrors = [System.Collections.ArrayList]@();

   # count of how many good/bad/info calls for summary at the end
   resultCounts = @{
      Good = 0;
      Bad = 0;
      Skipped = 0;
      Warning = 0;
   };

   # set to $true by including "log" in the command line
   # will do a PowerShell transcript to capture all output
   createLog = $false;

   # control how much output is ... put out
   # 0 == very quiet
   # 1 == normal (whatever that means)
   # 2 == some diagnostics and default tableFormat calls
   # 3 == MOAR OUTPUT! (someday)
   Verbosity = 2;

   # default background & foreground color at startup
   bgcolor = (get-host).ui.rawui.backgroundcolor;
   fgcolor = (get-host).ui.rawui.foregroundcolor;

   # This is populated at the beginning of each block of tests with one of the $DATA.Tests objects
   currentTest = $null;

   # We this will be set to either LTS or Feature based on command line parameters
   testBranch = "LTS"
};

$GLOBALS += @{
   # ############################################################################
   # You may need/want to change these based on your shell color settings
   # ############################################################################
   COLORS = @{
      # used for general info messages
      info      = @{BackgroundColor="$($GLOBALS.bgcolor)"; ForegroundColor="Cyan";};
      # used for good / bad test results
      bad       = @{BackgroundColor="$($GLOBALS.bgcolor)"; ForegroundColor="Red";};
      good      = @{BackgroundColor="$($GLOBALS.bgcolor)"; ForegroundColor="DarkGreen";};
      warning   = @{BackgroundColor="$($GLOBALS.bgcolor)"; ForegroundColor="Yellow";};
      # highlighted output
      highlight = @{BackgroundColor="$($GLOBALS.bgcolor)"; ForegroundColor="DarkRed";};
      white     = @{BackgroundColor="$($GLOBALS.bgcolor)"; ForegroundColor="White";};
      # for processes that use Write-Progress (patch, cluster, etc.)
      # this will help powershell's stupid progress bar stand out.
      # If you want to use the standard colors then set the values to
      # $host.privatedata.ProgressBackgroundColor/ProcessForegroundColor
      # or just comment out the following line.
      progress  = @{BackgroundColor="Black";    ForegroundColor="White";};
   };
}

. "$SCRIPT_PATH\harness-data.ps1"
. "$SCRIPT_PATH\harness-tests.ps1"
. "$SCRIPT_PATH\harness-helphash.ps1"
. "$SCRIPT_PATH\harness-functions.ps1"

