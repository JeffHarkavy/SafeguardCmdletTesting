# SafeguardCmdletTesting
PowerShell Testing Harness for Safeguard PS cmdlet module

Files (all must be in the same directory):
File | Description
---- | -----
safeguard-cmdlet-testing.ps1 | "the harness".  main testing harness to be invoked from powershell commandline. Can also be run from VisualStudio Code or Powershell ISE.
harness-data.ps1 | home for "global" variables
harness-functions.ps1 | functions used by harness and cmdlet-tests
cmdlet-tests-\*.ps1 | blocks of tests. only meant to be dot-source invoked from harness. Do not invoke these by hand.
license-123-456-000.dlv | perpetual SPP license for testing. Use this one or supply your own (make sure to edit the harness to point to the correct file)
Command Coverage.xlsx | just a sheet so I can keep track of what commands are covered

## Instructions / Notes

1) make sure you have safeguard powershell environment installed. See https://github.com/OneIdentity/safeguard-ps for instructions.

2) edit `safeguard-cmdlet-testing.ps1`, `harness-data.ps1`, and maybe `harness-functions.ps1` to change variable values to reflect "your" environment. Hopefully names and comments are enough to go on. Save.

3) In a powershell window, invoke the harness as `.\safeguard-cmdlet-testing.ps1` to run all tests
  - If you only want to run specific blocks of tests, `./safeguard-cmdlet-testing.ps1 ?` will list tests that can be run. Pass one or more test names on the commandline.
  - Invoke with argument of `showdata` to see current values used across all tests
  - Invoke with no arguments or the single argument `all` to run all commands.
  - Some tests are not included in the `all` run and must be specifically requested. These tests can be run individually or pass `allexplicit` to run all of them at once.
  - Invoke with a space-delimited list of test names to run individual tests. Test names do not have to be exact, but must be non-ambiguous.
  - Pass `LTS` or `Feature` to change test targets. Tests LTS branch by default.
  - Pass `Log` or `NoLog` to turn transcript logging on or off (default is Off).

4) Tests will report success or failure (green or red output by default). Many tests in each block will output their own data as part of the test (not colored).
  - Tests that only apply to h/w or vm, LTS or feature-release, should only run in their respective environments
  - As feature-releases add new commands to the PS library they will need to be added to the appropriate file.
  - Some tests will require human interaction (prompt to continue or such). These are noted in both the help output and in the pre-run summary of what tests are about to be executed.
  - Some tests need to br run by hand due to user input or what the command actually does (restart, factory reset, etc.). These can be listed by specifying `manual` in the command line.
  - Output directories will be created in the current working directory to hold output (logs, reports, etc.) created by some commands.

5) Counts of pass/fail will be reported at the end of each block of tests and at end of the run. All reported failures will be repeated at the end of the output.

## n.b.
As of this writing this is still a WIP. These are not exhaustive tests of each command.  Pretty much just making sure the command runs in its basic form and does not throw an exception. Right now there's only ~75% coverage of commands. The cmdlet-tests-* files have TODO sections with a list of commands that have not been stubbed or not tested yet.
