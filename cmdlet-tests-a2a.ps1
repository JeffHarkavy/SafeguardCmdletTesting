try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
}
catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running A2A Tests"
$blockInfo = testBlockHeader $TestBlockName
# TODO - stubbed code
# Clear-SafeguardA2aAccessRequestBroker
# Clear-SafeguardA2aAccessRequestBrokerIpRestriction
# Clear-SafeguardA2aCredentialRetrievalIpRestriction
# Disable-SafeguardA2aService
# Edit-SafeguardA2a
# Get-SafeguardA2aPassword
# Get-SafeguardA2aPrivateKey
# Get-SafeguardA2aRetrievableAccount
# Get-SafeguardReportA2aEntitlement
# New-SafeguardA2aAccessRequest
# Remove-SafeguardA2aCredentialRetrieval
# Set-SafeguardA2aAccessRequestBrokerIpRestriction
# Set-SafeguardA2aCredentialRetrievalIpRestriction


#$a2aRequest = New-SafeguardA2aAccessRequest -Appliance $DATA.appliance -Thumbprint $thumb -ApiKey $api -ForUserName "Perm-User-0" -AssetToUse "PermAsset1" -AccessRequestType Password -AccountToUse "PermAccount1" #-Verbose
#$a2aRequestState = $a2aRequest.State
#Write-Host "Request state: $a2aRequestState"

# ===== Covered Commands =====
# Add-SafeguardA2aCredentialRetrieval
# Enable-SafeguardA2aService
# Get-SafeguardA2aServiceStatus
# Get-SafeguardA2a
# Get-SafeguardA2aAccessRequestBroker
# Get-SafeguardA2aAccessRequestBrokerApiKey
# Get-SafeguardA2aAccessRequestBrokerIpRestriction
# Get-SafeguardA2aCredentialRetrieval
# Get-SafeguardA2aCredentialRetrievalApiKey
# Get-SafeguardA2aCredentialRetrievalInformation
# Get-SafeguardA2aCredentialRetrievalIpRestriction
# New-SafeguardA2a
# Reset-SafeguardA2aAccessRequestBrokerApiKey
# Reset-SafeguardA2aCredentialRetrievalApiKey
# Set-SafeguardA2aAccessRequestBroker
# Remove-SafeguardA2a
#

writeCallHeader "A2A test Set up"
$newPolicyStr = '{
  "Name": "Linux Policy",
  "Description": "Linux Policy*",
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
  "AccessRequestProperties": {
    "AccessRequestType": "Ssh",
    "AllowSimultaneousAccess": false,
    "MaximumSimultaneousReleases": 1,
    "ChangePasswordAfterCheckin": false,
    "AllowSessionPasswordRelease": true,
    "SessionAccessAccountType": "None",
    "SessionAccessAccounts": [],
    "TerminateExpiredSessions": false,
    "AllowLinkedAccountPasswordAccess": false
  },
  "SessionProperties": {
    "SessionModuleConnectionId": #CONNECTION_MODULE#,
    "SessionConnectionPolicyRef": "#CONNECTION_POLICY#"
  },
  "EmergencyAccessProperties": {
    "AllowEmergencyAccess": false,
    "IgnoreHourlyRestrictions": true
  },
  "ScopeItems": [
    {
      "Id": #ACCOUNT_ID#,
      "ScopeItemType": "Account"
    }
  ],
  "ExpirationDate": null,
  "IsExpired": false,
  "InvalidConnectionPolicy": false
}'
$newPolicyBody = $newPolicyStr.Replace("`n", "").Replace("`r", "").Replace(" ", "")
$newWindowsPolicyStr = '{
  "Name": "Windows 2016 Policy",
  "Description": "Windows 2016 Policy*",
  "RoleId": #ENTITLEMENT_ID#,
  "RolePriority": 1,
  "Priority": 2,
  "ApproverProperties": {
    "RequireApproval": false
  },
  "ReviewerProperties": {
    "RequiredReviewers": 0,
    "RequireReviewerComment": false,
    "PendingReviewEscalationEnabled": false
  },
  "AccessRequestProperties": {
    "AccessRequestType": "RemoteDesktop",
    "AllowSimultaneousAccess": false,
    "MaximumSimultaneousReleases": 1,
    "ChangePasswordAfterCheckin": false,
    "AllowSessionPasswordRelease": true,
    "SessionAccessAccountType": "None",
    "SessionAccessAccounts": [],
    "TerminateExpiredSessions": false,
    "AllowLinkedAccountPasswordAccess": false
  },
  "SessionProperties": {
    "SessionModuleConnectionId": #CONNECTION_MODULE#,
    "SessionConnectionPolicyRef": "#CONNECTION_POLICY#"
  },
  "EmergencyAccessProperties": {
    "AllowEmergencyAccess": false,
    "IgnoreHourlyRestrictions": true
  },
  "ScopeItems": [
    {
      "Id": #ACCOUNT_ID#,
      "ScopeItemType": "Account"
    }
  ],
  "ExpirationDate": null,
  "IsExpired": false,
  "InvalidConnectionPolicy": false
}'
$newWindowsPolicyBody = $newWindowsPolicyStr.Replace("`n", "").Replace("`r", "").Replace(" ", "")
$newAccessRequestStr = '{"AccountId": #ACCOUNT_ID#,"AssetId": #ASSET_ID#,"AccessRequestType": "SSH"}'
$newAccessRequestBody = $newAccessRequestStr.Replace("`n", "").Replace("`r", "").Replace(" ", "")

# managedsystem = {'properties':{'PlatformId':547,'NetworkAddress':'sg-2019-ads.sg.lab','Name':'sg-2019-ads'},'fa':{'properties':{'Name':'sb-sa'},'password':'Test1234'},'ma':{'properties':{'Name':'sb-aa1'},'password':'Test1234'}}
# managedsystem = {'properties':{'PlatformId':270,'NetworkAddress':'sg-ubuntu1904.sg.lab','Name':'sg-ubuntu1904'},'fa':{'properties':{'Name':'root'},'password':'test123'},'ma':{'properties':{'Name':'sb-aa1'},'password':'Test1234'},'sshkey':'data/smoke_ssh_rsa','invalidsymbols':['\n', '\r']}

class Asset {
   [string]$NetworkAddress
   [int]$Platform
   [string]$Description
   [string]$DisplayName
   [string]$ServiceAccountCredentialType
   [string]$ServiceAccount
   [securestring]$ServiceAccountPassword
   [string]$AssetAccount
   [string]$AssetAccountDescription
   [securestring]$AssetPassword
   [int]$AssetId
   [int]$AccountId;
   
   Asset(
      [string]$NetworkAddress,
      [int]$Platform,
      [string]$Description,
      [string]$DisplayName,
      [string]$ServiceAccountCredentialType,
      [string]$ServiceAccount,
      [securestring]$ServiceAccountPassword,
      [string]$AssetAccount,
      [string]$AssetAccountDescription,
      [securestring]$AssetPassword) {
      $this.NetworkAddress = $NetworkAddress
      $this.Platform = $Platform
      $this.Description = $Description
      $this.DisplayName = $DisplayName
      $this.ServiceAccountCredentialType = $ServiceAccountCredentialType
      $this.ServiceAccount = $ServiceAccount
      $this.ServiceAccountPassword = $ServiceAccountPassword
      $this.AssetAccount = $AssetAccount
      $this.AssetAccountDescription = $AssetAccountDescription
      $this.AssetPassword = $AssetPassword
   }
}

$as400Password = "qcpass" | ConvertTo-SecureString -AsPlainText -Force
$tsoePassword = "TESTING" | ConvertTo-SecureString -AsPlainText -Force
$winpassword = "Test1234" | ConvertTo-SecureString -AsPlainText -Force
$linuxpassword = "test123" | ConvertTo-SecureString -AsPlainText -Force
$assetsToCreate = @([Asset]::new("sg-ubuntu1804.sg.lab", 261, "Linux Server*", "Linux Server", "Password", "root", $linuxpassword, "qa-aa1", "Testing Linux Account", $linuxpassword),
   [Asset]::new("sg-2019-ads.sg.lab", 547, "Windows Server 2019*", "Windows Server 2019", "Password", "sb-sa", $winpassword, "sb-aa1", "Testing Windows Account", $winpassword),
   [Asset]::new("10.10.180.8", 250, "IBM AS400*", "IBM AS400", $null, $null, $null, "QCINST", "AS400 Account", $as400Password),
   [Asset]::new("10.10.180.223", 96, "IBM TSOe*", "IBM TSOe", $null, $null, $null, "SAFETU4", "IBM TSOe Account", $tsoePassword))

function Cleanup {
   $allAssets = Get-SafeguardAsset
   if ($null -ne $allAssets) {
      foreach ($asset in $allAssets) {
         try {
            Remove-SafeguardAsset $asset.Id > $null
         }
         catch {
            Write-Host "Failed to remove " $asset.Name
            Write-Host $_.Exception
         }
      }
   }
   Remove-SafeguardUser -UserToDelete $userUsername > $null
   Remove-SafeguardUser -UserToDelete $certUserName > $null

   $allPolicies = Get-SafeguardAccessPolicy
   if ($null -ne $allPolicies) {
      foreach ($policy in $allPolicies) {
         $url = 'AccessPolicies/' + $policy.Id
         Invoke-SafeguardMethod -Method Delete -RelativeUrl $url -Service Core  > $null
      }
   }
   $allEntitlements = Get-SafeguardEntitlement
   if ($null -ne $allEntitlements) {
      foreach ($entitlement in $allEntitlements) {
         Remove-SafeguardEntitlement -EntitlementToDelete $entitlement.Id > $null
      }
   }
   $allA2ARegistrations = Get-SafeguardA2A
   if ($null -ne $allA2ARegistrations) {
      foreach ($registration in $allA2ARegistrations) {
         Remove-SafeguardA2A $registration.Id > $null
      }
   }
   $allRequests = Get-SafeguardAccessRequest
   if ($null -ne $allRequests) {
      foreach ($request in $allRequests) {
         if ($request.State -eq "RequestAvailable") {
            Edit-SafeguardAccessRequest $request.Id Cancel -ErrorAction SilentlyContinue > $null
         }
         if ($request.State -eq "SessionInitialized") {
            Edit-SafeguardAccessRequest $request.Id CheckIn -ErrorAction SilentlyContinue > $null
         }
      }
   }
}

function FindAssetAccount($index) {
   $accounts = Find-SafeguardAssetAccount $assetsToCreate[$index].AssetAccountDescription
   if ($null -eq $accounts) {
      Write-Host "Failed to find the account " $assetsToCreate[$index].AssetAccountDescription
      return
   }

   return $accounts[0]
}

$ready = $true

try {
   # Create-User
   #region Users
   
   New-SafeguardUser -NewUserName "Testing" -FirstName "Test" -LastName "ing" -NoPassword -Provider -1 > $null
   $secPassword = "root4EDMZ" | ConvertTo-SecureString -AsPlainText -Force
   Set-SafeguardUserPassword -Password $secPassword -UserToEdit "Testing" > $null
   Edit-SafeguardUser -UserToEdit "Testing" -EmailAddress "blah@test.com" > $null
   $userUsername = Get-SafeguardUser -UserToGet "Testing"
   #endregion

   # Create-CertificateUser
   #region Users 
   New-SafeguardUser -NewUserName "cert-safeguard-ps-user" -FirstName "safeguard" -LastName "ps-user" -NoPassword -Provider -2 -Thumbprint "2349a0311c312f6dff57875fd2b2a112b8e2c644" > $null
   $certUserName = Get-SafeguardUser -UserToGet "cert-safeguard-ps-user"
   #endregion

   # Create-AssetAccount
   Write-Host "Create Assets and Accounts"
   foreach ($asset in $assetsToCreate) {
      if ([string]::IsNullOrEmpty($asset.ServiceAccountCredentialType)) {
         $newAsset = New-SafeguardAsset -NetworkAddress $asset.NetworkAddress -Platform $asset.Platform -Description $asset.Description -DisplayName $asset.DisplayName -ServiceAccountCredentialType None -AcceptSshHostKey
      }
      else {
         $newAsset = New-SafeguardAsset -NetworkAddress $asset.NetworkAddress -Platform $asset.Platform -Description $asset.Description -DisplayName $asset.DisplayName -ServiceAccountCredentialType $asset.ServiceAccountCredentialType -ServiceAccountName $asset.ServiceAccount -ServiceAccountPassword $secPassword -AcceptSshHostKey
      }
      $asset.AssetId = $newAsset.Id
      $newAccount = New-SafeguardAssetAccount -NewAccountName $asset.AssetAccount -ParentAsset $newAsset.Id -Description $asset.AssetAccountDescription
      $asset.AccountId = $newAccount.Id
      Set-SafeguardAssetAccountPassword -AccountToSet $newAccount.Id -NewPassword $asset.AssetPassword > $null
   }
   #endregion

   #Add SPS
   Write-Host "Get-SafeguardSessionCluster"
   if ((Get-SafeguardSessionCluster).Count -eq 0) {
      infoResult "Get-SafeguardSessionCluster" "No session appliances exist in this cluster."
      infoResult "Joining" "Attempting to join to SPS appliance $($DATA.clusterSession[0])"
      Join-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] -SessionUserName $DATA.SPSAdmin -SessionPassword $DATA.SPSAdminPassword > $null
   }

   # Create-EntitlementPolicy
   Write-Host "Create-EntitlementPolicy"
   #region Entitlement/Policy
   $user = Get-SafeguardUser -UserToGet $DATA.userName
   $newEntitlement = New-SafeguardEntitlement "Entitlements" $user.Id
   $allSessionModules = Invoke-SafeguardMethod Core GET Cluster/SessionModules
   $url = 'Cluster/SessionModules/' + ($allSessionModules[0].Id) + '/ConnectionPolicies'
   $connectionPolicy = Invoke-SafeguardMethod Core GET $url -Parameters @{ protocol = "Ssh"; filter = "Name eq 'safeguard_default'" }
   $accounts = Find-SafeguardAssetAccount $assetsToCreate[0].AssetAccountDescription
   $convertedJson = ConvertFrom-Json $newPolicyBody.Replace("#ENTITLEMENT_ID#", $newEntitlement.Id).Replace("#CONNECTION_MODULE#", $connectionPolicy.SessionModuleConnectionId).Replace("#CONNECTION_POLICY#", $connectionPolicy.Id).Replace("#ACCOUNT_ID#", $accounts[0].Id)
   Invoke-SafeguardMethod Core Post AccessPolicies -Body $convertedJson > $null
   $connectionPolicy = Invoke-SafeguardMethod Core GET $url -Parameters @{ protocol = "Rdp"; filter = "Name eq 'safeguard_rdp'" }
   $accounts = Find-SafeguardAssetAccount $assetsToCreate[1].AssetAccountDescription
   $convertedJson = ConvertFrom-Json $newWindowsPolicyBody.Replace("#ENTITLEMENT_ID#", $newEntitlement.Id).Replace("#CONNECTION_MODULE#", $connectionPolicy.SessionModuleConnectionId).Replace("#CONNECTION_POLICY#", $connectionPolicy.Id).Replace("#ACCOUNT_ID#", $accounts[0].Id)
   Invoke-SafeguardMethod Core Post AccessPolicies -Body $convertedJson > $null
   #endregion

   # Create-AccessRequest
   Write-Host "Create-AccessRequest"
   #region AccessRequest
   $selectedAccount = FindAssetAccount(0)
   $selectedAsset = Get-SafeguardAsset -AssetToGet $selectedAccount.Asset.Id
   
   Write-Host "Create-AccessRequest 2"
   $selectedAccount = Get-SafeguardAssetAccount -AccountToGet $selectedAccount.Id
   
   Write-Host "Create-AccessRequest 3"
   $convertedJson = ConvertFrom-Json $newAccessRequestBody.Replace("#ACCOUNT_ID#", $selectedAccount.Id).Replace("#ASSET_ID#", $selectedAsset.Id)
   
   Write-Host "Create-AccessRequest 4"
   $newAccessRequest = Invoke-SafeguardMethod Core Post AccessRequests -Body $convertedJson
   
   Write-Host "Create-AccessRequest 5"
   Get-SafeguardAccessRequest -RequestId $newAccessRequest.Id > $null
   
   Write-Host "Create-AccessRequest 6"
   Edit-SafeguardAccessRequest $newAccessRequest.Id InitializeSession  > $null
   
   Write-Host "Create-AccessRequest 7"
   Get-SafeguardAccessRequestPassword -RequestId $newAccessRequest.Id > $null
   
   Write-Host "Create-AccessRequest 8"
   $updatedAccessRequest = Get-SafeguardAccessRequest -RequestId $newAccessRequest.Id
   if ($updatedAccessRequest.State -eq "RequestAvailable") {
      Edit-SafeguardAccessRequest $updatedAccessRequest.Id Cancel -ErrorAction SilentlyContinue > $null
   }
   elseif ($updatedAccessRequest.State -eq "SessionInitialized") {
      Edit-SafeguardAccessRequest $updatedAccessRequest.Id CheckIn -ErrorAction SilentlyContinue > $null
   }
   #endregion
   Write-Host "Finished Setup"
}
catch {
   badResult "A2A general" "Failed in A2A test setup" $_
   $ready =$false
   Cleanup
}


if($ready){
   try {
      writeCallHeader "Testing A2A Cmndlets"
      # Create-A2ARegistration
      #region A2ARegistration
      $certUser = Get-SafeguardUser $certUserName
      $newA2ARegistration = New-SafeguardA2a -CertificateUser $certUser.Id -Name MyA2aApp
      goodResult "New-SafeguardA2a" "Success"
      Get-SafeguardA2A -A2aToGet $newA2ARegistration.Id  > $null
      goodResult "Get-SafeguardA2a" "Success"
      Set-SafeguardA2aAccessRequestBroker -ParentA2a $newA2ARegistration.Id -Users $userUsername > $null
      goodResult "Set-SafeguardA2aAccessRequestBroker" "Success"
      $compareRequestBroker = Get-SafeguardA2aAccessRequestBroker -ParentA2a $newA2ARegistration.Id
      goodResult "Get-SafeguardA2aAccessRequestBroker" "Success"
      if ($null -ne $compareRequestBroker) {
         Get-SafeguardA2aAccessRequestBrokerApiKey -ParentA2a $newA2ARegistration.Id > $null
         goodResult "Get-SafeguardA2aAccessRequestBrokerApiKey" "Success"
         Reset-SafeguardA2aAccessRequestBrokerApiKey -ParentA2a $newA2ARegistration.Id > $null
         goodResult "Reset-SafeguardA2aAccessRequestBrokerApiKey" "Success"
      }
      else {
         Write-Host "Failed to get new A2A access request broker "
         badResult "Get-SafeguardA2aAccessRequestBroker" "Couldn't find" $newA2ARegistration
      }
      $selectedAccount = FindAssetAccount(0)
      Add-SafeguardA2aCredentialRetrieval -ParentA2a $newA2ARegistration.Id -Account $selectedAccount.Id > $null
      goodResult "Add-SafeguardA2aCredentialRetrieval" "Success"
      $compareCredentialRetrieval = Get-SafeguardA2aCredentialRetrieval -ParentA2a $newA2ARegistration.Id
      goodResult "Get-SafeguardA2aCredentialRetrieval" "Success"
      if ($null -ne $compareCredentialRetrieval) {
         Get-SafeguardA2aCredentialRetrievalInformation -AccountName $cr.AccountName > $null
         goodResult "Get-SafeguardA2aCredentialRetrievalInformation" "Success"
         foreach ($cr in $compareCredentialRetrieval) {
            Get-SafeguardA2aCredentialRetrievalApiKey -ParentA2a $newA2ARegistration.Id -Account $cr.AccountName > $null
            goodResult "Get-SafeguardA2aCredentialRetrievalApiKey" "Success"
            Reset-SafeguardA2aCredentialRetrievalApiKey -ParentA2a $newA2ARegistration.Id -Account $cr.AccountName > $null
            goodResult "Reset-SafeguardA2aCredentialRetrievalApiKey" "Success"
         }
      }
      else {
         Write-Host "Failed to get the new A2A credential retrieval "
         badResult "Get-SafeguardA2aCredentialRetrieval" "Couldn't find" $newA2ARegistration
      }
      Enable-SafeguardA2aService > $null
      goodResult "Enable-SafeguardA2aService" "Success"
      #endregion
      Get-SafeguardA2aServiceStatus > $null
      goodResult "Get-SafeguardA2aServiceStatus" "Success"

      # PerformGetCommands
      $a2aRegistrations = Get-SafeguardA2a
      goodResult "Get-SafeguardA2a" "Success"
      if ($null -ne $a2aRegistrations) {
         $a2aRegistration = Get-SafeguardA2a -A2aToGet $a2aRegistrations[0].Id
         goodResult "Get-SafeguardA2a" "Success"
         Get-SafeguardA2aAccessRequestBroker -ParentA2a $a2aRegistration.Id > $null
         goodResult "Get-SafeguardA2aAccessRequestBroker" "Success"
         Get-SafeguardA2aAccessRequestBrokerApiKey -ParentA2a $a2aRegistration.Id > $null
         goodResult "Get-SafeguardA2aAccessRequestBrokerApiKey" "Success"
         Get-SafeguardA2aAccessRequestBrokerIpRestriction -ParentA2a $a2aRegistration.Id > $null
         goodResult "Get-SafeguardA2aAccessRequestBrokerIpRestriction" "Success"
         $a2aRetrieval = Get-SafeguardA2aCredentialRetrieval -ParentA2a $a2aRegistration.Id
         goodResult "Get-SafeguardA2aCredentialRetrieval" "Success"
         if ($null -ne $a2aRetrieval) {
            Get-SafeguardA2aCredentialRetrievalApiKey -ParentA2a $a2aRegistration.Id -Account $a2aRetrieval[0].AccountId > $null
            goodResult "Get-SafeguardA2aCredentialRetrievalApiKey" "Success"
            $a2aInfo = Get-SafeguardA2aCredentialRetrievalInformation
            goodResult "Get-SafeguardA2aCredentialRetrievalInformation" "Success"
            if ($null -ne $a2aInfo) {
               Get-SafeguardA2aCredentialRetrievalInformation -AccountName $a2aInfo[0].AccountName > $null
               goodResult "Get-SafeguardA2aCredentialRetrievalInformation" "Success"
            }
            Get-SafeguardA2aCredentialRetrievalIpRestriction -ParentA2a $a2aRegistration.Id -Account $a2aRetrieval[0].AccountId > $null
            goodResult "Get-SafeguardA2aCredentialRetrievalIpRestriction" "Success"
         }
      }
   }
   catch {
      badResult "A2A general" "Unexpected error in A2A test" $_
   } 
   finally {
      Cleanup
   }
}

testBlockHeader $TestBlockName $blockInfo





##### This code is from Brad Nicholes from his Testing####
# $appliance = "10.5.34.62"
# $idProvider = "local"
# $userName = "bnicholes"
# $password = "root4EDMZ"
# $secPassword = $password | ConvertTo-SecureString -AsPlainText -Force
# $userPassword = "Test1234"
# $secUserPassword = $userPassword | ConvertTo-SecureString -AsPlainText -Force
# $userUsername = "0safeguard-ps-user"
# $userEmail = "blah@test.com"
# $certUserName = "a2acertuser"
# $thumb = "2349a0311c312f6dff57875fd2b2a112b8e2c633"

# $newPolicyStr = '{
#   "Name": "Linux Policy",
#   "Description": "Linux Policy*",
#   "RoleId": #ENTITLEMENT_ID#,
#   "RolePriority": 1,
#   "Priority": 1,
#   "ApproverProperties": {
#     "RequireApproval": false
#   },
#   "ReviewerProperties": {
#     "RequiredReviewers": 0,
#     "RequireReviewerComment": false,
#     "PendingReviewEscalationEnabled": false
#   },
#   "AccessRequestProperties": {
#     "AccessRequestType": "Ssh",
#     "AllowSimultaneousAccess": false,
#     "MaximumSimultaneousReleases": 1,
#     "ChangePasswordAfterCheckin": false,
#     "AllowSessionPasswordRelease": true,
#     "SessionAccessAccountType": "None",
#     "SessionAccessAccounts": [],
#     "TerminateExpiredSessions": false,
#     "AllowLinkedAccountPasswordAccess": false
#   },
#   "SessionProperties": {
#     "SessionModuleConnectionId": #CONNECTION_MODULE#,
#     "SessionConnectionPolicyRef": "#CONNECTION_POLICY#"
#   },
#   "EmergencyAccessProperties": {
#     "AllowEmergencyAccess": false,
#     "IgnoreHourlyRestrictions": true
#   },
#   "ScopeItems": [
#     {
#       "Id": #ACCOUNT_ID#,
#       "ScopeItemType": "Account"
#     }
#   ],
#   "ExpirationDate": null,
#   "IsExpired": false,
#   "InvalidConnectionPolicy": false
# }'
# $newPolicyBody = $newPolicyStr.Replace("`n","").Replace("`r","").Replace(" ","")
# $newWindowsPolicyStr = '{
#   "Name": "Windows 2016 Policy",
#   "Description": "Windows 2016 Policy*",
#   "RoleId": #ENTITLEMENT_ID#,
#   "RolePriority": 1,
#   "Priority": 2,
#   "ApproverProperties": {
#     "RequireApproval": false
#   },
#   "ReviewerProperties": {
#     "RequiredReviewers": 0,
#     "RequireReviewerComment": false,
#     "PendingReviewEscalationEnabled": false
#   },
#   "AccessRequestProperties": {
#     "AccessRequestType": "RemoteDesktop",
#     "AllowSimultaneousAccess": false,
#     "MaximumSimultaneousReleases": 1,
#     "ChangePasswordAfterCheckin": false,
#     "AllowSessionPasswordRelease": true,
#     "SessionAccessAccountType": "None",
#     "SessionAccessAccounts": [],
#     "TerminateExpiredSessions": false,
#     "AllowLinkedAccountPasswordAccess": false
#   },
#   "SessionProperties": {
#     "SessionModuleConnectionId": #CONNECTION_MODULE#,
#     "SessionConnectionPolicyRef": "#CONNECTION_POLICY#"
#   },
#   "EmergencyAccessProperties": {
#     "AllowEmergencyAccess": false,
#     "IgnoreHourlyRestrictions": true
#   },
#   "ScopeItems": [
#     {
#       "Id": #ACCOUNT_ID#,
#       "ScopeItemType": "Account"
#     }
#   ],
#   "ExpirationDate": null,
#   "IsExpired": false,
#   "InvalidConnectionPolicy": false
# }'
# $newWindowsPolicyBody = $newWindowsPolicyStr.Replace("`n","").Replace("`r","").Replace(" ","")
# $newAccessRequestStr = '{
#   "AccountId": #ACCOUNT_ID#,
#   "SystemId": #ASSET_ID#,
#   "AccessRequestType": "SSH"
# }'
# $newAccessRequestBody = $newAccessRequestStr.Replace("`n","").Replace("`r","").Replace(" ","")

# class Asset {
#     [string]$NetworkAddress
#     [int]$Platform
#     [string]$Description
#     [string]$DisplayName
#     [string]$ServiceAccountCredentialType
#     [string]$ServiceAccount
#     [securestring]$ServiceAccountPassword
#     [string]$AssetAccount
#     [string]$AssetAccountDescription
#     [securestring]$AssetPassword
#     [int]$AssetId
#     [int]$AccountId;

#     Asset(
#     [string]$NetworkAddress,
#     [int]$Platform,
#     [string]$Description,
#     [string]$DisplayName,
#     [string]$ServiceAccountCredentialType,
#     [string]$ServiceAccount,
#     [securestring]$ServiceAccountPassword,
#     [string]$AssetAccount,
#     [string]$AssetAccountDescription,
#     [securestring]$AssetPassword)
#     {
#         $this.NetworkAddress = $NetworkAddress
#         $this.Platform = $Platform
#         $this.Description = $Description
#         $this.DisplayName = $DisplayName
#         $this.ServiceAccountCredentialType = $ServiceAccountCredentialType
#         $this.ServiceAccount = $ServiceAccount
#         $this.ServiceAccountPassword = $ServiceAccountPassword
#         $this.AssetAccount = $AssetAccount
#         $this.AssetAccountDescription = $AssetAccountDescription
#         $this.AssetPassword = $AssetPassword
#     }
# }



# function Create-User {

#     #region Users

#     $newUserName = Read-Host "User Name"
#     $newUserFirstName = Read-Host "First Name"
#     $newUserLastName = Read-Host "Last Name"

#     New-SafeguardUser -NewUserName $newUserName -FirstName $newUserFirstName -LastName $newUserLastName -NoPassword -Provider -1 > $null

#     $newuserPassword = Read-Host "Password" -AsSecureString
#     Set-SafeguardUserPassword -Password $newuserPassword -UserToEdit $newUserName

#     $newUserEmail = Read-Host "Email Address"
#     Edit-SafeguardUser -UserToEdit $newUserName -EmailAddress $newUserEmail > $null

#     $newUser = Get-SafeguardUser -UserToGet $newUserName
#     Write-Host "Created new user " $newUser.UserName

#     #endregion
# }

# function Create-CertificateUser {

#     #region Users

#     $newUserName = Read-Host "User Name"
#     $newUserFirstName = Read-Host "First Name"
#     $newUserLastName = Read-Host "Last Name"
#     $newUserThumbprint = Read-Host "Thumbprint"

#     New-SafeguardUser -NewUserName $newUserName -FirstName $newUserFirstName -LastName $newUserLastName -NoPassword -Provider -2 -Thumbprint $newUserThumbprint > $null

#     $newUser = Get-SafeguardUser -UserToGet $newUserName
#     Write-Host "Created new user " $newUser

#     #endregion
# }

# $assetAccount = "pluto"
# $as400Password = "qcpass" | ConvertTo-SecureString -AsPlainText -Force
# $tsoePassword = "TESTING" | ConvertTo-SecureString -AsPlainText -Force
# $assetsToCreate = 
# @([Asset]::new("bnichvm1.sg.lab", 68, "Linux Server*", "Linux Server", "Password", "servadmin", $secPassword, $assetAccount, "Pluto Linux Account", $secPassword),
#     [Asset]::new("10.5.33.210", 197, "Windows Server 2016*", "Windows Server 2016", "Password", "servadmin", $secPassword, $assetAccount, "Pluto Windows Account", $secPassword),
#     [Asset]::new("bnichvm1.sg.lab", 68, "Linux Telnet*", "Linux Telnet", "Password", "servadmin", $secPassword, $assetAccount, "Pluto Telnet Account", $secPassword),
#     [Asset]::new("10.10.180.8", 250, "IBM AS400*", "IBM AS400", $null, $null, $null, "QCINST", "AS400 Account", $as400Password),
#     [Asset]::new("10.10.180.223", 96, "IBM TSOe*", "IBM TSOe", $null, $null, $null, "SAFETU4", "IBM TSOe Account", $tsoePassword))

# function Clear-AllAsset {

#     $allAssets = Get-SafeguardAsset
#     if ($allAssets -ne $null) {
#         foreach ($asset in $allAssets) {
#             try {
#                 Remove-SafeguardAsset $asset.Id
#                 Write-Host "Removed asset " + $asset.Name
#             } catch {
#                 Write-Host "Failed to remove " $asset.Name
#                 Write-Host $_.Exception
#             }
#         }
#     }
# }

# function Create-DefaultAssetAccounts {

#     #region Asset/Account

#     foreach ($asset in $assetsToCreate) {
#         if ([string]::IsNullOrEmpty($asset.ServiceAccountCredentialType)) {
#             $newAsset = New-SafeguardAsset -NetworkAddress $asset.NetworkAddress -Platform $asset.Platform -Description $asset.Description -DisplayName $asset.DisplayName -ServiceAccountCredentialType None -AcceptSshHostKey
#         }
#         else {
#             $newAsset = New-SafeguardAsset -NetworkAddress $asset.NetworkAddress -Platform $asset.Platform -Description $asset.Description -DisplayName $asset.DisplayName -ServiceAccountCredentialType $asset.ServiceAccountCredentialType -ServiceAccountName $asset.ServiceAccount -ServiceAccountPassword $secPassword -AcceptSshHostKey
#         }
#         $asset.AssetId = $newAsset.Id
#         $newAccount = New-SafeguardAssetAccount -NewAccountName $asset.AssetAccount -ParentAsset $newAsset.Id -Description $asset.AssetAccountDescription
#         $asset.AccountId = $newAccount.Id
#         Set-SafeguardAssetAccountPassword -AccountToSet $newAccount.Id -NewPassword $asset.AssetPassword
#     }
    
#     try {
#         $compareAsset = Get-SafeguardAsset -AssetToGet $assetsToCreate[0].AssetId
#         if ($compareAsset -ne $null) {
#             Write-Output "Found the new asset " $newAsset
#         } else {
#             Write-Host "Failed to get the asset " $assetsToCreate[0].AssetId - $assetsToCreate[0].DisplayName
#         }
    
#         $compareAsset = Find-SafeguardAsset $assetsToCreate[0].DisplayName
#         if ($compareAsset -ne $null) {
#             Write-Output "Found the new asset " $asset
#         } else {
#             Write-Host "Failed to find the asset " $assetsToCreate[0].AssetId - $assetsToCreate[0].DisplayName
#         }

#         $compareAccount = Get-SafeguardAssetAccount -AccountToGet $assetsToCreate[0].AccountId
#         if ($compareAccount -ne $null) {
#             Write-Output "Found the new account " $newAccount
#         } else {
#             Write-Host "Failed to get the account " $assetsToCreate[0].AccountId - $assetsToCreate[0].AssetAccount
#         }

#         $compareAccount = Find-SafeguardAssetAccount $assetsToCreate[0].AssetAccount
#         if ($compareAccount -ne $null) {
#             Write-Output "Found the new account " $assetsToCreate[0].AssetAccount
#         } else {
#             Write-Host "Failed to find the account " $assetsToCreate[0].AccountId - $assetsToCreate[0].AssetAccount
#         }

#     }
#     catch {
#         Write-Host $_.Exception
#         Write-Host $_.ScriptStackTrace
#     }
#     #endregion
# }

# function Create-AssetAccount {

#     #region Asset/Account

#     #[string]$NetworkAddress
#     #[int]$Platform
#     #[string]$Description
#     #[string]$DisplayName
#     #[string]$ServiceAccountCredentialType
#     #[string]$ServiceAccount
#     #[securestring]$ServiceAccountPassword
#     #[string]$AssetAccount
#     #[string]$AssetAccountDescription
#     #[securestring]$AssetPassword
#     #[int]$AssetId
#     #[int]$AccountId;

#     $assetObject = [Asset]::new("bnichvm1.sg.lab", 68, "Linux Server*", "Linux Server", "Password", "servadmin", $secPassword, $assetAccount, "Pluto Linux Account", $secPassword)

#     $assetObject.NetworkAddress = Read-Host "Network Address[ex. $($assetObject.NetworkAddress)]"
#     $assetObject.Platform = Read-Host "Platform[ex. $($assetObject.Platform)]"
#     $assetObject.Description = Read-Host "Description[ex. $($assetObject.Description)]"
#     $assetObject.DisplayName = Read-Host "Display Name[ex. $($assetObject.DisplayName)]"
#     $assetObject.ServiceAccountCredentialType = Read-Host "Service Account Credential Type[ex. $($assetObject.ServiceAccountCredentialType)]"
#     $assetObject.ServiceAccount = Read-Host "Service Account Name[ex. $($assetObject.ServiceAccount)]"
#     $assetObject.ServiceAccountPassword = Read-Host "Service Account Password[ex. $($assetObject.ServiceAccountPassword)]" -AsSecureString

#     try {
#         if ([string]::IsNullOrEmpty($assetObject.ServiceAccountCredentialType)) {
#             $newAsset = New-SafeguardAsset -NetworkAddress $assetObject.NetworkAddress -Platform $assetObject.Platform -Description $assetObject.Description -DisplayName $assetObject.DisplayName -ServiceAccountCredentialType None -AcceptSshHostKey
#         }
#         else {
#             $newAsset = New-SafeguardAsset -NetworkAddress $assetObject.NetworkAddress -Platform $assetObject.Platform -Description $assetObject.Description -DisplayName $assetObject.DisplayName -ServiceAccountCredentialType $assetObject.ServiceAccountCredentialType -ServiceAccountName $assetObject.ServiceAccount -ServiceAccountPassword $assetObject.ServiceAccountPassword -AcceptSshHostKey
#         }

#         $assetObject.AssetAccount = Read-Host "Asset Account Name"
#         $assetObject.AssetAccountDescription = Read-Host "Asset Account Description"
#         $assetObject.AssetPassword = Read-Host "Asset Account Password" -AsSecureString

#         $newAccount = New-SafeguardAssetAccount -NewAccountName $assetObject.AssetAccount -ParentAsset $newAsset.Id -Description $assetObject.AssetAccountDescription
#         Set-SafeguardAssetAccountPassword -AccountToSet $newAccount.Id -NewPassword $assetObject.AssetPassword
#     }
#     catch {
#         Write-Host $_.Exception
#         Write-Host $_.ScriptStackTrace
#         return
#     }
    
#     try {
#         $compareAsset = Get-SafeguardAsset -AssetToGet $newAsset.Id
#         if ($compareAsset -ne $null) {
#             Write-Output "Found the new asset by id " $compareAsset
#         } else {
#             Write-Host "Failed to get the asset by id " $newAsset.Id - $newAsset.Name
#         }
    
#         $compareAsset = Find-SafeguardAsset $newAsset.Name
#         if ($compareAsset -ne $null) {
#             Write-Output "Found asset(s) by name" $compareAsset
#         } else {
#             Write-Host "Failed to find any asset(s) by name" $newAsset.Name
#         }

#         $compareAccount = Get-SafeguardAssetAccount -AccountToGet $newAccount.Id
#         if ($compareAccount -ne $null) {
#             Write-Output "Found the new account by id " $compareAccount
#         } else {
#             Write-Host "Failed to get the account by id " $newAccount.Id - $newAccount.Name
#         }

#         $compareAccount = Find-SafeguardAssetAccount $newAsset.Name
#         if ($compareAccount -ne $null) {
#             Write-Host "Found account(s) by name " $compareAccount
#         } else {
#             Write-Host "Failed to find any account(s) by name " $newAsset.Name
#         }

#     }
#     catch {
#         Write-Host $_.Exception
#         Write-Host $_.ScriptStackTrace
#     }
#     #endregion
# }

# function Create-EntitlementPolicy {

#     #region Entitlement/Policy
#     $allPolicies = Get-SafeguardAccessPolicy
#     if ($allPolicies -ne $null) {
#         Write-Host "Removing all access policies"
#         foreach ($policy in $allPolicies) {
#             $url = 'AccessPolicies/'+$policy.Id
#             Invoke-SafeguardMethod -Method Delete -RelativeUrl $url -Service Core
#             #Invoke-SafeguardMethod Core Delete $url -Debug -Verbose
#             Write-Host "Removed policy " $policy.Name
#         }
#     }

#     $allEntitlements = Get-SafeguardEntitlement
#     if ($allEntitlements -ne $null) {
#         Write-Host "Removing all entitlements"
#         foreach ($entitlement in $allEntitlements) {
#             Remove-SafeguardEntitlement -EntitlementToDelete $entitlement.Id
#             Write-Host "Removed entitlement " $entitlement.Name
#         }
#     }

#     try {
#         $user = Get-SafeguardUser -UserToGet $userName
#         $newEntitlement = New-SafeguardEntitlement "Entitlements" $user.Id
#         $compareEntitlement = Get-SafeguardEntitlement -EntitlementToGet $newEntitlement.Id
#         if ($compareEntitlement -ne $null) {
#             Write-Host "Found the new entitlement " $compareEntitlement
#         } else {
#             Write-Host "Failed to get the entitlement " $compareEntitlement.Id - $newEntitlement.Name
#         }
    
#         $allSessionModules = Invoke-SafeguardMethod Core GET Cluster/SessionModules
#         $url = 'Cluster/SessionModules/'+($allSessionModules[0].Id)+'/ConnectionPolicies'
#         $connectionPolicy = Invoke-SafeguardMethod Core GET $url -Parameters @{ protocol = "Ssh"; filter = "Name eq 'safeguard_default'" }

#         $accounts = Find-SafeguardAssetAccount $assetsToCreate[0].AssetAccountDescription
#         if ($accounts -eq $null) {
#             Write-Host "Failed to find the account " $assetsToCreate[0].AssetAccountDescription
#             return
#         }

#         $convertedJson = ConvertFrom-Json $newPolicyBody.Replace("#ENTITLEMENT_ID#", $newEntitlement.Id).Replace("#CONNECTION_MODULE#", $connectionPolicy.SessionModuleConnectionId).Replace("#CONNECTION_POLICY#", $connectionPolicy.Id).Replace("#ACCOUNT_ID#", $accounts[0].Id)
#         $newPolicy = Invoke-SafeguardMethod Core Post AccessPolicies -Body $convertedJson
#         $comparePolicy = Get-SafeguardAccessPolicy -PolicyToGet $newPolicy.Id
#         if ($comparePolicy -ne $null) {
#             Write-Host "Found the new policy " $newPolicy
#         } else {
#             Write-Host "Failed to get the policy " $newPolicy.Id - $newPolicy.Name
#         }

#         $connectionPolicy = Invoke-SafeguardMethod Core GET $url -Parameters @{ protocol = "Rdp"; filter = "Name eq 'safeguard_rdp'" }
#         $accounts = Find-SafeguardAssetAccount $assetsToCreate[1].AssetAccountDescription
#         if ($accounts -eq $null) {
#             Write-Host "Failed to find the account " $assetsToCreate[1].AssetAccountDescription
#             return
#         }

#         $convertedJson = ConvertFrom-Json $newWindowsPolicyBody.Replace("#ENTITLEMENT_ID#", $newEntitlement.Id).Replace("#CONNECTION_MODULE#", $connectionPolicy.SessionModuleConnectionId).Replace("#CONNECTION_POLICY#", $connectionPolicy.Id).Replace("#ACCOUNT_ID#", $accounts[0].Id)
#         $newPolicy = Invoke-SafeguardMethod Core Post AccessPolicies -Body $convertedJson
#         $comparePolicy = Get-SafeguardAccessPolicy -PolicyToGet $newPolicy.Id
#         if ($comparePolicy -ne $null) {
#             Write-Host "Found the new policy " $newPolicy
#         } else {
#             Write-Host "Failed to get the policy " $newPolicy.Id - $newPolicy.Name
#         }

#     }
#     catch {
#         Write-Host $_.Exception
#         Write-Host $_.ScriptStackTrace
#     }
#     #endregion
# }

# function Create-AccessRequest {

#     #region AccessRequest

#     $allRequests = Get-SafeguardAccessRequest
#     if ($allRequests -ne $null) {
#         Write-Host "Removing all access requests"
#         foreach ($request in $allRequests) {
#             if ($request.State -eq "RequestAvailable") {
#                 Edit-SafeguardAccessRequest $request.Id Cancel -ErrorAction SilentlyContinue
#                 Write-Host "Cancel request " $request.AssetName " " $request.AccessRequestType
#             }
                
#             if ($request.State -eq "SessionInitialized") {
#                 Edit-SafeguardAccessRequest $request.Id CheckIn -ErrorAction SilentlyContinue
#                 Write-Host "CheckIn request " $request.AssetName " " $request.AccessRequestType
#             }

#         }
#     }

#     $selectedAccount = FindAssetAccount(0)

#     $selectedAsset = Get-SafeguardAsset -AssetToGet $selectedAccount.AssetId
#     $selectedAccount = Get-SafeguardAssetAccount -AccountToGet $selectedAccount.Id

#     try {
#         #$newAccessRequest = New-SafeguardAccessRequest -AccessRequestType SSH -AssetToUse $selectedAsset.Id -AccountToUse $selectedAccount.Id -Debug -Verbose
#         #$newAccessRequest = New-SafeguardAccessRequest $selectedAccount.AssetName $selectedAccount.Name SSH -Debug -Verbose

#         $convertedJson = ConvertFrom-Json $newAccessRequestBody.Replace("#ACCOUNT_ID#", $selectedAccount.Id).Replace("#ASSET_ID#", $selectedAsset.Id)
#         $newAccessRequest = Invoke-SafeguardMethod Core Post AccessRequests -Body $convertedJson

#         $compareAccessRequest = Get-SafeguardAccessRequest -RequestId $newAccessRequest.Id
#         if ($compareAccessRequest -ne $null) {
#             Write-Host "Found the new access request " $compareAccessRequest
#         } else {
#             Write-Host "Failed to get the access request " $compareAccessRequest.Id
#         }


#         $initializedAccessRequest = Edit-SafeguardAccessRequest $newAccessRequest.Id InitializeSession
#         $accessRequestPassword = Get-SafeguardAccessRequestPassword -RequestId $newAccessRequest.Id

#         $updatedAccessRequest = Get-SafeguardAccessRequest -RequestId $newAccessRequest.Id

#         if ($accessRequestPassword -ne $null) {
#             Write-Host "Got the password for the access request " $updatedAccessRequest
#         } else {
#             Write-Host "Failed to get the password for the access request " $updatedAccessRequest.Id
#         }

#         if ($updatedAccessRequest.State -eq "RequestAvailable") {
#             Edit-SafeguardAccessRequest $updatedAccessRequest.Id Cancel -ErrorAction SilentlyContinue
#         } elseif ($updatedAccessRequest.State -eq "SessionInitialized") {
#             Edit-SafeguardAccessRequest $updatedAccessRequest.Id CheckIn -ErrorAction SilentlyContinue
#         }
#     }
#     catch {
#         Write-Host $_.Exception
#         Write-Host $_.ScriptStackTrace
#     }
#     #endregion
# }

# function Create-A2ARegistration {

#     #region A2ARegistration
#     $allA2ARegistrations = Get-SafeguardA2A
#     if ($allA2ARegistrations -ne $null) {
#         Write-Host "Removing all A2A registrations"
#         foreach ($registration in $allA2ARegistrations) {
#             Remove-SafeguardA2A $registration.Id
#             Write-Host "Removed registration " + $registration.AppName
#         }
#     }

#     $variable = Read-Host "Certificate User Name[$certUserName]: "
#     if (![string]::IsNullOrEmpty($variable)) {
#         $certUserName = $variable
#     }
#     $variable = Read-Host "Broker User Name[$userUsername]: "
#     if (![string]::IsNullOrEmpty($variable)) {
#         $userUsername = $variable
#     }


#     $certUser = Get-SafeguardUser $certUserName
#     $otherUser = Get-SafeguardUser $userUsername

#     try {
#         $newA2ARegistration = New-SafeguardA2a -CertificateUser $certUser.Id -Name MyA2aApp
#         $compareA2ARegistration = Get-SafeguardA2A -A2aToGet $newA2ARegistration.Id
#         if ($compareA2ARegistration -ne $null) {
#             Write-Host "Found the new A2A registration " $compareA2ARegistration.AppName
#         } else {
#             Write-Host "Failed to get the A2A registration " $newA2ARegistration.Id - $newA2ARegistration.AppName
#         }
    
#         $newRequestBroker = Set-SafeguardA2aAccessRequestBroker -ParentA2a $newA2ARegistration.Id -Users $userUsername
#         $compareRequestBroker = Get-SafeguardA2aAccessRequestBroker -ParentA2a $newA2ARegistration.Id
#         if ($compareRequestBroker -ne $null) {
#             $apiKey = Get-SafeguardA2aAccessRequestBrokerApiKey -ParentA2a $newA2ARegistration.Id
#             Write-Host "Found the new A2A access request broker and API key " $apiKey
#             $apiKey = Reset-SafeguardA2aAccessRequestBrokerApiKey -ParentA2a $newA2ARegistration.Id
#             Write-Host "Reset the API key " $apiKey
#         } else {
#             Write-Host "Failed to get new A2A access request broker "
#         }

#         $selectedAccount = FindAssetAccount(0)
#         $newCredentialRetrieval = Add-SafeguardA2aCredentialRetrieval -ParentA2a $newA2ARegistration.Id -Account $selectedAccount.Id
#         $compareCredentialRetrieval = Get-SafeguardA2aCredentialRetrieval -ParentA2a $newA2ARegistration.Id
#         if ($compareCredentialRetrieval -ne $null) {
#             Write-Host "Found the new A2A credential retrieval " (Get-SafeguardA2aCredentialRetrievalInformation -AccountName $cr.AccountName)
#             foreach ($cr in $compareCredentialRetrieval) {
#                 $apiKey = Get-SafeguardA2aCredentialRetrievalApiKey -ParentA2a $newA2ARegistration.Id -Account $cr.AccountName
#                 Write-Host "Credential retrieval API key " $apiKey
#                 $apiKey = Reset-SafeguardA2aCredentialRetrievalApiKey -ParentA2a $newA2ARegistration.Id -Account $cr.AccountName
#                 Write-Host "Reset the credential retrieval API key " $apiKey
#             }
#         } else {
#             Write-Host "Failed to get the new A2A credential retrieval "
#         }

#         Enable-SafeguardA2aService
#     }
#     catch {
#         Write-Host $_.Exception
#         Write-Host $_.ScriptStackTrace
#     }
#     #endregion
# }

# function PerformGetCommands {

#     if ((Get-SafeguardA2aServiceStatus) -eq $false) {
#         Enable-SafeguardA2aService
#     }

#     Write-host "Get-SafeguardMyRequestable:"
#     Get-SafeguardMyRequestable | Write-Output

#     Write-host "Get-SafeguardVersion:"
#     Get-SafeguardVersion | Write-Output

#     Write-host "Get-SafeguardStatus:"
#     Get-SafeguardStatus | Write-Output

#     Write-host "Get-SafeguardHealth:"
#     Get-SafeguardHealth | Write-Output

#     Write-host "Get-SafeguardTime:"
#     Get-SafeguardTime | Write-Output

#     Write-host "Get-SafeguardTimeZone:"
#     Get-SafeguardTimeZone | Write-Output

#     Write-host "Get-SafeguardTransferProtocol:"
#     Get-SafeguardTransferProtocol | Write-Output

#     Write-host "Get-SafeguardApplianceAvailability:"
#     Get-SafeguardApplianceAvailability | Write-Output

#     Write-host "Get-SafeguardApplianceName:"
#     Get-SafeguardApplianceName | Write-Output

#     Write-host "Get-SafeguardApplianceState:"
#     Get-SafeguardApplianceState | Write-Output

#     Write-host "Get-SafeguardApplianceUptime:"
#     Get-SafeguardApplianceUptime | Write-Output

#     Write-host "Get-SafeguardApplianceVerification:"
#     Get-SafeguardApplianceVerification | Write-Output

#     Write-host "Get-SafeguardBmcConfiguration:"
#     Get-SafeguardBmcConfiguration | Write-Output

#     Write-host "Get-SafeguardClusterHealth:"
#     Get-SafeguardClusterHealth | Write-Output

#     Write-host "Get-SafeguardClusterMember:"
#     Get-SafeguardClusterMember | Write-Output

#     Write-host "Get-SafeguardClusterOperationStatus:"
#     Get-SafeguardClusterOperationStatus | Write-Output

#     Write-host "Get-SafeguardClusterPlatformTaskLoadStatus:"
#     Get-SafeguardClusterPlatformTaskLoadStatus | Write-Output

#     Write-host "Get-SafeguardClusterPlatformTaskQueueStatus:"
#     Get-SafeguardClusterPlatformTaskQueueStatus | Write-Output

#     Write-host "Get-SafeguardClusterPrimary:"
#     Get-SafeguardClusterPrimary | Write-Output

#     Write-host "Get-SafeguardClusterSummary:"
#     Get-SafeguardClusterSummary | Write-Output

#     Write-host "Get-SafeguardPlatform:"
#     Get-SafeguardPlatform | Write-Output

#     Write-host "Get-SafeguardLicense:"
#     Get-SafeguardLicense | Write-Output

#     Write-host "Get-SafeguardA2a:"
#     $a2aRegistrations = Get-SafeguardA2a
#     Write-Output $a2aRegistrations

#     if ($a2aRegistrations -ne $null) {

#         try {
#             $a2aRegistration = Get-SafeguardA2a -A2aToGet $a2aRegistrations[0].Id

#             Write-host "Get-SafeguardA2aAcessRequestBroker:"
#             Get-SafeguardA2aAccessRequestBroker -ParentA2a $a2aRegistration.Id | Write-Output

#             Write-host "Get-SafeguardA2aAcessRequestBrokerApiKey:"
#             Get-SafeguardA2aAccessRequestBrokerApiKey -ParentA2a $a2aRegistration.Id | Write-Output

#             Write-host "Get-SafeguardA2aAcessRequestBrokerIpRestriction:"
#             Get-SafeguardA2aAccessRequestBrokerIpRestriction -ParentA2a $a2aRegistration.Id | Write-Output

#             Write-host "Get-SafeguardA2aCredentialRetrieval:"
#             ($a2aRetrieval = Get-SafeguardA2aCredentialRetrieval -ParentA2a $a2aRegistration.Id) | Write-Output

#             if ($a2aRetrieval -ne $null) {
#                 Write-host "Get-SafeguardA2aCredentialRetrievalApiKey:"
#                 Get-SafeguardA2aCredentialRetrievalApiKey -ParentA2a $a2aRegistration.Id -Account $a2aRetrieval[0].AccountId | Write-Output

#                 Write-host "Get-SafeguardA2aCredentialRetrievalInformation:"
#                 ($a2aInfo = Get-SafeguardA2aCredentialRetrievalInformation) | Write-Output

#                 if ($a2aInfo -ne $null) {
#                     Write-host "Get-SafeguardA2aCredentialRetrievalInformation:"
#                     Get-SafeguardA2aCredentialRetrievalInformation -AccountName $a2aInfo[0].AccountName | Write-Output
#                 }

#                 Write-host "Get-SafeguardA2aCredentialRetrievalIpRestriction:"
#                 Get-SafeguardA2aCredentialRetrievalIpRestriction -ParentA2a $a2aRegistration.Id -Account $a2aRetrieval[0].AccountId | Write-Output
#             }


#         } catch {
# 	        Write-Host $_.Exception
# 	        Write-Host $_.ScriptStackTrace
#         }
#     }

#     Write-host "Get-SafeguardAccessPolicy:"
#     ($accessPolicies = Get-SafeguardAccessPolicy) | Write-Output


#     if ($accessPolicies -ne $null) {
#         try {
#             $accessPolicy = Get-SafeguardAccessPolicy -PolicyToGet $accessPolicies[0].Id

#             Write-host "Get-SafeguardAccessPolicyAccessRequestProperty:"
#             (Get-SafeguardAccessPolicyAccessRequestProperty -PolicyToGet $accessPolicy.Id) | Write-Output

#             Write-host "Get-SafeguardAccessPolicyScopeItem:"
#             (Get-SafeguardAccessPolicyScopeItem -PolicyToGet $accessPolicy.Id) | Write-Output

#             Write-host "Get-SafeguardAccessPolicySessionProperty:"
#             (Get-SafeguardAccessPolicySessionProperty -PolicyToGet $accessPolicy.Id) | Write-Output

#         } catch {
# 	        Write-Host $_.Exception
# 	        Write-Host $_.ScriptStackTrace
#         }
#     }

#     Write-host "Get-SafeguardAccessPolicy:"
#     ($assets = Get-SafeguardAsset) | Write-Output


#     if ($assets -ne $null) {
#         try {
#             $asset = Get-SafeguardAsset -AssetToGet $assets[0].Id

#             Write-host "Get-SafeguardAssetAccount:"
#             (Get-SafeguardAssetAccount -AssetToGet $asset.Id) | Write-Output

#         } catch {
# 	        Write-Host $_.Exception
# 	        Write-Host $_.ScriptStackTrace
#         }

#     }

#     Write-host "Get-SafeguardUser:"
#     ($users = Get-SafeguardUser) | Write-Output


#     if ($users -ne $null) {
#         try {
#             $user = Get-SafeguardUser -UserToGet $users[0].Id

#             Write-host "Get-SafeguardUserLinkedAccount:"
#             (Get-SafeguardUserLinkedAccount -UserToGet $user.Id) | Write-Output

#         } catch {
# 	        Write-Host $_.Exception
# 	        Write-Host $_.ScriptStackTrace
#         }

#     }

#     Write-host "Get-SafeguardEntitlement:"
#     ($entitlements = Get-SafeguardEntitlement) | Write-Output


#     if ($entitlements -ne $null) {
#         try {
#             $entitlement = Get-SafeguardEntitlement -EntitlementToGet $entitlements[0].Id

#         } catch {
# 	        Write-Host $_.Exception
# 	        Write-Host $_.ScriptStackTrace
#         }

#     }

# }

# function InitializeVariables {
#     $variable = Read-Host "SPP Appliance[$appliance]: "
#     if (![string]::IsNullOrEmpty($variable)) {
#         $appliance = $variable
#     }

#     $variable = Read-Host "SPP Appliance[$idProvider]: "
#     if (![string]::IsNullOrEmpty($variable)) {
#         $idProvider = $variable
#     }

#     $variable = Read-Host "User Name[$userName]: "
#     if (![string]::IsNullOrEmpty($variable)) {
#         $userName = $variable
#     }

#     $variable = Read-Host "Password: " -AsSecureString
#     if (![string]::IsNullOrEmpty($variable)) {
#         $secPassword = $variable
#     }

#     Connect-Safeguard -Insecure -Appliance $appliance -IdentityProvider $idProvider -Password $secPassword -Username $userName
# }

# function FindAssetAccount($index) {
#     $accounts = Find-SafeguardAssetAccount $assetsToCreate[$index].AssetAccountDescription
#     if ($accounts -eq $null) {
#         Write-Host "Failed to find the account " $assetsToCreate[$index].AssetAccountDescription
#         return
#     }

#     return $accounts[0]
# }


# function GetMenuSelection {
#     Write-Host ""
#     Write-Host "1: Set Login Data"
#     Write-Host "2: Create User"
#     Write-Host "3: Create Certificate User"
#     Write-Host "4: Create Asset Account"
#     Write-Host "5: Create Default Asset Accounts"
#     Write-Host "6: Create Entitlement Policy"
#     Write-Host "7: Create Access Request"
#     Write-Host "8: Create A2A Registration"
#     Write-Host "15: Clear All Asset Accounts"
#     Write-Host "20: Perform Get Commands"
#     Write-Host "q: Quit"

#     $selection = Read-Host "Please make a selection"
#     return $selection
# }

# try {
#     InitializeVariables

#     do {
#         $selection = GetMenuSelection
        
#         switch ($selection) {
#             '1' {
#                 InitializeVariables
#                 }
#             '2' {
#                 Create-User
#                 }
#             '3' {
#                 Create-CertificateUser
#                 }
#             '4' {
#                 Create-AssetAccount
#                 }
#             '5' {
#                 Create-DefaultAssetAccounts
#                 }
#             '6' {
#                 Create-EntitlementPolicy
#                 }
#             '7' {
#                 Create-AccessRequest
#                 }
#             '8' {
#                 Create-A2ARegistration
#                 }


#             '15' {
#                  Clear-AllAsset
#                  }

#             '20' {
#                  PerformGetCommands
#                  }

#         }
#     } until ($selection -eq 'q')
# }
# catch {
# 	Write-Host $_.Exception
# 	Write-Host $_.ScriptStackTrace
# }
# finally {
#     #Remove-SafeguardUser -UserToDelete $userUsername > $null
#     #Remove-SafeguardUser -UserToDelete $certUsername > $null
#     Disconnect-Safeguard
# }