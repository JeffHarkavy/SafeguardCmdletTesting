
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

      
      if ("Y" -eq (Read-Host "Enter Y if your starling account is set up with a 2fa trial")) {
         $ProviderName= Read-Host "Please enter your ProviderName [A string containing the name to give this new identity provider]"
         $APiKey = Read-Host "Please enter your ApiKey[A string containing the API Key obtained from Starling 2FA console]"
         if ("Y" -eq (Read-Host "Enter Y if your wish to make the identity providor $($ProviderName) with the key $($APiKey)")) {
            New-SafeguardStarling2faAuthentication -ProviderName "$($ProviderName)" -ApiKey "$($APiKey)"
            goodResult "New-SafeguardStarling2faAuthentication" "Successfully New-SafeguardStarling2faAuthentication"
         }
      }

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

