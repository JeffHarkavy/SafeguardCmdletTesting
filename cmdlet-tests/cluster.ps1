try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Cluster
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:savedcolors = $GLOBALS.setProgressBarColors()
$script:replicas = @()

# N.B. Some cluster calls are covered in the "noparameters" test
# TODO
# Clear-SafeguardClusterOperation

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   $GLOBALS.setProgressBarColors($script:savedcolors)
}

try {
   $nope = 0
   $primaryVersion = $GLOBALS.formatSgVersion($sgVersion)
   $cluster = Get-SafeguardClusterMember

   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Connect-Safeguard"; message = "Attempting to connect to replicas ($($DATA.clusterReplicas -join ', '))"; })
   foreach ($repl in $DATA.clusterReplicas) {
      $replToken = $GLOBALS.sgConnect($repl, $null, $true)
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Connect-Safeguard"; message = "Successful access token received for $($DATA.clusterReplicas[0])"; })

      # Versions need to match and vm/hw
      $version = Get-SafeguardVersion -Appliance $repl -Insecure
      $replVersion = $GLOBALS.formatSgVersion($version)
      $vm = $knownVMTypes -contains $version.BuildPlatform
      if ($replVersion -eq $primaryVersion -and $isVM -eq $vm) {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardVersion"; message = "Future replica $repl version $replVersion matches appliance version and platform type"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardVersion"; message = "Future replica $repl version is $replVersion $(iif $vm "VM" "hardware"), appliance version is $primaryVersion $(iif $isVM "VM" "hardware")"; })
         $nope = 1
      }
      $joined = 0
      if (($cluster | Where-Object { $_.Ipv4Address -eq $repl })) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Cluster Member"; message = "$repl is already member of the cluster"; })
         $joined = 2
      }
      $script:replicas += @{ address = $repl; joined = $joined; }
   }
   if ($nope) {
      throw "Version mismatch between primary and one or more future replicas"
   }

   $appliancesToJoin = ($script:replicas | Where-Object {$_.joined -eq 0})
   if ($appliancesToJoin) {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Add-SafeguardClusterMember"; message = "Attempting to join $($appliancesToJoin.Count) appliances. This may take a while."; })

      foreach ($repl in $appliancesToJoin) {
         # yeah, we just got a token above but since the replicas are not being joined in parallel
         # there's the chance the old token might have expired by the time we get to the 2nd
         # or later replica
         $replToken = $GLOBALS.sgConnect($repl.address, $null, $true)

         # Even though the connect was just done w/ -Insecure apparently we need to add it here, too?
         $timing = @{ startTime = (Get-Date); }
         try {
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Add-SafeguardClusterMember"; message = "Attempting to add $($repl.ipv4Address) from cluster (%time%)"; })
            $joinInfo = Add-SafeguardClusterMember -ReplicaNetworkAddress $repl.address -ReplicaAccessToken $replToken -Insecure
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Add-SafeguardClusterMember"; message = "Successfully added $($repl.address) as a replica"; timing = $timing; })
            $GLOBALS.formatTable(@{ output = $joinInfo; })
            $repl.joined += 1
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Add-SafeguardClusterMember"; message = "Cluster join $($repl.address) as a replica failed"; timing = $timing; })
         }
      }
   } else {
      $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Add-SafeguardClusterMember"; message = "Appliances already joined to cluster"; skipCount = (2 - $appliancesToJoin.Count); })
   }

   $result = Invoke-SafeguardClusterPing | Select-Object -Property * -ExcludeProperty *Id
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardClusterPing"; message = "Successfully pinged cluster"; })
   $GLOBALS.formatTable(@{ output = $result; })
   
   $result = Invoke-SafeguardClusterThroughput -Megabytes 10 | Select-Object -Property * -ExcludeProperty *Id
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardClusterThroughput"; message = "Successfully checked cluster throughput"; })
   $GLOBALS.formatTable(@{ output = $result; })

   try {
      Enable-SafeguardClusterPrimary > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardClusterPrimary"; message = "Successfully enabled cluster"; })
   } catch {
      if ($_ -match "This action cannot be performed in the current appliance state") {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardClusterPrimary"; message = "Successful but does not apply to current appliance state"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Enable-SafeguardClusterPrimary"; message = "Unexpected error"; ex = $_; })
      }
   }

   try {
      Set-SafeguardClusterPrimary -Member $DATA.appliance > $null
   } catch {
      if ($_ -match "Cannot failover to the Primary appliance") {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardClusterPrimary"; message = "Successful but cannot failover to the Primary appliance"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardClusterPrimary"; message = "Unexpected error"; ex = $_; })
      }
   }

   Unlock-SafeguardCluster
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Unlock-SafeguardCluster"; message = "Successfully called"; })

   $members = ((Get-SafeguardClusterMember) | Where-Object {$_.IsLeader -eq $false})
   if ($members) {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardClusterMember"; message = "$($members.Count) replicas exist. Enter Y to remove all of them from the cluster"; })
      if("Y" -eq (Read-Host "Enter Y to remove all replicas")) {
         foreach ($repl in $members) {
            try {
               $timing = @{ startTime = (Get-Date); }
               $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardClusterMember"; message = "Attempting to remove $($repl.ipv4Address) from cluster (%time%)"; })
               Remove-SafeguardClusterMember -Member $repl.Ipv4Address
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardClusterMember"; message = "Successfully removed $($repl.Ipv4Address) from the cluster"; timing = $timing; })
            } catch {
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Remove-SafeguardClusterMember"; message = "Removal of $($repl.Ipv4Address) from cluster failed"; timing = $timing; ex = $_; })
            }
         }
      } else {
         $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardClusterMember"; message = "Call was NOT tested"; skipCount = 2; })
      }
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Cluster Management general"; message = "Unexpected error in Cluster Management test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup
   
   $GLOBALS.testBlockHeader($script:blockInfo)
}

