try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Diagnostic Package Tests"
$blockInfo = testBlockHeader $TestBlockName
# ===== Covered Commands =====
# Clear-SafeguardDiagnosticPackage
# Get-SafeguardDiagnosticPackage
# Get-SafeguardDiagnosticPackageLog
# Get-SafeguardDiagnosticPackageStatus
# Invoke-SafeguardDiagnosticPackage
# Set-SafeguardDiagnosticPackage

try {
   $localDiagnosticPackageFilename = "cmdlet-test-sgdiagnosticpackage_$testBranch_$("{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f (Get-Date)).sgb"
   $localDiagnosticPackageFilePath = "$($DATA.outputPaths.logs)\$localDiagnosticPackageFilename"

   $diagon = Clear-SafeguardDiagnosticPackage
   goodResult "Clear-SafeguardDiagnosticPackage" "Successfull Clear SafeguardDiagnosticPackage $($diagon)"

   $diagon = Get-SafeguardDiagnosticPackage
   goodResult "Get-SafeguardDiagnosticPackage" "Successfull retrieved DiagnosticPackage $($diagon)"

   $diagon = Get-SafeguardDiagnosticPackageLog -OutFile "$localDiagnosticPackageFilePath"
   goodResult "Get-SafeguardDiagnosticPackageLog" "Successfull retrieved Get-SafeguardDiagnosticPackageLog $($diagon)"

   $diagon = Get-SafeguardDiagnosticPackage
   goodResult "Get-SafeguardDiagnosticPackageStatus" "Successfull retrieved Get-SafeguardDiagnosticPackageStatus $($diagon)"

   #This only tests Prod... A test one can be found here https://sg-archive.sg.lab/pangaea/qa/secdiags/test/mbx_3000/AutomationSuccess.sgd to used by hand if wanted
   $DiagnosticPackageFileName = "\AutomationSuccess.sgd"
   if  ($isVm) {
      $DiagnosticPackageFileName = "\VmAutomationSuccess.sgd"
   }
   $DiagnosticPackageFilePath = "$($SCRIPT_PATH)" + "$($DiagnosticPackageFileName)"
   $diagon = Set-SafeguardDiagnosticPackage -PackagePath "$($DiagnosticPackageFilePath)"
   goodResult "Set-SafeguardDiagnosticPackage" "Successfull set Set-SafeguardDiagnosticPackage $($diagon)"

   $diagon = Invoke-SafeguardDiagnosticPackage
   goodResult "Invoke-SafeguardDiagnosticPackage" "Successfull Invoke SafeguardDiagnosticPackage $($diagon)"

   $diagon = Get-SafeguardDiagnosticPackage
   goodResult "Get-SafeguardDiagnosticPackage" "Successfull retrieved DiagnosticPackage $($diagon)"

   $diagon = Get-SafeguardDiagnosticPackageLog -OutFile "$localDiagnosticPackageFilePath"
   goodResult "Get-SafeguardDiagnosticPackageLog" "Successfull retrieved Get-SafeguardDiagnosticPackageLog $($diagon)"

   $diagon = Get-SafeguardDiagnosticPackage
   
   #@{PackageType=Diagnostic; Name=Test Hello World; Description=Diagnostic package used for automation. Should run for 5 seconds and output to the log file the text "Hello World"; MinimumSafeguardVersion=2.9.0; ApplianceId=; Expiration=2050-01-01T00:00:00Z}
   if  ($diagon.Name -match "Test Hello World") {
      goodResult "Get-SafeguardDiagnosticPackageStatus" "Successfull retrieved Get-SafeguardDiagnosticPackageStatus $($diagon)"
   }
   
   $diagon = Clear-SafeguardDiagnosticPackage
   goodResult "Clear-SafeguardDiagnosticPackage" "Successfull Clear SafeguardDiagnosticPackage $($diagon)"

} catch {
   badResult "Diagnostic Package general" "Unexpected error in Diagnostic Package test" $_
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader $TestBlockName $blockInfo

