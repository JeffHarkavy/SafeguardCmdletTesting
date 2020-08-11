# A single hash object with all the "global" data used by test scripts
$DATA = @{
   # ip address of appliance to test
   appliance = "10.9.4.227";

   # uber-admin user with all admin permissions
   userName = "sgAdmin";
   secPassword = "Admin4SG" | ConvertTo-SecureString -AsPlainText -Force;

   # login provider for the above ID
   idProvider = "local";

   # peon user who will be added and manipulated
   userUsername = "safeguard-ps-user";
   secUserPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
   userEmail = "blah@test.com";
   #thumb = "548d3218e6a03dff7602dcf5dd92ca25e56259a6";

   # Other users used for specific purposes. Will be created if not already there.
   partitionOwnerUserName = 'partitionowner';
   renamedUsername = "fredflintstone";

   # real archive server information
   # This networkaddress will also be used in Network diagnostic tests
   # Make sure to edit this to fit your environment - I don't guarantee this
   # server will be up all the time.
   realArchiveServer = @{
      NetworkAddress = "10.9.4.226";
      TransferProtocol = "Scp";
      Port = "22";
      StoragePath = "/home/sgarchive";
      ServiceAccountCredentialType = "Password";
      ServiceAccountName = "root";
      ServiceAccountPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
   };

   # names of assets, accounts, and groups to be created and meddled with
   assetName = "ps.Asset_001";
   assetAccountName = "ps.AssetAccount_001";
   userGroupName = "UserGroup_001";
   assetGroupName = "AssetGroup_001";
   accountGroupName = "AccountGroup_001";

   #license file to be used for license remove/install testing
   licenseFile = $SCRIPT_PATH + "\license-123-456-000.dlv";

   # This DNS must be in the list for X0 in order for certain functions to work
   # If the default DNS is sufficient then either set that address here or set
   # this to an empty string
   requiredDNS = "10.9.6.64";
   domainName = "jshdevvm.dell.com";
   netBIOS = "JSHDEVVM";
   domainAdmin = "administrator";
   domainPassword = "root4EDMZ" | ConvertTo-SecureString -AsPlainText -Force;
   directoryAccounts = @("User_001","User_002","User_003");
}

