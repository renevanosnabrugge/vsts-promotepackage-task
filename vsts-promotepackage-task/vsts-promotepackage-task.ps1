[CmdletBinding()]
param()

$outputVarBuildResult = Get-VstsInput -Name outputVarBuildResult
$tagsBuildChanged = Get-VstsInput -Name tagsBuildChanged
$tagsBuildNotChanged =Get-VstsInput -Name tagsBuildNotChanged

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
    [CmdletBinding()]
    [OutputType([object])]
    param
    (
        [string] $feedType="nuget",
        [string] $feedName="",
        [string] $packageId="",
        [string] $packageVersion="",
        [string] $packageQuality=""
        
    )

    $token = New-VSTSAuthenticationToken
    
    #API URL is slightly different for npm vs. nuget...
    switch($feedType)
    {
        "npm" { $releaseViewURL = "$basepackageurl/$feedName/npm/$packageId/versions/$($packageVersion)?api-version=3.0-preview.1" }
        "nuget" { $releaseViewURL = "$basepackageurl/$feedName/nuget/packages/$packageId/versions/$($packageVersion)?api-version=3.0-preview.1" }
        default { $releaseViewURL = "$basepackageurl/$feedName/nuget/packages/$packageId/versions/$($packageVersion)?api-version=3.0-preview.1" }
    }
    
     $json = @{
        views = @{
            op = "add"
            path = "/views/-"
            value = "$packageQuality"
        }
    }

    $response = Invoke-RestMethod -Uri $releaseViewURL -Headers @{Authorization = $token}   -ContentType "application/json" -Method Patch -Body (ConvertTo-Json $json)
    return $response
}

$headers=InitializeRestHeaders
Set-PackageQuality