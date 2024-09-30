try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Session
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

# N.B. Some cluster calls are covered in the "noparameters" test
# TODO
#Clear-SafeguardSpsTransaction
#Close-SafeguardSpsTransaction
#Complete-SafeguardSpsWelcomeWizard
#Connect-SafeguardSps
#Disable-SafeguardSpsRemoteAccess
#Disable-SafeguardSpsSra
#Disconnect-SafeguardSps
#Enable-SafeguardSpsRemoteAccess
#Enable-SafeguardSpsSra
#Get-SafeguardSpsFirmwareSlot
#Get-SafeguardSpsInfo
#Get-SafeguardSpsSupportBundle
#Get-SafeguardSpsTransaction
#Get-SafeguardSpsVersion
#Get-SafeguardSpsWelcomeWizardStatus
#Import-SafeguardSpsFirmware
#Install-SafeguardSpsFirmware
#Install-SafeguardSpsUpgrade
#Invoke-SafeguardSpsMethod
#Invoke-SafeguardSpsStarlingJoinBrowser
#Open-SafeguardSpsTransaction
#Remove-SafeguardSpsStarlingJoin
#Save-SafeguardSpsTransaction
#Show-SafeguardSpsEndpoint
#Show-SafeguardSpsTransactionChange
#Test-SafeguardSpsFirmware

$replicas = [System.Collections.ArrayList]@()
try {
   (Get-SafeguardSessionCluster) | Select-Object -Property Id,SpsNetworkAddress,SpsHostName
   if ((Get-SafeguardSessionCluster).Count -eq 0) {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSessionCluster"; message = "No session appliances exist in this cluster."; })
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Joining"; message = "Attempting to join to SPS appliance $($DATA.clusterSession[0])"; })

      $joinresult = Join-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] -SessionUserName $DATA.SPSAdmin -SessionPassword $DATA.SPSAdminPassword
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Join-SafeguardSessionCluster"; message = "Successfully joined to SPS appliance at $($DATA.clusterSession[0])"; })
   } else {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSessionCluster"; message = "Session Appliances retrieved"; })
      $GLOBALS.formatTable(@{ output = $sessionAppliances; })
   }

   $spsappliance = Set-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] -Description "Test Description for SPS"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardSessionCluster"; message = "Successfully updated SPS $($DATA.clusterSession[0]) Description to '$($spsappliance.Description)'"; })

   $broker = Get-SafeguardSessionClusterAccessRequestBroker
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSessionClusterAccessRequestBroker"; message = "Success - enabled=$($broker.Enabled)"; })

   if ($broker.Enabled) {
      Disable-SafeguardSessionClusterAccessRequestBroker > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Disable-SafeguardSessionClusterAccessRequestBroker"; message = "Success"; })

      Enable-SafeguardSessionClusterAccessRequestBroker > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardSessionClusterAccessRequestBroker"; message = "Success"; })
   } else {
      Enable-SafeguardSessionClusterAccessRequestBroker > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardSessionClusterAccessRequestBroker"; message = "Success"; })

      Disable-SafeguardSessionClusterAccessRequestBroker > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Disable-SafeguardSessionClusterAccessRequestBroker"; message = "Success"; })
   }

   $auditstream = Get-SafeguardSessionClusterAuditStream
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSessionClusterAuditStream"; message = "Success - enabled=$($auditstream.Enabled)"; })

   if ($auditstream.Enabled) {
      Disable-SafeguardSessionClusterAuditStream > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Disable-SafeguardSessionClusterAuditStream"; message = "Success"; })

      Enable-SafeguardSessionClusterAuditStream > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardSessionClusterAuditStream"; message = "Success"; })
   } else {
      Enable-SafeguardSessionClusterAuditStream > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardSessionClusterAuditStream"; message = "Success"; })

      Disable-SafeguardSessionClusterAuditStream > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Disable-SafeguardSessionClusterAuditStream"; message = "Success"; })
   }

   if ($joinResult) {
      Split-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Split-SafeguardSessionCluster"; message = "Successfully split from session cluster at $($DATA.clusterSession[0])"; })

      (Get-SafeguardSessionSplitCluster) | Select-Object -Property Id,SpsNetworkAddress,SpsHostName
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSessionSplitCluster"; message = "Successfully retrieved session split cluster information"; })

      $remove = Remove-SafeguardSessionSplitCluster -SessionMaster $DATA.clusterSession[0]
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardSessionSplitCluster"; message = "Successfully removed split SPS at $($DATA.clusterSession[0]) from session cluster"; })
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "SPS Cluster Management general"; message = "Unexpected error in SPS Cluster Management test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   $GLOBALS.testBlockHeader($script:blockInfo)
}

