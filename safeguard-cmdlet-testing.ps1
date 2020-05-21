# Gather any parameters into a single array
param([Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)][string[]] $allParameters)

$SCRIPT_PATH = (Split-Path $myInvocation.MyCommand.Path)
$collectedErrors = [System.Collections.ArrayList]@()

# ip address of appliance to test
$appliance = "10.9.4.227"

# uber-admin user with all admin permissions
$userName = "sgAdmin"
$secPassword = "Admin4SG" | ConvertTo-SecureString -AsPlainText -Force

# login provider for the above ID
$idProvider = "local"

# peon user who will be added and manipulated
$userUsername = "safeguard-ps-user"
$secUserPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force
$userEmail = "blah@test.com"
#$thumb = "548d3218e6a03dff7602dcf5dd92ca25e56259a6"

# Other users used for specific purposes. Will be created if not already there.
$partitionOwnerUserName = 'partitionowner'
$renamedUsername = "fredflintstone"

# real archive server information
# This networkaddress will also be used in Network diagnostic tests
# Make sure to edit this to fit your environment - I don't guarantee this
# server will be up all the time.
$realArchiveServer = @{
   NetworkAddress = "10.9.4.226";
   TransferProtocol = "Scp";
   Port = "22";
   StoragePath = "/home/sgarchive";
   ServiceAccountCredentialType = "Password";
   ServiceAccountName = "root";
   ServiceAccountPassword = "Password1" | ConvertTo-SecureString -AsPlainText -Force;
}

# names of assets, accounts, and groups to be created and meddled with
$assetName = "ps.Asset_001"
$assetAccountName = "ps.AssetAccount_001"
$userGroupName = "UserGroup_001"
$assetGroupName = "AssetGroup_001"
$accountGroupName = "AccountGroup_001"

#license file to be used for license remove/install testing
$licenseFile = $SCRIPT_PATH + "\license-123-456-000.dlv"

# flags to run / not run a given block of tests
# add to this and create cmdlet-tests files as functionality gets added
$Tests = @{
   CheckHelp =             @{Seq=1;  runTest = "N"; fileName = "cmdlet-tests-help.ps1";};
   NoParameter =           @{Seq=2;  runTest = "Y"; fileName = "cmdlet-tests-noparameter.ps1";};
   Users =                 @{Seq=3;  runTest = "N"; fileName = "cmdlet-tests-users.ps1";};
   Groups =                @{Seq=4;  runTest = "N"; fileName = "cmdlet-tests-groups.ps1";};
   AssetsAndAccounts =     @{Seq=5;  runTest = "N"; fileName = "cmdlet-tests-assets-and-accounts.ps1";};
   AccountPasswordRules =  @{Seq=6;  runTest = "N"; fileName = "cmdlet-tests-account-password-rules.ps1";};
   CheckChangeSchedules =  @{Seq=7;  runTest = "N"; fileName = "cmdlet-tests-check-change-schedules.ps1";};
   AssetPartition =        @{Seq=8;  runTest = "N"; fileName = "cmdlet-tests-asset-partition.ps1";};
   PasswordProfile =       @{Seq=9;  runTest = "N"; fileName = "cmdlet-tests-password-profile.ps1";};
   NetworkDiagnostics =    @{Seq=10; runTest = "N"; fileName = "cmdlet-tests-network-diagnostics.ps1";};
   NewSchedules =          @{Seq=11; runTest = "N"; fileName = "cmdlet-tests-new-schedules.ps1";};
   EventSubscriptions =    @{Seq=12; runTest = "N"; fileName = "cmdlet-tests-event-subscriptions.ps1";};
   Backups =               @{Seq=13; runTest = "N"; fileName = "cmdlet-tests-backups.ps1";};
   Miscellaneous =         @{Seq=14; runTest = "N"; fileName = "cmdlet-tests-miscellaneous.ps1";};
   ObsoleteCommands =      @{Seq=15; runTest = "N"; fileName = "cmdlet-tests-obsolete-commands.ps1";};
}

# count of how many good/bad/info calls for summary at the end
$resultCounts = @{
   Good = 0;
   Bad = 0;
   Info = 0;
}
function writeCallHeader($cmd) {
   write-host "`n--------------------------------------------------"
   foreach ($l in $cmd.Split([Environment]::NewLine)) {
      write-host "-- $l"
   }
   write-host "--------------------------------------------------"
}
function goodResult($cmd, $str) {
   Write-Host "$($cmd) : $($str)" -ForegroundColor Green
   $resultCounts.Good++
}
function infoResult($cmd, $str) {
   Write-Host "$($cmd) : $($str)" -ForegroundColor Yellow
   $resultCounts.Info++
}
function badResult($cmd, $str, $exception) {
   $exMsg = ""
   if ($null -ne $exception) {
      $exMsg = " - $($exception.Message)"
   }
   $outputLine = "$($cmd) : $($str)$($exMsg)"
   Write-Host $outputLine  -ForegroundColor Red
   $collectedErrors.Add($outputLine) > $null
   $resultCounts.Bad++
}
function showHelp {
   Write-Host "
--- Running Selected or All tests ---
  Invoke with no arguments or the single argument all to run all commands.
  Invoke with a space-delimited list of test names to run individual tests.
  Valid test names are: "
  $Tests.keys | foreach-object {'      {0}' -f $_}  
  exit
}

if ($allParameters -contains "help" -or $allParameters -contains "?") {
   showHelp
} elseif ($allParameters.Length -eq 0 -or $allParameters -contains "all") {
   foreach ($t in $Tests.GetEnumerator()) {
      $t.Value.runTest = "Y"
   }
} else {
   foreach ($t in $Tests.GetEnumerator()) {
      $t.Value.runTest = "N"
   }
   foreach ($p in $allParameters) {
      if ($Tests.Keys -contains $p) {
         $Tests[$p].runTest = "Y"
      } else {
         Write-Host "$p is not a recognized test name" -ForegroundColor Red -BackgroundColor Black
         $quit = $true
      }
   }
   if ($quit) { 
      showHelp
   }
}

write-host "Running the following tests"
foreach ($t in ($Tests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})) {
   write-host "   $($t.Key)"
}
pause

try {
   Connect-Safeguard -Appliance $appliance -IdentityProvider $idProvider -Password $secPassword -Username $userName -Insecure
   goodResult "Connect-Safeguard" "Success"

   writeCallHeader "Get-SafeguardVersion"
   goodResult "Get-SafeguardVersion" "Success"
   $sgVersion = Get-SafeguardVersion
   $sgVersion | format-table
   $isVm = $sgVersion.BuildPlatform -match "hyperv" -or $sgVersion.BuildPlatform -match "vmware"
   $thisIsLTS = $sgVersion.Minor -eq "0"

   writeCallHeader "Test-SafeguardVersion - min 6.0"
   Test-SafeguardVersion -MinVersion 6.0
   goodResult "Test-SafeguardVersion" "Success"
 
   foreach ($t in ($Tests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})) {
      . "$SCRIPT_PATH\$($t.Value.fileName)"
   }

   #region Directory
   # TODO - stubbed code
   #Edit-SafeguardDirectory
   #Edit-SafeguardDirectoryAccount
   #Edit-SafeguardDirectoryIdentityProvider
   #Find-SafeguardDirectoryAccount
   #Get-SafeguardDirectory
   #Get-SafeguardDirectoryAccount
   #Get-SafeguardDirectoryIdentityProvider
   #Get-SafeguardDirectoryIdentityProviderDomain
   #Get-SafeguardDirectoryIdentityProviderSchemaMapping
   #Get-SafeguardDirectoryMigrationData
   #Invoke-SafeguardDirectoryAccountPasswordChange
   #New-SafeguardDirectory
   #New-SafeguardDirectoryAccount
   #New-SafeguardDirectoryAccountRandomPassword
   #New-SafeguardDirectoryIdentityProvider
   #Remove-SafeguardDirectory
   #Remove-SafeguardDirectoryAccount
   #Remove-SafeguardDirectoryIdentityProvider
   #Set-SafeguardDirectoryAccountPassword
   #Set-SafeguardDirectoryIdentityProviderSchemaMapping
   #Sync-SafeguardDirectory
   #Sync-SafeguardDirectoryAsset
   #Sync-SafeguardDirectoryIdentityProvider
   #Test-SafeguardDirectory
   #Test-SafeguardDirectoryAccountPassword
   #endregion

   #region User Linked Accounts
   # TODO - stubbed code
   #   try {
   #Add-SafeguardUserLinkedAccount
   #Get-SafeguardUserLinkedAccount
   #Remove-SafeguardUserLinkedAccount
   #
   #Add-SafeguardUserLinkedAccount -UserToSet $userUsername -AccountToAdd "ui-nightly-d-ad" -DirectoryToAdd "d.sg.lab" > $null
   #$userLinkedAccounts = Get-SafeguardUserLinkedAccount -UserToGet $userUsername
   #foreach ($userLinkedAccount in $userLinkedAccounts) {Write-Host $userLinkedAccount.Name -ForegroundColor Green}
   #Remove-SafeguardUserLinkedAccount -UserToSet $userUsername -AccountToRemove "ui-nightly-d-ad" -DirectoryToRemove "d.sg.lab" > $null
   #$userLinkedAccounts = Get-SafeguardUserLinkedAccount -UserToGet $userUsername
   #foreach ($userLinkedAccount in $userLinkedAccounts) {Write-Host $userLinkedAccount.Name -ForegroundColor Yellow}    
   #endregion

   #region Entitlement
   # TODO - stubbed code
   #Get-SafeguardAccessCertificationEntitlement
   #Get-SafeguardEntitlement
   #New-SafeguardEntitlement
   #Remove-SafeguardEntitlement
   #
   #$entitlement = Get-SafeguardEntitlement -EntitlementToGet "Entitlement"
   #$policy = Get-SafeguardAccessPolicy -PolicyToGet "EntitlementPolicy" -EntitlementToGet "Entitlement"
   #if ($null -eq $entitlement -or $null -eq $policy) {badResult "Couldn't get entitlement stuff",$null
   #endregion

   #region A2A
   # TODO - stubbed code
   #Add-SafeguardA2aCredentialRetrieval
   #Clear-SafeguardA2aAccessRequestBroker
   #Clear-SafeguardA2aAccessRequestBrokerIpRestriction
   #Clear-SafeguardA2aCredentialRetrievalIpRestriction
   #Edit-SafeguardA2a
   #Get-SafeguardA2a
   #Get-SafeguardA2aAccessRequestBroker
   #Get-SafeguardA2aAccessRequestBrokerApiKey
   #Get-SafeguardA2aAccessRequestBrokerIpRestriction
   #Get-SafeguardA2aCredentialRetrieval
   #Get-SafeguardA2aCredentialRetrievalApiKey
   #Get-SafeguardA2aCredentialRetrievalInformation
   #Get-SafeguardA2aCredentialRetrievalIpRestriction
   #Get-SafeguardA2aPassword
   #Get-SafeguardA2aPrivateKey
   #Get-SafeguardA2aRetrievableAccount
   #New-SafeguardA2a
   #New-SafeguardA2aAccessRequest
   #Remove-SafeguardA2a
   #Remove-SafeguardA2aCredentialRetrieval
   #Reset-SafeguardA2aAccessRequestBrokerApiKey
   #Reset-SafeguardA2aCredentialRetrievalApiKey
   #Set-SafeguardA2aAccessRequestBroker
   #Set-SafeguardA2aAccessRequestBrokerIpRestriction
   #Set-SafeguardA2aCredentialRetrievalIpRestriction
   #
   #$a2aStatus = Get-SafeguardA2aServiceStatus
   #$a2a = Get-SafeguardA2a
   #Set-SafeguardA2aAccessRequestBroker -ParentA2a "BaseA2A" -Groups "PermGroup"
   #$a2aBroker = Get-SafeguardA2aAccessRequestBroker -ParentA2a "BaseA2A"    
   #$api = $a2aBroker.ApiKey
   #$a2aRequest = New-SafeguardA2aAccessRequest -Appliance $appliance -Thumbprint $thumb -ApiKey $api -ForUserName "Perm-User-0" -AssetToUse "PermAsset1" -AccessRequestType Password -AccountToUse "PermAccount1" #-Verbose 
   #$a2aRequestState = $a2aRequest.State
   #Write-Host "Request state: $a2aRequestState"
   #endregion

   #region Access Requests
   # TODO - stubbed code
   #Get-SafeguardAccessRequestCheckoutPassword
   #Revoke-SafeguardAccessRequest
   #Approve-SafeguardAccessRequest
   #Assert-SafeguardAccessRequest
   #Clear-SafeguardA2aAccessRequestBroker
   #Clear-SafeguardA2aAccessRequestBrokerIpRestriction
   #Close-SafeguardAccessRequest
   #Copy-SafeguardAccessRequestPassword
   #Deny-SafeguardAccessRequest
   #Disable-SafeguardSessionClusterAccessRequestBroker
   #Edit-SafeguardAccessRequest
   #Enable-SafeguardSessionClusterAccessRequestBroker
   #Find-SafeguardAccessRequest
   #Get-SafeguardA2aAccessRequestBroker
   #Get-SafeguardA2aAccessRequestBrokerApiKey
   #Get-SafeguardA2aAccessRequestBrokerIpRestriction
   #Get-SafeguardAccessPolicyAccessRequestProperty
   #Get-SafeguardAccessRequest
   #Get-SafeguardAccessRequestActionLog
   #Get-SafeguardAccessRequestPassword
   #Get-SafeguardAccessRequestRdpFile
   #Get-SafeguardAccessRequestRdpUrl
   #Get-SafeguardAccessRequestSshUrl
   #Get-SafeguardReportDailyAccessRequest
   #Get-SafeguardSessionClusterAccessRequestBroker
   #New-SafeguardA2aAccessRequest
   #New-SafeguardAccessRequest
   #Reset-SafeguardA2aAccessRequestBrokerApiKey
   #Set-SafeguardA2aAccessRequestBroker
   #Set-SafeguardA2aAccessRequestBrokerIpRestriction
   #Start-SafeguardAccessRequestSession
   #Find-SafeguardMyRequestable
   #Get-SafeguardMyRequestable
   #Find-SafeguardRequestableAccount
   #Get-SafeguardActionableRequest
   #Get-SafeguardArchiveServer
   #Get-SafeguardMyApproval
   #Get-SafeguardMyRequest
   #Get-SafeguardMyReview
   #Get-SafeguardRequestableAccount
   #Get-SafeguardAccessRequestSshHostKey - !$thisIsLTS
   #Get-SafeguardAccessRequestSshKey - !$thisIsLTS
   #endregion

   #region Cluster Management
   # TODO - stubbed code
   #Add-SafeguardClusterMember
   #Disable-SafeguardSessionClusterAuditStream
   #Enable-SafeguardClusterPrimary
   #Enable-SafeguardSessionClusterAuditStream
   #Get-SafeguardSessionCluster
   #Get-SafeguardSessionClusterAuditStream
   #Get-SafeguardSessionSplitCluster
   #Invoke-SafeguardClusterPing
   #Join-SafeguardSessionCluster
   #Remove-SafeguardClusterMember
   #Remove-SafeguardSessionSplitCluster
   #Set-SafeguardClusterPrimary
   #Set-SafeguardSessionCluster
   #Split-SafeguardSessionCluster
   #Unlock-SafeguardCluster
   #endregion

   #region Certificates
   # TODO - stubbed code
   #Clear-SafeguardSslCertificateForAppliance
   #Get-ADAccessCertificationIdentity
   #Get-SafeguardAccessCertificationAccount
   #Get-SafeguardAccessCertificationAll
   #Get-SafeguardAccessCertificationGroup
   #Get-SafeguardAccessCertificationIdentity
   #Install-SafeguardAuditLogSigningCertificate
   #Install-SafeguardSessionCertificate
   #Install-SafeguardSslCertificate
   #Install-SafeguardTrustedCertificate
   #New-SafeguardCertificateSigningRequest
   #New-SafeguardCsr
   #New-SafeguardTestCertificatePki
   #Remove-SafeguardCertificateSigningRequest
   #Remove-SafeguardCsr
   #Reset-SafeguardSessionCertificate
   #Set-SafeguardSslCertificateForAppliance
   #Uninstall-SafeguardAuditLogSigningCertificate
   #Uninstall-SafeguardSslCertificate
   #Uninstall-SafeguardTrustedCertificate
   #Update-SafeguardAccessCertificationGroupFromAD
   #endregion

   #region Access Policy
   # TODO - stubbed code
   #Find-SafeguardPolicyAccount
   #Find-SafeguardPolicyAsset
   #Get-SafeguardAccessPolicy
   #Get-SafeguardAccessPolicyScopeItem
   #Get-SafeguardAccessPolicySessionProperty
   #Get-SafeguardPolicyAccount
   #Get-SafeguardPolicyAsset
   #endregion

   #region Diagnostic Package
   # TODO - stubbed code
   #Clear-SafeguardDiagnosticPackage
   #Get-SafeguardDiagnosticPackage
   #Get-SafeguardDiagnosticPackageLog
   #Get-SafeguardDiagnosticPackageStatus
   #Invoke-SafeguardDiagnosticPackage
   #Set-SafeguardDiagnosticPackage
   #endregion

   #region Starling
   # TODO - stubbed code
   #Get-SafeguardStarlingSubscription
   #Invoke-SafeguardStarlingJoin
   #New-SafeguardStarling2faAuthentication
   #New-SafeguardStarlingSubscription
   #Remove-SafeguardStarlingSubscription
   #Set-SafeguardStarlingSetting
   #endregion

   #region Patch
   # TODO - stubbed code
   #Clear-SafeguardPatch
   #Get-SafeguardPatch
   #Install-SafeguardPatch
   #Set-SafeguardPatch
   #endregion

}
catch {
   Write-Host $_.Exception
   Write-Host $_.ScriptStackTrace
}
finally {
   Disconnect-Safeguard

   writeCallHeader "Final Tally"
   Write-Host "Info: $($resultCounts.Info)" -ForegroundColor Yellow
   Write-Host "Good: $($resultCounts.Good)" -ForegroundColor Green
   Write-Host "Bad:  $($resultCounts.Bad)" -ForegroundColor Red
   if ($resultCounts.Bad -gt 0) {
      Write-Host "===== Collected Errors =====" -ForegroundColor Red
      $collectedErrors | Write-Host -ForegroundColor Red
   }
}
