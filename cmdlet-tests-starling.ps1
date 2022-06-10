
try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Starling Tests"
$blockInfo = testBlockHeader $TestBlockName
# ===== Covered Commands =====
# New-SafeguardStarlingSubscription
# Remove-SafeguardStarlingSubscription
# Set-SafeguardStarlingSetting
# Get-SafeguardStarlingJoinUrl
# Get-SafeguardStarlingSubscription
# Invoke-SafeguardStarlingJoin
# New-SafeguardStarling2faAuthentication
#

try {
   $curent = Get-SafeguardStarlingSetting -SettingKey "Environment"
   goodResult "Get-SafeguardStarlingSetting" "Successfully Get-SafeguardStarlingSetting"

   $enviorment = Read-Host "Enter starling enviroment [nothing for prod, '-devtest', ect] Curent value is $($curent.Value). Set to"
   Set-SafeguardStarlingSetting -SettingKey "Environment" -SettingValue "$($enviorment)"
   goodResult "Set-SafeguardStarlingSetting" "Successfully Set-SafeguardStarlingSetting"

   if ("Y" -eq (Read-Host "Enter Y to continue if you have a starling account set up to do this at http://account$($enviorment).cloud.oneidentity.com/")) {
      Invoke-SafeguardStarlingJoin
      goodResult "Invoke-SafeguardStarlingJoin" "Successfully Invoke-SafeguardStarlingJoin"
      goodResult "Get-SafeguardStarlingJoinUrl" "Successfully Get-SafeguardStarlingJoinUrl called by Invoke-SafeguardStarlingJoin"
      goodResult "New-SafeguardStarlingSubscription" "Successfully New-SafeguardStarlingSubscription called by Invoke-SafeguardStarlingJoin"

      Remove-SafeguardStarlingSubscription -Name "Default" -Force
      goodResult "Remove-SafeguardStarlingSubscription" "Successfully Remove-SafeguardStarlingSubscription"
   }

   Get-SafeguardStarlingSubscription
   goodResult "Get-SafeguardStarlingSubscription" "Successfully Get-SafeguardStarlingSubscription"

} catch {
   badResult "Starling general" "Unexpected error in Starling test" $_
} finally {  
   try { Remove-SafeguardStarlingSubscription -Name "Default" -Force > $null } catch {}
}

testBlockHeader $TestBlockName $blockInfo

