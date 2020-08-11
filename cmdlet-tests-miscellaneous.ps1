try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Miscellaneous Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
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

# TODO - stubbed code
#Enable-SafeguardBmcConfiguration - !$isVm
#Set-SafeguardBmcAdminPassword - !$isVm
#Repair-SafeguardSessionModule
#Set-SafeguardTime
#Test-SafeguardAuditLogArchive - !$isLTS

try {
   $output = Invoke-SafeguardMethod Core POST ReasonCodes -Body @{ Name = "RN12345"; Description = "Routine maintenance." }
   goodResult "Invoke-SafeguardMethod" "Successfuly created reasonCode Id=$($output.Id)"

   Invoke-SafeguardMethod Core DELETE ReasonCodes/$($output.Id) > $null
   infoResult "Invoke-SafeguardMethod" "Successfuly removed reasonCode Id=$($output.Id)"
} catch {
   badResult "Invoke-Safegaurdmethod general" "Unexpected error" $_.Exception
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
   badResult "Network Interface general" "Unexpected error in setting X0 DnsServers" $_.Exception
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
   badResult "Appliance Name general" "Unexpected error in edit appliance name" $_.Exception
}

try {
   $licenseKey = (Get-SafeguardLicense).Key
   infoResult "Get-SafeguardLicense" "Retrieved license key $licenseKey"
   Uninstall-SafeguardLicense $licenseKey > $null
   goodResult "Uninstall-SafeguardLicense" "Successfully uninstalled license $licenseKey"
   $newLicense = Install-SafeguardLicense -LicenseFile "$($DATA.licenseFile)"
   goodResult "Install-SafeguardLicense" "Successfully installed license $($newLicense.Key)"
} catch {
   badResult "Licensing general" "Unexpected error in licensing" $_.Exception
}

try {
   $archSrvName = "ps.ArchSrv_001"
   $archiveServer = New-SafeguardArchiveServer -DisplayName $archSrvName `
     -NetworkAddress $DATA.realArchiveServer.NetworkAddress `
     -TransferProtocol $DATA.realArchiveServer.TransferProtocol `
     -Port $DATA.realArchiveServer.Port `
     -StoragePath $DATA.realArchiveServer.StoragePath `
     -ServiceAccountCredentialType $DATA.realArchiveServer.ServiceAccountCredentialType `
     -ServiceAccountName $DATA.realArchiveServer.ServiceAccountName `
     -ServiceAccountPassword $DATA.realArchiveServer.ServiceAccountPassword `
     -AcceptSshHostKey
   goodResult "New-SafeguardArchiveServer" "Successfully created Archive Server $archSrvName Id=$($archiveServer.Id)"

   $editedArchiveServer = Edit-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id -Description "Edited ArchSrv description"
   if ($editedArchiveServer.Description -match "ArchSrv") {
      goodResult "Edit-SafeguardArchiveServer" "Successfully editd Archive Server $archSrvName, Description=$($archiveServer.Description)"
   } else {
      badResult "Edit-SafeguardArchiveServer" "Editing Archive Server $archSrvName was NOT successful"
   }

   $archiveServer = Get-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id
   goodResult "Get-SafeguardArchiveServer" "Successfully retrieved Archive Server $($archiveServer.DisplayName) Id=$($archiveServer.Id)"

   Test-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id 
   goodResult "Test-SafeguardArchiveServer" "Successfully called test on Archive Server $($archiveServer.DisplayName) Id=$($archiveServer.Id). Check results to see test *worked* as expected."

   Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null
   goodResult "Remove-SafeguardArchiveServer" "Successfully removed Archive Server $archSrvName Id=$($archiveServer.Id)"
} catch {
   badResult "Archive Server general" "Unexpected error in Archive Server tests" $_.Exception
} finally {
   if ($archiveServer.Id) { try{Remove-SafeguardArchiveServer -ArchiveServerId $archiveServer.Id > $null} catch{} }
}

writeCallHeader "Make sure to run the following as manual tests`nuser interaction or reboots or other stuff required"
infoResult "Open-CsvInExcel -FilePath foo-bar.csv" "Best to run manually on a known CSV when Excel is known to be present"
infoResult "Get-SafeguardSupportBundle -OutFile somefilename" "This can take a long time to process, so probably best to do manually"
infoResult "Install-SafeguardDesktopClient" "not really a script-y kind of thing to do, requires user interaction"
infoResult "Invoke-SafeguardApplianceFactoryReset -Reason ""Give a reason here""" " --- VM Only - beware!"
infoResult "Invoke-SafeguardApplianceReboot -Reason ""Give a reason here"""
infoResult "Invoke-SafeguardApplianceShutdown -Reason ""Give a reason here"""
infoResult "Update-SafeguardAccessToken" "requires user interaction"
infoResult "Enable-SafeguardTls12Only" "requires user interaction, use Get-SafeguardTls12OnlyStatus to see the current setting"
infoResult "Disable-SafeguardTls12Only" "requires user interaction, use Get-SafeguardTls12OnlyStatus to see the current setting"

testBlockHeader "end" $TestBlockName $blockInfo
