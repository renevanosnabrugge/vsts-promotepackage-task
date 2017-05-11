[CmdletBinding()]
param()

$feedName = Get-VstsInput -Name feed
$packageId = Get-VstsInput -Name definition
$packageVersion =Get-VstsInput -Name version
$releaseView =Get-VstsInput -Name releaseView
$feedType =Get-VstsInput -Name feedType

$baseurl = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI 
$baseprojecturl += $baseurl +  $env:SYSTEM_TEAMPROJECT + "/_apis"
$basefeedsurl = $baseurl -replace ".visualstudio", ".feeds.visualstudio"


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
   
    #API URL is slightly different for npm vs. nuget...
    switch($feedType)
    {
        "npm" { $releaseViewURL = "$basepackageurl/$feedName/$feedType/$packageId/versions/$($packageVersion)?api-version=3.0-preview.1" }
        "nuget" { $releaseViewURL = "$basepackageurl/$feedName/$feedType/packages/$packageId/versions/$($packageVersion)?api-version=3.0-preview.1" }
        default { $releaseViewURL = "$basepackageurl/$feedName/$feedType/packages/$packageId/versions/$($packageVersion)?api-version=3.0-preview.1" }
    }
    
     $json = @{
        views = @{
            op = "add"
            path = "/views/-"
            value = "$releaseView"
        }
    }

    $response = Invoke-RestMethod -Uri $releaseViewURL -Headers $headers   -ContentType "application/json" -Method Patch -Body (ConvertTo-Json $json)
    return $response
}

$headers=InitializeRestHeaders
Set-PackageQuality