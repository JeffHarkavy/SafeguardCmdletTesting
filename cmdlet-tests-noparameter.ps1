try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

# So this is really no-parameter ish commands. Some take a minimal parameter just to get to run
# but they're all just simple commands that can be run w/o any other data setup.
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
$commands = @{
   GetSafeguardBackup =                             @{cmdName = 'Get-SafeguardBackup'; pipe = "format-table"};
   GetSafeguardEvent =                              @{cmdName = 'Get-SafeguardEvent'; pipe = "format-table"};
   GetSafeguardIdentityProvider =                   @{cmdName = 'Get-SafeguardIdentityProvider'; pipe = "format-table"};
   GetSafeguardIdentityProviderType =               @{cmdName = 'Get-SafeguardIdentityProviderType'; pipe = "format-table"};
   GetSafeguardLicense =                            @{cmdName = 'Get-SafeguardLicense'; pipe = "format-table"};
   GetSafeguardAuthenticationProvider =             @{cmdName = 'Get-SafeguardAuthenticationProvider'; pipe = "format-table"};
   GetSafeguardLoggedInUser =                       @{cmdName = 'Get-SafeguardLoggedInUser'; pipe = "format-table"};
   GetSafeguardNetworkInterface =                   @{cmdName = 'Get-SafeguardNetworkInterface'; pipe = "format-table"};
   GetSafeguardAccountPasswordRule =                @{cmdName = 'Get-SafeguardAccountPasswordRule'; pipe = "format-table"};
   GetSafeguardPasswordChangeSchedule =             @{cmdName = 'Get-SafeguardPasswordChangeSchedule'; pipe = "format-table"};
   GetSafeguardPasswordCheckSchedule =              @{cmdName = 'Get-SafeguardPasswordCheckSchedule'; pipe = "format-table"};
   GetSafeguardPasswordProfile =                    @{cmdName = 'Get-SafeguardPasswordProfile'; pipe = "format-table"};
   GetSafeguardStatus =                             @{cmdName = 'Get-SafeguardStatus'; pipe = "format-table"};
   GetSafeguardTransferProtocol =                   @{cmdName = 'Get-SafeguardTransferProtocol'; pipe = "format-table"};
   GetSafeguardA2aServiceStatus =                   @{cmdName = 'Get-SafeguardA2aServiceStatus'; pipe = "format-table"};
   FindSafeguardPlatform =                          @{cmdName = 'Find-SafeguardPlatform'; cmd = "Find-SafeguardPlatform windows"; pipe = "format-table"};
   GetSafeguardAssetPartition =                     @{cmdName = 'Get-SafeguardAssetPartition'; pipe = "format-table"};
   GetSafeguardApplianceAvailability =              @{cmdName = 'Get-SafeguardApplianceAvailability';};
   GetSafeguardApplianceName =                      @{cmdName = 'Get-SafeguardApplianceName';};
   GetSafeguardApplianceState =                     @{cmdName = 'Get-SafeguardApplianceState';};
   GetSafeguardApplianceUptime =                    @{cmdName = 'Get-SafeguardApplianceUptime';};
   GetSafeguardApplianceVerification =              @{cmdName = 'Get-SafeguardApplianceVerification';};
   GetSafeguardAuditLogSigningCertificate =         @{cmdName = 'Get-SafeguardAuditLogSigningCertificate';};
   GetSafeguardCertificateSigningRequest =          @{cmdName = 'Get-SafeguardCertificateSigningRequest';};
   GetSafeguardClusterHealth =                      @{cmdName = 'Get-SafeguardClusterHealth';};
   GetSafeguardClusterMember =                      @{cmdName = 'Get-SafeguardClusterMember';};
   GetSafeguardClusterOperationStatus =             @{cmdName = 'Get-SafeguardClusterOperationStatus';};
   GetSafeguardClusterPlatformTaskLoadStatus =      @{cmdName = 'Get-SafeguardClusterPlatformTaskLoadStatus';};
   GetSafeguardClusterPlatformTaskQueueStatus =     @{cmdName = 'Get-SafeguardClusterPlatformTaskQueueStatus';}; 
   GetSafeguardClusterPrimary =                     @{cmdName = 'Get-SafeguardClusterPrimary';};
   GetSafeguardClusterSummary =                     @{cmdName = 'Get-SafeguardClusterSummary';};
   GetSafeguardClusterVpnIpv6Address =              @{cmdName = 'Get-SafeguardClusterVpnIpv6Address';};
   GetSafeguardCsr =                                @{cmdName = 'Get-SafeguardCsr';};
   GetSafeguardDnsSuffix =                          @{cmdName = 'Get-SafeguardDnsSuffix'; cmd = "Get-SafeguardDnsSuffix x0";};
   GetSafeguardEventName =                          @{cmdName = 'Get-SafeguardEventName';};
   GetSafeguardHealth =                             @{cmdName = 'Get-SafeguardHealth';};
   GetSafeguardPlatform =                           @{cmdName = 'Get-SafeguardPlatform'; cmd = "(Get-SafeguardPlatform).DisplayName";};
   GetSafeguardReportA2aEntitlement =               @{cmdName = 'Get-SafeguardReportA2aEntitlement';};
   GetSafeguardReportAccountWithoutPassword =       @{cmdName = 'Get-SafeguardReportAccountWithoutPassword'; cmd = "Get-SafeguardReportAccountWithoutPassword -StdOut";};
   GetSafeguardReportAssetManagementConfiguration = @{cmdName = 'Get-SafeguardReportAssetManagementConfiguration'; cmd = "Get-SafeguardReportAssetManagementConfiguration -StdOut";};
   GetSafeguardReportDailyAccessRequest =           @{cmdName = 'Get-SafeguardReportDailyAccessRequest'; cmd = "Get-SafeguardReportDailyAccessRequest -StdOut";};
   GetSafeguardReportDailyPasswordChangeFail =      @{cmdName = 'Get-SafeguardReportDailyPasswordChangeFail'; cmd = "Get-SafeguardReportDailyPasswordChangeFail -StdOut";};
   GetSafeguardReportDailyPasswordChangeSuccess =   @{cmdName = 'Get-SafeguardReportDailyPasswordChangeSuccess'; cmd = "Get-SafeguardReportDailyPasswordChangeSuccess -StdOut";};
   GetSafeguardReportDailyPasswordCheckFail =       @{cmdName = 'Get-SafeguardReportDailyPasswordCheckFail'; cmd = "Get-SafeguardReportDailyPasswordCheckFail -StdOut";};
   GetSafeguardReportDailyPasswordCheckSuccess =    @{cmdName = 'Get-SafeguardReportDailyPasswordCheckSuccess'; cmd = "Get-SafeguardReportDailyPasswordCheckSuccess -StdOut";};
   GetSafeguardReportUserEntitlement =              @{cmdName = 'Get-SafeguardReportUserEntitlement'; cmd = "Get-SafeguardReportUserEntitlement -StdOut";};
   GetSafeguardReportUserGroupMembership =          @{cmdName = 'Get-SafeguardReportUserGroupMembership'; cmd = "Get-SafeguardReportUserGroupMembership -StdOut";};
   GetSafeguardSslCertificate =                     @{cmdName = 'Get-SafeguardSslCertificate';};
   GetSafeguardSslCertificateForAppliance =         @{cmdName = 'Get-SafeguardSslCertificateForAppliance';};
   GetSafeguardStarlingJoinUrl =                    @{cmdName = 'Get-SafeguardStarlingJoinUrl';};
   GetSafeguardStarlingSetting =                    @{cmdName = 'Get-SafeguardStarlingSetting'; cmd = "Get-SafeguardStarlingSetting -SettingKey Environment";};
   GetSafeguardTime =                               @{cmdName = 'Get-SafeguardTime';};
   GetSafeguardTimeZone =                           @{cmdName = 'Get-SafeguardTimeZone'; cmd = "(Get-SafeguardTimeZone).DisplayName";};
   GetSafeguardTls12OnlyStatus =                    @{cmdName = 'Get-SafeguardTls12OnlyStatus';};
   GetSafeguardTrustedCertificate =                 @{cmdName = 'Get-SafeguardTrustedCertificate'; };
   WaitSafeguardApplianceStateOnline =              @{cmdName = 'Wait-SafeguardApplianceStateOnline';};
   EnableSafeguardA2aService =                      @{cmdName = 'Enable-SafeguardA2aService';};
   DisableSafeguardA2aService =                     @{cmdName = 'Disable-SafeguardA2aService';};
   GetSafeguardAccessTokenStatus =                  @{cmdName = 'Get-SafeguardAccessTokenStatus';};
   GetSafeguardBmcConfiguration=                    @{cmdName = 'Get-SafeguardBmcConfiguration'; onVm=$false;};
   DisableSafeguardBmcConfiguration =               @{cmdName = 'Disable-SafeguardBmcConfiguration'; onVm=$false;};
   GetSafeguardEventProperty =                      @{cmdName = 'Get-SafeguardEventProperty'; onLTS=$false; cmd = "Get-SafeguardEventProperty AssetCreated"};
   FindSafeguardEvent =                             @{cmdName = 'Find-SafeguardEvent'; onLTS=$false; cmd = "Find-SafeguardEvent req"; pipe = "format-table";};
}

writeCallHeader "Running 'no parameter' type commands"
try {
   foreach ($t in ($commands.GetEnumerator() | Sort {$_.Key})) {
      if ($null -ne $t.Value.onVm -and $t.Value.onVm -ne $isVm) {
         continue
      }
      if ($null -ne $t.Value.onLTS -and $t.Value.onLTS -ne $thisIsLTS) {
         continue
      }
      writeCallHeader $($t.Value.cmdName)
      $cmd = $t.Value.cmd
      if ($null -eq $t.Value.cmd) {
         $cmd = $t.Value.cmdName
      }
      if ($null -ne $t.Value.pipe -and $t.Value.pipe -ne "") {
         $cmd += " | $($t.Value.pipe)"
      }
      try {
         Invoke-Expression $cmd
         goodResult "$($t.Value.cmdName)" "Successfully executed"
      } catch {
         badResult "$($t.Value.cmdName)" "Unepxected error" $_.Exception
      }
   }
}
catch {
   badResult "no-parameter general" "Unexpected error running no-parameter command"  $_.Exception
}
