# Gather any parameters into a single array
param([Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)][string[]] $allParameters)

$SCRIPT_PATH = (Split-Path $myInvocation.MyCommand.Path)
$collectedErrors = [System.Collections.ArrayList]@()

# flags to run / not run a given block of tests
# add to this and create cmdlet-tests files as functionality gets added
# Default these all to "N" and cmdline processing will turn things on/off
# based on the list of tests passed in.
$Tests = @{
   CheckHelp =             @{Seq=1;  runTest = "N"; fileName = "cmdlet-tests-help.ps1";};
   NoParameter =           @{Seq=2;  runTest = "N"; fileName = "cmdlet-tests-noparameter.ps1";};
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

# just moving the "global" data to a separate file for maintainability
# (yes, it's powershell, everything is global)
. "$script_path\harness-data.ps1"

# load up the harness functions
. "$script_path\harness-functions.ps1"

# ========================================================================
#
#  Actual Start of Script logic
#
# ========================================================================

# Process the command line and either show help or set the list of tests to run
if ($allParameters -contains "help" -or $allParameters -contains "?") {
   showHelp
} elseif ($allParameters.Length -eq 0 -or $allParameters -contains "all") {
   foreach ($t in $Tests.GetEnumerator()) {
      $t.Value.runTest = "Y"
   }
} else {
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

write-host "Running the following tests (in order)"
foreach ($t in ($Tests.GetEnumerator() | Where-Object {$_.Value.runTest -eq "Y"} | Sort {$_.Value.Seq})) {
   write-host "   $($t.Key)"
}
pause

try {
   $fullRunInfo = testBlockHeader "begin" "All Test Blocks"

   Connect-Safeguard -Appliance $appliance -IdentityProvider $idProvider -Password $secPassword -Username $userName -Insecure
   goodResult "Connect-Safeguard" "Success"

   writeCallHeader "Get-SafeguardVersion"
   goodResult "Get-SafeguardVersion" "Success"
   $sgVersion = Get-SafeguardVersion
   $sgVersion | format-table
   # TODO Make sure to add any other known "vm" types
   $isVm = @('vmware','hyperv') -contains $sgVersion.BuildPlatform
   $isLTS = $sgVersion.Minor -eq "0"

   writeCallHeader "Test-SafeguardVersion - minimum 6.0"
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
   #Get-SafeguardAccessRequestSshHostKey - !$isLTS
   #Get-SafeguardAccessRequestSshKey - !$isLTS
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

   testBlockHeader "end" "All Test Blocks`nFinal Tally" $fullRunInfo 
   if ($resultCounts.Bad -gt 0) {
      Write-Host "===== Collected Errors =====" -ForegroundColor Red
      $collectedErrors | Write-Host -ForegroundColor Red
   }
}
