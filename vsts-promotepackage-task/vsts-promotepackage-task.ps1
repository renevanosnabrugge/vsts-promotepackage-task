[CmdletBinding()]
param(
    [boolean]$localRun=$false
)


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
        Write-Verbose "Username = $Username" -Verbose
        if ($localRun -eq $true) {
            $Username = ""
            $Password = $env:pat
        }
        else {
		    $Username = $connectedServiceDetails.Authorization.Parameters.Username
            $Password = $connectedServiceDetails.Authorization.Parameters.Password
        }
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

function Get-FeedId
{
    $ret = ""
    try
    {
        $feedUrl = "$basefeedsurl/$feedName/?api-version=5.0-preview.1"
        Write-Verbose -Verbose "Trying to retrieve feed information: $feedUrl"
        $feedResponse = Invoke-RestMethod -Uri $feedUrl -Headers $headers -ContentType "application/json" -Method Get
        $ret = $feedResponse.id
    }
    catch
    {
        throw "Unhandled exception while reading feed $feedName"
    }

    # If the feed id is empty throw an exception (fallback scenario)
    if ([string]::IsNullOrWhiteSpace($ret))
    {
        throw "Feed $feedName could not be found"
    }

    return $ret
}

function Get-ViewId($FeedId)
{
    $ret = ""
    try
    {
        $viewUrl = "$basefeedsurl/$FeedId/views/$releaseView/?api-version=5.0-preview.1"
        Write-Verbose -Verbose "Trying to retrieve view information: $viewUrl"
        $viewResponse = Invoke-RestMethod -Uri $viewUrl -Headers $headers -ContentType "application/json" -Method Get
        $ret = $viewResponse.id
    }
    catch
    {
        throw "Unhandled exception while reading view $releaseView"
    }

    # If the view id is empty throw an exception (fallback scenario)
    if ([string]::IsNullOrWhiteSpace($ret))
    {
        throw "View $releaseView could not be found"
    }

    return $ret
}

function Get-PackageInfo($FeedId)
{
    $name = "";
    $protocolType = "";
    $id = ""
    $isId = $true
    try
    {
        $packageUrl = "$basefeedsurl/$FeedId/packages/$packageId/?api-version=5.0-preview.1"
        Write-Verbose -Verbose "Trying to retrieve package information: $packageUrl"
        $packageResponse = Invoke-RestMethod -Uri $packageUrl -Headers $headers -ContentType "application/json" -Method Get
        $name = $packageResponse.normalizedName
        $protocolType = $packageResponse.protocolType
        $id = $packageResponse.id
    }
    catch [System.Net.WebException]
    {
        $isId = $false
    }
    catch
    {
        throw "Unhandled exception while reading package $packageId by id"
    }

    # Package not found with id, searching with name
    if ($isId -eq $false)
    {
        try
        {
            Write-Verbose -Verbose "Package with id $packageId not found, searching with name"
            $packagesUrl = "$basefeedsurl/$FeedId/packages?api-version=5.0-preview.1"
            Write-Verbose -Verbose "Retrieving all packages of requested feed: $packagesUrl"
            $packagesResponse = Invoke-RestMethod -Uri $packagesUrl -Headers $headers -ContentType "application/json" -Method Get
            $packages = $packagesResponse.value
            foreach ($package in $packages)
            {
                if ($package.name -eq $packageId)
                {
                    $name = $package.normalizedName
                    $protocolType = $package.protocolType
                    $id = $package.id
                }
            }
        }
        catch
        {
            Write-Verbose -Verbose "Failed to retrieve package information by name"
            throw "Unhandled exception while reading package $packageId by name"
        }
    }

    # If the package id is empty throw an exception (fallback scenario)
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($protocolType))
    {
        throw "Package $packageId could not be found"
    }

    return $id, $name, $protocolType
}

function Get-NormalizedVersion($FeedId, $FeedType, $Id, $PackageVersion)
{
    Write-Verbose "Trying to get package versions"

    #API URL is slightly different for npm vs. nuget...
    switch($FeedType)
    {
        "npm" { $versionsUrl = "$basefeedsurl/$FeedId/$FeedType/$Id/versions?api-version=5.0-preview.1" }
        "nuget" { $versionsUrl = "$basefeedsurl/$FeedId/packages/$Id/versions?api-version=5.0-preview.1" }
        "upack" { $versionsUrl = "$basefeedsurl/$feedId/$FeedType/packages/$Id/versions?api-version=5.0-preview.1" }
        "pypi" { $versionsUrl = "$basefeedsurl/$FeedId/$FeedType/packages/$Id/versions?api-version=5.0-preview.1" }
        default { $versionsUrl = "$basefeedsurl/$FeedId/$FeedType/packages/$Id/versions?api-version=5.0-preview.1" }
    }

    try
    {
        $packageVersionsResponse = Invoke-RestMethod -Uri $versionsUrl -Headers $headers -ContentType "application/json" -Method Get

        $packageVersions = $packageVersionsResponse.value

        # Check version attribute first
        foreach ($version in $packageVersions)
        {
            if ($version.version -eq $PackageVersion)
            {
                Write-Verbose -Verbose "Found a suitable Version (Version field): $($version.version)"
                return $version.normalizedVersion
            }
        }

        # Fall back to normalizedVersion attribute
        foreach ($version in $packageVersions)
        {
            if ($version.normalizedVersion -eq $PackageVersion)
            {
                Write-Verbose -Verbose "Found a suitable Version (normalizedVersion field): $($version.normalizedVersion)"
                return $version.normalizedVersion
            }
        }
    }
    catch
    {
        Write-Verbose -Verbose "Failed to retrieve package version information"
        Write-Error $_
        throw "Unhandled exception while reading package version $PackageName"
    }

    Write-Verbose -Verbose "Package Version $PackageVersion not found for Package $PackageName"
    throw "Package Version $PackageVersion not found for Package $PackageName"
}

function Set-PackageQuality
{
    Write-Host "Promoting version $packageVersion of package $packageId from feed $feedName to view $releaseView"

    # Get ids for feed, package and view
    $feedId = Get-FeedId
    $viewId = Get-ViewId -FeedId $feedId
    $packageInfo = Get-PackageInfo -FeedId $feedId
    $id = $packageInfo[0]
    $packageName = $packageInfo[1]
    $feedType = $packageInfo[2]
    $normalizedVersion = Get-NormalizedVersion -FeedId $feedId -FeedType $feedType -Id $id -PackageVersion $packageVersion

    #API URL is slightly different for npm vs. nuget...
    switch($feedType)
    {
        "npm" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/$packageName/versions/$($normalizedVersion)?api-version=5.0-preview.1" }
        "nuget" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($normalizedVersion)?api-version=5.0-preview.1" }
        "upack" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($normalizedVersion)?api-version=5.0-preview.1" }
        "pypi" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($normalizedVersion)?api-version=5.0-preview.1" }
        default { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($normalizedVersion)?api-version=5.0-preview.1" }
    }

    $json = @{
        views = @{
            op = "add"
            path = "/views/-"
            value = "$viewId"
        }
    }

    Write-Host $releaseViewURL
    $response = Invoke-RestMethod -Uri $releaseViewURL -Headers $headers -ContentType "application/json" -Method Patch -Body (ConvertTo-Json $json)
    return $response
}

function Run() {

$url = $env:SYSTEM_TEAMFOUNDATIONSERVERURI 
$url = $url.ToLower()


if ($url  -like "https://vsrm.dev.azure.com*") {
    #new style
    $account = ($env:SYSTEM_TEAMFOUNDATIONSERVERURI -replace "https://vsrm.dev.azure.com/(.*)\/", '$1').split('.')[0]
    $basepackageurl = ("https://pkgs.dev.azure.com/{0}/_apis/packaging/feeds" -f $account)
    $basefeedsurl = ("https://feeds.dev.azure.com/{0}/_apis/packaging/feeds" -f $account)
}
elseif ($url -like "https://dev.azure.com*")
{
        #new style
        $account = ($env:SYSTEM_TEAMFOUNDATIONSERVERURI -replace "https://dev.azure.com/(.*)\/", '$1').split('.')[0]
        $basepackageurl = ("https://pkgs.dev.azure.com/{0}/_apis/packaging/feeds" -f $account)
        $basefeedsurl = ("https://feeds.dev.azure.com/{0}/_apis/packaging/feeds" -f $account)
}
elseif ($url -like "*visualstudio.com*")
{
    #old style
    $account = ($env:SYSTEM_TEAMFOUNDATIONSERVERURI -replace "https://(.*)\.visualstudio\.com/", '$1').split('.')[0]
    $basepackageurl = ("https://{0}.pkgs.visualstudio.com/DefaultCollection/_apis/packaging/feeds" -f $account)
    $basefeedsurl = ("https://{0}.feeds.visualstudio.com/DefaultCollection/_apis/packaging/feeds" -f $account)
}
else {
    Write-Host "On-Premise TFS / Azure DevOps Server not supported"
}

    $headers=InitializeRestHeaders
    Set-PackageQuality
}

if ($localRun -eq $false)
{   
    $feedName = Get-VstsInput -Name feed
    $packageId = Get-VstsInput -Name definition
    $packageVersion = Get-VstsInput -Name version
    $releaseView =Get-VstsInput -Name releaseView
    Run
}