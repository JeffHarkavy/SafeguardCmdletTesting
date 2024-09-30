try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Imports
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false
$script:createdItems = @{
   Assets = @();
   Users = @();
}

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Removing created items")
   $script:createdItems.Keys | ForEach-Object {
      $dto = $_
      if ($script:createdItems[$dto].length) {
         Write-Host "Removing $dto"
         foreach ($item in $script:createdItems[$dto]) {
           try {
             Invoke-SafeguardMethod core DELETE "$dto/$($item.id)" > $null
           } catch {
              # Trying to remove accounts or systems with pending access request actions will
              # throw an error, so try it with force.
              if ($_ -match "is referenced by") {
                 try { Invoke-SafeguardMethod core DELETE "$dto/$($item.id)?forceDelete=true" -ErrorAction SilentlyContinue > $null } catch {}
              } else {
                $GLOBALS.warningResult(@{ minVerbosity = 1; cmd = "Cleanup"; message = "Exception trying to remove $dto/$($item.id)."; ex = $_; })
             }
           }
         }
      }
   }

   if (Test-Path -Type Leaf -Path "$SCRIPT_PATH/*Results.csv") {
      $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Moving *Results.csv files to $($DATA.filePaths.imports)")
      Move-Item -Force -Path "$SCRIPT_PATH/*Results.csv" -Destination "$($DATA.filePaths.imports)/" > $null
   }
}

function script:testTemplateFile($filename) {
   if (!(Test-Path -Type Leaf $filename)) {
      $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "$local:Cmd -all"; message = "$($filename) not found"; })
      return @{success = $false; content = "$($filename) not found"}
   }
   $local:file = Get-Content $filename
   if ($local:file.Count -eq 1 -and
        ($local:file -split ',').Count -gt 1) {
      return @{success = $true; content = $local:file;}
   } else {
      return @{success = $false; content = "Unexpected file content. File=$($filename). Content=$local:file";}
   }
}

try {
   $local:templates = @(
         @{ Cmd="New-SafeguardUserImportTemplate";                 file="$($DATA.filePaths.imports)/template-user.csv"; },
         @{ Cmd="New-SafeguardUserImportTemplate -All";            file="$($DATA.filePaths.imports)/template-user-all.csv"; },
         @{ Cmd="New-SafeguardAssetImportTemplate";                file="$($DATA.filePaths.imports)/template-asset.csv"; },
         @{ Cmd="New-SafeguardAssetImportTemplate -All";           file="$($DATA.filePaths.imports)/template-asset-all.csv"; },
         @{ Cmd="New-SafeguardAssetAccountImportTemplate";         file="$($DATA.filePaths.imports)/template-account.csv"; },
         @{ Cmd="New-SafeguardAssetAccountImportTemplate -All";    file="$($DATA.filePaths.imports)/template-account-all.csv"; },
         @{ Cmd="New-SafeguardAssetAccountPasswordImportTemplate"; file="$($DATA.filePaths.imports)/template-account-password.csv"; },
         @{ Cmd="New-SafeguardAssetAccountSshKeyImportTemplate";   file="$($DATA.filePaths.imports)/template-account-sshkey.csv"; }
   )
   $local:templates | ForEach {
      $local:cmd = $_.Cmd
      try {
         $local:execCmd = "$($_.Cmd) -Path '$($_.file)'"
         Invoke-Expression $local:execCmd | out-host
         $local:result = testTemplateFile $_.file
         if ($local:result.success) {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "$local:Cmd"; message = "Successfully executed"; })
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Content"; message = $local:result.content; })
         } else {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "$local:Cmd"; message = $local:result.content; })
         }
      } catch {
         if ($_ -match "parameter name 'all'") {
            $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "$local:cmd"; message = "-all parameter not support for this command"; })
         } else {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "$local:cmd"; message = "Unexpected error"; ex = $_; })
         }
      }
   }

   # import returns an array - successful elements are an object, unsuccessful is a number
   # errors are in *Results.csv (name varies by type but no way to know what that name is programmatically)
   try {
      # simple user import is "Provider","NewUserName" 
      $local:content = @(Get-Content "$($DATA.filePaths.imports)/template-user.csv")
      $local:content += "local,fflintstone"
      $local:content += "local,brubble"
      $local:importFile = "$($DATA.filePaths.imports)/import-users.csv"
      Set-Content -Path $local:importFile -Value $local:content > $null
      $local:resultsFile = "./UserImportResults.csv"
      Remove-Item -Path $local:resultsFile -ErrorAction SilentlyContinue > $null
      $local:results = Import-SafeguardUser -Path $local:importFile
      if ($null -eq $local:results -or $local:results.Count -eq 0) {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardUser"; message = "Failed to import $local:importFile"; })
         if (Test-Path -Type Leaf -Path $local:resultsFile) {
            Get-Content -Path $local:resultsFile
         }
      } else {
         $script:createdItems.Users = $local:results | Where { $_.GetType().Name -ne "Int32" }
         $local:successCount = $script:createdItems.Users.Count
         $local:failureCount = ($local:results | Where { $_.GetType().Name -eq "Int32" }).Count
         $GLOBALS.goodResult(@{ minVerbosity = 0; cmd = "Import-SafeguardUser"; message = "Succssful Import-SafeguardUser call. ImportCount=$local:successCount; FailCount=$local:failureCount"; })
         $GLOBALS.formatTable(@{ output = $script:createdItems.Users; properties = @{ Property = @("AdminRoles","Id","Name"); }})
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardUser"; message = "Unexpected error"; ex = $_; })
   }

   try {
      # simple asset import is "DisplayName","Platform"
      $local:content = @(Get-Content "$($DATA.filePaths.imports)/template-asset.csv")
      # PlatformID 500 == "Other", so we don't get confused with "Other Directory" and "Other Managed"
      $local:content += "ps.system.other.1,500"
      $local:content += "ps.system.other.2,500"
      $local:importFile = "$($DATA.filePaths.imports)/import-assets.csv"
      Set-Content -Path $local:importFile -Value $local:content > $null
      $local:resultsFile = "./AssetImportResults.csv"
      Remove-Item -Path $local:resultsFile -ErrorAction SilentlyContinue > $null
      $local:results = Import-SafeguardAsset -Path $local:importFile
      if ($null -eq $local:results -or $local:results.Count -eq 0) {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAsset"; message = "Failed to import $local:importFile"; })
         if (Test-Path -Type Leaf -Path $local:resultsFile) {
            Get-Content -Path $local:resultsFile
         }
      } else {
         $script:createdItems.Assets = $local:results | Where { $_.GetType().Name -ne "Int32" }
         $local:successCount = $script:createdItems.Assets.Count
         $local:failureCount = ($local:results | Where { $_.GetType().Name -eq "Int32" }).Count
         $GLOBALS.goodResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAsset"; message = "Succssful Import-SafeguardAsset call. ImportCount=$local:successCount; FailCount=$local:failureCount"; })
         $GLOBALS.formatTable(@{ output = $script:createdItems.Assets; properties = @{ Property = @("Id","Name","PlatformDisplayName"); }})
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAsset"; message = "Unexpected error"; ex = $_; })
   }

   try {
      # simple account import is "ParentAsset","NewAccountName"
      $local:content = @(Get-Content "$($DATA.filePaths.imports)/template-account.csv")
      $local:content += "ps.system.other.1,ps.other.account.1.1"
      $local:content += "ps.system.other.1,ps.other.account.1.2"
      $local:content += "ps.system.other.2,ps.other.account.2.1"
      $local:content += "ps.system.other.2,ps.other.account.2.2"
      $local:importFile = "$($DATA.filePaths.imports)/import-accounts.csv"
      Set-Content -Path $local:importFile -Value $local:content > $null
      $local:resultsFile = "./AssetAccountImportResults.csv"
      Remove-Item -Path $local:resultsFile -ErrorAction SilentlyContinue > $null
      $local:results = Import-SafeguardAssetAccount -Path $local:importFile
      if ($null -eq $local:results -or $local:results.Count -eq 0) {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccount"; message = "Failed to import $local:importFile"; })
         if (Test-Path -Type Leaf -Path $local:resultsFile) {
            Get-Content -Path $local:resultsFile
         }
      } else {
         # Don't need to store these for removal since the asset will be removed
         $local:AssetAccounts = $local:results | Where { $_.GetType().Name -ne "Int32" }
         $local:successCount = $local:AssetAccounts.Count
         $local:failureCount = ($local:results | Where { $_.GetType().Name -eq "Int32" }).Count
         $GLOBALS.goodResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccount"; message = "Succssful Import-SafeguardAssetAccount call. ImportCount=$local:successCount; FailCount=$local:failureCount"; })
         $GLOBALS.formatTable(@{ output = $local:AssetAccounts; properties = @{ Property = @("Id","Name",@{label="AssetName";e={$_.Asset.Name}}); }})
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccount"; message = "Unexpected error"; ex = $_; })
   }

   try {
      # simple passord import is "AssetPartition","AssetToSet","AccountToSet","NewPassword"
      $local:content = @(Get-Content "$($DATA.filePaths.imports)/template-account-password.csv")
      $local:content += "-1,ps.system.other.1,ps.other.account.1.1,argle"
      $local:content += "-1,ps.system.other.1,ps.other.account.1.2,bargle"
      $local:content += "-1,ps.system.other.2,ps.other.account.2.1,morble"
      $local:content += "-1,ps.system.other.2,ps.other.account.2.2,whoosh"
      $local:importFile = "$($DATA.filePaths.imports)/import-accounts-password.csv"
      Set-Content -Path $local:importFile -Value $local:content > $null
      $local:resultsFile = "./AssetAccountPaswordImportResults.csv"
      Remove-Item -Path $local:resultsFile -ErrorAction SilentlyContinue > $null
      $local:results = Import-SafeguardAssetAccountPassword -Path $local:importFile
      if ($null -eq $local:results -or $local:results.Count -eq 0) {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccountPassword"; message = "Failed to import $local:importFile"; })
         if (Test-Path -Type Leaf -Path $local:resultsFile) {
            Get-Content -Path $local:resultsFile
         }
      } else {
         # Don't need to store these for removal since the asset will be removed
         $local:AccountPasswords = $local:results | Where { $_.GetType().Name -ne "Int32" }
         $local:successCount = $local:AccountPasswords.Count
         $local:failureCount = ($local:results | Where { $_.GetType().Name -eq "Int32" }).Count
         # there is no output for successful imports for this command
         $GLOBALS.goodResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccountPassword"; message = "Succssful Import-SafeguardAssetAccountPassword call. ImportCount=$local:successCount; FailCount=$local:failureCount"; })
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccountPassword"; message = "Unexpected error"; ex = $_; })
   }

   $local:keyfile = "$SCRIPT_PATH/testkey"
   try {
      # first off, we need a key, 
      $local:keyContents = ""
      try {
         # Generate an ssh key with no passphrase.
         # There's no logical reason why the syntax for "no passphrase" needs
         # to be different between PS 5 and 7 for the *exact* *same* *executable*
         # ... but apparently it does.
         if ($PSVersionTable.PSVersion.Major -lt 7) {
            $local:output = (Write-Output "y" | ssh-keygen -t rsa -b 4096 -f $local:keyfile -N '""')
         } else {
            $local:output = (Write-Output "y" | ssh-keygen -t rsa -b 4096 -f $local:keyfile -N "")
         }
         if (!(Test-Path -Type Leaf -Path $local:keyfile)) {
            throw "sshkeygen"
         }
         $local:keycontents = (Get-Content -Path $local:keyfile) -join ''
      } catch {
         $GLOBALS.skipResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccountSshKey"; message = "Cannot generate sshkey for use. Skipping Import-SafeguardAssetAccountSshKey test."; })
         throw "sshkeygen"
      }
      # simple ssh key import is "AssetPartition","AssetToSet","AccountToSet","PrivateKey"
      $local:content = @(Get-Content "$($DATA.filePaths.imports)/template-account-sshkey.csv")
      $local:content += "-1,ps.system.other.1,ps.other.account.1.1,`"$local:keycontents`""
      $local:content += "-1,ps.system.other.1,ps.other.account.1.2,`"$local:keycontents`""
      $local:content += "-1,ps.system.other.2,ps.other.account.2.1,`"$local:keycontents`""
      $local:content += "-1,ps.system.other.2,ps.other.account.2.2,`"$local:keycontents`""
      $local:importFile = "$($DATA.filePaths.imports)/import-accounts-sshkey.csv"
      Set-Content -Path $local:importFile -Value $local:content > $null
      $local:resultsFile = "./AssetAccountSshKeyImportResults.csv"
      Remove-Item -Path $local:resultsFile -ErrorAction SilentlyContinue > $null
      $local:results = Import-SafeguardAssetAccountSshKey -Path $local:importFile
      if ($null -eq $local:results -or $local:results.Count -eq 0) {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccountSshKey"; message = "Failed to import $local:importFile"; })
         if (Test-Path -Type Leaf -Path $local:resultsFile) {
            Get-Content -Path $local:resultsFile
         }
      } else {
         # Don't need to store these for removal since the asset will be removed
         $local:AccountSshKeys = $local:results | Where { $_.GetType().Name -ne "Int32" }
         $local:successCount = $local:AccountSshKeys.Count
         $local:failureCount = ($local:results | Where { $_.GetType().Name -eq "Int32" }).Count
         # there is no output for successful imports for this command
         $GLOBALS.goodResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccountSshKey"; message = "Succssful Import-SafeguardAssetAccountSshKey call. ImportCount=$local:successCount; FailCount=$local:failureCount"; })
         $GLOBALS.formatTable(@{ output = $local:AccountSshKeys; })
      }
   } catch {
      if ($_ -ne "sshkeygen") {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Import-SafeguardAssetAccountSshKey"; message = "Unexpected error"; ex = $_; })
      }
   } finally {
      Remove-Item -Path $local:keyfile -ErrorAction SilentlyContinue > $null
      Remove-Item -Path "$($local:keyfile).pub" -ErrorAction SilentlyContinue > $null
   }

   $script:completedSuccessfully = $true
}
catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "general"; message = "Error working with Reports"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}


