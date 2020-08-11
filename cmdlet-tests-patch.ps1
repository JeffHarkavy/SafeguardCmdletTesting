try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running Patch Tests"
$blockInfo = testBlockHeader "begin" $TestBlockName
   # TODO - stubbed code
   #Clear-SafeguardPatch
   #Get-SafeguardPatch
   #Install-SafeguardPatch
   #Set-SafeguardPatch

# ===== Covered Commands =====
#

try {
} catch {
   badResult "Patch general" "Unexpected error in Patch test" $_.Exception
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader "end" $TestBlockName $blockInfo

