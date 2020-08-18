try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Identity Provider Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# ===== Covered Commands =====
# Edit-SafeguardDirectoryIdentityProvider
# Get-SafeguardDirectoryIdentityProvider
# Get-SafeguardDirectoryIdentityProviderDomain
# Get-SafeguardDirectoryIdentityProviderSchemaMapping
# New-SafeguardDirectoryIdentityProvider
# Set-SafeguardDirectoryIdentityProviderSchemaMapping
# Remove-SafeguardDirectoryIdentityProvider
# Sync-SafeguardDirectoryIdentityProvider
#

$providerAdded = 0
try {
   if ($DATA.requiredDNS -ne "") {
      $x0 = Get-SafeguardNetworkInterface "X0"
      if ($x0.DnsServers -contains $DATA.requiredDNS) {
         infoResult "Set-SafeguardNetworkInterface" "$($DATA.requiredDNS) already present in X0 DNS list"
      } else {
         try {
            Set-SafeguardNetworkInterface -Interface "X0" -DnsServers $(,$DATA.requiredDNS+$($x0.DnsServers))
            goodResult "Set-SafeguardNetworkInterface" "$DATA.requiredDNS added to X0 DNS Servers"
         } catch {
            badResult "Set-SafeguardNetworkInterface" "Unexpected error setting DNS $DATA.requiredDNS on X0" $_
            throw $_.Exception
         }
      }
   }

   try {
      $identProvider = Get-SafeguardDirectoryIdentityProvider -DirectoryToGet $DATA.domainName
      infoResult "Get-SafeguardDirectoryIdentityProvider" "Identity provier $($DATA.domainName) already exists"
   } catch {
      if ($_.Exception.Message -match "unable to find") {
         $identProvider = New-SafeguardDirectoryIdentityProvider -ServiceAccountDomain $DATA.domainName -ServiceAccountName $DATA.domainAdmin -ServiceAccountPassword $DATA.domainPassword
         goodResult "New-SafeguardDirectoryIdentityProvider" "Successfully created identity provider $($DATA.domainName)"
         $providerAdded = 1
      } else {
         badResult "Get-SafeguardDirectoryIdentityProvider" "Unexpected error fetching provider $($DATA.domainName)" $_
         throw $_.Exception
      }
  }

  $identProvider = Edit-SafeguardDirectoryIdentityProvider -DirectoryToEdit $DATA.domainName -Description "Edited description for provider $($DATA.domainName)"
  if ($identProvider.Description -ne "") { goodResult "Edit-SafeguardDirectoryIdentityProvider" "Successfully edited provider $($DATA.domainName)" }
  else { badResult "Edit-SafeguardDirectoryIdentityProvider" "Failed to edit provider $($DATA.domainName)" }

  try {
     $identList = Get-SafeguardDirectoryIdentityProvider -DirectoryToGet $DATA.domainName
     goodResult "Get-SafeguardDirectoryIdentityProvider" "Successfully found provider $($DATA.domainName)"
  } catch {
     badResult "Get-SafeguardDirectoryIdentityProvider" "Failed to find provider $($DATA.domainName)" $_
  }

  try {
     $provider = Get-SafeguardDirectoryIdentityProviderDomain -DirectoryToGet $DATA.domainName
     goodResult "Get-SafeguardDirectoryIdentityProviderDomain" "Successfully retrieved provider domain $($DATA.domainName)"
  } catch {
     badResult "Get-SafeguardDirectoryIdentityProviderDomain" "Get provider domain failed $($DATA.domainName)" $_
  }

  try {
     $schema = Get-SafeguardDirectoryIdentityProviderSchemaMapping -DirectoryToGet $DATA.domainName -SchemaType User
     goodResult "Get-SafeguardDirectoryIdentityProviderSchemaMapping" "Successfully retrieved User schema for provider $($DATA.domainName)"
  } catch {
     badResult "Get-SafeguardDirectoryIdentityProviderSchemaMapping" "Retrieve of User schema failed provider $($DATA.domainName)" $_
  }

  try {
     $existingAttr = $schema.DescriptionAttribute
     $schema = Set-SafeguardDirectoryIdentityProviderSchemaMapping -DirectoryToGet $DATA.domainname -SchemaType User -SchemaMappingObj @{ DescriptionAttribute = "userPrincipalName" }
     if ($schema.DescriptionAttribute -eq "userPrincipalName") { 
        goodResult "Set-SafeguardDirectoryIdentityProviderSchemaMapping" "Successfully edited User schema on provider $($DATA.domainname)"
        $schema = Set-SafeguardDirectoryIdentityProviderSchemaMapping -DirectoryToGet $DATA.domainname -SchemaType User -SchemaMappingObj @{ DescriptionAttribute = "$existingAttr" }
     }
     else { badResult "Set-SafeguardDirectoryIdentityProviderSchemaMapping" "User schema edit failed on provider $($DATA.domainName)" }
  } catch {
     badResult "Set-SafeguardDirectoryIdentityProviderSchemaMapping" "Unexpected error editing User schema on provider $($DATA.domainName)" $_
  }

  try {
     Sync-SafeguardDirectoryIdentityProvider -DirectoryToSync $DATA.domainName > $NULL
     goodResult "Sync-SafeguardDirectoryIdentityProvider" "Successfully synced provider $($DATA.domainName)"
  } catch {
     badResult "Sync-SafeguardDirectoryIdentityProvider" "Sync was unsuccessful on provider $($DATA.domainName)" $_
  }

  try {
     if ($providerAdded -eq 1 ) {
        Remove-SafeguardDirectoryIdentityProvider -DirectoryToDelete $DATA.domainName > $null
        goodResult "Remove-SafeguardDirectoryIdentityProvider" "Successfully removed provider $($DATA.domainName)"
     } else {
        infoResult "Remove-SafeguardDirectoryIdentityProvider" "Existing provider $($DATA.domainName) NOT removed"
     }
  } catch {
     badResult "Remove-SafeguardDirectoryIdentityProvider" "Unexpected error removing provider $($DATA.domainName)" $_
  }
} catch {
      badResult "Directory Identity Provider" "Unexpected error in Directory test" $_
} finally {
   try { if ($providerAdded -eq 1) { Remove-SafeguardDirectoryIdentityProvider -DirectoryToDelete $DATA.domainName > $NULL } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo
