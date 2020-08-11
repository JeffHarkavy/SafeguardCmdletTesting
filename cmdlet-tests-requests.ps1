try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Access Requests Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
   # TODO - stubbed code
   #Get-SafeguardAccessRequestCheckoutPassword
   #Revoke-SafeguardAccessRequest
   #Approve-SafeguardAccessRequest
   #Assert-SafeguardAccessRequest
   #Close-SafeguardAccessRequest
   #Copy-SafeguardAccessRequestPassword
   #Deny-SafeguardAccessRequest
   #Disable-SafeguardSessionClusterAccessRequestBroker
   #Edit-SafeguardAccessRequest
   #Enable-SafeguardSessionClusterAccessRequestBroker
   #Find-SafeguardAccessRequest
   #Get-SafeguardAccessPolicyAccessRequestProperty
   #Get-SafeguardAccessRequest
   #Get-SafeguardAccessRequestActionLog
   #Get-SafeguardAccessRequestPassword
   #Get-SafeguardAccessRequestRdpFile
   #Get-SafeguardAccessRequestRdpUrl
   #Get-SafeguardAccessRequestSshUrl
   #Get-SafeguardReportDailyAccessRequest
   #Get-SafeguardSessionClusterAccessRequestBroker
   #New-SafeguardAccessRequest
   #Start-SafeguardAccessRequestSession
   #Find-SafeguardMyRequestable
   #Get-SafeguardMyRequestable
   #Find-SafeguardRequestableAccount
   #Get-SafeguardActionableRequest
   #Get-SafeguardArchiveServer
   #Get-SafeguardMyApproval
   #Get-SafeguardMyRequest
   #Get-SafeguardMyReview
   #Get-SafeguardRequestableAccount
   #Get-SafeguardAccessRequestSshHostKey - !$isLTS
   #Get-SafeguardAccessRequestSshKey - !$isLTS

# ===== Covered Commands =====
#

try {
} catch {
   badResult "Access Requests general" "Unexpected error in Access Requests test" $_.Exception
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo

