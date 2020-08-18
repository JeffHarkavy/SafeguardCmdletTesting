try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Cluster Management Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# N.B. Some cluster calls are covered in the "noparameters" test
#
# ===== Covered Commands =====
# Add-SafeguardClusterMember
# Invoke-SafeguardClusterPing
# Invoke-SafeguardClusterThroughput
# Remove-SafeguardClusterMember
# Enable-SafeguardClusterPrimary
# Set-SafeguardClusterPrimary
# Unlock-SafeguardCluster
#

$replicas = [System.Collections.ArrayList]@()
try {
   $nope = 0
   $primaryVersion = formatSgVersion $sgVersion
   $cluster = Get-SafeguardClusterMember

   foreach ($repl in $DATA.clusterReplicas) {
      $replToken = sgConnect $repl $true
      goodResult "Connect-Safeguard" "Successful access token received for $($DATA.clusterReplicas[0])"

      # Versions need to match and vm/hw
      $version = Get-SafeguardVersion -Appliance $repl -Insecure
      $replVersion = formatSgVersion $version
      $vm = $knownVMTypes -contains $version.BuildPlatform
      if ($replVersion -eq $primaryVersion -and $isVM -eq $vm) {
         goodResult "Get-SafeguardVersion" "Future replica $repl version $replVersion matches appliance version and platform type"
      } else {
         badResult "Get-SafeguardVersion" "Future replica $repl version is $replVersion $(iif $vm "VM" "hardware"), appliance version is $primaryVersion $(iif $isVM "VM" "hardware")"
         $nope = 1
      }
      $joined = 0
      if (($cluster | Where-Object { $_.Ipv4Address -eq $repl })) {
         infoResult "Cluster Member" "$repl is already member of the cluster"
         $joined = 2
      }
      $replicas.Add(@{address=$repl;joined=$joined}) > $null
   }
   if ($nope) {
      throw "Version mismatch between primary and one or more future replicas"
   }

   $appliancesToJoin = ($replicas | Where-Object {$_.joined -eq 0})
   if ($appliancesToJoin) {
      infoResult "Add-SafeguardClusterMember" "Attempting to join $($appliancesToJoin.Count) appliances. This may take a while."

      foreach ($repl in $appliancesToJoin) {
         # yeah, we just got a token above but since the replicas are not being joined in parallel
         # there's the chance the old token might have expired by the time we get to the 2nd
         # or later replica
         $replToken = sgConnect $repl $true

         $joinInfo = Add-SafeguardClusterMember -ReplicaNetworkAddress $repl.address -ReplicaAccessToken $replToken
         goodResult "Add-SafeguardClusterMember" "Successfully added $($repl.address) as a replica"
         $repl.joined += 1
      }
   }

   # Out-String added because of a Powershell "feature" that tries to optimize output
   # of the follwing 2 commands when run in a script. W/o it the 2nd command will drop
   # any columns that are not also present in the first.
   # And by "feature" i really mean "<expletiving> bug that just wasted 3 hours of my time"
   Invoke-SafeguardClusterPing | Select-Object -Property * -ExcludeProperty *Id | Out-String
   goodResult "Invoke-SafeguardClusterPing" "Successfully pinged cluster"
   
   Invoke-SafeguardClusterThroughput -Megabytes 10 | Select-Object -Property * -ExcludeProperty *Id | Out-String
   goodResult "Invoke-SafeguardClusterThroughput" "Successfully checked cluster throughput"

   try {
      Enable-SafeguardClusterPrimary > $null
      goodResult "Enable-SafeguardClusterPrimary" "Successfully enabled cluster"
   } catch {
      if ($_ -match "This action cannot be performed in the current appliance state") {
         goodResult "Enable-SafeguardClusterPrimary" "Successful but does not apply to current appliance state"
      } else {
         badResult "Enable-SafeguardClusterPrimary" "Unexpected error" $_
      }
   }

   try {
      Set-SafeguardClusterPrimary -Member $DATA.appliance > $null
   } catch {
      if ($_ -match "Cannot failover to the Primary appliance") {
         goodResult "Set-SafeguardClusterPrimary" "Successful but cannot failover to the Primary appliance"
      } else {
         badResult "Set-SafeguardClusterPrimary" "Unexpected error" $_
      }
   }

   Unlock-SafeguardCluster
   goodResult "Unlock-SafeguardCluster" "Successfully called"

   $members = ((Get-SafeguardClusterMember) | Where-Object {$_.IsLeader -eq $false})
   if ($members) {
      infoResult "Remove-SafeguardClusterMember" "$($members.Count) replicas exist. Enter Y to remove all of them from the cluster"
      if("Y" -eq (Read-Host "Enter Y to remove all replicas")) {
         foreach ($repl in $members) {
            try {
               infoResult "Remove-SafeguardClusterMember" "Attempting to remove $($repl.ipv4Address) from cluster"
               Remove-SafeguardClusterMember -Member $repl.Ipv4Address
               goodResult "Remove-SafeguardClusterMember" "Successfully removed $($repl.Ipv4Address) from the cluster"
            } catch {
               badResult "Remove-SafeguardClusterMember" "Removal of $($repl.Ipv4Address) from cluster failed" $_
            }
         }
      } else {
         infoResult "Remove-SafeguardClusterMember" "Call was NOT tested"
      }
   }
   
} catch {
   badResult "Cluster Management general" "Unexpected error in Cluster Management test" $_
} finally {
   #try { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo

