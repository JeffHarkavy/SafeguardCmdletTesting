try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Certificates
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false
$script:csr = $null

# TODO - stubbed code
# Clear-SafeguardSslCertificateForAppliance
# Install-SafeguardAuditLogSigningCertificate
# Install-SafeguardSessionCertificate
# Install-SafeguardSslCertificate
# Install-SafeguardTrustedCertificate
# Reset-SafeguardSessionCertificate
# Set-SafeguardSslCertificateForAppliance
# Uninstall-SafeguardAuditLogSigningCertificate
# Uninstall-SafeguardSslCertificate
# Uninstall-SafeguardTrustedCertificate

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { if ($script:csr) { Remove-SafeguardCsr -Thumbprint $script:csr.Thumbprint -ErrorAction SilentlyContinue > $null } } catch {}
}

try {
   try {
      $script:csr = New-SafeguardCsr -CertificateType Ssl -Subject $DATA.newCsr.Subject `
          -DnsNames $DATA.newCsr.Dns -IpAddresses $DATA.newCsr.IpAddress `
          -OutFile "$($DATA.filePaths.certificates)$($DATA.newCsr.OutputFile)"
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardCsr"; message = "Successfully created new CSR, thumbprint=$($csr.Thumbprint). Check CSR file for output."; })
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "New-SafeguardCsr"; message = "Unable to create new CSR for $($DATA.newCsr.Subject)"; ex = $_; })
   }

   if ($script:csr) {
      $retrievedCsr = Get-SafeguardCsr -Thumbprint $script:csr.Thumbprint
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardCsr"; message = "Successfully retrieved CSR, thumbprint=$($retrievedCsr.Thumbprint)"; })

      Remove-SafeguardCsr -Thumbprint $retrievedCsr.Thumbprint > $null
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardCsr"; message = "Successfully removed CSR, thumbprint=$($retrievedCsr.Thumbprint)"; })

      $script:csr = $null
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Certificates general"; message = "Unexpected error in Certificates test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup
   $GLOBALS.testBlockHeader($script:blockInfo)
}

