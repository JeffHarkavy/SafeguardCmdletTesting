try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host "Not meant to be run as a standalone script" -ForegroundColor Red
   exit
}
$TestBlockName ="Running Filter Properties Tests"
$blockInfo = testBlockHeader $TestBlockName

function nestedPropertyCheck($call, $object, $prefix) {
   $failures = [System.Collections.ArrayList]@()
   $depth++
   #JIC there are some nested recursive definitions somewhere
   if ($depth -gt 10) {
      $failures.Add("Max depth of 10 exceeded - call=$call, prefix=$prefix")
      return $failures
   }
   try {
      $props = $object | get-member -membertype noteproperty
      $props | ForEach-Object {$idx = 0} {
         if ($_.Definition -match "PSCustomObject") {
            $n = $_.Name
            $newprefix = $prefix -ne "" ? "$prefix.$n" : $n 
            $nestedFailures = nestedPropertyCheck $call $object."$n" "$newprefix"
            if ($nestedFailures.length -gt 0) {
               $failures.AddRange($nestedFailures)
            }
         } elseif ( $_.Definition -match "^Object\[\]") {
           $n = $prefix -ne "" ? "$prefix.$($_.Name)" : $_.Name
           if (-not $quiet) {
              write-host -ForegroundColor Cyan "SKIPPED $n"
           }
         } else {
           $n = $prefix -ne "" ? "$prefix.$($_.Name)" : $_.Name
           try {
            $script:loops++
            if ($quiet) {
              if ($script:loops % 5 -eq 0) {
                 write-host -NoNewLine $script:loops
              } else {
                 write-host -NoNewLine "."
              }
            }
            $filter = "$n ne null"
            $count = invoke-safeguardmethod core GET $call -parameters @{filter=$filter; count=$true}
            if (-not $quiet) {
              goodResult "GET $call" "$n - count=$count"
            }
           } catch {
             $failures.Add("FAILED : $n") > $null
           }
         }
         $idx++
      }
   } catch {
      $failures.Add("FAILED : get-member $call - $prefix : L:$($_.InvocationInfo.ScriptLineNumber) $($_.Exception.Message)") > $null
   }
   $depth--
   return $failures
}

function checkAllProperties($topLevel) {
   infoResult "START" "######## $topLevel ########"
   try {
      $obj = Invoke-expression "invoke-safeguardmethod core GET $topLevel -parameters @{page=0;limit=1}"
      if ($null -eq $obj -or $obj -eq "" -or $obj.length -eq 0) {
         infoResult "$topLevel" "GET returned no results"
         return
      }
      $script:loops = 0
      $results = nestedPropertyCheck $topLevel $obj[0] ""
      if ($quiet -and $script:loops -gt 0) {
         Write-Host
      }
      if ($results.length -gt 0) {
         $results | ForEach-Object { badResult "$toplevel" $_ }
      } else {
         goodResult "$topLevel" "No failures"
      }
   } catch {
      badResult "$topLevel" "Unexpected error checking $topLevel" $_
   } finally {
      infoResult "END  " "######## $topLevel ########`n"
   }
}
# ===== Covered DTOs =====
#  see DTO ForEach-Object below
#
#  Note - a "GET" of the DTO must return something, e.g., if you
#  don't have an AccountGroup defined then checking filter properties
#  for AccountGroups will not work. This is reported as an infoResult
#  in the output and is not considered a failure.
#
try {
   $depth = 0
   $loops = 0
   $quiet = $true
   @("AccessPolicies", "AccessRequests", "AccountGroups", "ArchiveServers", `
      "AssetAccounts", "AssetGroups", "AssetPartitions", "Assets", `
      "EmailTemplates", "Events", "EventSubscribers", "Identities", `
      "IdentityProviders", "IdentityProviderTypes", "Licenses", "Platforms", `
      "PolicyAccounts", "PolicyAssets", "ReasonCodes", "Roles", `
      "SshAlgorithms", "SshKeys", "TicketSystems", "TimeZones", `
      "UserGroups", "Users") | ForEach-Object {
      checkAllProperties $_
   }
}
catch {
   badResult "general" "Error working with Filter Properties" $_
} finally {
}

testBlockHeader $TestBlockName $blockInfo

