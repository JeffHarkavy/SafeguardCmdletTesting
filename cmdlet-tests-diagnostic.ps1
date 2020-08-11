try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Diagnostic Package Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
   # TODO - stubbed code
   #Clear-SafeguardDiagnosticPackage
   #Get-SafeguardDiagnosticPackage
   #Get-SafeguardDiagnosticPackageLog
   #Get-SafeguardDiagnosticPackageStatus
   #Invoke-SafeguardDiagnosticPackage
   #Set-SafeguardDiagnosticPackage

# ===== Covered Commands =====
#

try {
} catch {
   badResult "Diagnostic Package general" "Unexpected error in Diagnostic Package test" $_.Exception
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo

