
try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Starling Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
   # TODO - stubbed code
   #Get-SafeguardStarlingSubscription
   #Invoke-SafeguardStarlingJoin
   #New-SafeguardStarling2faAuthentication
   #New-SafeguardStarlingSubscription
   #Remove-SafeguardStarlingSubscription
   #Set-SafeguardStarlingSetting
#
# ===== Covered Commands =====
#

try {
} catch {
   badResult "Starling general" "Unexpected error in Starling test" $_.Exception
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo

