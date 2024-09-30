try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.NoParameter
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false
$script:createdItems = @{
   Assets = @();
   AssetAccounts = @();
}
$script:accounts = @()
$script:assets = @()

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Removing created items")
   $script:createdItems.Keys | ForEach-Object {
      $dto = $_
      if ($script:createdItems[$dto].length) {
         foreach ($item in $script:createdItems[$dto]) {
           try {
             Invoke-SafeguardMethod core DELETE "$dto/$($item.id)" > $null
           } catch {
              # Trying to remove accounts or systems with pending access request actions will
              # throw an error, so try it with force.
              if ($_ -match "is referenced by") {
                 try { Invoke-SafeguardMethod core DELETE "$dto/$($item.id)?forceDelete=true" -ErrorAction SilentlyContinue > $null } catch {}
              } else {
                $GLOBALS.warningResult(@{ minVerbosity = 1; cmd = "Cleanup"; message = "Exception trying to remove $dto/$($item.id)."; extra = $_; })
             }
           }
         }
      }
   }
}

# some reports need an asset or account, so just some simple ones
# These need to be created before the commands hash gets created
try {
   $GLOBALS.writeCallHeader("Creating Asset and Accounts for reports")
   $defaultPassword = "AbCD123!@#"
   $securePassword = $defaultPassword | ConvertTo-SecureString -AsPlainText -Force
   $asset = Find-SafeguardAsset $DATA.asset.DisplayName
   if ($asset) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAsset"; message = "found $($DATA.asset.DisplayName)"; }) }
   else {
     $asset = $GLOBALS.createAsset()
     $script:createdItems.Assets += $asset
   }
   $script:assets += $asset

   foreach ($acctName in $DATA.assetAccounts.GetEnumerator()) {
      $found = Find-SafeguardAssetAccount -QueryFilter "Asset.Name eq '$($DATA.asset.DisplayName)' and Name eq '$acctname'"
      if ($found) { $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAssetAccount"; message = "$acctName already exists on $($DATA.asset.DisplayName)"; }) }
      else {
         $found = New-SafeguardAssetAccount -ParentAsset $DATA.asset.DisplayName -NewAccountName $acctname
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAssetAccount"; message = "$acctName successfully created on $($DATA.asset.DisplayName)"; })
         $script:createdItems.AssetAccounts += $found
      }
      Set-SafeguardAssetAccountPassword -AccountToSet $found -NewPassword $securePassword > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAssetAccountPassword"; message = "$acctName password reset"; })
      Invoke-SafeguardMethod Core PUT "AssetAccounts/$($found.Id)/SshKey?keyFormat=OpenSsh" -Body @{ KeyType = "Rsa"; KeyLength = 2048; Comment = ""; }> $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAssetAccountSshKey"; message = "$acctName SSH Key reset"; })
      $script:accounts += $found
   }
} catch {
}

# So this is really no-parameter ish commands. Some take a minimal parameter just to get to run
# but they"re all just simple commands that can be run w/o any other data setup.
#
# Commands will be executed in alphabetic order based on the Key. If a specific order is desired
# then a Seq member must be added to the hash as done in safeguard-cmdlet-testing.ps1
#
# Hash values
#    cmdName - Name of the command being invoked
#    cmd     - The actual invocation. If null or not specified then cmdName is used.
#    pipe    - If output is to be piped through something, e.g., format-table
#    onVm    - T/F - if not specified command will run on both h/w and vm. Use $true to run only on VM, $false to run only on h/w
#    onLTS   - T/F - if not specified command will run on both LTS and feature release. Use $true to run only on LTS, $false to run only on feature release
#
# Notes:
# - many long lists are truncated to -First $($DATA.defaultFormatTableLineCount). This is a test of what runs, not necessarily verifying all the output.
# - any "wide" output for Format-Table is cut down to a few properties. See above.
# - all report calls send output to the directory specifed in $DATA.filePaths.reports
#
$commands = @{
   GetSafeguardBackup =                             @{cmdName = "Get-SafeguardBackup"; cmd = "(Get-SafeguardBackup) | select -Property CreatedOn,Id,Size"; pipe = "format-table"};
   GetSafeguardEvent =                              @{cmdName = "Get-SafeguardEvent"; cmd = "(Get-SafeguardEvent) | Select -Property Name,CategoryDisplayName -First $($DATA.defaultFormatTableLineCount)"; pipe = "format-table"};
   GetSafeguardIdentityProvider =                   @{cmdName = "Get-SafeguardIdentityProvider"; pipe = "format-table"};
   GetSafeguardIdentityProviderType =               @{cmdName = "Get-SafeguardIdentityProviderType"; pipe = "format-table"};
   GetSafeguardLicense =                            @{cmdName = "Get-SafeguardLicense"; pipe = "format-table"};
   GetSafeguardAuthenticationProvider =             @{cmdName = "Get-SafeguardAuthenticationProvider"; pipe = "format-table"};
   GetSafeguardLoggedInUser =                       @{cmdName = "Get-SafeguardLoggedInUser"; cmd = "(Get-SafeguardLoggedInUser) | select -Property UserName,AdminRoles,LastLoginDate"; pipe = "format-table"};
   GetSafeguardNetworkInterface =                   @{cmdName = "Get-SafeguardNetworkInterface"; pipe = "format-table"};
   GetSafeguardAccountPasswordRule =                @{cmdName = "Get-SafeguardAccountPasswordRule"; cmd = "(Get-SafeguardAccountPasswordRule) | select -Property Id,AssetPartitionName,CreatedDate,Name"; pipe = "format-table"};
   GetSafeguardPasswordChangeSchedule =             @{cmdName = "Get-SafeguardPasswordChangeSchedule"; cmd = "(Get-SafeguardPasswordChangeSchedule) | select -Property Id,Name,CreatedDate"; pipe = "format-table"};
   GetSafeguardPasswordCheckSchedule =              @{cmdName = "Get-SafeguardPasswordCheckSchedule"; cmd = "(Get-SafeguardPasswordCheckSchedule) | select -Property Id,Name,CreatedDate"; pipe = "format-table"};
   GetSafeguardPasswordProfile =                    @{cmdName = "Get-SafeguardPasswordProfile"; cmd = "(Get-SafeguardPasswordProfile) | select -Property Id,Name,Description,CreatedDate"; pipe = "format-table"};
   GetSafeguardStatus =                             @{cmdName = "Get-SafeguardStatus"; cmd = "(Get-SafeguardStatus) | select -Property ApplianceName,ApplianceCurrentState,ApplianceVersion,CurrentTime"; pipe = "format-table"};
   GetSafeguardTransferProtocol =                   @{cmdName = "Get-SafeguardTransferProtocol"; pipe = "format-table"};
   GetSafeguardA2aServiceStatus =                   @{cmdName = "Get-SafeguardA2aServiceStatus"; pipe = "format-table"};
   FindSafeguardPlatform =                          @{cmdName = "Find-SafeguardPlatform"; cmd = "(Find-SafeguardPlatform windows) | select -Property Id,PlatformType,DisplayName,Name,Version"; pipe = "format-table"};
   GetSafeguardAssetPartition =                     @{cmdName = "Get-SafeguardAssetPartition"; cmd = "(Get-SafeguardAssetPartition) | Select -Property Id,Name,CreatedDate,Owners"; pipe = "format-table"};
   GetSafeguardApplianceAvailability =              @{cmdName = "Get-SafeguardApplianceAvailability";};
   GetSafeguardApplianceName =                      @{cmdName = "Get-SafeguardApplianceName";};
   GetSafeguardApplianceState =                     @{cmdName = "Get-SafeguardApplianceState";};
   GetSafeguardApplianceUptime =                    @{cmdName = "Get-SafeguardApplianceUptime";};
   GetSafeguardApplianceVerification =              @{cmdName = "Get-SafeguardApplianceVerification";};
   GetSafeguardAuditLogSigningCertificate =         @{cmdName = "Get-SafeguardAuditLogSigningCertificate"; pipe = "format-table";};
   GetSafeguardCertificateSigningRequest =          @{cmdName = "Get-SafeguardCertificateSigningRequest";};
   GetSafeguardClusterHealth =                      @{cmdName = "Get-SafeguardClusterHealth";};
   GetSafeguardClusterMember =                      @{cmdName = "Get-SafeguardClusterMember";};
   GetSafeguardClusterOperationStatus =             @{cmdName = "Get-SafeguardClusterOperationStatus";};
   GetSafeguardClusterPlatformTaskLoadStatus =      @{cmdName = "Get-SafeguardClusterPlatformTaskLoadStatus";};
   GetSafeguardClusterPlatformTaskQueueStatus =     @{cmdName = "Get-SafeguardClusterPlatformTaskQueueStatus";}; 
   GetSafeguardClusterPrimary =                     @{cmdName = "Get-SafeguardClusterPrimary";};
   GetSafeguardClusterSummary =                     @{cmdName = "Get-SafeguardClusterSummary";};
   GetSafeguardClusterVpnIpv6Address =              @{cmdName = "Get-SafeguardClusterVpnIpv6Address";};
   GetSafeguardCsr =                                @{cmdName = "Get-SafeguardCsr";};
   GetSafeguardDnsSuffix =                          @{cmdName = "Get-SafeguardDnsSuffix"; cmd = "Get-SafeguardDnsSuffix";};
   GetSafeguardEventName =                          @{cmdName = "Get-SafeguardEventName"; cmd = "(Get-SafeguardEventName) | select -First $($DATA.defaultFormatTableLineCount)";};
   GetSafeguardHealth =                             @{cmdName = "Get-SafeguardHealth";};
   GetSafeguardPlatform =                           @{cmdName = "Get-SafeguardPlatform"; cmd = "(Get-SafeguardPlatform).DisplayName | select -First $($DATA.defaultFormatTableLineCount)";};
   GetSafeguardReportAccountGroupMembership =       @{cmdName = "Get-SafeguardReportAccountGroupMembership"; cmd = "Get-SafeguardReportAccountGroupMembership -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportAssetAccountPasswordHistory =  @{cmdName = "Get-SafeguardReportAssetAccountPasswordHistory"; cmd = "Get-SafeguardReportAssetAccountPasswordHistory -AccountToGet $($script:accounts[1].Id) -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportAssetGroupMembership =         @{cmdName = "Get-SafeguardReportAssetGroupMembership"; cmd = "Get-SafeguardReportAssetGroupMembership -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportPasswordLastChanged =          @{cmdName = "Get-SafeguardReportPasswordLastChanged"; cmd = "Get-SafeguardReportPasswordLastChanged -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportA2aEntitlement =               @{cmdName = "Get-SafeguardReportA2aEntitlement"; cmd = "Get-SafeguardReportA2aEntitlement -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportAccountWithoutPassword =       @{cmdName = "Get-SafeguardReportAccountWithoutPassword"; cmd = "Get-SafeguardReportAccountWithoutPassword -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportAssetManagementConfiguration = @{cmdName = "Get-SafeguardReportAssetManagementConfiguration"; cmd = "Get-SafeguardReportAssetManagementConfiguration -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportDailyAccessRequest =           @{cmdName = "Get-SafeguardReportDailyAccessRequest"; cmd = "Get-SafeguardReportDailyAccessRequest -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportDailyPasswordChangeFail =      @{cmdName = "Get-SafeguardReportDailyPasswordChangeFail"; cmd = "Get-SafeguardReportDailyPasswordChangeFail -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportDailyPasswordChangeSuccess =   @{cmdName = "Get-SafeguardReportDailyPasswordChangeSuccess"; cmd = "Get-SafeguardReportDailyPasswordChangeSuccess -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportDailyPasswordCheckFail =       @{cmdName = "Get-SafeguardReportDailyPasswordCheckFail"; cmd = "Get-SafeguardReportDailyPasswordCheckFail -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportDailyPasswordCheckSuccess =    @{cmdName = "Get-SafeguardReportDailyPasswordCheckSuccess"; cmd = "Get-SafeguardReportDailyPasswordCheckSuccess -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportUserEntitlement =              @{cmdName = "Get-SafeguardReportUserEntitlement"; cmd = "Get-SafeguardReportUserEntitlement -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardReportUserGroupMembership =          @{cmdName = "Get-SafeguardReportUserGroupMembership"; cmd = "Get-SafeguardReportUserGroupMembership -OutputDirectory '$($DATA.filePaths.reports)'";};
   GetSafeguardSslCertificate =                     @{cmdName = "Get-SafeguardSslCertificate"; pipe = "format-table";};
   GetSafeguardSslCertificateForAppliance =         @{cmdName = "Get-SafeguardSslCertificateForAppliance"; pipe = "format-table";};
   GetSafeguardStarlingJoinUrl =                    @{cmdName = "Get-SafeguardStarlingJoinUrl";};
   GetSafeguardStarlingSetting =                    @{cmdName = "Get-SafeguardStarlingSetting"; cmd = "Get-SafeguardStarlingSetting -SettingKey Environment";};
   GetSafeguardTime =                               @{cmdName = "Get-SafeguardTime";};
   GetSafeguardTimeZone =                           @{cmdName = "Get-SafeguardTimeZone"; cmd = "(Get-SafeguardTimeZone) | select -Property Id,DisplayName,IanaName,UtcOffset,Obsolete -First $($DATA.defaultFormatTableLineCount)"; pipe = "format-table";};
   GetSafeguardTls12OnlyStatus =                    @{cmdName = "Get-SafeguardTls12OnlyStatus";};
   GetSafeguardTrustedCertificate =                 @{cmdName = "Get-SafeguardTrustedCertificate"; pipe = "format-table";};
   EnableSafeguardA2aService =                      @{cmdName = "Enable-SafeguardA2aService";};
   DisableSafeguardA2aService =                     @{cmdName = "Disable-SafeguardA2aService";};
   GetSafeguardAccessTokenStatus =                  @{cmdName = "Get-SafeguardAccessTokenStatus";};
   GetSafeguardBmcConfiguration=                    @{cmdName = "Get-SafeguardBmcConfiguration"; onVm=$false;};
   DisableSafeguardBmcConfiguration =               @{cmdName = "Disable-SafeguardBmcConfiguration"; onVm=$false;};
   GetSafeguardEventProperty =                      @{cmdName = "Get-SafeguardEventProperty"; onLTS=$false; cmd = "Get-SafeguardEventProperty AssetCreated"};
   FindSafeguardEvent =                             @{cmdName = "Find-SafeguardEvent"; onLTS=$false; cmd = "(Find-SafeguardEvent req) | select -Property Name,DisplayName -First $($DATA.defaultFormatTableLineCount)"; pipe = "format-table";};
   DisableSafeguardTlsLogging =                     @{cmdName = "Disable-SafeguardTlsLogging"; onLTS=$false;};
   EnableSafeguardTlsLogging =                      @{cmdName = "Enable-SafeguardTlsLogging"; onLTS=$false;};
   GetSafeguardApplianceDnsName =                   @{cmdName = "Get-SafeguardApplianceDnsName"; onLTS=$false;};
   GetSafeguardApplianceDnsSuffix =                 @{cmdName = "Get-SafeguardApplianceDnsSuffix"; onLTS=$false;};
}

try {
   foreach ($t in ($commands.GetEnumerator() | Sort {$_.Key})) {
      if ($null -ne $t.Value.onVm -and $t.Value.onVm -ne $isVm) {
         continue
      }
      if ($null -ne $t.Value.onLTS -and $t.Value.onLTS -ne $isLTS) {
         continue
      }
      $GLOBALS.writeCallHeader($($t.Value.cmdName))
      $cmd = $t.Value.cmd
      if ($null -eq $t.Value.cmd) {
         $cmd = $t.Value.cmdName
      }
      if ($null -ne $t.Value.pipe -and $t.Value.pipe -ne "") {
         $cmd += " | $($t.Value.pipe)"
      }
      try {
         # theoretically the pipe to out-host should not be necessary, but
         # without it the output from the rapid invocation of commands can
         # appear out-of-order with the header & result line.
         # i really hate powershell
         Invoke-Expression $cmd | out-host
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "$($t.Value.cmdName)"; message = "Successfully executed"; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "$($t.Value.cmdName)"; message = "Unepxected error"; ex = $_; })
      }
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "no-parameter general"; message = "Unexpected error running no-parameter command" ; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

