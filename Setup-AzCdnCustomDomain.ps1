
Install-Module Az -Force
Import-Module Az.Cdn -Force

$password = ConvertTo-SecureString -String $env:servicePrincipalKey -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($env:servicePrincipalId, $password)

Connect-AzAccount -Tenant $env:tenantId -Credential $credential -ServicePrincipal
Select-AzSubscription -Subscription $env:ARM_SUBSCRIPTION_ID

$cdnProfile = Get-AzCdnProfile -ProfileName StaticCdnProfile -ResourceGroupName $env:RG_NAME
$endpoint = Get-AzCdnEndpoint -ProfileName $cdnProfile.Name -ResourceGroupName $env:RG_NAME

$azCustomDomain = $null

# The friendly name of the custom domain in Azure Portal
$azCdnCustomDomainName = 'FundamentalIncome'

try {
  Write-Host "Enabling custom domain $env:CUSTOM_DOMAIN..."
  $azCustomDomain = New-AzCdnCustomDomain -HostName $env:CUSTOM_DOMAIN -CdnEndpoint $endpoint -CustomDomainName $azCdnCustomDomainName
}
catch {
  Write-Host 'Could not create new custom domain... it looks like it may already exist... Checking'
}

try {
  Write-Host 'Checking for existing custom domain name...'
  $azCustomDomain = Get-AzCdnCustomDomain -CustomDomainName $azCdnCustomDomainName -CdnEndpoint $endpoint
}
catch {
  throw 'Could not create custom domain for CDN Endpoint, it also could not be found!'
}

if ($azCustomDomain.CustomHttpsProvisioningState -ne ('Enabled' -or 'Enabling')) {
  try {
    Write-Host "Enabling HTTPS for $env:CUSTOM_DOMAIN on Resource Id $(azCustomDomain.Id)"
    Enable-AzCdnCustomDomainHttps -ResourceId $azCustomDomain.Id
  }
  catch {
    throw "Error enabling HTTPS for $env:CUSTOM_DOMAIN..."
  }
} elseif ($azCustomDomain -eq $null) {
  throw 'Failed to set custom domain, Domain object was null!'
}


Write-Host "Success:  CDN configured for HTTPS at $env:CUSTOM_DOMAIN" -ForegroundColor Green
