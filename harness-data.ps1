#
# A single hash object with all the "global" data used by test scripts
#
# ############################################################################
# MAKE SURE ALL IP ADDRESSES, SYSTEM/ACCOUNT/USER NAMES AND PASSWORDS ARE
# UPDATED TO REFLECT YOUR ENVIRONMENT
#
# In general, all appliances are expected to be Prod variants. If Test variants
# are used some tests or files may need to be altered.
# ############################################################################
$SCRIPT_PATH = if($SCRIPT_PATH) {$SCRIPT_PATH} else {(Get-Location).Path}
if ($DATA) { Remove-Variable -Scope Global DATA }

$DATA = @{
   #addresses of LTS and Feature branch appliances
   applianceLTS = "10.9.4.222";
   applianceFeature = "10.9.4.222"

   # ip address of appliance to test.
   # Based on cmdline args this will be set to either LTS or feature appliance
   appliance = "10.9.4.222";

   # Version numbers to be used when looking for patch files
   LTSVersion = "8.0.0";
   FeatureVersion = "8.0.0";

   # uber-admin user with all admin permissions. The same user will be used
   # to run all commands unless otherwise noted.
   # This user must already exist on your SPP appliances.
   superUser = @{
      userName = "sgAdmin";
      secPassword = "Admin4SG" | ConvertTo-SecureString -AsPlainText -Force;
      idProvider = "local";
   }

   # admin user and password for any SPS appliances. Again, the same user
   # needs to be provisioned on all appliances.
   # This user must already exist on your SPS appliances.
   SPSAdmin = "admin";
   SPSAdminPassword = "Root4EDMZ" | ConvertTo-SecureString -AsPlainText -Force;

   # peon user who will be added and manipulated
   basicUser = @{
      userName = "safeguard-ps-user";
      secPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
      userEmail = "blah@test.com";
      idProvider = "local";
   }

   # request workflow related users - note the hella-secure passwords
   # These will be created if they're not already present. All are expected
   # to use the idProvider specified above for authentication.
   requestWorkflowUsers = @{
      Requester = @{ UserName = "requester"; FirstName = "Global"; LastName = "Requester"; IdProvider = "local"; SecPassword = "Password 4 requester" | ConvertTo-SecureString -AsPlainText -Force; };
      Approver =  @{ UserName = "approver";  FirstName = "Global"; LastName = "Approver";  IdProvider = "local"; SecPassword = "Password 4 approver" | ConvertTo-SecureString -AsPlainText -Force; };
      Reviewer =  @{ UserName = "reviewer";  FirstName = "Global"; LastName = "Reviewer";  IdProvider = "local"; SecPassword = "Password 4 reviewer" | ConvertTo-SecureString -AsPlainText -Force; };
   }

   # Other users used for specific purposes. Will be created if not already there.
   partitionOwnerUserName = 'partitionowner';
   renamedUsername = "fredflintstone";

   # real archive server information
   # This networkaddress will also be used in network-diagnostics, backups, filter-properties, etc.
   # Make sure to edit this to fit your environment.
   realArchiveServer = @{
      DisplayName = "ps.ArchSrv_001";
      NetworkAddress = "10.9.6.69";
      TransferProtocol = "Scp";
      Port = "22";
      StoragePath = "/home/sgarchive";
      ServiceAccountCredentialType = "Password";
      ServiceAccountName = "sgarchive";
      ServiceAccountPassword = "Root4()EDMZ" | ConvertTo-SecureString -AsPlainText -Force;
   };

   # names of assets, accounts, and groups to be created and meddled with.
   # Asset and accounts are expected to be "real" and reachable during tests.
   # Used to splat the parameters for creating a new asset, so if any properties
   # are added make sure they conform to expected parameters for New-SafegaurdAsset.
   asset = @{
      DisplayName = "ps.Asset_001";
      ServiceAccountName = "jeff";
      ServiceAccountPassword = "Root4EDMZ" | ConvertTo-SecureString -AsPlainText -Force;
      NetworkAddress = "10.9.6.69";
      Platform = "Ubuntu 20.04 x86_64";
      ServiceAccountCredentialType = "Password";
      AcceptSshHostKey = $true;
      PrivilegeElevationCommand = "sudo";
   };

   # Other information about assets and accounts and such
   assetAccounts = @("user_0001","user_0002","user_0003","user_0004","user_0005");
   userGroupName = "ps.UserGroup_001";
   assetGroupName = "ps.AssetGroup_001";
   accountGroupName = "ps.AccountGroup_001";
   dynamicAssetGroupRule = "([Name startswith 'ps'])";
   dynamicAccountGroupRule = "([AssetName startswith 'ps'] and ([Name contains '2'] or [Name contains '5']))";
   entitlementName = "ps.Entitlement"
   accessPolicyName = "ps.TestPolicy"

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
   newCsr = @{
      Subject = "CN=Bedrock,OU=Yabba,O=Dabba";
      Dns = "bedrock.yabba.dabba.com";
      IpAddress = "1.2.3.4";
      OutputFile = "csr-output.csr";
   }

   # when createLog is true the main harness will do a Start-Transcript to capture all output
   # Oldest Logs will be removed when maxLogs count is reached
   logName = "$($BASE_NAME)_$(getTimestamp 1).log";
   maxLogs = 5;

   # Default line limit when using GLOBALS.formatTable output function
   defaultFormatTableLineCount = 10;

   # Paths for command output
   # The directories will be created if not already there.
   filePaths = @{
      backups = "$SCRIPT_PATH\backups";
      logs = "$SCRIPT_PATH\logs\";
      reports = "$SCRIPT_PATH\reports\";
      certificates = "$SCRIPT_PATH\certs\";
      licenses = $SCRIPT_PATH + "\licenses";
      tests = $SCRIPT_PATH + "\cmdlet-tests";
      diagnostics = $SCRIPT_PATH + "\diagnostic-packages";
      imports = $SCRIPT_PATH + "\imports";
   };
}

# For things that need to be created based on other DATA hashtable members
$DATA += @{
   #license files to be used for license remove/install testing
   licenseFiles = @{
      v7 = $DATA.filePaths.licenses + "\license-123-456-000.dlv";
      v8 = $DATA.filePaths.licenses + "\v8 SPP-Enterprise-132-232-529.dlv";
      v8EnterpriseVault = $DATA.filePaths.licenses + "\v8 EnterpriseVault-Enterprise-132-232-541.dlv";
   }

   # Currently these appliance diagnostic packages only test Prod appliances.
   # If Test variant packages are added you can add them here and make allowances
   # in the diagnostic.ps1 script.
   diagnosticPackages = @{
      hardware = $DATA.filePaths.diagnostics + "\AutomationSuccess.sgd";
      vm = $DATA.filePaths.diagnostics + "\VmAutomationSuccess.sgd";
   }

   # Need this PSCred for accessing some domain-related calls
   domainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DATA.domainAdmin,$DATA.domainPassword;

   # G: is mapped to \\bldstor.prod.quest.corp\Safeguard
   # The patch test code will figure out if it's hardware or
   # VM and dig into the right subdirectory
   patchPathShare = "\\bldstor.prod.quest.corp\Safeguard"
   patchPathLTS = "G:\$($DATA.LTSVersion)\Patch\prod\";
   patchPathFeature = "G:\$($DATA.FeatureVersion)\Patch\prod\";

   # TODO still deciding on what to do with clustering for SPS...
   clusterPrimaryLTS = $DATA.applianceLTS;
   clusterReplicasLTS = @("10.9.4.223","10.9.4.224");
   clusterSessionLTS = @("10.9.4.220");
   clusterPrimaryFeature = $DATA.applianceFeature;
   clusterReplicasFeature = @("10.9.4.228","10.9.4.229");
   clusterSessionFeature = @("10.9.4.225");

   # Based on cmdline args will be set to either LTS or feature appliance values
   # These appliances are expected to accept the same uber-admin name and
   # password specified at the top of the file
   clusterPrimary = $DATA.appliance;
   clusterReplicas = @("10.9.4.223","10.9.4.224");
   clusterSession = @("10.9.4.220","10.9.4.221");
}

# the access policy strings are human-readable strings that will be used to create
# policy body strings in the DATA.accessPolicyBodyString object.
$local:baseAccessPolicyString = '{
     "Name": "#NAME#",
     "Description": "#NAME#",
     "RoleId": #ENTITLEMENT_ID#,
     "RolePriority": 1,
     "Priority": 1,
     "ApproverProperties": {
       "RequireApproval": false
     },
     "ReviewerProperties": {
       "RequiredReviewers": 0,
       "RequireReviewerComment": false,
       "PendingReviewEscalationEnabled": false
     },
     #ACCESS_REQUEST_PROPERTIES#
     #SESSION_PROPERTIES#
     "EmergencyAccessProperties": {
       "AllowEmergencyAccess": false,
       "IgnoreHourlyRestrictions": true
     },
     "ScopeItems": #SCOPE_ITEMS#,
     "ExpirationDate": null,
     "IsExpired": false,
     "InvalidConnectionPolicy": false
   }'
$local:passwordAccessPolicyString = $local:baseAccessPolicyString.replace('#ACCESS_REQUEST_PROPERTIES#', '
     "AccessRequestProperties": {
       "AccessRequestType": "Password",
       "AllowSimultaneousAccess": false,
       "MaximumSimultaneousReleases": 1,
       "ChangePasswordAfterCheckin": false,
       "AllowSessionPasswordRelease": false,
       "SessionAccessAccountType": "None",
       "SessionAccessAccounts": [],
       "TerminateExpiredSessions": false,
       "AllowLinkedAccountPasswordAccess": false
     },
').replace('#SESSION_PROPERTIES#', '')
$local:sshKeyAccessPolicyString = $local:passwordAccessPolicyString.replace('"AccessRequestType": "Password"', '"AccessRequestType": "SshKey"')
$local:sshAccessPolicyString = $local:baseAccessPolicyString.replace('#ACCESS_REQUEST_PROPERTIES#', '
     "AccessRequestProperties": {
       "AccessRequestType": "Ssh",
       "AllowSimultaneousAccess": false,
       "MaximumSimultaneousReleases": 1,
       "ChangePasswordAfterCheckin": false,
       "AllowSessionPasswordRelease": true,
       "AllowSessionSshKeyRelease": true,
       "SessionAccessAccountType": "None",
       "SessionAccessAccounts": [],
       "TerminateExpiredSessions": false,
       "AllowLinkedAccountPasswordAccess": false
     },
').replace('#SESSION_PROPERTIES#', '
     "SessionProperties": {
       "SessionModuleConnectionId": #CONNECTION_MODULE#,
       "SessionConnectionPolicyRef": "#CONNECTION_POLICY#"
     },
')
$local:rdpAccessPolicyString = $local:sshAccessPolicyString.replace('"AccessRequestType": "Ssh"', '"AccessRequestType": "RemoteDesktop"')

$DATA += @{
   # Used filter-properties tests to create a simple access policy to test
   accessPolicy = @{
      Name = "$($DATA.accessPolicyName)";
      Description = "Test Access Policy Description";
      RoleId = 0; # fill in when used
      Priority = 2;
      AccessRequestProperties = @{
        AccessRequestType = "Password";
        AllowSimultaneousAccess = $false;
        MaximumSimultaneousReleases = 1;
        ChangePasswordAfterCheckin = $true;
        AllowSessionPasswordRelease = $false;
        SessionAccessAccountType = "None";
        TerminateExpiredSessions = $false;
        AllowLinkedAccountPasswordAccess = $false
      };
      ApproverProperties = @{
        RequireApproval = $false;
      };
      # example - will get overwritten when used
      ScopeItems = @(
         @{
            ScopeItemType = "Account";
            Id = 0;
         }
      );
   }

   # used in Entitlements and Requests tests
   accessPolicyBodyString = @{
      Password = ($local:passwordAccessPolicyString -replace '[\r\n ]+', '').replace('#NAME#', 'Password Access Policy');
      SshKey = ($local:sshKeyAccessPolicyString -replace '[\r\n ]+', '').replace('#NAME#', 'SshKey Access Policy');
      SshSession = ($local:sshAccessPolicyString -replace '[\r\n ]+', '').replace('#NAME#', 'SshSession Access Policy');
      RdpSession = ($local:rdpAccessPolicyString -replace '[\r\n ]+', '').replace('#NAME#', 'RdpSession Access Policy');
   }
}

