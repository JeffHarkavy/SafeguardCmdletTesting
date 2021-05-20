try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Patch Tests"
$blockInfo = testBlockHeader $TestBlockName
# ===== Covered Commands =====
# Clear-SafeguardPatch
# Get-SafeguardPatch
# Install-SafeguardPatch
# Set-SafeguardPatch
#

$savedcolors = setProgressBarColors

try {
   if ($testBranch -match "^other:") {
      throw "Patch testing not done for 'Other' test branch. Skipping all Patch tests."
   }
   $patchPath = (iif ($testBranch -eq "LTS") $DATA.patchPathLTS $DATA.patchPathFeature) + (iif $isVM "vm\" "")
   if (-not (Test-Path $patchPath -PathType Container)) {
      throw "Can not find directory for patch - $patchPath. Skipping all Patch tests."
   }

   # Find the newest patch file in the designated directory, but give the user
   # the option to veto it, JIC
   $patchFile = (Get-ChildItem "$patchPath\*.sgp" | Sort CreationTime | Select -Last 1)
   if (-not (Test-Path $patchFile -PathType Leaf)) {
      throw "Can not find patch file - $patchFile. Skipping all Patch tests."
   }
   infoResult "Patch file" "$(Split-Path -Leaf $patchFile)"
   if ("Y" -ne (Read-Host "Enter Y to proceed using this patch for $($DATA.appliance)")) {
      exit
   }

   # If appliance is already clustered this can take a long time
   try {
      infoResult "Set-SafeguardPatch" "Starting Set-SafeguardPatch"
      $patchResults = Set-SafeguardPatch -Patch $patchFile -Force
      if ($patchResults) {
         $obj = $patchResults #ConvertFrom-JSON -InputObject $patchResults
         if ($obj.Errors.Count) {
            if ($obj.Errors -match "cannot be applied to this version" -and (formatSgVersion $obj.Metadata.PatchVersion) -eq $sgVersion) {
               infoResult "Set-SafeguardPatch" "Patch is $(formatSgVersion $obj.Metadata.PatchVersion) - $($DATA.appliance) is already at that version"
            } else {
               badResult "Set-SafeguardPatch" "Errors returned: " + ($obj.Errors -join "`n")
               throw "Errors returned from Set-SafeguardPatch"
            }
         }
         if ($obj.Warnings.Count) {
            infoResult "Set-SafeguardPatch" "Warnings returned: " + ($obj.Warnings -join "`n")
         }
      }
      goodResult "Set-SafeguardPatch" "Patch $DATA.patchFileName successfully staged"
   } catch {
      if ($_.Exception.Message -match "cannot be applied to this version" -and (formatSgVersion $_.PatchVersion) -eq $sgVersion) {
         infoResult "Set-SafeguardPatch" "Patch is $(formatSgVersion  $_.PatchVersion) - $($DATA.appliance) is already at that version"
      } else {
         badResult "Set-SafeguardPatch" "Unexpected error" $_
         throw $_
      }
   }

   Get-SafeguardPatch
   goodResult "Get-SafeguardPatch" "Successfully retrieved patch information"

   Clear-SafeguardPatch > $null
   goodResult "Clear-SafeguardPatch" "Successfully cleared patch information"

   # This is going to take a while. Maybe a long while.
   # If appliance is already clustered this can take a REALLY long time
   try {
      infoResult "Install-SafeguardPatch" "Starting Install-SafeguardPatch"
      $patchResults = Install-SafeguardPatch -Patch $patchFile -Force
      if ($patchResults) {
         $obj = $patchResults #ConvertFrom-JSON -InputObject $patchResults
         if ($obj.Errors -match "cannot be applied to this version" -and (formatSgVersion $obj.Metadata.PatchVersion) -eq $sgVersion) {
            infoResult "Set-SafeguardPatch" "Patch is $(formatSgVersion $obj.Metadata.PatchVersion) - $($DATA.appliance) is already at that version"
         } elseif ($obj.Errors.Count) {
            badResult "Install-SafeguardPatch" "Errors returned: " + ($obj.Errors -join "`n")
            throw "Errors returned from Install-SafeguardPatch"
         }
         if ($obj.Warnings.Count) {
            infoResult "Install-SafeguardPatch" "Warnings returned: " + ($obj.Warnings -join "`n")
         }
      }
      goodResult "Install-SafeguardPatch" "Patch $DATA.patchFileName successfully installed"
   } catch {
      if ($_ -match "cannot be applied to this version") {
         infoResult "Install-SafeguardPatch" "Patch can not be applied"
      } else {
         badResult "Install-SafeguardPatch" "Unexpected error" $_
         throw $_
      }
   }

   if ((Get-SafeguardClusterMember).Count -gt 1) {
      infoResult "Get-SafeguardClusterMember" "Other cluster members exist. No extra patching will be attempted."
   } else {
      infoResult "Get-SafeguardClusterMember" "This is a standalone appliance. Replicas are expected to be $($DATA.clusterReplicas -join ",")"
      $doPatches = Read-Host "Enter Y to apply this patch to the replicas"
      if ($doPatches -eq "Y") {
         foreach ($repl in $DATA.clusterReplicas) {
            $replToken = sgConnect $repl $true
            goodResult "Connect-Safeguard" "Successful access token received for $($DATA.clusterReplicas[0])"

            infoResult "Install-SafeguardPatch" "Attempting patch on $repl"
            $patchResults = Install-SafeguardPatch -Appliance $repl -AccessToken $replToken -Patch $patchFile -Force
            if ($patchResults) {
               $obj = $patchResults #ConvertFrom-JSON -InputObject $patchResults
               if ($obj.Errors -match "cannot be applied to this version" -and (formatSgVersion $obj.Metadata.PatchVersion) -eq $sgVersion) {
                  infoResult "Install-SafeguardPatch" "Patch is $(formatSgVersion $obj.Metadata.PatchVersion) - $repl is already at that version"
                  continue
               } elseif ($obj.Errors.Count) {
                  badResult "Install-SafeguardPatch" "Errors returned: " + ($obj.Errors -join "`n")
                  throw "Errors returned from Install-SafeguardPatch"
               }
               if ($obj.Warnings.Count) {
                  infoResult "Install-SafeguardPatch" "Warnings returned: " + ($obj.Warnings -join "`n")
               }
            }
            goodResult "Install-SafeguardPatch" "Patch $DATA.patchFileName successfully installed on $repl"
         }
      }
   }

} catch {
   badResult "Patch general" "Unexpected error in Patch test" $_
} finally {
   try { Clear-SafeguardPatch > $null } catch {}
   setProgressBarColors $savedcolors
}

testBlockHeader $TestBlockName $blockInfo

