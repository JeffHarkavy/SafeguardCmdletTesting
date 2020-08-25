try {
   Get-Command "writeCallHeader" -ErrorAction Stop > $null
} catch {
   write-host -ForegroundColor Red "Not meant to be run as a standalone script"
   exit
}
$TestBlockName = "Running A2A Tests"
$blockInfo = testBlockHeader $TestBlockName
# TODO - stubbed code
# Add-SafeguardA2aCredentialRetrieval               
# Clear-SafeguardA2aAccessRequestBroker             
# Clear-SafeguardA2aAccessRequestBrokerIpRestriction
# Clear-SafeguardA2aCredentialRetrievalIpRestriction
# Disable-SafeguardA2aService                       
# Edit-SafeguardA2a                                 
# Enable-SafeguardA2aService                        
# Get-SafeguardA2a                                  
# Get-SafeguardA2aAccessRequestBroker               
# Get-SafeguardA2aAccessRequestBrokerApiKey         
# Get-SafeguardA2aAccessRequestBrokerIpRestriction  
# Get-SafeguardA2aCredentialRetrieval               
# Get-SafeguardA2aCredentialRetrievalApiKey         
# Get-SafeguardA2aCredentialRetrievalInformation    
# Get-SafeguardA2aCredentialRetrievalIpRestriction  
# Get-SafeguardA2aPassword                          
# Get-SafeguardA2aPrivateKey                        
# Get-SafeguardA2aRetrievableAccount                
# Get-SafeguardA2aServiceStatus                     
# Get-SafeguardReportA2aEntitlement                 
# New-SafeguardA2a                                  
# New-SafeguardA2aAccessRequest                     
# Remove-SafeguardA2a                               
# Remove-SafeguardA2aCredentialRetrieval            
# Reset-SafeguardA2aAccessRequestBrokerApiKey       
# Reset-SafeguardA2aCredentialRetrievalApiKey       
# Set-SafeguardA2aAccessRequestBroker               
# Set-SafeguardA2aAccessRequestBrokerIpRestriction  
# Set-SafeguardA2aCredentialRetrievalIpRestriction  

#
#$a2aStatus = Get-SafeguardA2aServiceStatus
#$a2a = Get-SafeguardA2a
#Set-SafeguardA2aAccessRequestBroker -ParentA2a "BaseA2A" -Groups "PermGroup"
#$a2aBroker = Get-SafeguardA2aAccessRequestBroker -ParentA2a "BaseA2A"    
#$api = $a2aBroker.ApiKey
#$a2aRequest = New-SafeguardA2aAccessRequest -Appliance $DATA.appliance -Thumbprint $thumb -ApiKey $api -ForUserName "Perm-User-0" -AssetToUse "PermAsset1" -AccessRequestType Password -AccountToUse "PermAccount1" #-Verbose 
#$a2aRequestState = $a2aRequest.State
#Write-Host "Request state: $a2aRequestState"

# ===== Covered Commands =====
#

try {
} catch {
   badResult "A2A general" "Unexpected error in A2A test" $_
} finally {
#try { if ($directoryAdded -eq 1) { Remove-SafeguardDirectory -DirectoryToDelete $domainname > $null } } catch {}
}

testBlockHeader $TestBlockName $blockInfo

