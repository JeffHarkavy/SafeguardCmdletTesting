try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

$GLOBALS.currentTest = $DATA.Tests.Patch
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false

$script:savedcolors = $GLOBALS.setProgressBarColors()

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   try { Clear-SafeguardPatch -ErrorAction SilentlyContinue > $null } catch {}
   $GLOBALS.setProgressBarColors($script:savedcolors)
}

try {
   if ($testBranch -match "^other:") {
      throw "Patch testing not done for 'Other' test branch. Skipping all Patch tests."
   }
   $patchPath = (iif ($testBranch -eq "LTS") $DATA.patchPathLTS $DATA.patchPathFeature) + (iif $isVM "vm\" "")
   if (Test-Path $patchPath -PathType Container) {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Test-Path"; message = "$patchPath is available"; })
   } else {
      $GLOBALS.warningResult(@{ minVerbosity = 0; cmd = "Test-Path"; message = "The directory or file share for $patchPath cannot be found."; })
      $GLOBALS.warningResult(@{ minVerbosity = 0; cmd = "Test-Path"; message = "Make sure you have a file share to $($DATA.patchPathShare) on drive $(($patchPath -split '\\')[0])"; })
      throw "Can not find directory for patch - $patchPath. Skipping all Patch tests."
   }

   # Find the newest patch file in the designated directory, but give the user
   # the option to veto it, JIC
   $patchFile = (Get-ChildItem "$patchPath\*.sgp" | Sort CreationTime | Select -Last 1)
   if (-not (Test-Path $patchFile -PathType Leaf)) {
      throw "Can not find patch file - $patchFile. Skipping all Patch tests."
   }
   $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Patch file"; message = "$(Split-Path -Leaf $patchFile)"; })
   if ("Y" -ne (Read-Host "Enter Y to proceed using this patch for $($DATA.appliance)")) {
      exit
   }

   # Depending on bandwidth and where the test are being run from,
   # the patch upload can be stupid-long (download from network share
   # to local machine then upload to whereever).
   # Patching itself can be a long process.
   # If appliance is already clustered patching can be a *really* long process.
   try {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardPatch"; message = "Starting Set-SafeguardPatch"; })
      $patchResults = Set-SafeguardPatch -Patch $patchFile -Force
      if ($patchResults) {
         $obj = $patchResults #ConvertFrom-JSON -InputObject $patchResults
         if ($obj.Errors.Count) {
            if ($obj.Errors -match "cannot be applied to this version" -and ($GLOBALS.formatSgVersion($obj.Metadata.PatchVersion)) -eq $sgVersion) {
               $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardPatch"; message = "Patch is $($GLOBALS.formatSgVersion($obj.Metadata.PatchVersion)) - $($DATA.appliance) is already at that version"; })
            } else {
               $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardPatch"; message = "Errors returned: " + ($obj.Errors -join "`n"); })
               throw "Errors returned from Set-SafeguardPatch"
            }
         }
         if ($obj.Warnings.Count) {
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardPatch"; message = "Warnings returned: " + ($obj.Warnings -join "`n"); })
         }
      }
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardPatch"; message = "Patch $DATA.patchFileName successfully staged"; })
   } catch {
      if ($_.Exception.Message -match "cannot be applied to this version" -and ($GLOBALS.formatSgVersion($_.PatchVersion) -eq $sgVersion)) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardPatch"; message = "Patch is $(formatSgVersion  $_.PatchVersion) - $($DATA.appliance) is already at that version"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Set-SafeguardPatch"; message = "Unexpected error"; ex = $_; })
         throw $_
      }
   }

   Get-SafeguardPatch
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardPatch"; message = "Successfully retrieved patch information"; })

   Clear-SafeguardPatch > $null
   $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Clear-SafeguardPatch"; message = "Successfully cleared patch information"; })

   # This is going to take a while. Maybe a long while.
   # If appliance is already clustered this can take a REALLY long time
   try {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Starting Install-SafeguardPatch"; })
      $patchResults = Install-SafeguardPatch -Patch $patchFile -Force
      if ($patchResults) {
         $obj = $patchResults #ConvertFrom-JSON -InputObject $patchResults
         if ($obj.Errors -match "cannot be applied to this version" -and ($GLOBALS.formatSgVersion($obj.Metadata.PatchVersion)) -eq $sgVersion) {
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Set-SafeguardPatch"; message = "Patch is $($GLOBALS.formatSgVersion($obj.Metadata.PatchVersion)) - $($DATA.appliance) is already at that version"; })
         } elseif ($obj.Errors.Count) {
            $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Install-SafeguardPatch"; message = "Errors returned: " + ($obj.Errors -join "`n"); })
            throw "Errors returned from Install-SafeguardPatch"
         }
         if ($obj.Warnings.Count) {
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Warnings returned: " + ($obj.Warnings -join "`n"); })
         }
      }
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Patch $DATA.patchFileName successfully installed"; })
   } catch {
      if ($_ -match "cannot be applied to this version") {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Patch can not be applied"; })
      } else {
         $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Install-SafeguardPatch"; message = "Unexpected error"; ex = $_; })
         throw $_
      }
   }

   if ((Get-SafeguardClusterMember).Count -eq 1) {
      $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardClusterMember"; message = "No other cluster members exist. No extra patching will be attempted."; })
   } else {
      $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Get-SafeguardClusterMember"; message = "This is a standalone appliance. Replicas are expected to be $($DATA.clusterReplicas -join ",")"; skipCount = 2; })
      $doPatches = Read-Host "Enter Y to apply this patch to the replicas"
      if ($doPatches -eq "Y") {
         foreach ($repl in $DATA.clusterReplicas) {
            $replToken = $GLOBALS.sgConnect($repl, $null, $true)
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Connect-Safeguard"; message = "Successful access token received for $($DATA.clusterReplicas[0])"; })

            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Attempting patch on $repl"; })
            $patchResults = Install-SafeguardPatch -Appliance $repl -AccessToken $replToken -Patch $patchFile -Force
            if ($patchResults) {
               $obj = $patchResults #ConvertFrom-JSON -InputObject $patchResults
               if ($obj.Errors -match "cannot be applied to this version" -and ($GLOBALS.formatSgVersion($obj.Metadata.PatchVersion)) -eq $sgVersion) {
                  $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Patch is $($GLOBALS.formatSgVersion($obj.Metadata.PatchVersion)) - $repl is already at that version"; })
                  continue
               } elseif ($obj.Errors.Count) {
                  $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Install-SafeguardPatch"; message = "Errors returned: " + ($obj.Errors -join "`n"); })
                  throw "Errors returned from Install-SafeguardPatch"
               }
               if ($obj.Warnings.Count) {
                  $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Warnings returned: " + ($obj.Warnings -join "`n"); })
               }
            }
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Install-SafeguardPatch"; message = "Patch $DATA.patchFileName successfully installed on $repl"; })
         }
      }
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Patch general"; message = "Unexpected error in Patch test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}


