try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

# TODO
#Sync-SafeguardUserGroupAuthenticationProvider

$GLOBALS.currentTest = $DATA.Tests.Identity
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:providerAdded = $false

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { if ($script:providerAdded) { Remove-SafeguardDirectoryIdentityProvider -DirectoryToDelete $DATA.domainName -ErrorAction SilentlyContinue > $NULL } } catch {}
}

try {
   if ($DATA.requiredDNS -ne "") {
      $x0 = Get-SafeguardNetworkInterface "X0"
      if ($x0.DnsServers -contains $DATA.requiredDNS) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardNetworkInterface"; message = "$($DATA.requiredDNS) already present in X0 DNS list"; })
      } else {
         try {
            Set-SafeguardNetworkInterface -Interface "X0" -DnsServers $(,$DATA.requiredDNS+$($x0.DnsServers))
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardNetworkInterface"; message = "$DATA.requiredDNS added to X0 DNS Servers"; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardNetworkInterface"; message = "Unexpected error setting DNS $DATA.requiredDNS on X0"; ex = $_; })
            throw $_.Exception
         }
      }
   }

   try {
      $identProvider = Get-SafeguardDirectoryIdentityProvider -DirectoryToGet $DATA.domainName
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDirectoryIdentityProvider"; message = "Identity provier $($DATA.domainName) already exists"; })
   } catch {
      if ($_.Exception.Message -match "unable to find") {
         $identProvider = New-SafeguardDirectoryIdentityProvider -ServiceAccountDomain $DATA.domainName -ServiceAccountName $DATA.domainAdmin -ServiceAccountPassword $DATA.domainPassword
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardDirectoryIdentityProvider"; message = "Successfully created identity provider $($DATA.domainName)"; })
         $script:providerAdded = $true
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDirectoryIdentityProvider"; message = "Unexpected error fetching provider $($DATA.domainName)"; ex = $_; })
         throw $_.Exception
      }
  }

  $identProvider = Edit-SafeguardDirectoryIdentityProvider -DirectoryToEdit $DATA.domainName -Description "Edited description for provider $($DATA.domainName)"
  if ($identProvider.Description -ne "") { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardDirectoryIdentityProvider"; message = "Successfully edited provider $($DATA.domainName)"; }) }
  else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardDirectoryIdentityProvider"; message = "Failed to edit provider $($DATA.domainName)"; }) }

  try {
     $identList = Get-SafeguardDirectoryIdentityProvider -DirectoryToGet $DATA.domainName
     $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDirectoryIdentityProvider"; message = "Successfully found provider $($DATA.domainName)"; })
  } catch {
     $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDirectoryIdentityProvider"; message = "Failed to find provider $($DATA.domainName)"; ex = $_; })
  }

  try {
     $provider = Get-SafeguardDirectoryIdentityProviderDomain -DirectoryToGet $DATA.domainName
     $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDirectoryIdentityProviderDomain"; message = "Successfully retrieved provider domain $($DATA.domainName)"; })
  } catch {
     $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDirectoryIdentityProviderDomain"; message = "Get provider domain failed $($DATA.domainName)"; ex = $_; })
  }

  try {
     $schema = Get-SafeguardDirectoryIdentityProviderSchemaMapping -DirectoryToGet $DATA.domainName -SchemaType User
     $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDirectoryIdentityProviderSchemaMapping"; message = "Successfully retrieved User schema for provider $($DATA.domainName)"; })
  } catch {
     $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardDirectoryIdentityProviderSchemaMapping"; message = "Retrieve of User schema failed provider $($DATA.domainName)"; ex = $_; })
  }

  try {
     $existingAttr = $schema.DescriptionAttribute
     $schema = Set-SafeguardDirectoryIdentityProviderSchemaMapping -DirectoryToGet $DATA.domainname -SchemaType User -SchemaMappingObj @{ DescriptionAttribute = "userPrincipalName" }
     if ($schema.DescriptionAttribute -eq "userPrincipalName") { 
        $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardDirectoryIdentityProviderSchemaMapping"; message = "Successfully edited User schema on provider $($DATA.domainname)"; })
        $schema = Set-SafeguardDirectoryIdentityProviderSchemaMapping -DirectoryToGet $DATA.domainname -SchemaType User -SchemaMappingObj @{ DescriptionAttribute = "$existingAttr" }
     }
     else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardDirectoryIdentityProviderSchemaMapping"; message = "User schema edit failed on provider $($DATA.domainName)"; }) }
  } catch {
     $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardDirectoryIdentityProviderSchemaMapping"; message = "Unexpected error editing User schema on provider $($DATA.domainName)"; ex = $_; })
  }

  try {
     Sync-SafeguardDirectoryIdentityProvider -DirectoryToSync $DATA.domainName > $NULL
     $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Sync-SafeguardDirectoryIdentityProvider"; message = "Successfully synced provider $($DATA.domainName)"; })
  } catch {
     $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Sync-SafeguardDirectoryIdentityProvider"; message = "Sync was unsuccessful on provider $($DATA.domainName)"; ex = $_; })
  }

  try {
     if ($script:providerAdded) {
        Remove-SafeguardDirectoryIdentityProvider -DirectoryToDelete $DATA.domainName > $null
        $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardDirectoryIdentityProvider"; message = "Successfully removed provider $($DATA.domainName)"; })
     } else {
        $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardDirectoryIdentityProvider"; message = "Existing provider $($DATA.domainName) NOT removed"; })
     }
  } catch {
     $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardDirectoryIdentityProvider"; message = "Unexpected error removing provider $($DATA.domainName)"; ex = $_; })
  }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Directory Identity Provider"; message = "Unexpected error in Directory test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

