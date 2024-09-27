try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Entitlement
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

# TODO - stubbed code
# Get-SafeguardAccessPolicySessionProperty

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Remove-SafeguardEntitlement -EntitlementToDelete "$($DATA.entitlementName)" -ErrorAction SilentlyContinue > $null } catch {}
   try { Remove-SafeguardAsset -AssetToDelete "$($DATA.assetName)" -ErrorAction SilentlyContinue > $null } catch {}
}

try {
   $entUser = $GLOBALS.createUser($DATA.userUserName).newUser

   try {
      Get-SafeguardEntitlement -EntitlementToGet $DATA.entitlementName > $null
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardEntitlement"; message = "Entitlement $($entitlement.Name) already exists. Resetting for test."; })
      Remove-SafeguardEntitlement -EntitlementToDelete "$($DATA.entitlementName)" > $null
   } catch {
   }
   $entitlement = New-SafeguardEntitlement -Name "$($DATA.entitlementName)" -MemberUsers "$($entUser.Name)"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardEntitlement"; message = "Successfully created entitlement $($entitlement.Name)"; })

   $entitlement = Get-SafeguardEntitlement -EntitlementToGet $DATA.entitlementName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardEntitlement"; message = "Successfully retrieved entitlement $($entitlement.Name)"; })

   $asset = Find-SafeguardAsset $DATA.assetName
   if ($asset) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAsset"; message = "found $($DATA.assetName)"; }) }
   else {
      $asset = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
         -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
         -AcceptSshHostKey
   }
   try {
      foreach ($acctname in $DATA.assetAccounts.GetEnumerator()) {
         $found = Find-SafeguardAssetAccount -QueryFilter "Asset.Name eq '$($DATA.assetName)' and Name eq '$acctname'"
         if ($found) { $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardDirectoryAccount"; message = "$acctname already exists on $($DATA.assetName)"; }) }
         else {
            try {
               $newacct = New-SafeguardAssetAccount -ParentAsset $DATA.assetName -NewAccountName $acctname
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAssetAccount"; message = "$acctName successfully created on $($DATA.assetName)"; })
            } catch {
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardAssetAccount"; message = "Unexpected error creating $acctName on $($DATA.assetName)"; ex = $_; })
            }
         }
      }
   }
   catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Unexpected error creating Asset Accounts on $($DATA.assetName)" ; ex = $_; })
      throw $_
   }

   $local:jsonAccountScopes = (Get-SafeguardAssetAccount -AssetToGet $asset) | Where {$_.Name -match 'user_'} | ForEach { @{ ScopeItemType = "Account"; Id = $_.id; } } | ConvertTo-Json -Compress
   $policyBody = $DATA.accessPolicyBodyString.Password.Replace("#ENTITLEMENT_ID#", $entitlement.Id)
   $policyBody = $policyBody.Replace("#SCOPE_ITEMS#", $local:jsonAccountScopes)
   $policyBody = $policyBody.Replace("#CONNECTION_MODULE#", '')
   $policyBody = $policyBody.Replace("#CONNECTION_POLICY#", '')
   $convertedJson = ConvertFrom-Json $policyBody
   $accessPolicy = Invoke-SafeguardMethod Core Post AccessPolicies -Body $convertedJson
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardMethod"; message = "Successfully added policy to entitlement $($DATA.entitlementName)"; })

   $result = Get-SafeguardAccessPolicy -EntitlementToGet $DATA.entitlementName -PolicyToGet $accessPolicy.Name
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicy"; message = "Successfully retrieved entitlement $($DATA.entitlementName) policy $($accessPolicy.Name)"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $result = Get-SafeguardPolicyAccount -AssetToGet $DATA.assetName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardPolicyAccount"; message = "Successfully retrieved account policy"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $result = Get-SafeguardPolicyAsset -AssetToGet $DATA.assetName
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardPolicyAsset"; message = "Successfully retrieved asset policy"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $result = Get-SafeguardAccessPolicyAccessRequestProperty -PolicyToGet $accessPolicy.Id
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicyAccessRequestProperty"; message = "Successfully retrieved access request policy properties"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $result = Get-SafeguardAccessPolicySessionProperty -PolicyToGet $accessPolicy.Id
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicySessionProperty"; message = "Successfully retrieved access request policy properties"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $acctPolicy = Find-SafeguardPolicyAccount $DATA.assetAccounts[0]
   if ($acctPolicy) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardPolicyAccount"; message = "Found policy $($acctPolicy.Name) for account $($DATA.assetAccounts[0])"; }) }
   else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardPolicyAccount"; message = "Failed to find policy $($acctPolicy.Name) for account $($DATA.assetAccounts[0])"; }) }

   $assetPolicy = Find-SafeguardPolicyAsset $DATA.assetName
   if ($assetPolicy) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardPolicyAsset"; message = "Found policy $($acctPolicy.Name) for account $($DATA.assetName)"; }) }
   else { $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Find-SafeguardPolicyAsset"; message = "Failed to find policy $($acctPolicy.Name) for account $($DATA.assetName)"; }) }

   $result = Get-SafeguardAccessPolicyScopeItem -PolicyToGet $accessPolicy.Name
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicyScopeItem"; message = "Successfully retrieved policy $($accessPolicy.Name)"; })
   $GLOBALS.formatTable(@{ output = $result; })

   Remove-SafeguardEntitlement -EntitlementToDelete "$($DATA.entitlementName)" > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardEntitlement"; message = "Successfully removed entitlement $($DATA.entitlementName)"; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Entitlement and Access Policy general"; message = "Unexpected error in Entitlement and Access Policy test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   #script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

