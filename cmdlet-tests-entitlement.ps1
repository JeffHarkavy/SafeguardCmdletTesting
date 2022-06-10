try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Entitlement and Access Policy Tests"
$blockInfo = testBlockHeader $TestBlockName
# TODO - stubbed code
# Get-SafeguardAccessPolicySessionProperty

# ===== Covered Commands =====
# Get-SafeguardEntitlement
# New-SafeguardEntitlement
# Remove-SafeguardEntitlement
# Get-SafeguardAccessPolicy
# Get-SafeguardPolicyAccount
# Get-SafeguardPolicyAsset
# Find-SafeguardPolicyAccount
# Find-SafeguardPolicyAsset
# Get-SafeguardAccessPolicyScopeItem
#

try {
   $entUser = createUser $DATA.userUserName

   $entitlement = New-SafeguardEntitlement -Name "$($DATA.entitlementName)" -MemberUsers "$($entUser.Name)"
   goodResult "New-SafeguardEntitlement" "Successfully created entitlement $($entitlement.Name)"

   $entitlement = Get-SafeguardEntitlement -EntitlementToGet $DATA.entitlementName
   goodResult "Get-SafeguardEntitlement" "Successfully retrieved entitlement $($entitlement.Name)"

   $asset = Find-SafeguardAsset $DATA.assetName
   if ($asset) { goodResult "Find-SafeguardAsset" "found $($DATA.assetName)" }
   else {
      $asset = New-SafeguardAsset -DisplayName "$($DATA.assetName)" -Platform $DATA.assetPlatform -NetworkAddress $DATA.assetIpAddress `
         -ServiceAccountCredentialType Password -ServiceAccountName $DATA.assetServiceAccount -ServiceAccountPassword $DATA.assetServiceAccountPassword `
         -AcceptSshHostKey
   }
   try {
      foreach ($acctname in $DATA.assetAccounts.GetEnumerator()) {
         $found = Find-SafeguardAssetAccount -QueryFilter "Asset.Name eq '$($DATA.assetName)' and Name eq '$acctname'"
         if ($found) { infoResult "New-SafeguardDirectoryAccount" "$acctname already exists on $($DATA.assetName)" }
         else {
            try {
               $newacct = New-SafeguardAssetAccount -ParentAsset $DATA.assetName -NewAccountName $acctname
               goodResult "New-SafeguardAssetAccount" "$acctName successfully created on $($DATA.assetName)"
            } catch {
               badResult "New-SafeguardAssetAccount" "Unexpected error creating $acctName on $($DATA.assetName)" $_
            }
         }
      }
   }
   catch {
      badResult "general" "Unexpected error creating Asset Accounts on $($DATA.assetName)"  $_
      throw $_
   }

   $newPolicy = @{ Name = "$($DATA.accessPolicy)";
       Description = "Test Access Policy Description";
       RoleId = $entitlement.Id;
       Priority = 2;
       AccessRequestProperties = @{
         AccessRequestType = "Password";
         AllowSimultaneousAccess = $false;
         MaximumSimultaneousReleases = 1;
         ChangePasswordAfterCheckin = $true;
         AllowSessionPasswordRelease = $false;
         SessionAccessAccountType = "None";
         SessionAccessAccounts = @();
         TerminateExpiredSessions = $false;
         AllowLinkedAccountPasswordAccess = $false
       };
       ApproverProperties = @{
         RequireApproval = $false;
       };
       ScopeItems = @(
          @{
             Id = 0;
             ScopeItemType = "Account";
             Account = @{SystemName="$($DATA.assetName)"; Name="$($DATA.assetAccounts[0])"};
          },
          @{
             Id = 0;
             ScopeItemType = "Account";
             Account = @{SystemName="$($DATA.assetName)"; Name="$($DATA.assetAccounts[1])"};
          }
       );
   }   
   $output = Invoke-SafeguardMethod Core POST AccessPolicies -Body $newPolicy
   goodResult "Invoke-SafeguardMethod" "Successfully added policy to entitlement $($DATA.entitlementName)"

   Get-SafeguardAccessPolicy -EntitlementToGet $DATA.entitlementName -PolicyToGet $DATA.accessPolicy | Format-Table
   goodResult "Get-SafeguardAccessPolicy" "Successfully retrieved entitlement $($DATA.entitlementName) policy $($DATA.accessPolicy)"

   Get-SafeguardPolicyAccount -AssetToGet $DATA.assetName | format-table
   goodResult "Get-SafeguardAccessPolicy" "Successfully retrieved account policy"

   Get-SafeguardPolicyAsset -AssetToGet $DATA.assetName | format-table
   goodResult "Get-SafeguardPolicyAsset" "Successfully retrieved asset policy"

   $acctPolicy = Find-SafeguardPolicyAccount $DATA.assetAccounts[0]
   if ($acctPolicy) { goodResult "Find-SafeguardPolicyAccount" "Found policy $($acctPolicy.Name) for account $($DATA.assetAccounts[0])" }
   else { badResult "Find-SafeguardPolicyAccount" "Failed to find policy $($acctPolicy.Name) for account $($DATA.assetAccounts[0])" }

   $assetPolicy = Find-SafeguardPolicyAsset $DATA.assetName
   if ($assetPolicy) { goodResult "Find-SafeguardPolicyAsset" "Found policy $($acctPolicy.Name) for account $($DATA.assetName)" }
   else { badResult "Find-SafeguardPolicyAsset" "Failed to find policy $($acctPolicy.Name) for account $($DATA.assetName)" }

   Get-SafeguardAccessPolicyScopeItem -PolicyToGet $DATA.accessPolicy | Format-Table
   goodResult "Get-SafeguardAccessPolicyScopeItem" "Successfully retrieved policy $($DATA.accessPolicy)"

   Remove-SafeguardEntitlement -EntitlementToDelete "$($DATA.entitlementName)" > $null
   goodResult "Remove-SafeguardEntitlement" "Successfully removed entitlement $($DATA.entitlementName)"
} catch {
   badResult "Entitlement and Access Policy general" "Unexpected error in Entitlement and Access Policy test" $_
} finally {
   try { Remove-SafeguardEntitlement -EntitlementToDelete "$($DATA.entitlementName)" > $null } catch {}
   try { Remove-SafeguardAsset -AssetToDelete "$($DATA.assetName)" > $null } catch {}
}

testBlockHeader $TestBlockName $blockInfo

