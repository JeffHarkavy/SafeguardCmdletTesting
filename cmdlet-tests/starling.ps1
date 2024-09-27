
try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

# TODO
#Get-SafeguardStarlingJoinInstance
#Invoke-SafeguardStarlingJoinBrowser
#New-SafeguardStarlingSubscription

$GLOBALS.currentTest = $DATA.Tests.Starling
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Remove-SafeguardStarlingSubscription -Name "Default" -Force -ErrorAction SilentlyContinue > $null } catch {}
}

try {
   $current = Get-SafeguardStarlingSetting -SettingKey "Environment"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardStarlingSetting"; message = "Successfully Get-SafeguardStarlingSetting"; })

   $enviorment = Read-Host "Enter starling enviroment [nothing for prod, '-devtest', etc.] current value is $(iif $current.Value $current.Value "(nothing)"). Set to"
   Set-SafeguardStarlingSetting -SettingKey "Environment" -SettingValue "$($enviorment)"
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardStarlingSetting"; message = "Successfully Set-SafeguardStarlingSetting"; })

   if ("Y" -eq (Read-Host "Enter Y to continue if you have a starling account set up to do this at http://account$($enviorment).cloud.oneidentity.com/")) {
      Invoke-SafeguardStarlingJoin
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Invoke-SafeguardStarlingJoin"; message = "Successfully Invoke-SafeguardStarlingJoin"; })
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardStarlingJoinUrl"; message = "Successfully Get-SafeguardStarlingJoinUrl called by Invoke-SafeguardStarlingJoin"; })
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardStarlingSubscription"; message = "Successfully New-SafeguardStarlingSubscription called by Invoke-SafeguardStarlingJoin"; })

      
      if ("Y" -eq (Read-Host "Enter Y if your starling account is set up with a 2fa trial")) {
         $ProviderName= Read-Host "Please enter your ProviderName [A string containing the name to give this new identity provider]"
         $APiKey = Read-Host "Please enter your ApiKey[A string containing the API Key obtained from Starling 2FA console]"
         if ("Y" -eq (Read-Host "Enter Y if your wish to make the identity providor $($ProviderName) with the key $($APiKey)")) {
            New-SafeguardStarling2faAuthentication -ProviderName "$($ProviderName)" -ApiKey "$($APiKey)"
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardStarling2faAuthentication"; message = "Successfully New-SafeguardStarling2faAuthentication"; })
         }
      }

      Remove-SafeguardStarlingSubscription -Name "Default" -Force
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Remove-SafeguardStarlingSubscription"; message = "Successfully Remove-SafeguardStarlingSubscription"; })
   }

   Get-SafeguardStarlingSubscription
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardStarlingSubscription"; message = "Successfully Get-SafeguardStarlingSubscription"; })

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Starling general"; message = "Unexpected error in Starling test"; ex = $_; })
} finally {  
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

