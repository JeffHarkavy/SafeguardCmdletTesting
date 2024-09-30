try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Settings
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

  try { Reset-SafeguardPurgeSettings -ErrorAction SilentlyContinue > $null } catch {}
}

try {
   $result = Get-SafeguardApplianceSetting
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardApplianceSetting"; message = "Success"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $result = Get-SafeguardCoreSetting
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardCoreSetting"; message = "Success"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $result = Get-SafeguardDebugSettings
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardDebugSettings"; message = "Success"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $result = Get-SafeguardPurgeSettings
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardPurgeSettings"; message = "Success"; })
   $GLOBALS.formatTable(@{ output = $result; })

   $settingName = "Backup Retention Number"
   $oldSetting = Get-SafeguardApplianceSetting -SettingName $settingName
   $newSetting = Set-SafeguardApplianceSetting -SettingName $settingName -Value $(($oldSetting.Value -as [int]) + 1)
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardApplianceSetting"; message = "Successfully changed $settingName from $($oldSetting.Value) to $($newSetting.value)"; })
   $newSetting = Set-SafeguardApplianceSetting -SettingName $settingName -Value $oldSetting.Value

   $settingName = "Max Platform Task Retries"
   $oldSetting = Get-SafeguardCoreSetting -SettingName $settingName
   $newSetting = Set-SafeguardCoreSetting -SettingName $settingName -Value $(($oldSetting.Value -as [int]) + 1)
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardCoreSetting"; message = "Successfully changed $settingName from $($oldSetting.Value) to $($newSetting.value)"; })
   $newSetting = Set-SafeguardCoreSetting -SettingName $settingName -Value $oldSetting.Value

   $settingName = "NetworkDebugEnabled"
   $oldSetting = Get-SafeguardDebugSettings
   $newSetting = Set-SafeguardDebugSettings @{ NetworkDebugEnabled = $true; }
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardDebugSettings"; message = "Successfully changed  from $settingName $($oldSetting.NetworkDebugEnabled) to $($newSetting.NetworkDebugEnabled)"; })
   $newSetting = Set-SafeguardDebugSettings @{ NetworkDebugEnabled = $false; }

   $settingName = "DeletedAssetRetentionInDays"
   $oldSetting = Get-SafeguardPurgeSettings
   $newSetting = Update-SafeguardPurgeSettings -DeletedAssetRetentionInDays $(($oldSetting.DeletedAssetRetentionInDays -as [int]) - 1)
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Update-SafeguardPurgeSettings"; message = "Successfully changed $settingName from $($oldSetting.DeletedAssetRetentionInDays) to $($newSetting.DeletedAssetRetentionInDays)"; })
   $newSetting = Update-SafeguardPurgeSettings -DeletedAssetRetentionInDays $oldSetting.DeletedAssetRetentionInDays

   Reset-SafeguardPurgeSettings > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Reset-SafeguardPurgeSettings"; message = "Success"; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Settings General"; message = "Unexpected error in Settings Tests"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

