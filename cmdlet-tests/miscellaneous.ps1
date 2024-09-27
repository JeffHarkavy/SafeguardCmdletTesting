try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Miscellaneous
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

# TODO - stubbed code
#Set-SafeguardApplianceDnsSuffix
#Test-SafeguardAuditLogArchive
#Open-CsvInExcel

try {
   ###############################################################################
   $GLOBALS.writeCallHeader("Reason Codes")
   ###############################################################################
   try {
      $output = Invoke-SafeguardMethod Core POST ReasonCodes -Body @{ Name = "RN12345"; Description = "Routine maintenance." }
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardMethod"; message = "Successfuly created reasonCode Id=$($output.Id)"; })

      Invoke-SafeguardMethod Core DELETE ReasonCodes/$($output.Id) > $null
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardMethod"; message = "Successfuly removed reasonCode Id=$($output.Id)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Invoke-Safegaurdmethod general"; message = "Unexpected error"; ex = $_; })
   }

   ###############################################################################
   $GLOBALS.writeCallHeader("Network Interface DNS")
   ###############################################################################
   try {
      $x0 = Get-SafeguardNetworkInterface -Interface "x0"
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardNetworkInterface"; message = "Existing DNSServers for x0=$($x0.DnsServers -join ' ')"; })

      $setX0 = Set-SafeguardNetworkInterface -Interface "x0" -DnsServers @("10.1.1.37","10.1.1.10")
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardNetworkInterface"; message = "Successfuly edited X0.DnsServers=$($setX0.DnsServers -join ' ')"; })

      $setX0 = Set-SafeguardNetworkInterface -Interface "x0" -DnsServers $x0.DnsServers
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardNetworkInterface"; message = "Reset DNSServers for x0=$($x0.DnsServers -join ' ')"; })

      $x0Dns = Get-SafeguardDnsSuffix
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardNetworkInterface"; message = "Existing DnsSuffixes for x0=$($x0Dns.DomainNames -join ' ')"; })

      $setX0Dns = Set-SafeguardDnsSuffix -DnsSuffixes @("foo.com","bar.com")
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardDnsSuffix"; message = "Successfuly edited X0 DnsSuffixes=$($setX0Dns.DomainNames -join ' ')"; })

      $setX0Dns = Set-SafeguardDnsSuffix -DnsSuffixes "$($x0Dns.DomainNames)"
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardDnsSuffix"; message = "Successfuly reset X0 DnsSuffixes=$($setX0Dns.DomainNames -join ' ')"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Network Interface general"; message = "Unexpected error"; ex = $_; })
   }

   ###############################################################################
   $GLOBALS.writeCallHeader("Appliance Name")
   ###############################################################################
   try {
      $currentApplianceName = Get-SafeguardApplianceName
      Set-SafeguardApplianceName -Name "THIS IS A TEST" > $null
      $editedApplianceName = Get-SafeguardApplianceName
      if ($editedApplianceName -eq "THIS IS A TEST") {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardApplianceName"; message = "successfully changed name to $editedApplianceName"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardApplianceName"; message = "Appliance name edit was NOT successful"; })
      }

      Set-SafeguardApplianceName -Name "$currentApplianceName" > $null
      if ((Get-SafeguardApplianceName) -eq $currentApplianceName) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardApplianceName"; message = "successfully reverted name to $currentApplianceName"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardApplianceName"; message = "Appliance name edit was NOT successful"; })
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Appliance Name general"; message = "Unexpected error in edit appliance name"; ex = $_; })
   }

   ###############################################################################
   $GLOBALS.writeCallHeader("Licensing")
   ###############################################################################
   try {
      $licenseKey = (Get-SafeguardLicense).Key
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardLicense"; message = "Retrieved license key $licenseKey"; })

      if ($licenseKey) {
         Uninstall-SafeguardLicense $licenseKey > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Uninstall-SafeguardLicense"; message = "Successfully uninstalled license $licenseKey"; })
      } else {
         $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Uninstall-SafeguardLicense"; message = "Skipped - no license retrieved to uninstall"; })
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Licensing general"; message = "Unexpected error in licensing"; ex = $_; })
   }
   try {
      $newLicense = Install-SafeguardLicense -LicenseFile "$($DATA.licenseFiles.v7)"
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Install-SafeguardLicense"; message = "v7 license file should not be accepted $($newLicense.Key)"; })
   } catch {
      $GLOBALS.goodResult(@{ minVerbosity = 0; cmd = "Licensing install"; message = "Version 7 license file rejected correctly"; extra = $_; })
   }
   try {
      $newLicense = Install-SafeguardLicense -LicenseFile "$($DATA.licenseFiles.v8)"
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Install-SafeguardLicense"; message = "Successfully installed Version 8 license $($newLicense.Key)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Licensing install"; message = "Unexpected error in licensing (Version 8)"; ex = $_; })
   }
   try {
      $newLicense = Install-SafeguardLicense -LicenseFile "$($DATA.licenseFiles.v8EnterpriseVault)"
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Install-SafeguardLicense"; message = "Successfully installed Version 8 Enterprise Vault license $($newLicense.Key)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Licensing install"; message = "Unexpected error in licensing (Version 8 Enterprise Vault)"; ex = $_; })
   }
   try {
      $local:results = Confirm-SafeguardStaAcceptance
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Confirm-SafeguardStaAcceptance"; message = "Successfully accepted STA"; })
      $GLOBALS.formatTable(@{ output = $local:results; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Confirm-SafeguardStaAcceptance"; message = "Unexpected error accepting STA"; ex = $_; })
   }


   ###############################################################################
   $GLOBALS.writeCallHeader("Archive Server")
   ###############################################################################
   try {
      $archiveServer = New-SafeguardArchiveServer -DisplayName $DATA.realArchiveServer.archSrvName `
        -NetworkAddress $DATA.realArchiveServer.NetworkAddress `
        -TransferProtocol $DATA.realArchiveServer.TransferProtocol `
        -Port $DATA.realArchiveServer.Port `
        -StoragePath $DATA.realArchiveServer.StoragePath `
        -ServiceAccountCredentialType $DATA.realArchiveServer.ServiceAccountCredentialType `
        -ServiceAccountName $DATA.realArchiveServer.ServiceAccountName `
        -ServiceAccountPassword $DATA.realArchiveServer.ServiceAccountPassword `
        -AcceptSshHostKey
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardArchiveServer"; message = "Successfully created Archive Server $($DATA.realArchiveServer.archSrvName) Id=$($archiveServer.Id)"; })

      $editedArchiveServer = Edit-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id -Description "Edited ArchSrv description"
      if ($editedArchiveServer.Description -match "ArchSrv") {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardArchiveServer"; message = "Successfully editd Archive Server $($DATA.realArchiveServer.archSrvName), Description=$($archiveServer.Description)"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Edit-SafeguardArchiveServer"; message = "Editing Archive Server $($DATA.realArchiveServer.archSrvName) was NOT successful"; })
      }

      $archiveServer = Get-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardArchiveServer"; message = "Successfully retrieved Archive Server $($archiveServer.DisplayName) Id=$($archiveServer.Id)"; })

      Test-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id 
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardArchiveServer"; message = "Successfully called test on Archive Server $($archiveServer.DisplayName) Id=$($archiveServer.Id). Check results to see test *worked* as expected."; })

      Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardArchiveServer"; message = "Successfully removed Archive Server $($DATA.realArchiveServer.archSrvName) Id=$($archiveServer.Id)"; })

      try {
         $waitResults = Wait-SafeguardApplianceStateOnline -Timeout 10
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Wait-SafeguardApplianceStateOnline"; message = "Successfully waited for online state"; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Wait-SafeguardApplianceStateOnline "; message = "Unexpected error waiting for online state"; ex = $_; })
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Archive Server general"; message = "Unexpected error in Archive Server tests"; ex = $_; })
   } finally {
      if ($archiveServer.Id) { try{Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null} catch{} }
   }

   ###############################################################################
   $GLOBALS.writeCallHeader("Syslog Server")
   ###############################################################################
   try {
      $syslogList = Get-SafeguardSyslogServer
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSyslogServer"; message = "Successfully retrieved $($syslogList.Count) syslog servers"; })

      $newsyslog = New-SafeguardSyslogServer -NetworkAddress "1.2.3.4" -Name "fred"
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardSyslogServer"; message = "Successfully created SyslogServer Id=$($newsyslog.Id) Name=$($newSyslog.Name)"; })

      $newSyslog.Name = "Son of Fred"
      $editedSyslog = Edit-SafeguardSyslogServer -SysLogServer $newSyslog
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSyslogServer"; message = "Successfully edited Id=$($editedSyslog.Id) Name=$($editedSyslog.Name)"; })

      Remove-SafeguardSyslogServer -ServerToRemove $editedSyslog.Id > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardSyslogServer"; message = "Successfully removed Id=$($editedSyslog.Id) Name=$($editedSyslog.Name)"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "SysLog Server general"; message = "Unexpected error in SysLog Server tests"; ex = $_; })
   } finally {
      if ($newsyslog.Id) { try{Remove-SafeguardSyslogServer -ServerToRemove $newsyslog.Id > $null} catch{} }
   }


   ###############################################################################
   $GLOBALS.writeCallHeader("BMC Configuration")
   ###############################################################################
   if ($isVm) {
      $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardBmcConfiguration"; message = "Skipping BMC tests - does not apply to VM"; skipCount = 4; })
   } else {
      try {
         $bmcpassword = $DATA.appliancebmc.Password | ConvertTo-SecureString -AsPlainText -Force
         Enable-SafeguardBmcConfiguration -Ipv4Address "$($DATA.appliancebmc.Ipv4Address)" -Ipv4Gateway "$($DATA.appliancebmc.Ipv4Gateway)" -Ipv4NetMask "$($DATA.appliancebmc.Ipv4NetMask)" -Password $bmcpassword > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardBmcConfiguration"; message = "Successful Enable SafeguardBmcConfiguration"; })
      } catch {
         if ($isVM) {
            if ($_ -match "This operation is not supported for this platform type"){
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardBmcConfiguration"; message = "Successful Enable-SafeguardBmcConfiguration doesn't work on VMs"; })
            }
            else {
               $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardBmcConfiguration"; message = "You may need to add 'appliancebmc = @{Ipv4Address=; Ipv4Gateway = ; Ipv4NetMask = ; Password=}  to your Data object"; })
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Enable-SafeguardBmcConfiguration"; message = "Unexpected error in Enable-SafeguardBmcConfiguration"; ex = $_; })
            }
         }
         else{
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Enable-SafeguardBmcConfiguration"; message = "You may need to add 'appliancebmc = @{Ipv4Address=; Ipv4Gateway = ; Ipv4NetMask = ; Password=}  to your Data object"; })
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Enable-SafeguardBmcConfiguration"; message = "Unexpected error in Enable-SafeguardBmcConfiguration"; ex = $_; })
         }
      }
      try {
         $notbmcpassword = "NotTest1234" | ConvertTo-SecureString -AsPlainText -Force
         Set-SafeguardBmcAdminPassword -Password $notbmcpassword > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardBmcAdminPassword"; message = "Successful Set SafeguardBmcAdminPassword"; })
         Set-SafeguardBmcAdminPassword -Password $bmcpassword > $null
      } catch {
         if ($isVM) {
            if ($_ -match "This operation is not supported for this platform type"){
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardBmcAdminPassword"; message = "Successful Set-SafeguardBmcAdminPassword doesn't work on VMs"; })
            }
            else {
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardBmcAdminPassword"; message = "Unexpected error in VM Set-SafeguardBmcAdminPassword"; ex = $_; })
            }
         }
         else{
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardBmcAdminPassword"; message = "Unexpected error in Set-SafeguardBmcAdminPassword"; ex = $_; })
         }
      }

      try {
         Get-SafeguardBmcConfiguration > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardBmcConfiguration"; message = "Successful Get-SafeguardBmcConfiguration"; })
      } catch {
         if ($isVM) {
            if ($_ -match "This operation is not supported for this platform type"){
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardBmcConfiguration"; message = "Successful Get-SafeguardBmcConfiguration doesn't work on VMs"; })
            }
            else {
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardBmcConfiguration"; message = "Unexpected error in VM Get-SafeguardBmcConfiguration"; ex = $_; })
            }
         }
         else{
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Get-SafeguardBmcConfiguration"; message = "Unexpected error in Get-SafeguardBmcConfiguration"; ex = $_; })
         }
      }

      try {
         Disable-SafeguardBmcConfiguration > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Disable-SafeguardBmcConfiguration"; message = "Successful Disable-SafeguardBmcConfiguration"; })
      } catch {
         if ($isVM) {
            if ($_ -match "This operation is not supported for this platform type"){
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Disable-SafeguardBmcConfiguration"; message = "Successful Disable-SafeguardBmcConfiguration doesn't work on VMs"; })
            }
            else {
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Disable-SafeguardBmcConfiguration"; message = "Unexpected error in VM Disable-SafeguardBmcConfiguration"; ex = $_; })
            }
         }
         else{
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Disable-SafeguardBmcConfiguration"; message = "Unexpected error in Disable-SafeguardBmcConfiguration"; ex = $_; })
         }
      }
   }

   try {
      $local:results = Get-SafeguardAuditLog -Log ObjectChanges -Hours 1
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAuditLog"; message = "Successfully retrived audit log"; })
      $GLOBALS.formatTable(@{ output = $local:results; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAuditLog"; message = "Unexpected error retrieving audit log"; ex = $_; })
   }

   try {
      $local:results = Test-SafeguardVersion -MinVersion 8.0
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardVersion"; message = "Successfully tested version"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Test-SafeguardVersion"; message = "Unexpected error retrieving audit log"; ex = $_; })
   }

   try {
      $local:results = Switch-SafeguardConnectionVersion -Version 3
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Switch-SafeguardConnectionVersion"; message = "Successfully switched to API v3"; })
      $GLOBALS.formatTable(@{ output = $local:results; })
      $local:results = Switch-SafeguardConnectionVersion -Version 4
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Switch-SafeguardConnectionVersion"; message = "Successfully switched back to API v4"; })
      $GLOBALS.formatTable(@{ output = $local:results; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Switch-SafeguardConnectionVersion"; message = "Unexpected error switching API version"; ex = $_; })
   }

   try {
      $local:results = Set-SafeguardAuthenticationProviderAsDefault -ProviderToSet Local
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAuthenticationProviderAsDefault"; message = "Successfully set Local as default authentication provider"; })
      $GLOBALS.formatTable(@{ output = $local:results; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAuthenticationProviderAsDefault"; message = "Unexpected error switching API version"; ex = $_; })
   }

   try {
      $local:results = Clear-SafeguardAuthenticationProviderAsDefault
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Clear-SafeguardAuthenticationProviderAsDefault"; message = "Successfully cleared local authentication provider"; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Clear-SafeguardAuthenticationProviderAsDefault"; message = "Unexpected error switching API version"; ex = $_; })
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Miscellaneous"; message = "Unexpected error in Miscellaneous test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   $GLOBALS.testBlockHeader($script:blockInfo)
}


# try {
#    #TODO Need to make these files and commit then to the repo. Then this code can be polished
#    $AuditLogArchiveKeyFileName = "\AuditLogArchiveKeyFile.sgd"
#    $AuditLogArchiveFileName = "\AuditLogArchiveFile.sgd"
#    if  ($isVm) {
#       $AuditLogArchiveFileName = "\VmAuditLogArchiveFile.sgd"
#       $AuditLogArchiveKeyFileName = "\VmAuditLogArchiveKeyFile.sgd"
#    }
#    $AuditLogArchiveFilePath = "$($SCRIPT_PATH)" + "$($AuditLogArchiveFileName)"
#    $AuditLogArchiveKeyFilePath = "$($SCRIPT_PATH)" + "$($AuditLogArchiveKeyFileName)"
#    Test-SafeguardAuditLogArchive -ArchiveZip "$($AuditLogArchiveFilePath)" -SigningCertificate "$($AuditLogArchiveKeyFilePath)"
#    $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardAuditLogArchive"; message = "Successful Test-SafeguardAuditLogArchive"; })
# } catch {
#    if ($isLTS) {
#       $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Test-SafeguardAuditLogArchive"; message = "Successful Test-SafeguardAuditLogArchive doesn't work on VMs"; })
#    }
#    else{
#       $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Test-SafeguardAuditLogArchive"; message = "Unexpected error in Test-SafeguardAuditLogArchive"; ex = $_; })
#    }
# }
