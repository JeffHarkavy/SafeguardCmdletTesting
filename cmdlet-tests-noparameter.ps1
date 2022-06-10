try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName = "Running ""no parameter"" type commands"
$blockInfo = testBlockHeader $TestBlockName
$DEFAULT_MAXROWS = 10

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
# - many long lists are truncated to -First $DEFAULT_MAXROWS. This is a test of what runs, not necessarily verifying all the output.
# - any "wide" output for Format-Table is cut down to a few properties. See above.
# - all report calls send output to the directory specifed in $DATA.outputPaths.reports
#
$commands = @{
   GetSafeguardBackup =                             @{cmdName = "Get-SafeguardBackup"; cmd = "(Get-SafeguardBackup) | select -Property CreatedOn,Id,Size"; pipe = "format-table"};
   GetSafeguardEvent =                              @{cmdName = "Get-SafeguardEvent"; cmd = "(Get-SafeguardEvent) | Select -Property Name,CategoryDisplayName -First $DEFAULT_MAXROWS"; pipe = "format-table"};
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
   GetSafeguardEventName =                          @{cmdName = "Get-SafeguardEventName"; cmd = "(Get-SafeguardEventName) | select -First $DEFAULT_MAXROWS"};
   GetSafeguardHealth =                             @{cmdName = "Get-SafeguardHealth";};
   GetSafeguardPlatform =                           @{cmdName = "Get-SafeguardPlatform"; cmd = "(Get-SafeguardPlatform).DisplayName | select -First $DEFAULT_MAXROWS";};
   GetSafeguardReportA2aEntitlement =               @{cmdName = "Get-SafeguardReportA2aEntitlement"; cmd = "Get-SafeguardReportA2aEntitlement -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportAccountWithoutPassword =       @{cmdName = "Get-SafeguardReportAccountWithoutPassword"; cmd = "Get-SafeguardReportAccountWithoutPassword -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportAssetManagementConfiguration = @{cmdName = "Get-SafeguardReportAssetManagementConfiguration"; cmd = "Get-SafeguardReportAssetManagementConfiguration -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportDailyAccessRequest =           @{cmdName = "Get-SafeguardReportDailyAccessRequest"; cmd = "Get-SafeguardReportDailyAccessRequest -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportDailyPasswordChangeFail =      @{cmdName = "Get-SafeguardReportDailyPasswordChangeFail"; cmd = "Get-SafeguardReportDailyPasswordChangeFail -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportDailyPasswordChangeSuccess =   @{cmdName = "Get-SafeguardReportDailyPasswordChangeSuccess"; cmd = "Get-SafeguardReportDailyPasswordChangeSuccess -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportDailyPasswordCheckFail =       @{cmdName = "Get-SafeguardReportDailyPasswordCheckFail"; cmd = "Get-SafeguardReportDailyPasswordCheckFail -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportDailyPasswordCheckSuccess =    @{cmdName = "Get-SafeguardReportDailyPasswordCheckSuccess"; cmd = "Get-SafeguardReportDailyPasswordCheckSuccess -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportUserEntitlement =              @{cmdName = "Get-SafeguardReportUserEntitlement"; cmd = "Get-SafeguardReportUserEntitlement -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardReportUserGroupMembership =          @{cmdName = "Get-SafeguardReportUserGroupMembership"; cmd = "Get-SafeguardReportUserGroupMembership -OutputDirectory ""$($DATA.outputPaths.reports)""";};
   GetSafeguardSslCertificate =                     @{cmdName = "Get-SafeguardSslCertificate"; pipe = "format-table";};
   GetSafeguardSslCertificateForAppliance =         @{cmdName = "Get-SafeguardSslCertificateForAppliance"; pipe = "format-table";};
   GetSafeguardStarlingJoinUrl =                    @{cmdName = "Get-SafeguardStarlingJoinUrl";};
   GetSafeguardStarlingSetting =                    @{cmdName = "Get-SafeguardStarlingSetting"; cmd = "Get-SafeguardStarlingSetting -SettingKey Environment";};
   GetSafeguardTime =                               @{cmdName = "Get-SafeguardTime";};
   GetSafeguardTimeZone =                           @{cmdName = "Get-SafeguardTimeZone"; cmd = "(Get-SafeguardTimeZone) | select -Property Id,DisplayName,IanaName,UtcOffset,Obsolete -First $DEFAULT_MAXROWS"; pipe = "format-table";};
   GetSafeguardTls12OnlyStatus =                    @{cmdName = "Get-SafeguardTls12OnlyStatus";};
   GetSafeguardTrustedCertificate =                 @{cmdName = "Get-SafeguardTrustedCertificate"; pipe = "format-table";};
   EnableSafeguardA2aService =                      @{cmdName = "Enable-SafeguardA2aService";};
   DisableSafeguardA2aService =                     @{cmdName = "Disable-SafeguardA2aService";};
   GetSafeguardAccessTokenStatus =                  @{cmdName = "Get-SafeguardAccessTokenStatus";};
   GetSafeguardBmcConfiguration=                    @{cmdName = "Get-SafeguardBmcConfiguration"; onVm=$false;};
   DisableSafeguardBmcConfiguration =               @{cmdName = "Disable-SafeguardBmcConfiguration"; onVm=$false;};
   GetSafeguardEventProperty =                      @{cmdName = "Get-SafeguardEventProperty"; onLTS=$false; cmd = "Get-SafeguardEventProperty AssetCreated"};
   FindSafeguardEvent =                             @{cmdName = "Find-SafeguardEvent"; onLTS=$false; cmd = "(Find-SafeguardEvent req) | select -Property Name,DisplayName -First $DEFAULT_MAXROWS"; pipe = "format-table";};
   DisableSafeguardTlsLogging =                     @{cmdName = "Disable-SafeguardTlsLogging"; onLTS=$false;};
   EnableSafeguardTlsLogging =                      @{cmdName = "Enable-SafeguardTlsLogging"; onLTS=$false;};
}

try {
   foreach ($t in ($commands.GetEnumerator() | Sort {$_.Key})) {
      if ($null -ne $t.Value.onVm -and $t.Value.onVm -ne $isVm) {
         continue
      }
      if ($null -ne $t.Value.onLTS -and $t.Value.onLTS -ne $isLTS) {
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
         # theoretically the pipe to out-host should not be necessary, but
         # without it the output from the rapid invocation of commands can
         # appear out-of-order with the header & result line.
         # i really hate powershell
         Invoke-Expression $cmd | out-host
         goodResult "$($t.Value.cmdName)" "Successfully executed"
      } catch {
         badResult "$($t.Value.cmdName)" "Unepxected error" $_
      }
   }
}
catch {
   badResult "no-parameter general" "Unexpected error running no-parameter command"  $_
}

testBlockHeader $TestBlockName $blockInfo
