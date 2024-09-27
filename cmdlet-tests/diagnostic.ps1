try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Diagnostic
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

try {
   $localDiagnosticPackageFilename = "cmdlet-test-sgdiagnosticpackage_$testBranch_$("{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f (Get-Date)).sgb"
   $localDiagnosticPackageFilePath = "$($DATA.filePaths.logs)\$localDiagnosticPackageFilename"

   $diagon = Clear-SafeguardDiagnosticPackage
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Clear-SafeguardDiagnosticPackage"; message = "Successful Clear SafeguardDiagnosticPackage $($diagon)"; })

   $diagon = Get-SafeguardDiagnosticPackage
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDiagnosticPackage"; message = "Successful retrieved DiagnosticPackage $($diagon)"; })

   $diagon = Get-SafeguardDiagnosticPackageLog -OutFile "$localDiagnosticPackageFilePath"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDiagnosticPackageLog"; message = "Successful retrieved Get-SafeguardDiagnosticPackageLog $($diagon)"; })

   $diagon = Get-SafeguardDiagnosticPackage
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDiagnosticPackageStatus"; message = "Successful retrieved Get-SafeguardDiagnosticPackageStatus $($diagon)"; })

   #This only tests Prod... A test one can be found here https://sg-archive.sg.lab/pangaea/qa/secdiags/test/mbx_3000/AutomationSuccess.sgd to used by hand if wanted
   $DiagnosticPackageFilePath = $DATA.diagnosticPackages.hardware
   if  ($isVm) {
      $DiagnosticPackageFilePath = $DATA.diagnosticPackages.vm
   }
   $diagon = Set-SafeguardDiagnosticPackage -PackagePath "$($DiagnosticPackageFilePath)"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardDiagnosticPackage"; message = "Successful set Set-SafeguardDiagnosticPackage $($diagon)"; })

   $diagon = Invoke-SafeguardDiagnosticPackage
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardDiagnosticPackage"; message = "Successful Invoke SafeguardDiagnosticPackage $($diagon)"; })

   $diagon = Get-SafeguardDiagnosticPackage
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDiagnosticPackage"; message = "Successful retrieved DiagnosticPackage $($diagon)"; })

   $diagon = Get-SafeguardDiagnosticPackageLog -OutFile "$localDiagnosticPackageFilePath"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDiagnosticPackageLog"; message = "Successful retrieved Get-SafeguardDiagnosticPackageLog $($diagon)"; })

   $diagon = Get-SafeguardDiagnosticPackage
   
   #@{PackageType=Diagnostic; Name=Test Hello World; Description=Diagnostic package used for automation. Should run for 5 seconds and output to the log file the text "Hello World"; MinimumSafeguardVersion=2.9.0; ApplianceId=; Expiration=2050-01-01T00:00:00Z}
   if  ($diagon.Name -match "Test Hello World") {
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDiagnosticPackageStatus"; message = "Successful retrieved Get-SafeguardDiagnosticPackageStatus $($diagon)"; })
   }
   
   $diagon = Clear-SafeguardDiagnosticPackage
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Clear-SafeguardDiagnosticPackage"; message = "Successful Clear SafeguardDiagnosticPackage $($diagon)"; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Diagnostic Package general"; message = "Unexpected error in Diagnostic Package test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   $GLOBALS.testBlockHeader($script:blockInfo)
}

