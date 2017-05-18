[CmdletBinding()]
param()

$feedName = Get-VstsInput -Name feed
$packageId = Get-VstsInput -Name definition
$packageVersion =Get-VstsInput -Name version
$releaseView =Get-VstsInput -Name releaseView

$account = ($env:SYSTEM_TEAMFOUNDATIONSERVERURI -replace "https://(.*)\.visualstudio\.com/", '$1').split('.')[0]
$basepackageurl = ("https://{0}.pkgs.visualstudio.com/DefaultCollection/_apis/packaging/feeds" -f $account)
$basefeedsurl = ("https://{0}.feeds.visualstudio.com/DefaultCollection/_apis/packaging/feeds" -f $account)

function InitializeRestHeaders()
{
	$restHeaders = New-Object -TypeName "System.Collections.Generic.Dictionary[[String], [String]]"
	if([string]::IsNullOrWhiteSpace($connectedServiceName))
	{
		$patToken = GetAccessToken $connectedServiceDetails
		ValidatePatToken $patToken
		$restHeaders.Add("Authorization", [String]::Concat("Bearer ", $patToken))
		
	}
	else
	{
		$Username = $connectedServiceDetails.Authorization.Parameters.Username
		Write-Verbose "Username = $Username" -Verbose
		$Password = $connectedServiceDetails.Authorization.Parameters.Password
		$alternateCreds = [String]::Concat($Username, ":", $Password)
		$basicAuth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($alternateCreds))
		$restHeaders.Add("Authorization", [String]::Concat("Basic ", $basicAuth))
	}
	return $restHeaders
}

function GetAccessToken($vssEndPoint) 
{
        $endpoint = (Get-VstsEndpoint -Name SystemVssConnection -Require)
        $vssCredential = [string]$endpoint.auth.parameters.AccessToken	
        return $vssCredential
}

function ValidatePatToken($token)
{
	if([string]::IsNullOrWhiteSpace($token))
	{
		throw "Unable to generate Personal Access Token for the user. Contact Project Collection Administrator"
	}
}

function Set-PackageQuality
{
   # First get the name of the package (strange REST API behavior) and the Package Feed Type
   $packageURL = "$basefeedsurl/$feedName/packages/$packageId/?api-version=2.0-preview"
   $packResponse = Invoke-RestMethod -Uri $packageURL -Headers $headers -ContentType "application/json" -Method Get 

   $feedType = $packResponse.protocolType
   $packageName = $packResponse.normalizedName


    #API URL is slightly different for npm vs. nuget...
    switch($feedType)
    {
        "npm" { $releaseViewURL = "$basepackageurl/$feedName/$feedType/$packageName/versions/$($packageVersion)?api-version=3.0-preview.1" }
        "nuget" { $releaseViewURL = "$basepackageurl/$feedName/$feedType/packages/$packageName/versions/$($packageVersion)?api-version=3.0-preview.1" }
        default { $releaseViewURL = "$basepackageurl/$feedName/$feedType/packages/$packageName/versions/$($packageVersion)?api-version=3.0-preview.1" }
    }
    
     $json = @{
        views = @{
            op = "add"
            path = "/views/-"
            value = "$releaseView"
        }
    }
Write-Host $releaseViewURL
    $response = Invoke-RestMethod -Uri $releaseViewURL -Headers $headers   -ContentType "application/json" -Method Patch -Body (ConvertTo-Json $json)
    return $response
}

$headers=InitializeRestHeaders
Set-PackageQuality