try {
    Get-Command "writeCallHeader" -ErrorAction Stop > $null
 } catch {
    write-host "Not meant to be run as a standalone script" -ForegroundColor Red
    exit
 }
 $TestBlockName ="Running time Test"
 $blockInfo = testBlockHeader $TestBlockName
 # ===== Covered Commands =====
 #Set-SafeguardTime
try {
    infoResult "Restore-SafeguardBackup" "Do you want to set your SPP box back 30 days.?"
    if ("Y" -eq (Read-Host "Enter Y to continue with setting time -30 day on $($DATA.appliance). Note: no Y means set it to current time.")) {
        infoResult "Set-SafeguardTime" "Warning: This will set your SPP box back 30 days and your user may be unable to stay authenticate while SPP changes the time to catch back up. The users token will expire as SPP jumps to catch up."
        Set-SafeguardTime -SystemTime (get-date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        goodResult "Set-SafeguardTime" "Successfull reset Set-SafeguardTime" 
    }
    else{
        Set-SafeguardTime -SystemTime (get-date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        goodResult "Set-SafeguardTime" "Successfull reset Set-SafeguardTime"
    }
 
 } catch {
    badResult "Set-SafeguardTime" "Unexpected error in Set-SafeguardTime" $_
 }
 
 testBlockHeader $TestBlockName $blockInfo