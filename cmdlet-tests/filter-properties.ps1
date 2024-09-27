try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.FilterProperties
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:endpointService = "core"

# When setting things up if we need to create something to query put the object
# created here so that it can get cleaned up at the end. Not all DTOs are
# included here - only the ones that *might* be empty and can be created.
$script:createdItems = @{
  AccessPolicies = $null;
  AccountGroups = $null;
  ArchiveServers = $null;
  AssetAccounts = $null;
  AssetGroups = $null;
  Assets = $null;
  ReasonCodes = $null;
  Roles = $null;
  SyslogServers = $null;
  TicketSystems = $null;
  UserGroups = $null;
}
function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################
   $script:createdItems.Keys | ForEach-Object {
      if ($script:createdItems[$_]) {
         try {
           Invoke-SafeguardMethod core DELETE "$($_)/$(script:createdItems[$_].id)" -ErrorAction SilentlyContinue > $null
         } catch {
         }
      }
   }
}

function script:ensureDataExists() {
   foreach ($key in @($script:createdItems.Keys)) {
      $obj = Invoke-expression "invoke-safeguardmethod $script:endpointService GET $key -parameters @{page=0;limit=1}"
      if ($null -eq $obj -or $obj -eq "" -or $obj.length -eq 0) {
         try {
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = $key; message = "No $key data found. Attempting to create."; })
            switch ($key) {
              'AccessPolicies'    {
                 $entitlement = $null
                 try { $entitlement = Get-SafeguardEntitlement -EntitlementToGet $DATA.entitlementName } catch {}
                 if ($null -eq $entitlement) {
                    $entitlement = New-SafeguardEntitlement -Name "$($DATA.entitlementName)" -MemberUsers "$($DATA.userName)"
                    $script:createdItems.Roles = $entitlement
                    $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardEntitlement"; message = "Added entitlement $($entitlement.Name)"; })
                 }
                 $policy = $GLOBALs.deepClone($DATA.accessPolicy)
                 $policy.RoleId = $entitlement.Id
                 $policy.ScopeItems = @()
                 $script:createdItems.AccessPolicies = Invoke-SafeguardMethod Core POST AccessPolicies -Body $policy
                 $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Access Policy"; message = "Added AccessPolicy $($script:createdItems.AccessPolicies.Name)"; })
              }
              'AccountGroups'     { $script:createdItems[$key] = New-SafeguardAccountGroup -Name "$($DATA.accountGroupName)" -Description "Description for $($DATA.accountGroupName)" }
              'ArchiveServers'    { $script:createdItems[$key] = New-SafeguardArchiveServer -DisplayName $DATA.realArchiveServer.archSrvName `
                 -NetworkAddress $DATA.realArchiveServer.NetworkAddress `
                 -TransferProtocol $DATA.realArchiveServer.TransferProtocol `
                 -Port $DATA.realArchiveServer.Port `
                 -StoragePath $DATA.realArchiveServer.StoragePath `
                 -ServiceAccountCredentialType $DATA.realArchiveServer.ServiceAccountCredentialType `
                 -ServiceAccountName $DATA.realArchiveServer.ServiceAccountName `
                 -ServiceAccountPassword $DATA.realArchiveServer.ServiceAccountPassword `
                 -AcceptSshHostKey
              }
              'AssetAccounts'     {
                 if (!(Find-SafeguardAsset $DATA.assetName)) {
                    $script:createdItems.Assets = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
                     -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
                     -AcceptSshHostKey -PrivilegeElevationCommand "sudo"
                 }
                 $script:createdItems[$key] = New-SafeguardAssetAccount -ParentAsset $DATA.assetName -NewAccountName $DATA.assetAccounts[0]
              }
              'AssetGroups'       { $script:createdItems[$key] = New-SafeguardAssetGroup -Name "$($DATA.assetGroupName)" -Description "Description for $($DATA.assetGroupName)" }
              'Assets'            { $script:createdItems[$key] = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
                  -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
                  -AcceptSshHostKey -PrivilegeElevationCommand "sudo"
              }
              'ReasonCodes'       { $script:createdItems[$key] = Invoke-SafeguardMethod Core POST ReasonCodes -Body @{ Name = "RN12345"; Description = "Routine maintenance." } }
              'Roles'             { $script:createdItems[$key] = New-SafeguardEntitlement -Name "$($DATA.entitlementName)" -MemberUsers "$($DATA.userName)" }
              'SyslogServers'     { $script:createdItems[$key] = New-SafeguardSyslogServer -NetworkAddress "1.2.3.4" -Name "SYSLOG12345" }
              'TicketSystems'     { $script:createdItems[$key] = Invoke-SafeguardMethod Core POST TicketSystem -Body @{ Name='TS12345'; TicketSystemType='Other'; TicketRegularExpression='1.*2'; } }
              'UserGroups'        { $script:createdItems[$key] = New-SafeguardUserGroup -Name "$($DATA.userGroupName)" }
            }
         } catch {
            $GLOBALS.warningResult(@{ minVerbosity = 1; cmd = "$_"; message = "Unable to create $key data. Proceeding with test."; ex = $_; })
         }
      }
   }
}

function script:nestedPropertyCheck($call, $object, $prefix) {
   $failures = [System.Collections.ArrayList]@()
   $depth++
   #JIC there are some nested recursive definitions somewhere
   if ($depth -gt 10) {
      $failures.Add("Max depth of 10 exceeded - call=$call, prefix=$prefix")
      return $failures
   }
   try {
      $props = $object | Get-Member -membertype noteproperty
      $props | ForEach-Object {$idx = 0} {
         if ($_.Definition -match "PSCustomObject") {
            $n = $_.Name
            $newprefix = iif $($prefix -ne "") "$prefix.$n" $n 
            $nestedFailures = script:nestedPropertyCheck $call $object."$n" "$newprefix"
            if ($nestedFailures.length -gt 0) {
               $failures.AddRange($nestedFailures)
            }
         } elseif ( $_.Definition -match "^Object\[\]") {
           $n = iif $($prefix -ne "") "$prefix.$($_.Name)" $_.Name
           if (-not $quiet) {
              write-host -ForegroundColor Cyan "SKIPPED $n"
           }
         } else {
           $n = iif $($prefix -ne "") "$prefix.$($_.Name)" $_.Name
           try {
            $script:loops++
            if ($quiet) {
              if ($script:loops % 5 -eq 0) {
                 write-host -NoNewLine $script:loops
              } else {
                 write-host -NoNewLine "."
              }
            }
            $filter = "$n ne null"
            $count = invoke-safeguardmethod $script:endpointService GET $call -parameters @{filter=$filter; count=$true}
            if (-not $quiet) {
              $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "GET $call"; message = "$n - count=$count"; })
            }
           } catch {
              # We'll report Null reference and "not a valid filter" error.
              # "is not a field" is an acceptable error for things like AuthenticationPassword
             if ($_ -notmatch "is not a field") {
                $failures.Add("$n ($_)") > $null
             }
           }
         }
         $idx++
      }
   } catch {
      $failures.Add("Get-Member $call - $prefix : L:$($_.InvocationInfo.ScriptLineNumber) $($_.Exception.Message)") > $null
   }
   $depth--
   return $failures
}

function script:checkAllProperties($topLevel) {
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "START"; message = "######## $topLevel ########"; })
   $local:good = $true
   try {
      $obj = Invoke-expression "invoke-safeguardmethod $script:endpointService GET $topLevel -parameters @{page=0;limit=1}"
      if ($null -eq $obj -or $obj -eq "" -or $obj.length -eq 0) {
         $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "$topLevel"; message = "GET returned no results"; })
         return
      }
      $script:loops = 0
      $results = script:nestedPropertyCheck $topLevel $obj[0] ""
      if ($quiet -and $script:loops -gt 0) {
         Write-Host
      }
      if ($results.length -gt 0) {
         $results | ForEach-Object { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "$topLevel"; message = $_; }) }
         $local:good = $false
      } else {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "$topLevel"; message = "No failures (property count: $script:loops)"; })
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "$topLevel"; message = "Unexpected error checking $topLevel"; ex = $_; })
      $local:good = $false
   } finally {
      if ($quiet -and $script:loops -gt 0 -and !$local:good) {
         Write-Host
      }
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "END  "; message = "######## $topLevel ########`n"; })
   }
}

# ===== Covered DTOs =====
#  see DTO ForEach-Object below
#
#  Note - a "GET" of the DTO must return something, e.g., if you
#  don't have an AccountGroup defined then checking filter properties
#  for AccountGroups will not work. This is reported as an infoResult
#  in the output and is not considered a failure.
#
try {
   $depth = 0
   $loops = 0
   $quiet = $true

   ###############################################################################
   $GLOBALS.writeCallHeader("Make sure some data exists")
   ###############################################################################
   script:ensureDataExists

   ###############################################################################
   $GLOBALS.writeCallHeader("Checking filter properties (core)")
   ###############################################################################
   @("A2ARegistrations", "AccessPolicies", "AccessRequests", "AccountGroups", `
     "ArchiveServers", "AssetAccounts", "AssetGroups", "AssetPartitions", "Assets", `
     "AuthenticationProviders", "EmailTemplates", "Events", "EventSubscribers", `
     "Identities", "IdentityProviders", "IdentityProviderTypes", "Licenses", `
     "Platforms", "PolicyAccounts", "PolicyAssets", "ReasonCodes", "Roles", `
     "RunningTasks", "SshAlgorithms", "SslCertificates", "SyslogServers", `
     "TicketSystems", "TimeZones", "TransferProtocols", "UserGroups", "Users") | ForEach-Object {
       script:checkAllProperties $_
   }

   ###############################################################################
   $GLOBALS.writeCallHeader("Checking filter properties (appliance)")
   ###############################################################################
   $script:endpointService = "appliance"
   @("Backups", "MaintenanceSchedules", "NetworkInterfaces") | ForEach-Object {
     script:checkAllProperties $_
   }

   $script:completedSuccessfully = $true
}
catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error working with Filter Properties"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

