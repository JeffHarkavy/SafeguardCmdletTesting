try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running SPS Cluster Management Tests"
$blockInfo = testBlockHeader $TestBlockName
# N.B. Some cluster calls are covered in the "noparameters" test
# ===== Covered Commands =====
# Get-SafeguardSessionCluster
# Join-SafeguardSessionCluster
# Remove-SafeguardSessionSplitCluster
# Get-SafeguardSessionSplitCluster
# Set-SafeguardSessionCluster
# Split-SafeguardSessionCluster
# Disable-SafeguardSessionClusterAccessRequestBroker
# Disable-SafeguardSessionClusterAuditStream
# Enable-SafeguardSessionClusterAccessRequestBroker
# Enable-SafeguardSessionClusterAuditStream
# Get-SafeguardSessionClusterAccessRequestBroker
# Get-SafeguardSessionClusterAuditStream
#

$replicas = [System.Collections.ArrayList]@()
try {
   (Get-SafeguardSessionCluster) | Select-Object -Property Id,SpsNetworkAddress,SpsHostName
   if ((Get-SafeguardSessionCluster).Count -eq 0) {
      infoResult "Get-SafeguardSessionCluster" "No session appliances exist in this cluster."
      infoResult "Joining" "Attempting to join to SPS appliance $($DATA.clusterSession[0])"

      $joinresult = Join-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] -SessionUserName $DATA.SPSAdmin -SessionPassword $DATA.SPSAdminPassword
      goodResult "Join-SafeguardSessionCluster" "Successfully joined to SPS appliance at $($DATA.clusterSession[0])"
   } else {
      $sessionAppliances | Format-Table
      goodResult "Get-SafeguardSessionCluster" "Session Appliances retrieved"
   }

   $spsappliance = Set-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] -Description "Test Description for SPS"
   goodResult "Set-SafeguardSessionCluster" "Successfully updated SPS $($DATA.clusterSession[0]) Description to '$($spsappliance.Description)'"

   $broker = Get-SafeguardSessionClusterAccessRequestBroker
   goodResult "Get-SafeguardSessionClusterAccessRequestBroker" "Success - enabled=$($broker.Enabled)"

   if ($broker.Enabled) {
      Disable-SafeguardSessionClusterAccessRequestBroker > $null
      goodResult "Disable-SafeguardSessionClusterAccessRequestBroker" "Success"

      Enable-SafeguardSessionClusterAccessRequestBroker > $null
      goodResult "Enable-SafeguardSessionClusterAccessRequestBroker" "Success"
   } else {
      Enable-SafeguardSessionClusterAccessRequestBroker > $null
      goodResult "Enable-SafeguardSessionClusterAccessRequestBroker" "Success"

      Disable-SafeguardSessionClusterAccessRequestBroker > $null
      goodResult "Disable-SafeguardSessionClusterAccessRequestBroker" "Success"
   }

   $auditstream = Get-SafeguardSessionClusterAuditStream
   goodResult "Get-SafeguardSessionClusterAuditStream" "Success - enabled=$($auditstream.Enabled)"

   if ($auditstream.Enabled) {
      Disable-SafeguardSessionClusterAuditStream > $null
      goodResult "Disable-SafeguardSessionClusterAuditStream" "Success"

      Enable-SafeguardSessionClusterAuditStream > $null
      goodResult "Enable-SafeguardSessionClusterAuditStream" "Success"
   } else {
      Enable-SafeguardSessionClusterAuditStream > $null
      goodResult "Enable-SafeguardSessionClusterAuditStream" "Success"

      Disable-SafeguardSessionClusterAuditStream > $null
      goodResult "Disable-SafeguardSessionClusterAuditStream" "Success"
   }

   if ($joinResult) {
      Split-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] > $null
      goodResult "Split-SafeguardSessionCluster" "Successfully split from session cluster at $($DATA.clusterSession[0])"

      (Get-SafeguardSessionSplitCluster) | Select-Object -Property Id,SpsNetworkAddress,SpsHostName
      goodResult "Get-SafeguardSessionSplitCluster" "Successfully retrieved session split cluster information"

      $remove = Remove-SafeguardSessionSplitCluster -SessionMaster $DATA.clusterSession[0]
      goodResult "Remove-SafeguardSessionSplitCluster" "Successfully removed split SPS at $($DATA.clusterSession[0]) from session cluster"
   }

} catch {
   badResult "SPS Cluster Management general" "Unexpected error in SPS Cluster Management test" $_
} finally {
   #try { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } catch {}
}

testBlockHeader $TestBlockName $blockInfo

