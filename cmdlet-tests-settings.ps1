try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Settings Tests"
$blockInfo = testBlockHeader $TestBlockName
# ===== Covered Commands =====
# Get-SafeguardApplianceSetting
# Get-SafeguardCoreSetting
# Get-SafeguardDebugSettings
# Get-SafeguardPurgeSettings
# Reset-SafeguardPurgeSettings
# Set-SafeguardApplianceSetting
# Set-SafeguardCoreSetting
# Set-SafeguardDebugSettings
# Update-SafeguardPurgeSettings
#

try {
   Get-SafeguardApplianceSetting | Format-Table
   goodResult "Get-SafeguardApplianceSetting" "Success"

   Get-SafeguardCoreSetting | Format-Table
   goodResult "Get-SafeguardCoreSetting" "Success"

   Get-SafeguardDebugSettings | Format-Table
   goodResult "Get-SafeguardDebugSettings" "Success"

   Get-SafeguardPurgeSettings | Format-Table
   goodResult "Get-SafeguardPurgeSettings" "Success"

   $settingName = "Backup Retention Number"
   $oldSetting = Get-SafeguardApplianceSetting -SettingName $settingName
   $newSetting = Set-SafeguardApplianceSetting -SettingName $settingName -Value $(($oldSetting.Value -as [int]) + 1)
   goodResult "Set-SafeguardApplianceSetting" "Successfully changed $settingName from $($oldSetting.Value) to $($newSetting.value)"
   $newSetting = Set-SafeguardApplianceSetting -SettingName $settingName -Value $oldSetting.Value

   $settingName = "Max Platform Task Retries"
   $oldSetting = Get-SafeguardCoreSetting -SettingName $settingName
   $newSetting = Set-SafeguardCoreSetting -SettingName $settingName -Value $(($oldSetting.Value -as [int]) + 1)
   goodResult "Set-SafeguardCoreSetting" "Successfully changed $settingName from $($oldSetting.Value) to $($newSetting.value)"
   $newSetting = Set-SafeguardCoreSetting -SettingName $settingName -Value $oldSetting.Value

   $settingName = "NetworkDebugEnabled"
   $oldSetting = Get-SafeguardDebugSettings
   $newSetting = Set-SafeguardDebugSettings @{ NetworkDebugEnabled = $true; }
   goodResult "Set-SafeguardDebugSettings" "Successfully changed  from $settingName $($oldSetting.NetworkDebugEnabled) to $($newSetting.NetworkDebugEnabled)"
   $newSetting = Set-SafeguardDebugSettings @{ NetworkDebugEnabled = $false; }

   $settingName = "DeletedAssetRetentionInDays"
   $oldSetting = Get-SafeguardPurgeSettings
   $newSetting = Update-SafeguardPurgeSettings -DeletedAssetRetentionInDays $(($oldSetting.DeletedAssetRetentionInDays -as [int]) - 1)
   goodResult "Update-SafeguardPurgeSettings" "Successfully changed $settingName from $($oldSetting.DeletedAssetRetentionInDays) to $($newSetting.DeletedAssetRetentionInDays)"
   $newSetting = Update-SafeguardPurgeSettings -DeletedAssetRetentionInDays $oldSetting.DeletedAssetRetentionInDays

   Reset-SafeguardPurgeSettings > $null
   goodResult "Reset-SafeguardPurgeSettings" "Success"
} catch {
   badResult "Settings General" "Unexpected error in Settings Tests" $_
} finally {
  try { Reset-SafeguardPurgeSettings > $null } catch {}
}

testBlockHeader $TestBlockName $blockInfo

