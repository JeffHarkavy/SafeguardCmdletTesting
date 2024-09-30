try {
   if (-not $GLOBALS.writeCallHeader) { throw "nofunc" }
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}

# TODO - some of these are just aliases, but should try to cover?
#Find-SafeguardMyRequestable
#Get-SafeguardAccessPolicySessionProperty
#Get-SafeguardAccessRequestApiKey
#Get-SafeguardMyApproval
#Get-SafeguardMyReview
#Get-SafeguardRequestableAccount
#Start-SafeguardAccessRequestSession
#Start-SafeguardAccessRequestWebSession

$GLOBALS.currentTest = $DATA.Tests.Requests
$script:blockInfo = $GLOBALS.testBlockHeader()
$script:completedSuccessfully = $false
$script:exceptionCaught = $false
$script:createdItems = @{
   Assets = @();
   AssetAccounts = @();
   AccessPolicies = @();
   Roles = @();
   Users = @();
}

function script:Cleanup() {
   ###############################################################################
   $GLOBALS.writeCallHeader("Cleanup")
   ###############################################################################

   $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Closing access requests")
   $script:requests | ForEach-Object {
      try { Close-SafeguardAccessRequest -Appliance $DATA.appliance -Insecure -AccessToken $script:tokens.Requester -ErrorAction SilentlyContinue -RequestId $_.id > $null } catch {}
   }

   $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Removing created items")
   $script:createdItems.Keys | ForEach-Object {
      $dto = $_
      if ($script:createdItems[$dto].length) {
         foreach ($item in $script:createdItems[$dto]) {
           try {
             Invoke-SafeguardMethod core DELETE "$dto/$($item.id)" > $null
           } catch {
              # Trying to remove accounts or systems with pending access request actions will
              # throw an error, so try it with force.
              if ($_ -match "is referenced by") {
                 try { Invoke-SafeguardMethod core DELETE "$dto/$($item.id)?forceDelete=true" -ErrorAction SilentlyContinue > $null } catch {}
              } else {
                $GLOBALS.warningResult(@{ minVerbosity = 1; cmd = "Cleanup"; message = "Exception trying to remove $dto/$($item.id)."; extra = $_; })
             }
           }
         }
      }
   }
   if ($script:files.Length) {
      $script:files | Foreach {
         if (Test-Path -Type Leaf $_) {
            Remove-Item -Path $_ > $null
         }
      }
   }

   $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Disconnecting ARW users")
   $script:tokens.Keys | ForEach-Object {
      if ($script:tokens.$_) { try { Write-Host -NoNewLine "$_ - "; Disconnect-Safeguard -Appliance $DATA.appliance -Insecure -AccessToken $script:tokens.$_ -ErrorAction SilentlyContinue > $null } catch {} }
   }
}

function script:restoreClipboard($text) {
   try {
      Set-Clipboard -Value $text > $null
   } catch {
      try {
         Set-ClipboardText $text > $null
      }
      catch {
         # meh. we tried to restore the clipoard. oh well.
      }
   }
}

$script:accounts = @()
$script:assets = @()
$script:users = @()
$script:requests = @()
$script:sessionAppliances = @()
$script:testSessionRequests = $false
$script:files = @()
try {
   # First need to set up the request worflow environment
   # - an entitlement and some access policies: pwd, session (RDP and SSH), ssh key
   # A good example for this setup can be found in cmdlet-test-a2a.ps1. I just didn't get around to this cmdlet.
   ###############################################################################
   $GLOBALS.writeCallHeader("Creating / Verifying Access Request Workflow environment")
   ###############################################################################
   $defaultPassword = "AbCD123!@#"
   $securePassword = $defaultPassword | ConvertTo-SecureString -AsPlainText -Force

   try {
      $script:sessionAppliances = (Get-SafeguardSessionCluster) | Select-Object -Property Id,SpsNetworkAddress,SpsHostName
      if ($script:sessionAppliances.Count -eq 0) {
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSessionCluster"; message = "No session appliances exist in this cluster."; })
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Joining"; message = "Attempting to join to SPS appliance $($DATA.clusterSession[0])"; })

         $joinresult = Join-SafeguardSessionCluster -SessionMaster $DATA.clusterSession[0] -SessionUserName $DATA.SPSAdmin -SessionPassword $DATA.SPSAdminPassword
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Join-SafeguardSessionCluster"; message = "Successfully joined to SPS appliance at $($DATA.clusterSession[0])"; })
         $script:sessionAppliances = Get-SafeguardSessionCluster
      } else {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardSessionCluster"; message = "Session Appliances retrieved"; })
         $GLOBALS.formatTable(@{ output = $script:sessionAppliances; })
      }
      $script:testSessionRequests = $true
   } catch {
      $GLOBALS.warningResult(@{ minVerbosity = 1; cmd = "Requests"; message = "Unable to join to SPS. Session-related tests will be skipped."; extra = $_; })
   }

   try {
      $asset = Find-SafeguardAsset $DATA.asset.DisplayName
      if ($asset) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAsset"; message = "found $($DATA.asset.DisplayName)"; }) }
      else {
        $asset = $GLOBALS.createAsset()
        $script:createdItems.Assets += $asset
      }
      $script:assets += $asset

      foreach ($acctName in $DATA.assetAccounts.GetEnumerator()) {
         $found = Find-SafeguardAssetAccount -QueryFilter "Asset.Name eq '$($DATA.asset.DisplayName)' and Name eq '$acctname'"
         if ($found) { $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAssetAccount"; message = "$acctName already exists on $($DATA.asset.DisplayName)"; }) }
         else {
            $found = New-SafeguardAssetAccount -ParentAsset $DATA.asset.DisplayName -NewAccountName $acctname
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAssetAccount"; message = "$acctName successfully created on $($DATA.asset.DisplayName)"; })
            $script:createdItems.AssetAccounts += $found
         }
         Set-SafeguardAssetAccountPassword -AccountToSet $found -NewPassword $securePassword > $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAssetAccountPassword"; message = "$acctName password reset"; })
         Invoke-SafeguardMethod Core PUT "AssetAccounts/$($found.Id)/SshKey?keyFormat=OpenSsh" -Body @{ KeyType = "Rsa"; KeyLength = 2048; Comment = ""; }> $null
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Set-SafeguardAssetAccountSshKey"; message = "$acctName SSH Key reset"; })
         $script:accounts += $found
      }

      foreach ($userKey in $DATA.requestWorkflowUsers.Keys) {
         $result = $GLOBALS.createUser($DATA.requestWorkflowUsers.$userKey)
         $script:users += $result.newUser
         if ($result.isNew) {
            $script:createdItems.Users += $result.newUser
         }
      }

      try { $entitlement = Get-SafeguardEntitlement -EntitlementToGet $DATA.entitlementName -ErrorAction SilentlyContinue } catch {}
      if ($null -eq $entitlement) {
         $entitlement = New-SafeguardEntitlement -Name "$($DATA.entitlementName)" -MemberUsers @($script:users[0],$script:users[1],$script:users[2])
         $script:createdItems.Roles += $entitlement
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardEntitlement"; message = "Created entitlement - $($DATA.entitlementName), Id=$($entitlement.Id)"; })
      } else {
         # need to check the $entitlement.Members to make sure the requester, approver, and reviewer are there
         $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardEntitlement"; message = "Entitlement already exists - $($DATA.entitlementName), Id=$($entitlement.Id)"; })
         $update = $false
         $script:users | ForEach-Object {
            $user = $_
            if (!($entitlement.Members | where {$_.Name -eq $user.Name})) {
               $update = $true
               $entitlement.Members += $user
            }
         }
         if ($update) {
            # need to use invoke to update existing entitlement
            $entitlement = Invoke-SafeguardMethod Core PUT "Roles/$($entitlement.id)/Members" -Body $entitlement.Members
            $GLOBALS.infoResult(@{ minVerbosity = 1; cmd = "New-SafeguardEntitlement"; message = "Added ARW users to entitlement"; })
         }
      }

      $local:jsonAccountScopes = $script:accounts | ForEach { @{ ScopeItemType = "Account"; Id = $_.id; } } | ConvertTo-Json -Compress
      foreach ($local:key in $DATA.accessPolicyBodyString.Keys) {
         $policyName = "$local:key Access Policy"
         try {
            $accessPolicy = $null
            try { $accessPolicy = Get-SafeguardAccessPolicy -EntitlementToGet $entitlement -PolicyToGet $policyName -ErrorAction SilentlyContinue } catch {}
            if ($accessPolicy) { $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicy"; message = "found $policyName"; }) }
            else {
               $policyBody = $DATA.accessPolicyBodyString.$local:key.Replace("#ENTITLEMENT_ID#", $entitlement.Id)
               $policyBody = $policyBody.Replace("#SCOPE_ITEMS#", $local:jsonAccountScopes)
               $connectionPolicy = $null
               if (@('SshSession', 'RdpSession') -contains $local:key) {
                  $url = 'Cluster/SessionModules/' + ($script:sessionAppliances[0].Id) + '/ConnectionPolicies'
                  $connectionPolicy = Invoke-SafeguardMethod Core GET $url -Parameters @{ protocol = $key.replace('Session', ''); filter = "Name eq 'safeguard_$(iif $($local:key -match 'Rdp') 'rdp' 'default')'" }
               }
               $policyBody = $policyBody.Replace("#CONNECTION_MODULE#", $(ifIsNull $connectionPolicy.SessionModuleConnectionId ''))
               $policyBody = $policyBody.Replace("#CONNECTION_POLICY#", $(ifIsNull $connectionPolicy.Id ''))
               $convertedJson = ConvertFrom-Json $policyBody
               $accessPolicy = Invoke-SafeguardMethod Core Post AccessPolicies -Body $convertedJson

               # If the entitlement was added new, then the cleanup at the end will take care
               # of the new access policy. Otherwise, add this to the list of things we created
               # to clean up later.
               if ($script:createdItems.Roles.length -eq 0) {
                  $script:createdItems.AccessPolicies += $accessPolicy
               }
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicy"; message = "Created $policyName"; })
            }
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicy"; message = "Failed to create $policyName"; ex = $_; })
         }
      }
   }
   catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "ARW Environment"; message = "Unexpected error setting up ARW environment"; ex = $_; })
      throw $_
   }

   ###############################################################################
   $GLOBALS.writeCallHeader("Access Request Workflow")
   ###############################################################################
   $script:tokens = @{
      Requester = $null;
      Approver = $null;
      Reviewer = $null;
   }
   try {
      ###############################################################################
      $GLOBALS.writeCallHeader("Auto-Approved Password Requests")
      ###############################################################################

      $local:numberOfRequests = 5

      $script:tokens.Requester = $GLOBALS.sgconnect($null, $DATA.requestWorkflowUsers.requester, $true)
      $local:requester = @{ Appliance = $DATA.appliance; Insecure = $true; AccessToken = $script:tokens.Requester; }

      $script:tokens.Approver = $GLOBALS.sgconnect($null, $DATA.requestWorkflowUsers.approver, $true)
      $local:approver = @{ Appliance = $DATA.appliance; Insecure = $true; AccessToken = $script:tokens.approver; }

      $script:tokens.Reviewer = $GLOBALS.sgconnect($null, $DATA.requestWorkflowUsers.reviewer, $true)
      $local:reviewer = @{ Appliance = $DATA.appliance; Insecure = $true; AccessToken = $script:tokens.reviewer; }

      # Create a couple of requests that are auto-approved and don't require reviews
      for ($i = 0; $i -lt $local:numberOfRequests; $i++) {
         $script:requests += New-SafeguardAccessRequest @local:requester Password -AssetToUse $script:accounts[$i].Asset -AccountToUse $script:accounts[$i] -ReasonComment "foo"
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Created request for $($script:accounts[$i].Asset.Name)/$($script:accounts[$i].Name), id $($script:requests[$i].id)"; })
         $GLOBALS.formatTable(@{ output = $script:requests[$i]; })
      }

      try {
         $reqs = Get-SafeguardAccessRequest @local:requester
         if ($reqs.length -lt $local:numberOfRequests) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequest"; message = "Number of requests retrieved=$($reqs.length), Expected $($local:numberOfRequests)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequest"; message = "Number of requests retrieved=$($reqs.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $reqs = Get-SafeguardMyRequest @local:requester
         if ($reqs.length -lt $local:numberOfRequests) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardMyRequest"; message = "Number of requests retrieved=$($reqs.length), Expected $($local:numberOfRequests)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardMyRequest"; message = "Number of requests retrieved=$($reqs.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardMyRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $reqs = Get-SafeguardActionableRequest @local:requester Requester
         if ($reqs.length -lt $local:numberOfRequests) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest (requester)"; message = "Number of requests retrieved=$($reqs.length), Expected $($local:numberOfRequests)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest (requester)"; message = "Number of requests retrieved=$($reqs.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $reqs = Find-SafeguardAccessRequest @local:requester -QueryFilter "AccountName eq '$($script:accounts[0].Name)'"
         if ($reqs.length -eq 0) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAccessRequest"; message = "Number of requests retrieved=$($reqs.length), Expected $($local:numberOfRequests)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAccessRequest"; message = "Number of requests retrieved=$($reqs.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Find-SafeguardAccessRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $accts = Get-SafeguardMyRequestable @local:requester
         if ($accts.length -lt 4) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardMyRequestable"; message = "Number of accounts retrieved=$($accts.length), expecting at least 4"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardMyRequestable"; message = "Number of accounts retrieved=$($accts.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardMyRequestable "; message = "Exception"; ex = $_; })
      }

      try {
         $accts = Find-SafeguardRequestableAccount @local:requester -AssetQueryFilter "Platform.PlatformType eq 'Ubuntu'"
         # 20 == 5 accounts * 4 access policies per accont
         if ($accts.length -ne 20) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Find-SafeguardRequestableAccount"; message = "Number of accounts retrieved=$($accts.length), expecting 4"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Find-SafeguardRequestableAccount"; message = "Number of accounts retrieved=$($accts.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $accts; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Find-SafeguardRequestableAccount "; message = "Exception"; ex = $_; })
      }

      try {
         # aliases to Get-SafeguardAccessRequestPassword, which calls Edit-SafeguardAccessRequest
         $pwd = Get-SafeguardAccessRequestCheckoutPassword @local:requester -RequestId $script:requests[0].id
         if ($pwd -ne $defaultPassword) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestCheckoutPassword"; message = "Retrieved password from $($script:requests[0].id) not what was expected. Retrieved '$pwd', Expected '$defaultPassword'"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestCheckoutPassword"; message = "Retrieved expected password for $($script:requests[0].id)"; })
         }
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestCheckoutPassword "; message = "Exception"; ex = $_; })
      }

      $local:savedClipboard = Get-Clipboard
      Copy-SafeguardAccessRequestPassword @local:requester -RequestId $script:requests[0].id > $null
      $clipboardPwd = Get-Clipboard
      if ($clipboardPwd -ne $pwd) {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Copy-SafeguardAccessRequestPassword"; message = "Copied password from $($script:requests[0].id) not what was expected. Copied '$clipboardPwd', Expected '$pwd'"; })
      } else {
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Copy-SafeguardAccessRequestPassword"; message = "Copied expected password for $($script:requests[0].id)"; })
      }

      script:restoreClipboard $local:savedClipboard

      #ssh key request tests
      ###############################################################################
      $GLOBALS.writeCallHeader("Auto-Approved SSH Key Requests")
      ###############################################################################
      # since all of the above work was done with the first account, use a different one
      $local:acctIdx = 1
      try {
         $local:sshKeyRequest = $null
         try {
            $local:sshKeyRequest = New-SafeguardAccessRequest @local:requester SshKey -AssetToUse $script:accounts[$local:acctIdx].Asset -AccountToUse $script:accounts[$local:acctIdx] -ReasonComment "foo"
            $script:requests += $local:sshKeyRequest
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Created Ssh key request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshKeyRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:sshKeyRequest; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Failed to create Ssh key request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
         }

         $local:savedClipboard = Get-Clipboard
         try {
            # this command puts the passphrase on the clipboard and adds a command history item
            # Since we don't know ahead of time what the passphrase will be we'll just check to
            # see if the clipboard is different that what was there and consider that a success.
            Get-SafeguardAccessRequestSshKey @local:requester -RequestId $local:sshKeyRequest.Id
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Retrieved Ssh key for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshKeyRequest.id)"; })
            if ((Get-Clipboard) -ne $local:savedClipboard) {
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Passphrase saved to clipboard: $(Get-Clipboard)"; })
            } else {
               $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Passphrase has not been saved to clipboard"; })
            }

            # command that was pused to history is assumed to be "ssh -i <file> account@asset"
            $local:commandline = (get-content (Get-PSReadlineOption).HistorySavePath) | Select-Object -Last 1
            if ($local:commandline -match "ssh -i") {
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Command line pushed into history: $local:commandline"; })
               # Try to parse the file name out of the ssh command line and check
               # to see that the file exists and looks vaguely key-like
               $local:keyfilename = ($local:commandline -split ' ')[2]
               $script:files += $local:keyfilename
               if (Test-Path -Type Leaf $local:keyfilename) {
                  if (((Get-Content $local:keyfilename) -join ' ') -match "--BEGIN RSA PRIVATE KEY---.*--END RSA PRIVATE KEY---") {
                     $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "File content looks like a private key: $local:keyfilename"; })
                  } else {
                     $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "File content does not look like a private key: $local:keyfilename"; })
                  }
               } else {
                  $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Cannot find key file $local:keyfilename"; })
               }
            } else {
               $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Command line failed to push to history. Last command line: $local:commandline"; })
            }
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Failed retrieve Ssh key for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
         } finally {
            restoreClipboard $local:savedClipboard
         }

         try {
            # -Raw retrieves the information rather that putting it on the clipboard and adding command history
            $local:rawResults = Get-SafeguardAccessRequestSshKey @local:requester -RequestId $local:sshKeyRequest.Id -Raw
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Retrieved Ssh key for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshKeyRequest.id)"; })
            if ($local:rawResults.PrivateKey -match '(?smi)-BEGIN RSA PRIVATE KEY-.*-END RSA PRIVATE KEY-' -and
                  $local:rawResults.Passphrase -and
                  $local:rawResults.PublicKey -match '^ssh-rsa .+' -and
                  $local:rawResults.FingerprintSha256 -and
                  $local:rawResults.Fingerprint -and
                  $local:rawResults.SshKeyFormat -eq "OpenSsh" -and
                  $local:rawResults.KeyType -eq "Rsa" -and
                  $local:rawResults.KeyLength -eq 2048) {
               $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Get-SafeguardAccessRequestSshKey -Raw information looks good"; })
            } else {
               $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Get-SafeguardAccessRequestSshKey -Raw information incorrect"; extra = $local:rawResults; })
            }
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Failed retrieve Ssh key for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
         } finally {
            restoreClipboard $local:savedClipboard
         }
      } catch {
         $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Auto-Approved Key Requests"; message = "Skipping remainder of Auto-Approved SSH Key Request tests"; })
      }

      #ssh session request tests
      ###############################################################################
      $GLOBALS.writeCallHeader("Auto-Approved SSH Session Requests")
      ###############################################################################
      # Password request w/ approver are using Accounts user_0003 and user_0004, so we'll use
      # user_0005 for the two session requests
      $local:acctIdx = 4
      try {
         $local:sshSessionRequest = $null

         try {
            $local:sshSessionRequest = New-SafeguardAccessRequest @local:requester Ssh -AssetToUse $script:accounts[$local:acctIdx].Asset -AccountToUse $script:accounts[$local:acctIdx] -ReasonComment "foo"
            $script:requests += $local:sshSessionRequest
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Created Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshSessionRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:sshSessionRequest; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Failed to create Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
            throw
         }

         try {
            $local:hostKey = Get-SafeguardAccessRequestSshHostKey @local:requester -RequestId $local:sshSessionRequest.Id
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshHostKey"; message = "Retrieved host key for Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshSessionRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:hostKey; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshHostKey"; message = "Failed to retrieve Host Key Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
            throw
         }

         try {
            $local:sshUrl = Get-SafeguardAccessRequestSshUrl @local:requester -RequestId $local:sshSessionRequest.Id
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshUrl"; message = "Retrieved Ssh Url for Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshSessionRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:sshUrl; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshUrl"; message = "Failed to retrieve Ssh Url Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
            throw
         }

         try {
            $local:sshSessionSshKey = Get-SafeguardAccessRequestSshKey @local:requester -RequestId $local:sshSessionRequest.Id -Raw
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Retrieved Ssh Key for Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshSessionRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:sshSessionSshKey; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestSshKey"; message = "Failed to retrieve Ssh Key for Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
            throw
         }

         Close-SafeguardAccessRequest -Appliance $DATA.appliance -Insecure -AccessToken $script:tokens.Requester -RequestId $local:sshSessionRequest.Id
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Close-SafeguardAccessRequest"; message = "Closed Ssh session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:sshSessionRequest.id)"; })
      } catch {
         $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Auto-Approved SSH Session Requests"; message = "Skipping remainder of Auto-Approved SSH Session tests"; })
      }

      #rdp session request tests
      ###############################################################################
      $GLOBALS.writeCallHeader("Auto-Approved RDP Session Requests")
      ###############################################################################
      try {
         $local:rdpSessionRequest = $null
         try {
            $local:rdpSessionRequest = New-SafeguardAccessRequest @local:requester RemoteDesktop -AssetToUse $script:accounts[$local:acctIdx].Asset -AccountToUse $script:accounts[$local:acctIdx] -ReasonComment "foo"
            $script:requests += $local:rdpSessionRequest
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Created RDP session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:rdpSessionRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:rdpSessionRequest; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Failed to create RDP session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
            throw
         }

         try {
            $local:rdpUrl = Get-SafeguardAccessRequestRdpUrl @local:requester -RequestId $local:rdpSessionRequest.Id
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestRdpUrl"; message = "Retrieved RDP Url for RDP session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:rdpSessionRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:rdpUrl; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestRdpUrl"; message = "Failed to retrieve RDP Url for RDP session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
            throw
         }

         try {
            $local:rdpFile = Get-SafeguardAccessRequestRdpFile @local:requester -RequestId $local:rdpSessionRequest.Id  -OutFile "$($DATA.filePaths.reports)\request.rdp"
            $script:files += "$($DATA.filePaths.reports)\request.rdp"
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestRdpFile"; message = "Retrieved RDP File for RDP session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name), requestId $($local:rdpSessionRequest.id)"; })
            $GLOBALS.formatTable(@{ output = $local:rdpFile; })
         } catch {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestRdpFile"; message = "Failed to retrieve RDP File for RDP session request for $($script:accounts[$local:acctIdx].Asset.Name)/$($script:accounts[$local:acctIdx].Name)"; ex = $_; })
            throw
         }
      } catch {
         $GLOBALS.skipResult(@{ minVerbosity = 1; cmd = "Auto-Approved RDP Session Requests"; message = "Skipping remainder of Auto-Approved RDP Session tests"; })
      }

      # clear these out for the next batch
      $GLOBALS.writeHostColor($GLOBALS.COLORS.info, "Closing first round of access requests")
      $script:requests | ForEach-Object {
         try { Close-SafeguardAccessRequest -Appliance $DATA.appliance -Insecure -AccessToken $script:tokens.Requester -RequestId $_.id -ErrorAction SilentlyContinue > $null } catch {}
      }

      ###############################################################################
      $GLOBALS.writeCallHeader("Password Requests with Approve and Review")
      ###############################################################################
      # Now to create some requests that need approval and review - just doing Password requests,
      # not doing SSH key and session requests
      # First off, update the Password access policy so it requires approval and review
      # Password request w/ 1 approver and review required
      $policyName = "Password Access Policy"
      $accessPolicy_Apr = Get-SafeguardAccessPolicy -EntitlementToGet $entitlement -PolicyToGet $policyName
      $accessPolicy_Apr.ApproverProperties.RequireApproval = $true
      $accessPolicy_Apr.ReviewerProperties = @{ RequiredReviewers = 1; }
      $accessPolicy_Apr.ApproverSets = @(
         @{ RequiredApprovers = 1; Approvers = @(($script:users | where { $_.Name -eq "approver" })); }
      )
      $accessPolicy_Apr.Reviewers = @(($script:users | where { $_.Name -eq "reviewer" }));
      $accessPolicy_Apr = Invoke-SafeguardMethod Core PUT "AccessPolicies/$($accessPolicy_Apr.id)" -Body $accessPolicy_Apr
      $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessPolicy"; message = "Updated $policyName to include Approve and Review"; })

      $script:requests = @()
      for ($i = 0; $i -lt $local:numberOfRequests; $i++) {
         # First two accounts were created as auto-approve
         # Second 2 require approval and review
         $script:requests += New-SafeguardAccessRequest @local:requester Password -AssetToUse $script:accounts[$i].Asset -AccountToUse $script:accounts[$i] -ReasonComment "foo"
         $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "New-SafeguardAccessRequest"; message = "Created request for $($script:accounts[$i].Asset.Name)/$($script:accounts[$i].Name), id $($script:requests[$i].id)"; })
         $GLOBALS.formatTable(@{ output = $script:requests[$i]; })
      }

      try {
         $reqs = Get-SafeguardActionableRequest @local:approver Approver
         if ($reqs.length -eq 0) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest (approver)"; message = "Number of requests retrieved=$($reqs.length), Expected $($local:numberOfRequests)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest (approver)"; message = "Number of requests retrieved=$($reqs.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $req = Approve-SafeguardAccessRequest @local:approver -RequestId $script:requests[0].id
         if (!$req) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Approve-SafeguardAccessRequest"; message = "Failed to approve request $($script:requests[0].id)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Approve-SafeguardAccessRequest"; message = "Successfully approved request $($script:requests[0].id)"; })
         }
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Approve-SafeguardAccessRequest"; message = "Exception"; ex = $_; })
      }

      try {
         $req = Edit-SafeguardAccessRequest @local:approver -RequestId $script:requests[1].id -Action Approve -Comment "A comment was entered"
         if (!$req) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAccessRequest"; message = "Failed to approve request $($script:requests[1].id) with comment"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAccessRequest"; message = "Successfully approved request $($script:requests[1].id) with comment"; })
         }
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Edit-SafeguardAccessRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $req = Deny-SafeguardAccessRequest @local:approver -RequestId $script:requests[2].id
         if (!$req) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Deny-SafeguardAccessRequest"; message = "Failed to approve request $($script:requests[2].id)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Deny-SafeguardAccessRequest"; message = "Successfully approved request $($script:requests[2].id)"; })
         }
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Deny-SafeguardAccessRequest"; message = "Exception"; ex = $_; })
      }

      try {
         $pwd = Get-SafeguardAccessRequestCheckoutPassword @local:requester -RequestId $script:requests[0].id
         if ($pwd -ne $defaultPassword) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestCheckoutPassword"; message = "Retrieved password from $($script:requests[0].id) not what was expected. Retrieved '$pwd', Expected '$defaultPassword'"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestCheckoutPassword"; message = "Retrieved expected password for $($script:requests[0].id) for approved request"; })
         }
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestCheckoutPassword (requester)"; message = "Exception"; ex = $_; })
      }

      try {
         $req = Revoke-SafeguardAccessRequest @local:approver -RequestId $script:requests[0].id
         if (!$req) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Revoke-SafeguardAccessRequest"; message = "Request revoke failed for $($script:requests[0].id)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Revoke-SafeguardAccessRequest"; message = "Approver successfully revoked request $($script:requests[0].id)"; })
         }
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Revoke-SafeguardAccessRequest"; message = "Exception"; ex = $_; })
      }

      try {
         $reqs = Get-SafeguardAccessRequestActionLog @local:reviewer -RequestId $script:requests[0].id
         if ($reqs.length -eq 0) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestActionLog (reviewer)"; message = "Number of requests retrieved=$($reqs.length), Expected 1"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestActionLog (reviewer)"; message = "Number of requests retrieved=$($reqs.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardAccessRequestActionLog (reviewer)"; message = "Exception"; ex = $_; })
      }

      try {
         $reqs = Get-SafeguardActionableRequest @local:reviewer Reviewer
         if ($reqs.length -eq 0) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest (reviewer)"; message = "Number of requests retrieved=$($reqs.length), Expected 1"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest (reviewer)"; message = "Number of requests retrieved=$($reqs.length)"; })
         }
         $GLOBALS.formatTable(@{ output = $reqs; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardActionableRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $req = Assert-SafeguardAccessRequest @local:reviewer -RequestId $script:requests[0].id
         if (!$req) {
            $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Assert-SafeguardAccessRequest"; message = "Failed to submit review for $($script:requests[0].id)"; })
         } else {
            $GLOBALS.goodResult(@{ minVerbosity = 1; cmd = "Assert-SafeguardAccessRequest"; message = "Review successfully submitted for $($script:requests[0].id)"; })
         }
         $GLOBALS.formatTable(@{ output = $req; })
      } catch {
         $GLOBALS.badResult(@{ minVerbosity = 1; cmd = "Assert-SafeguardAccessRequest "; message = "Exception"; ex = $_; })
      }

      try {
         $rpt = Get-SafeguardReportDailyAccessRequest -stdout
         $globals.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardReportDailyAccessRequest"; message = "successful report to stdout"; })
         $GLOBALS.formatTable(@{ output = ($rpt -split "`r`n"); })
      } catch {
         $globals.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardReportDailyAccessRequest "; message = "exception"; ex = $_; })
      }

      try {
         # There's no easy way to know exactly what file was just generated, so as long as it doesn't error out - cool!
         Get-SafeguardReportDailyAccessRequest -OutputDirectory "$($DATA.filePaths.reports)"
         $globals.goodResult(@{ minVerbosity = 1; cmd = "Get-SafeguardReportDailyAccessRequest"; message = "Successful report to CSV."; })
      } catch {
         $globals.badResult(@{ minVerbosity = 1; cmd = "Get-SafeguardReportDailyAccessRequest "; message = "exception"; ex = $_; })
      }
   } catch {
      $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "ARW"; message = "Unexpected error in ARW"; ex = $_; })
      throw $_
   }

   $script:completedSuccessfully = $true
} catch {
   $script:exceptionCaught = $true
   $GLOBALS.badResult(@{ minVerbosity = 0; cmd = "Access Requests general"; message = "Unexpected error in Access Requests test"; ex = $_; })
} finally {
   if (!($script:completedSuccessfully -or $script:exceptionCaught)) {
      Write-Host
      $GLOBALS.infoResult(@{ minVerbosity = 0; cmd = "END  "; message = "Early Termination. Ctrl-C?"; })
   }

   script:Cleanup

   $GLOBALS.testBlockHeader($script:blockInfo)
}

