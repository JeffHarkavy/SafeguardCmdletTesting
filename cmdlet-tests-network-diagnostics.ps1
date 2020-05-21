try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
# ===== Covered Commands =====
# Invoke-SafeguardClusterPing
# Invoke-SafeguardClusterThroughput
# Invoke-SafeguardMemberPing
# Invoke-SafeguardMemberThroughput
# Invoke-SafeguardPing
# Invoke-SafeguardSessionsPing
# Invoke-SafeguardSessionsTelnet
# Invoke-SafeguardTelnet
#
writeCallHeader "Running Networking Diagnostics Tests"
# TODO - stubbed code
# Some of these need a cluster or SPS - don't have one right now
try {
   #writeCallHeader "Invoke-SafeguardClusterPing"
   #Invoke-SafeguardClusterPing
   #goodResult "Invoke-SafeguardClusterPing" "Success"

   writeCallHeader "Invoke-SafeguardClusterThroughput"
   Invoke-SafeguardClusterThroughput -Megabytes 1
   goodResult "Invoke-SafeguardClusterThroughput" "Success"

   #writeCallHeader "Invoke-SafeguardMemberPing"
   #Invoke-SafeguardMemberPing
   #goodResult "Invoke-SafeguardMemberPing" "Success"

   #writeCallHeader "Invoke-SafeguardMemberThroughput"
   #Invoke-SafeguardMemberThroughput
   #goodResult "Invoke-SafeguardMemberThroughput" "Success"

   writeCallHeader "Invoke-SafeguardPing"
   Invoke-SafeguardPing -NetworkAddress $($realArchiveServer.NetworkAddress)
   goodResult "Invoke-SafeguardPing" "Success"

   #writeCallHeader "Invoke-SafeguardSessionsPing"
   #Invoke-SafeguardSessionsPing
   #goodResult "Invoke-SafeguardSessionsPing" "Success"

   #writeCallHeader "Invoke-SafeguardSessionsTelnet"
   #Invoke-SafeguardSessionsTelnet
   #goodResult "Invoke-SafeguardSessionsTelnet" "Success"

   writeCallHeader "Invoke-SafeguardTelnet"
   Invoke-SafeguardTelnet -NetworkAddress $($realArchiveServer.NetworkAddress) -Port 22
   goodResult "Invoke-SafeguardTelnet" "Success"
}
catch {
   badResult "Network Diagnostics general" "Unexpected error testing network diagnostic commands - $_.Exception.Message"
}
