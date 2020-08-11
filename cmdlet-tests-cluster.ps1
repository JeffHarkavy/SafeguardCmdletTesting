try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Cluster Management Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# TODO - stubbed code
#Add-SafeguardClusterMember
#Disable-SafeguardSessionClusterAuditStream
#Enable-SafeguardClusterPrimary
#Enable-SafeguardSessionClusterAuditStream
#Get-SafeguardSessionCluster
#Get-SafeguardSessionClusterAuditStream
#Get-SafeguardSessionSplitCluster
#Invoke-SafeguardClusterPing
#Join-SafeguardSessionCluster
#Remove-SafeguardClusterMember
#Remove-SafeguardSessionSplitCluster
#Set-SafeguardClusterPrimary
#Set-SafeguardSessionCluster
#Split-SafeguardSessionCluster
#Unlock-SafeguardCluster

# N.B. Some cluster calls are covered in the "noparameters" test
# ===== Covered Commands =====
#

try {
} catch {
   badResult "Cluster Management general" "Unexpected error in Cluster Management test" $_.Exception
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo

