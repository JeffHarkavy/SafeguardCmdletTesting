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
   applianceLTS = "10.9.4.222";
   applianceFeature = "10.9.4.227"

   # ip address of appliance to test.
   # Based on cmdline args this will be set to either LTS or feature appliance
   appliance = "10.9.4.222";

   # Version numbers to be used when looking for patch files
   LTSVersion = "6.0.7";
   FeatureVersion = "6.7.0";

   # uber-admin user with all admin permissions. The same user will be used
   # to run all commands unless otherwise noted.
   userName = "sgAdmin";
   secPassword = "Admin4SG" | ConvertTo-SecureString -AsPlainText -Force;

   # login provider for the above 
   idProvider = "local";

   # admin user and password for any SPS appliances. Again, the same user
   # needs to be provisioned on all appliances.
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
   # Make sure to edit this to fit your environment - this is one of my
   # linux boxes and I don't guarantee it will be up all the time.
   realArchiveServer = @{
      archSrvName = "ps.ArchSrv_001";
      NetworkAddress = "10.9.6.69";
      TransferProtocol = "Scp";
      Port = "22";
      StoragePath = "/home/sgarchive";
      ServiceAccountCredentialType = "Password";
      ServiceAccountName = "root";
      ServiceAccountPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
   };

   # names of assets, accounts, and groups to be created and meddled with.
   # Asset and accounts are expected to be "real" and reachable during tests
   assetName = "ps.Asset_001";
   assetServiceAccount = "root";
   assetServiceAccountPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
   assetIpAddress = "10.9.6.69";
   assetPlatform = "Ubuntu 16.04 LTS x86_64";
   assetAccounts = @("user_0001","user_0002","user_0003","user_0004","user_0005");
   userGroupName = "ps.UserGroup_001";
   assetGroupName = "ps.AssetGroup_001";
   accountGroupName = "ps.AccountGroup_001";
   dynamicAssetGroupRule = "([Name startswith 'ps'])";
   dynamicAccountGroupRule = "([AssetName startswith 'ps'] and ([Name contains '2'] or [Name contains '5']))";
   entitlementName = "ps.Entitlement"
   accessPolicy = "ps.TestPolicy"
   
   #license file to be used for license remove/install testing
   licenseFile = $SCRIPT_PATH + "\license-123-456-000.dlv";

   # This DNS must be in the list for X0 in order for certain functions to work.
   # If the default DNS is sufficient then either set that address here or set
   # this to an empty string
   requiredDNS = "10.9.6.64";

   # Domain information used for testing directory, identity provider, and certificates.
   domainName = "jshdevvm.dell.com";
   netBIOS = "JSHDEVVM";
   domainAdmin = "administrator";
   domainPassword = "root4EDMZ" | ConvertTo-SecureString -AsPlainText -Force;
   directoryAccounts = @("User_001","User_002","User_003");

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
   clusterSessionLTS = @("10.9.4.220","10.9.4.221");
   clusterPrimaryFeature = $DATA.applianceFeature;
   clusterReplicasFeature = @("10.9.4.228","10.9.4.229");
   clusterSessionFeature = @("10.9.4.225","10.9.4.226");

   # Based on cmdline args will be set to either LTS or feature appliance values
   # These appliances are expected to accept the same uber-admin name and
   # password specified at the top of the file
   clusterPrimary = $DATA.appliance;
   clusterReplicas = @("10.9.4.223","10.9.4.224");
   clusterSession = @("10.9.4.220","10.9.4.221");
}
