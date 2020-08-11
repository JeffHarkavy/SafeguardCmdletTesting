try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Entitlement and Access Policy Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
   # TODO - stubbed code
   #Get-SafeguardAccessCertificationEntitlement
   #Get-SafeguardEntitlement
   #New-SafeguardEntitlement
   #Remove-SafeguardEntitlement
   #
   #Find-SafeguardPolicyAccount
   #Find-SafeguardPolicyAsset
   #Get-SafeguardAccessPolicy
   #Get-SafeguardAccessPolicyScopeItem
   #Get-SafeguardAccessPolicySessionProperty
   #Get-SafeguardPolicyAccount
   #Get-SafeguardPolicyAsset
   #
   #$entitlement = Get-SafeguardEntitlement -EntitlementToGet "Entitlement"
   #$policy = Get-SafeguardAccessPolicy -PolicyToGet "EntitlementPolicy" -EntitlementToGet "Entitlement"
   #if ($null -eq $entitlement -or $null -eq $policy) {badResult "Couldn't get entitlement stuff",$null

# ===== Covered Commands =====
#

try {
} catch {
   badResult "Entitlement and Access Policy general" "Unexpected error in Entitlement and Access Policy test" $_.Exception
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo

