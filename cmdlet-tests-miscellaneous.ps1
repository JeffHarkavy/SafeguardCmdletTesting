﻿try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Miscellaneous Tests"
$blockInfo = testBlockHeader $TestBlockName
# TODO - stubbed code
#Enable-SafeguardBmcConfiguration - !$isVm
#Set-SafeguardBmcAdminPassword - !$isVm
#Set-SafeguardTime
#Test-SafeguardAuditLogArchive - !$isLTS

# === COVERED COMMANDS ===
# Edit-SafeguardArchiveServer
# Get-SafeguardApplianceName
# Get-SafeguardArchiveServer
# Get-SafeguardDnsSuffix
# Get-SafeguardLicense
# Get-SafeguardNetworkInterface
# Get-SafeguardSupportBundle
# Get-SafeguardTls
# Install-SafeguardDesktopClient
# Install-SafeguardLicense
# Invoke-SafeguardApplianceFactoryReset
# Invoke-SafeguardApplianceReboot
# Invoke-SafeguardApplianceShutdown
# Invoke-SafeguardMethod
# New-SafeguardArchiveServer
# Remove-SafeguardArchiveServer
# Set-SafeguardApplianceName
# Set-SafeguardDnsSuffix
# Set-SafeguardNetworkInterface
# Test-SafeguardArchiveServer
# Uninstall-SafeguardLicense
# Update-SafeguardAccessToken
# Wait-SafeguardApplianceStateOnline
# Edit-SafeguardSyslogServer
# Get-SafeguardSyslogServer
# New-SafeguardSyslogServer
# Remove-SafeguardSyslogServer
#

try {
   $output = Invoke-SafeguardMethod Core POST ReasonCodes -Body @{ Name = "RN12345"; Description = "Routine maintenance." }
   goodResult "Invoke-SafeguardMethod" "Successfuly created reasonCode Id=$($output.Id)"

   Invoke-SafeguardMethod Core DELETE ReasonCodes/$($output.Id) > $null
   infoResult "Invoke-SafeguardMethod" "Successfuly removed reasonCode Id=$($output.Id)"
} catch {
   badResult "Invoke-Safegaurdmethod general" "Unexpected error" $_
}

try {
   $x0 = Get-SafeguardNetworkInterface -Interface "x0"
   infoResult "Get-SafeguardNetworkInterface" "Existing DNSServers for x0=$($x0.DnsServers -join ' ')"

   $setX0 = Set-SafeguardNetworkInterface -Interface "x0" -DnsServers @("10.1.1.37","10.1.1.10")
   goodResult "Set-SafeguardNetworkInterface" "Successfuly edited X0.DnsServers=$($setX0.DnsServers -join ' ')"

   $setX0 = Set-SafeguardNetworkInterface -Interface "x0" -DnsServers $x0.DnsServers
   infoResult "Set-SafeguardNetworkInterface" "Reset DNSServers for x0=$($x0.DnsServers -join ' ')"

   $x0Dns = Get-SafeguardDnsSuffix -Interface x0
   infoResult "Get-SafeguardNetworkInterface" "Existing DnsSuffixes for x0=$($x0Dns.DomainNames -join ' ')"

   $setX0Dns = Set-SafeguardDnsSuffix -Interface x0 -DnsSuffixes @("foo.com","bar.com")
   goodResult "Set-SafeguardDnsSuffix" "Successfuly edited X0 DnsSuffixes=$($setX0Dns.DomainNames -join ' ')"

   $setX0Dns = Set-SafeguardDnsSuffix -Interface x0 -DnsSuffixes "$($x0Dns.DomainNames)"
   infoResult "Set-SafeguardDnsSuffix" "Successfuly reset X0 DnsSuffixes=$($setX0Dns.DomainNames -join ' ')"
} catch {
   badResult "Network Interface general" "Unexpected error" $_
}

try {
   $currentApplianceName = Get-SafeguardApplianceName
   Set-SafeguardApplianceName -Name "THIS IS A TEST" > $null
   $editedApplianceName = Get-SafeguardApplianceName
   if ($editedApplianceName -eq "THIS IS A TEST") {
      goodResult "Set-SafeguardApplianceName" "successfully changed name to $editedApplianceName"
   } else {
      badResult "Set-SafeguardApplianceName" "Appliance name edit was NOT successful"
   }

   Set-SafeguardApplianceName -Name "$currentApplianceName" > $null
   if ((Get-SafeguardApplianceName) -eq $currentApplianceName) {
      infoResult "Set-SafeguardApplianceName" "successfully reverted name to $currentApplianceName"
   } else {
      badResult "Set-SafeguardApplianceName" "Appliance name edit was NOT successful"
   }
} catch {
   badResult "Appliance Name general" "Unexpected error in edit appliance name" $_
}

try {
   $licenseKey = (Get-SafeguardLicense).Key
   infoResult "Get-SafeguardLicense" "Retrieved license key $licenseKey"

   Uninstall-SafeguardLicense $licenseKey > $null
   goodResult "Uninstall-SafeguardLicense" "Successfully uninstalled license $licenseKey"

   $newLicense = Install-SafeguardLicense -LicenseFile "$($DATA.licenseFile)"
   goodResult "Install-SafeguardLicense" "Successfully installed license $($newLicense.Key)"
} catch {
   badResult "Licensing general" "Unexpected error in licensing" $_
}

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
   goodResult "New-SafeguardArchiveServer" "Successfully created Archive Server $($DATA.realArchiveServer.archSrvName) Id=$($archiveServer.Id)"

   $editedArchiveServer = Edit-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id -Description "Edited ArchSrv description"
   if ($editedArchiveServer.Description -match "ArchSrv") {
      goodResult "Edit-SafeguardArchiveServer" "Successfully editd Archive Server $($DATA.realArchiveServer.archSrvName), Description=$($archiveServer.Description)"
   } else {
      badResult "Edit-SafeguardArchiveServer" "Editing Archive Server $($DATA.realArchiveServer.archSrvName) was NOT successful"
   }

   $archiveServer = Get-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id
   goodResult "Get-SafeguardArchiveServer" "Successfully retrieved Archive Server $($archiveServer.DisplayName) Id=$($archiveServer.Id)"

   Test-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id 
   goodResult "Test-SafeguardArchiveServer" "Successfully called test on Archive Server $($archiveServer.DisplayName) Id=$($archiveServer.Id). Check results to see test *worked* as expected."

   Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null
   goodResult "Remove-SafeguardArchiveServer" "Successfully removed Archive Server $($DATA.realArchiveServer.archSrvName) Id=$($archiveServer.Id)"

   try {
      $waitResults = Wait-SafeguardApplianceStateOnline -Timeout 10
      goodResult "Wait-SafeguardApplianceStateOnline" "Successfully waited for online state"
   } catch {
      badResult "Wait-SafeguardApplianceStateOnline " "Unexpected error waiting for online state" $_
   }
} catch {
   badResult "Archive Server general" "Unexpected error in Archive Server tests" $_
} finally {
   if ($archiveServer.Id) { try{Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null} catch{} }
}

try {
   $syslogList = Get-SafeguardSyslogServer
   goodResult "Get-SafeguardSyslogServer" "Successfully retrieved $($syslogList.Count) syslog servers"

   $newsyslog = New-SafeguardSyslogServer -NetworkAddress "1.2.3.4" -Name "fred"
   goodResult "New-SafeguardSyslogServer" "Successfully created SyslogServer Id=$($newsyslog.Id) Name=$($newSyslog.Name)"

   $newSyslog.Name = "Son of Fred"
   $editedSyslog = Edit-SafeguardSyslogServer -SysLogServer $newSyslog
   goodResult "Get-SafeguardSyslogServer" "Successfully edited Id=$($editedSyslog.Id) Name=$($editedSyslog.Name)"

   Remove-SafeguardSyslogServer -ServerToRemove $editedSyslog.Id > $null
   goodResult "Remove-SafeguardSyslogServer" "Successfully removed Id=$($editedSyslog.Id) Name=$($editedSyslog.Name)"
} catch {
   badResult "SysLog Server general" "Unexpected error in SysLog Server tests" $_
} finally {
   if ($newsyslog.Id) { try{Remove-SafeguardSyslogServer -ServerToRemove $newsyslog.Id > $null} catch{} }
}

testBlockHeader $TestBlockName $blockInfo
