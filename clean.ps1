# Clean out all files from output paths
. ".\harness-data.ps1"
if ("Y" -eq (Read-Host "Enter Y to clear out all output files")) {
   foreach ($d in ($DATA.outputPaths.GetEnumerator())) {
      if ((Test-Path $d.Value -PathType Container) -and "Y" -eq (Read-Host "Enter Y to nuke everything in $($d.Value)")) {
         Write-Host "Clearing .\$(Split-Path -Path $($d.Value) -Leaf)"
         Remove-Item -Recurse -Path "$($d.Value)\*"
      }
   }
}
