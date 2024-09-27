# data is defined in a separate file to try and make maintenance and updates a little easier
# also, so it can be dot-sourced in from the command line for development and testing
if ($GLOBALS) { Remove-Variable -Scope Global GLOBALS }

# Simpler to add this as a true "global" function by itself rather than adding to the $GLOBALS object.
# Powershell 7 introduced the ternary operator (bool ? truestuff : falsestuff), but since
# safeguard-ps can work with PS 5.1 (for now) we'll keep this handy.
Function iif($If, $Right, $Wrong) { If ($If) {$Right} Else {$Wrong} }
Function ifIsNull($value, $isnullvalue) { If ($null -eq $value) {$isnullvalue} Else {$value} }

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

   # This is populated at the beginning of each block of test with one of the $DATA.Tests objects
   currentTest = $null;
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

