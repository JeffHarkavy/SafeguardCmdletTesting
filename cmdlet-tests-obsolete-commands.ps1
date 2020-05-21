try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
# ===== Covered Commands =====
# Add-SafeguardSessionSshAlgorithm
# Get-SafeguardSessionCertificate
# Get-SafeguardSessionContainerStatus
# Get-SafeguardSessionModuleStatus
# Get-SafeguardSessionModuleVersion
# Get-SafeguardSessionSshAlgorithms
# Invoke-SafeguardSessionsPing
# Invoke-SafeguardSessionsTelnet
# Remove-SafeguardSessionSshAlgorithm
# Reset-SafeguardSessionModule
# Set-SafeguardSessionSshAlgorithms
#
writeCallHeader "Running Obsolete Commands"

# All of the following commands are *expected* to be obsolete and should only spit out
# a Warning (or 2) about that. If any other error comes out we'll squawk
writeCallHeader "Add-SafeguardSessionSshAlgorithm OBSOLETE"
try { Add-SafeguardSessionSshAlgorithm ServerSide Cipher 3des-cbc -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Add-SafeguardSessionSshAlgorithm" "Unexpected error" $_.Exception } }

writeCallHeader "Get-SafeguardSessionCertificate OBSOLETE"
try { Get-SafeguardSessionCertificate -Type TimeStamping -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Get-SafeguardSessionCertificate" "Unexpected error" $_.Exception } }

writeCallHeader "Get-SafeguardSessionContainerStatus OBSOLETE"
try { Get-SafeguardSessionContainerStatus -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Get-SafeguardSessionContainerStatus" "Unexpected error" $_.Exception } }

writeCallHeader "Get-SafeguardSessionModuleStatus OBSOLETE"
try { Get-SafeguardSessionModuleStatus -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Get-SafeguardSessionModuleStatus" "Unexpected error" $_.Exception } }

writeCallHeader "Get-SafeguardSessionModuleVersion OBSOLETE"
try { Get-SafeguardSessionModuleVersion -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Get-SafeguardSessionModuleVersion" "Unexpected error" $_.Exception } }

writeCallHeader "Get-SafeguardSessionSshAlgorithms OBSOLETE"
try { Get-SafeguardSessionSshAlgorithms -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Get-SafeguardSessionSshAlgorithms" "Unexpected error" $_.Exception } }

writeCallHeader "Invoke-SafeguardSessionsPing OBSOLETE"
try { Invoke-SafeguardSessionsPing -NetworkAddress 10.9.6.79 -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Invoke-SafeguardSessionsPing" "Unexpected error" $_.Exception } }

writeCallHeader "Invoke-SafeguardSessionsTelnet OBSOLETE"
try { Invoke-SafeguardSessionsTelnet -NetworkAddress 10.9.6.79 -Port 22 -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Invoke-SafeguardSessionsTelnet" "Unexpected error" $_.Exception } }

writeCallHeader "Set-SafeguardSessionSshAlgorithms OBSOLETE"
try { Set-SafeguardSessionSshAlgorithms ServerSide Cipher -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Set-SafeguardSessionSshAlgorithms" "Unexpected error" $_.Exception } }

writeCallHeader "Remove-SafeguardSessionSshAlgorithm OBSOLETE"
try { Remove-SafeguardSessionSshAlgorithm ServerSide Cipher 3des-cbc -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Remove-SafeguardSessionSshAlgorithm" "Unexpected error" $_.Exception } }

writeCallHeader "Reset-SafeguardSessionModule OBSOLETE"
try { Reset-SafeguardSessionModule -ErrorAction:SilentlyContinue -WarningAction:Continue }
catch { if ($_.Exception.ErrorCode -ne 60385) { badResult "Reset-SafeguardSessionModule" "Unexpected error" $_.Exception } }
