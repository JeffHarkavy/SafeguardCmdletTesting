try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Certificates Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
# TODO - stubbed code
#Clear-SafeguardSslCertificateForAppliance
#Get-ADAccessCertificationIdentity
#Install-SafeguardAuditLogSigningCertificate
#Install-SafeguardSessionCertificate
#Install-SafeguardSslCertificate
#Install-SafeguardTrustedCertificate
#New-SafeguardCertificateSigningRequest
#New-SafeguardCsr
#New-SafeguardTestCertificatePki
#Remove-SafeguardCertificateSigningRequest
#Remove-SafeguardCsr
#Reset-SafeguardSessionCertificate
#Set-SafeguardSslCertificateForAppliance
#Uninstall-SafeguardAuditLogSigningCertificate
#Uninstall-SafeguardSslCertificate
#Uninstall-SafeguardTrustedCertificate
#Update-SafeguardAccessCertificationGroupFromAD

# ===== Covered Commands =====
#Get-SafeguardAccessCertificationAccount
#Get-SafeguardAccessCertificationAll
#Get-SafeguardAccessCertificationGroup
#Get-SafeguardAccessCertificationIdentity
#Get-SafeguardAccessCertificationEntitlement
#

try {
   Get-SafeguardAccessCertificationAccount -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationAccount" "Successfully called"

   # TODO - this needs extra work. asks for ad creds?
   # Get-SafeguardAccessCertificationAll -Identifier $DATA.appliance -OutputDirectory . -DomainName jshdevvm.dell.com
   # goodResult "Get-SafeguardAccessCertificationAll" "Successfully called"

   Get-SafeguardAccessCertificationGroup -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationGroup" "Successfully called"

   Get-SafeguardAccessCertificationIdentity -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationIdentity" "Successfully called"

   # This assumes some entitlement stuff being around for meaningful output?
   Get-SafeguardAccessCertificationEntitlement -Identifier $DATA.appliance -StdOut
   goodResult "Get-SafeguardAccessCertificationEntitlement" "Successfully called"

} catch {
   badResult "Certificates general" "Unexpected error in Certificates test" $_.Exception
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo
