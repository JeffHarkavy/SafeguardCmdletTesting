try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Access Requests Tests"
$blockInfo = testBlockHeader $TestBlockName
# TODO - stubbed code
# Get-SafeguardAccessRequestCheckoutPassword
# Revoke-SafeguardAccessRequest (no way to pass reason)
# Approve-SafeguardAccessRequest (no way to pass reason)
# Assert-SafeguardAccessRequest (aka, "Review". Srsly?) (no way to pass reason)
# Close-SafeguardAccessRequest (no way to pass reason)
# Copy-SafeguardAccessRequestPassword
# Deny-SafeguardAccessRequest (no way to pass reason)
# Edit-SafeguardAccessRequest
# Find-SafeguardAccessRequest
# Get-SafeguardAccessPolicyAccessRequestProperty
# Get-SafeguardAccessRequest
# Get-SafeguardAccessRequestActionLog
# Get-SafeguardAccessRequestPassword
# Get-SafeguardAccessRequestRdpFile
# Get-SafeguardAccessRequestRdpUrl
# Get-SafeguardAccessRequestSshUrl
# Get-SafeguardReportDailyAccessRequest
# Get-SafeguardSessionClusterAccessRequestBroker
# New-SafeguardAccessRequest (missing all SORTS of options!)
# Start-SafeguardAccessRequestSession
# Find-SafeguardMyRequestable
# Get-SafeguardMyRequestable
# Find-SafeguardRequestableAccount
# Get-SafeguardActionableRequest
# Get-SafeguardMyApproval
# Get-SafeguardMyRequest
# Get-SafeguardMyReview
# Get-SafeguardRequestableAccount
# Get-SafeguardAccessRequestSshHostKey - !$isLTS
# Get-SafeguardAccessRequestSshKey - !$isLTS

# ===== Covered Commands =====
#

try {
   # First need to set up the request worflow environment
   # - Req, Appr, Rev users
   # - an asset and some accounts
   # - SPS
   # - an entitlement and some access policies: pwd, session (RDP and SSH), ssh key
} catch {
   badResult "Access Requests general" "Unexpected error in Access Requests test" $_
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader $TestBlockName $blockInfo

