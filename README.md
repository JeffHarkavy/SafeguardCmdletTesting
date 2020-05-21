# SafeguardCmdletTesting
PowerShell Testing Harness for Safeguard PS cmdlet module

Files (all must be in the same directory):
  safeguard-cmdlet-testing.ps1 - "the harness".  main testing harness to be invoked
                                 from powershell commandline. Can also be run from
                                 VisualStudio Code or Powershell ISE.
  harness-data.ps1             - home for "global" variables
  cmdlet-tests-*.ps1           - blocks of tests. only meant to be dot-source invoked 
                                 from harness. Do not invoke these by hand.
  license-123-456-000.dlv      - perpetual SPP license for testing. Use this one or
                                 supply your own (make sure to edit the harness to
                                 point to the correct file)
  Command Coverage.xlsx        - just a sheet so I can keep track of what commands
                                 are covered

1) make sure you have safeguard powershell environment installed. See
   https://github.com/OneIdentity/safeguard-ps for instructions.

2) edit safeguard-cmdlet-testing.ps1 & harness-data.ps1 and change variable values at the top of
   the script to reflect "your" environment. Hopefully names and comments are
   enough to go on. Save.

3) In a powershell window, invoke the harness as .\safeguard-cmdlet-testing.ps1 to run all tests
   - If you only want to run specific blocks of tests, "./safeguard-cmdlet-testing.ps1 ?"
     will list tests that can be run. Pass one or more test names on the commandline .

4) Tests will report success or failure (green or red output). Many tests in
   each block will output their own data as part of the test (not colored).
   - Tests that only apply to h/w or vm, LTS or feature-release, should only run
     in their respective environments
   - As new feature-releases add commands to the PS library they will need to
     be added to the appropriate file.
   - Some tests in the cmdlet-tests-miscellaneous.ps1 are reported as "should be run
     by hand".  These are tests which require user input or do things like restart,
     power down, factory reset, etc.

5) Counts of pass/fail will be reported at the end of the run. All reported failures
   will be repeated at the end of the output.

n.b., As of this writing this is still a WIP. These are not exhaustive tests of
each command.  Pretty much just making sure the command runs in its basic form
and does not throw an exception. Right now there's only ~50% coverage of
commands. The harness file and the cmdlet-tests-* files have TODO sections with
a list of commands that have not been tested yet.
