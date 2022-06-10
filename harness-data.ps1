#
# A single hash object with all the "global" data used by test scripts
#
# ############################################################################
# MAKE SURE ALL IP ADDRESSES, SYSTEM/ACCOUNT/USER NAMES AND PASSWORDS ARE
# UPDATED TO REFLECT YOUR ENVIRONMENT
# ############################################################################
#
# Normally the script path is set in the safeguard-cmdlet-testing script, but I've
# found that dot-sourcing this file from the command line can make it easier to do
# hand-testing. Ergo, if the variable isn't populated yet then set it to the cwd.
# 
$SCRIPT_PATH = if($SCRIPT_PATH) {$SCRIPT_PATH} else {(Get-Location).Path}

$DATA = @{
   #addresses of LTS and Feature branch appliances
   applianceLTS = "10.5.34.128";
   applianceFeature = "10.5.34.128"

   # ip address of appliance to test.
   # Based on cmdline args this will be set to either LTS or feature appliance
   appliance = "10.5.33.128";

   # Version numbers to be used when looking for patch files
   LTSVersion = "7.0.0";
   FeatureVersion = "7.0.0";

   # uber-admin user with all admin permissions. The same user will be used
   # to run all commands unless otherwise noted.
   userName = "sudo";
   secPassword = "Test1234" | ConvertTo-SecureString -AsPlainText -Force;

   # login provider for the above 
   idProvider = "local";

   # admin user and password for any SPS appliances. Again, the same user
   # needs to be provisioned on all appliances.
   # Hint ask Brad Nicholes for a good SPS if you don't have one
   SPSAdmin = "admin";
   SPSAdminPassword = "root4EDMZ" | ConvertTo-SecureString -AsPlainText -Force;

   # peon user who will be added and manipulated
   userUsername = "safeguard-ps-user";
   secUserPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
   userEmail = "blah@test.com";

   # request workflow related users - note the hella-secure passwords
   # These will be created if they're not already present. All are expected
   # to use the idProvider specified above for authentication.
   requesterUserName = "requester";
   requesterPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
   approverUserName = "aprover";
   approverPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
   reviewerUserName = "reviewer";
   reviewerPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;

   # Other users used for specific purposes. Will be created if not already there.
   partitionOwnerUserName = 'partitionowner';
   renamedUsername = "fredflintstone";

   # real archive server information
   # This networkaddress will also be used in Network diagnostic tests
   ######Create the sub directory ps in /data/archives/archivist, then delete the subdirectory when you're done #####
   realArchiveServer = @{
      archSrvName = "ps.sg-archive";
      NetworkAddress = "sg-archive.sg.lab";
      TransferProtocol = "Scp";
      Port = "22";
      StoragePath = "/data/archives/archivist/ps";
      ServiceAccountCredentialType = "Password";
      ServiceAccountName = "archivist";
      ServiceAccountPassword = "!Deposit0r" | ConvertTo-SecureString -AsPlainText -Force;
   };

   # names of assets, accounts, and groups to be created and meddled with.
   # Asset and accounts are expected to be "real" and reachable during tests
   # as long as this one is up these psusers were made for this test.
   assetName = "ps.Asset_001";
   assetServiceAccount = "root";
   assetServiceAccountPassword = "test123" | ConvertTo-SecureString -AsPlainText -Force;
   assetIpAddress = "sg-ubuntu2004.sg.lab";
   assetPlatform = "Ubuntu 16.04 LTS x86_64";
   assetAccounts = @("psuser_1","psuser_2","psuser_3","psuser_4","psuser_5");
   userGroupName = "ps.UserGroup_001";
   assetGroupName = "ps.AssetGroup_001";
   accountGroupName = "ps.AccountGroup_001";
   dynamicAssetGroupRule = "([Name startswith 'ps'])";
   dynamicAccountGroupRule = "([AssetName startswith 'ps'] and ([Name contains '2'] or [Name contains '5']))";
   entitlementName = "ps.Entitlement"
   accessPolicy = "ps.TestPolicy"
   
   #license file to be used for license remove/install testing 7.0 version
   licenseFile = $SCRIPT_PATH + "\license-7-0.dlv";

   # This DNS must be in the list for X0 in order for certain functions to work.
   # If the default DNS is sufficient then either set that address here or set
   # this to an empty string
   requiredDNS = "10.9.6.64";

   # Domain information used for testing directory, identity provider, and certificates.
   domainName = "c.sg.lab";
   netBIOS = "CSG";
   domainAdmin = "admin-c-ps";
   domainPassword = "Test1234" | ConvertTo-SecureString -AsPlainText -Force;
   directoryAccounts = @("ps-user-c-1","ps-user-c-2","ps-user-c-3");

   # Certificate Signing Request stuff
   newCsrSubject = "CN=Bedrock,OU=Yabba,O=Dabba";
   newCsrDns = "bedrock.yabba.dabba.com";
   newCsrIpAddress = "1.2.3.4";
   newCsrOutputFile = "csr-output.csr";

   # when createLog is true the main harness will do a Start-Transcript to capture all output
   # Oldest Logs will be removed when maxLogs count is reached
   createLog = $false;
   logName = "$BASE_NAME_$("{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f (Get-Date)).log";
   maxLogs = 5;

   # Paths for command output
   # The directories will be created if not already there.
   outputPaths = @{
      backups = "$SCRIPT_PATH\backups";
      logs = "$SCRIPT_PATH\logs\";
      reports = "$SCRIPT_PATH\reports\";
      certificates = "$SCRIPT_PATH\certs\";
   }
   
   #BMC Data for a VM doesn't matter. If testing on hardware change this.
   appliancebmc = @{Ipv4Address="0.0.0.0"; Ipv4Gateway = "0.0.0.0"; Ipv4NetMask = "250.250.250.244"; Password="Junk"}
}

# For things that need to be created based on other hashtable members
$DATA += @{
   # Need this PSCred for accessing some domain-related calls
   domainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DATA.domainAdmin,$DATA.domainPassword;

   # G: is mapped to \\bldstor.prod.quest.corp\Safeguard
   # The patch test code will figure out if it's hardware or
   # VM and dig into the right subdirectory
   patchPathLTS = "G:\$($DATA.LTSVersion)\Patch\prod\";
   patchPathFeature = "G:\$($DATA.FeatureVersion)\Patch\prod\"; 

   # TODO still deciding on what to do with clustering...
   clusterPrimaryLTS = $DATA.applianceLTS;
   clusterReplicasLTS = @("10.9.4.223","10.9.4.224");
   #Hint ask Brad Nicholes for a good SPS if you don't have one
   #for the tests now you only need one.
   clusterSessionLTS = @("10.5.33.211","10.9.4.221");
   clusterPrimaryFeature = $DATA.applianceFeature;
   clusterReplicasFeature = @("10.9.4.228","10.9.4.229");
   #Hint ask Brad Nicholes for a good SPS if you don't have one
   #for the tests now you only need one.
   clusterSessionFeature = @("10.5.33.211","10.9.4.226");

   # Based on cmdline args will be set to either LTS or feature appliance values
   # These appliances are expected to accept the same uber-admin name and
   # password specified at the top of the file
   clusterPrimary = $DATA.appliance;
   clusterReplicas = @("10.9.4.223","10.9.4.224");
   clusterSession = @("10.9.4.220","10.9.4.221");
}
