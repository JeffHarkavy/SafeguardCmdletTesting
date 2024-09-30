# harness-data.ps1 must be processed first!
if ($null -eq $DATA) {
  Write-Host -ForegroundColor Red "Must process harness-data.ps1 first!"
  exit
} else {
   $DATA.Remove("Tests")
}

# List of tests that can be run (ok... hashmap)
#    Seq                = order in which test will be run if > 1 test is specified
#    runTest            = Y/N, will be filled in based on commandline parameters
#    interactive        = Y/N, test has prompting and/or may require human interaction
#    fileName           = script of tests that will be dot-sourced when needed.
#    description        = yadda yadda describing the test. Include the text WIP in the description for files that aren't done yet.
#    TestBlockName      = Used for writing block headers and in some error or diagnostic output
#    TestBlockShortName = Used in good/bad/info/warn output
#    testCount          = number of expected tests. Information purposes - i don't hold you to anything
#    expectedFailCount  = number of tests that are *expected* to produce "FAIL" results under normal conditions
$DATA.Tests = @{
   CheckHelp = @{
      Seq = 1; runTest = "N"; interactive = "N"; explicitTest = "Y";
      fileName = "$($DATA.filePaths.tests)/check-help.ps1";
      description = "Check to make sure all commands return help. Add verifyhelp to the command line to verify help content. Add updatehelp to output updated help hash values.";
      TestBlockName = "Help Commands";
      TestBlockShortName = "Help";
      testCount = 0; # this will be populated in harness-helphash.ps1
      expectedFailCount = 0;
   };
   NoParameter = @{
      Seq = 2;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/no-parameter.ps1";
      description = "Runs commands that don't require parameters.";
      TestBlockName = "No-Parameter Commands";
      TestBlockShortName = "NoParameter";
      testCount = 73;
      expectedFailCount = 0;
   };
   Users = @{
      Seq = 3;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/users.ps1";
      description = "User related commands.";
      TestBlockName = "User Commands";
      TestBlockShortName = "Users";
      testCount = 12;
      expectedFailCount = 0;
   };
   Groups = @{
      Seq = 4;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/groups.ps1";
      description = "User group related commands.";
      TestBlockName = "User Group Commands";
      TestBlockShortName = "UserGroups";
      testCount = 8;
      expectedFailCount = 0;
   };
   AssetsAndAccounts = @{
      Seq = 5;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/assets-and-accounts.ps1";
      description = "Assets, Accounts, and Asset/Account Groups.";
      TestBlockName = "Asset, Account and Group Commands";
      TestBlockShortName = "AssetCommands";
      testCount = 38;
      expectedFailCount = 0;
   };
   AccountPasswordRules = @{
      Seq = 6;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/account-password-rules.ps1";
      description = "Create, edit, and list account password rules.";
      TestBlockName = "Account Password Commands";
      TestBlockShortName = "AccountPasswords";
      testCount = 5;
      expectedFailCount = 0;
   };
   CheckChangeSchedules = @{
      Seq = 7;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/check-change-schedules.ps1";
      description = "Create, edit, and list check and change schedules.";
      TestBlockName = "Check and Change Schedule Commands";
      TestBlockShortName = "CheckChangeSchedules";
      testCount = 12;
      expectedFailCount = 0;
   };
   Directory = @{
      Seq = 8;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/directory.ps1";
      description = "Create, edit, and manipulate directory and directory accounts.";
      TestBlockName = "Directory Account Commands";
      TestBlockShortName = "DirectoryAccounts";
      testCount = 2;
      expectedFailCount = 0;
   };
   AssetPartition = @{
      Seq = 9;  runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/asset-partition.ps1";
      description = "Create, edit, and manipulate partitions.";
      TestBlockName = "Partition Commands";
      TestBlockShortName = "Partitions";
      testCount = 7;
      expectedFailCount = 0;
   };
   PasswordProfile = @{
      Seq = 10; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/password-profile.ps1";
      description = "Create, edit, and list password profiles.";
      TestBlockName = "Passsword Profile Commands";
      TestBlockShortName = "PasswordProfiles";
      testCount = 7;
      expectedFailCount = 0;
   };
   NetworkDiagnostics = @{
      Seq = 11; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/network-diagnostics.ps1";
      description = "Run network diagnostic commands.";
      TestBlockName = "Network Diagnostic Commands";
      TestBlockShortName = "NetworkDiagnostics";
      testCount = 6;
      expectedFailCount = 0;
   };
   NewSchedules = @{
      Seq = 12; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/new-schedules.ps1";
      description = "Schedule creation commands (does not assign schedules).";
      TestBlockName = "Schedule Commands";
      TestBlockShortName = "Schedules";
      testCount = 5;
      expectedFailCount = 0;
   };
   EventSubscriptions = @{
      Seq = 13; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/event-subscriptions.ps1";
      description = "Test event subscription commands.";
      TestBlockName = "Event Subscription Commands";
      TestBlockShortName = "Subscriptions";
      testCount = 6;
      expectedFailCount = 0;
   };
   Backups = @{
      Seq = 14; runTest = "N"; interactive = "Y";
      fileName = "$($DATA.filePaths.tests)/backups.ps1";
      description = "Backup related commands (not restore).";
      TestBlockName = "Backup Commands";
      TestBlockShortName = "Backups";
      testCount = 12;
      expectedFailCount = 0;
   };
   Entitlement = @{
      Seq = 15; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/entitlement.ps1";
      description = "Entitlement & Access Policy creation.";
      TestBlockName = "Entitlement Commands";
      TestBlockShortName = "Entitlements";
      testCount = 12;
      expectedFailCount = 0;
   };
   A2A = @{
      Seq = 16; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/a2a.ps1";
      description = "A2A configuration and use.";
      TestBlockName = "A2A Commands";
      TestBlockShortName = "A2A";
      testCount = 23;
      expectedFailCount = 0;
   };
   Requests = @{
      Seq = 17; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/requests.ps1";
      description = "Request workflow.";
      TestBlockName = "Access Request Workflow";
      TestBlockShortName = "Requests";
      testCount = 66;
      expectedFailCount = 0;
   };
   Cluster = @{
      Seq = 18; runTest = "N"; interactive = "Y";
      fileName = "$($DATA.filePaths.tests)/cluster.ps1";
      description = "Cluster operations.";
      TestBlockName = "Cluster Commands";
      TestBlockShortName = "Cluster";
      testCount = 13;
      expectedFailCount = 0;
   };
   Session = @{
      Seq = 19; runTest = "N"; interactive = "Y";
      fileName = "$($DATA.filePaths.tests)/sps.ps1";
      description = "Work with SPS Appliances.";
      TestBlockName = "SPS Related Commands";
      TestBlockShortName = "SPS";
      testCount = 11;
      expectedFailCount = 0;
   };
   Certificates = @{
      Seq = 20; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/certificates.ps1";
      description = "Csr, Certificates, and certification access.";
      TestBlockName = "Certificate Commands";
      TestBlockShortName = "Certificates";
      testCount = 3;
      expectedFailCount = 0;
   };
   Identity = @{
      Seq = 21; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/identity.ps1";
      description = "Create, edit, and manipulate identity provider.";
      TestBlockName = "Identity Provider Commands";
      TestBlockShortName = "IdentityProviders";
      testCount = 0;
      expectedFailCount = 0;
   };
   Diagnostic = @{
      Seq = 22; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/diagnostic.ps1";
      description = "Appliance diagnostic packages.";
      TestBlockName = "Appliance Diagnostic Commands";
      TestBlockShortName = "ApplianceDiagnostics";
      testCount = 10;
      expectedFailCount = 0;
   };
   Starling = @{
      Seq = 23; runTest = "N"; interactive = "Y";
      fileName = "$($DATA.filePaths.tests)/starling.ps1";
      description = "Starling join 'n stuff.";
      TestBlockName = "Starling Commands";
      TestBlockShortName = "Starling";
      testCount = 8;
      expectedFailCount = 0;
   };
   Patch = @{
      Seq = 24; runTest = "N"; interactive = "Y";
      fileName = "$($DATA.filePaths.tests)/patch.ps1";
      description = "Tests patching commands.";
      TestBlockName = "Patching Commands";
      TestBlockShortName = "Patching";
      testCount = 8;
      expectedFailCount = 0;
   };
   Settings = @{
      Seq = 25; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/settings.ps1";
      description = "Tests Settings commands";
      TestBlockName = "Settings Commands";
      TestBlockShortName = "Settings";
      testCount = 9;
      expectedFailCount = 0;
   };
   Time = @{
      Seq = 26; runTest = "N"; interactive = "Y";
      fileName = "$($DATA.filePaths.tests)/time.ps1";
      description = "Tests time commands.";
      TestBlockName = "Time Commands";
      TestBlockShortName = "Time";
      testCount = 1;
      expectedFailCount = 0;
   };
   Imports = @{
      Seq = 27; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/imports.ps1";
      description = "Tests Import commands.";
      TestBlockName = "Import Commands";
      TestBlockShortName = "Imports";
      testCount = 13;
      expectedFailCount = 0;
   };
   # Somebody has to be last, why not these?
   FilterProperties = @{
      Seq = 96; runTest = "N"; interactive = "N"; explicitTest = "Y";
      fileName = "$($DATA.filePaths.tests)/filter-properties.ps1";
      description = "Tests to make sure that all filterable properties of a DTO can actually be used as a filter.";
      TestBlockName = "Filter Properties";
      TestBlockShortName = "Filter Properties";
      testCount = 33;
      expectedFailCount = 0;
   };
   Manual = @{
      Seq = 97; runTest = "N"; interactive = "Y";
      fileName = "$($DATA.filePaths.tests)/manual.ps1";
      description = "Shows list of commands that have to be tested by hand. Does not actually do any tests.";
      TestBlockName = "Manual";
      TestBlockShortName = "Manual";
      testCount = 0;
      expectedFailCount = 0;
   };
   Miscellaneous = @{
      Seq = 98; runTest = "N"; interactive = "N";
      fileName = "$($DATA.filePaths.tests)/miscellaneous.ps1";
      description = "All kinds of don't-fit-elsewhere type commands.";
      TestBlockName = "Miscellaneous";
      TestBlockShortName = "Miscellaneous";
      testCount = 29;
      expectedFailCount = 0;
   };
   ObsoleteCommands = @{
      Seq = 99; runTest = "N"; interactive = "Y"; explicitTest = "Y";
      fileName = "$($DATA.filePaths.tests)/obsolete-commands.ps1";
      description = "Test to make sure Obsolete commands return that they are, in fact, obsolete.";
      TestBlockName = "Obsolete Commands";
      TestBlockShortName = "Obsolete";
      testCount = 0;
      expectedFailCount = 0;
   };
}

