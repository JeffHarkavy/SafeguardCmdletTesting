# SafeguardCmdletTesting
±PowerShell Testing Harness for testing safeguard-ps Powershell cmdlets

## Files
File | Description
---- | -----
safeguard-cmdlet-testing.ps1 | Main script to be invoked from powershell commandline. Can also be run from VisualStudio Code or Powershell ISE.
harness-globals.ps1 | Creates `$GLOBALS` object with global "constants". Loading this file loads other harness-\*.ps1 files.
harness-data.ps1 | Creates `$DATA` object used throughout tests. Edit this file to reflect your testing environment (asset names, ip addresses, etc.).
harness-tests.ps1 | Adds list of available tests to `$DATA`. Make sure to edit f you add or remove tests from the suite.
harness-helphash.ps1 | Adds MD5 hash values of all safeguard-ps cmdlets help output to `$DATA`.
harness-functions.ps1 | Adds functions to `$GLOBALS`.
cmdlet-tests/\*.ps1 | Individual test scripts. These are meant to be dot-source invoked from `safeguard-cmdlet-testing.ps1`.
licenses/\*.dlv | Licenses used for testing. Use or supply your own (make sure to edit `$DATA` to point to the correct files).

## Instructions / Notes

1) Make sure you have safeguard-ps installed. See https://github.com/OneIdentity/safeguard-ps for instructions.

2) Edit `$DATA` object values in `harness-data.ps1` to reflect your environment
  (ip addresses, user names, passwords, etc.). Hopefully names and comments are
  enough to make sense of all the pieces. Depending on your Powershell color
  scheme you may also want to adjust `$GLOBALS.COLORS` in the
  `harness-globals.ps1` file. Save edits.

3) In a powershell window cd to the root of the repository and invoke the
   harness as `.\safeguard-cmdlet-testing.ps1 <arguments>`.
  - If you only want to run specific blocks of tests,
    `./safeguard-cmdlet-testing.ps1 ?` or `./safeguard-cmdlet-testing.ps1
    testnames` will list tests that can be run. Pass one or more test names on the
    commandline separated by spaces.
  - Use an argument of `showdata` to see current values used across all tests
  - Invoke with no arguments or the single argument `all` to run all commands.
  - Some tests are not included in the `all` run and must be specifically
    requested. These tests can be run individually or pass `allexplicit` to run
    all of them at once.
  - Use a space-delimited list of test names to run individual tests. Test
    names are matched "begins with" the test name entered.
  - Pass `LTS` or `Feature` to change test targets. Tests LTS branch by default.
  - Pass `Log` or `NoLog` to turn transcript logging on or off (default is Off).\
    **About logging:** When logging is enabled the test harness uses PowerShell's
    Start-Transcript command to capture all output. Start-Transcript sees
    *everything* and reports some exceptions even when they handled in a `catch` or
    `-ErrorAction SilentlyContinue` is used. These show up in the transcript with
    `TerminatingError(...): "[...]"`. They should not be considered failed tests
    unless accompanied by a `: FAIL :` log output from the scripts.
  - Default verbosity level is 1 (see `harness-globals.ps1`). Pass `verbosity=2`
    on the command line to see additional output. The default table output for
    many command results is shown for verbosity level 2 or higher.

4) Tests will report success or failure (green or red output by default). Many
   tests in each block will output their own data as part of the test.
  - Tests that only apply to h/w or vm, LTS or feature-release, should only run
    in their respective environments
  - As feature-releases add new commands to the PS library they will need to be
    added to the appropriate file.
  - Some tests will require human interaction (prompt to continue or such).
    These are noted in both the help output and in the pre-run summary of what
    tests are about to be executed.
  - Some tests need to be run by hand due to user input or what the command
    actually does (restart, factory reset, etc.). These can be listed by
    specifying `manual` in the command line.
  - Directories will be created in the top level of the testing folderscurrent
    working directory to hold output (logs, reports, etc.) created by some
    commands.
  - Counts of pass/fail will be reported at the end of each block of tests and
    at end of the run. All reported failures will be repeated at the end of the
    output.

5) Some tests can be run in parallel Powershell sessions, some can not. Any tests
   that create or manipulate entities based on `$DATA` member information should
   not be run at the same, e.g., don't try to run AssetsAndAccounts and Requests
   in parallel sessions. Standalone tests like CheckHelp, Miscellaneous, and such
   can be run while other tests are also running.

## Debugging
If (when?) things crash and burn you can debug individual scripts by adding debug code
to the script and doing the following (make sure to remove debug code before checking
in any changes).
```
. ./harness-globals.ps1
$GLOBALS.sgConnect()
. ./cmdlet-tests/scriptName.ps1
```

If the script has a `script:Cleanup` function called in the `finally` clause you can
comment out the call to leave "scraps" behind for examination.

## Writing New Tests
Honestly, this will likely always be a WIP. These are not currently exhaustive
tests of each command - pretty much just making sure a command runs in its
basic form and does not throw an exception. Whoever comes across this can feel
free to add new tests to existing files or create new cmdlet-tests/\* files and
add them to the suite of tests.  The basic form of the test file is some setup
and a big try/catch/finally block covering the entire file. Many files create
data for use throughout those file's tests and then clean up the data in the
finally block.

**Do take care when editing or writing new code.** As of this writing (late 2024)
safeguard-ps supports Powershell 5.1 and above. The latest version of Powershell
is currently 7.4.4. Lots of new (and more modern) programming syntax has been
introduced in later PS versions, things like ternary operators (`cond ? true : false`)
and null coalesce assignments (`$var ??= "value"`). These will not work in PS 5.1
so make sure to test any new code in older versions. Someday PS 5.1 will go away.
Today is not that day, unfortunately.

Here's a basic template for a cmdlet-tests file:

```
try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

# Make sure to set GLOBALS.currentTest to the DATA.Tests object being run in this file
$GLOBALS.currentTest = $DATA.Tests.AccountPasswordRules
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

# Cleanup funciton can be omitted if there are no created items that should be cleaned up
function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   # script-specific cleanup steps
   # you can report on cleanup failures if you want or just have an empty catch block
   try { Remove-SafeguardAccountPasswordRule -PasswordRuleToDelete $pwdRuleName -ErrorAction SilentlyContinue > $null } catch { }
}

try {
   ... tests ...

   $script:completedSuccessfully = $true
}
catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error working with [name of test]"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}
```
