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
        $ex = [string]::Concat($_.Exception.ToString(), $_.ScriptStackTrace)
        throw "Unhandled exception while reading feed $feedName`n$ex"
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
        $ex = [string]::Concat($_.Exception.ToString(), $_.ScriptStackTrace)
        throw "Unhandled exception while reading view $releaseView`n$ex"
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
    #$ret = ""
    $isId = $true
    try
    {
        $packageUrl = "$basefeedsurl/$FeedId/packages/$packageId/?api-version=5.0-preview.1"
        Write-Verbose -Verbose "Trying to retrieve package information: $packageUrl"
        $packageResponse = Invoke-RestMethod -Uri $packageUrl -Headers $headers -ContentType "application/json" -Method Get
        $name = $packageResponse.normalizedName
        $protocolType = $packageResponse.protocolType
        #$ret = $packageResponse.id
    }
    catch [System.Net.WebException]
    {
        $isId = $false
    }
    catch
    {
        $ex = [string]::Concat($_.Exception.ToString(), $_.ScriptStackTrace)
        throw "Unhandled exception while reading package $packageId by id`n$ex"
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
                }
            }
        }
        catch
        {
            $ex = [string]::Concat($_.Exception.ToString(), $_.ScriptStackTrace)
            Write-Verbose -Verbose "Failed to retrieve package information by name`n$ex"
            throw "Unhandled exception while reading package $packageId by name`n$ex"
        }
    }

    # If the package id is empty throw an exception (fallback scenario)
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($protocolType))
    {
        throw "Package $packageId could not be found"
    }

    return $name, $protocolType
}

function Set-PackageQuality
{
    Write-Host "Promoting version $packageVersion of package $packageId from feed $feedName to view $releaseView"

    # Get ids for feed, package and view
    $feedId = Get-FeedId
    $viewId = Get-ViewId -FeedId $feedId
    $packageInfo = Get-PackageInfo -FeedId $feedId
    $packageName = $packageInfo[0]
    $feedType = $packageInfo[1]

    #API URL is slightly different for npm vs. nuget...
    switch($feedType)
    {
        "npm" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/$packageName/versions/$($packageVersion)?api-version=5.0-preview.1" }
        "nuget" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($packageVersion)?api-version=5.0-preview.1" }
        "upack" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($packageVersion)?api-version=5.0-preview.1" }
        "pypi" { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($packageVersion)?api-version=5.0-preview.1" }
        default { $releaseViewURL = "$basepackageurl/$feedId/$feedType/packages/$packageName/versions/$($packageVersion)?api-version=5.0-preview.1" }
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

function Initalize-Request() {

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
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string]$name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function New-PackageObject {
    $package = New-Object -TypeName PSObject
    $package | Add-Member -MemberType NoteProperty -Name Name -Value ''
    $package | Add-Member -MemberType NoteProperty -Name Version -Value ''
    return $package
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Get-NuGetPackageMetadata([string]$filePath) {
    $package = New-PackageObject
    $zip = [System.IO.Compression.ZipFile]::OpenRead($filePath)
    $tempFilePath = (New-TemporaryFile).FullName
    try {
        $nuspecEntry = $zip.Entries | Where-Object { $_.FullName -like '*.nuspec' } | Select-Object -First 1
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($nuspecEntry, $tempFilePath, $true)
        $ns = @{ msxml = "http://schemas.microsoft.com/packaging/2012/06/nuspec.xsd" }
        $metadata = Select-Xml -Path $tempFilePath -Namespace $ns -XPath "//msxml:metadata" | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty ChildNodes
        $package.Name = ($metadata | Where-Object {$_.Name -eq 'id' } | Select-Object -First 1).InnerText
        $package.Version = ($metadata | Where-Object {$_.Name -eq 'version' } | Select-Object -First 1).InnerText
    } finally {
        Remove-Item $tempFilePath -Force -ErrorAction SilentlyContinue
        $zip.Dispose()
    }
    return $package
}

function Get-NpmPackageMetadata([string]$filePath) {
    $package = New-PackageObject
    $tempDir = New-TemporaryDirectory
    try {
        if ($IsWindows -eq $null) {
            $IsWindows = $Env:OS.StartsWith('Windows')
        }
        $flags = if ($IsWindows) { '-xvzf' } else { 'xvzf' }
        tar $flags `"$filePath`" -C `"$tempDir`" 2> $null
        $packageJsonPath = "$tempDir/package/package.json"
        $packageJson = Get-Content -Raw -Path $packageJsonPath | ConvertFrom-Json
        $package.Name = $packageJson.name
        $package.Version = $packageJson.version
    } finally {
        Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue
    }
    return $package
}

function Get-PackageMetadata([string]$filePath) {
    $extension = [System.IO.Path]::GetExtension($filePath)
    if ($extension -eq '.nupkg') {
        return Get-NuGetPackageMetadata $filePath
    } else { # ($extension -eq '.tgz')
        return Get-NpmPackageMetadata $filePath
    }
}

function Run() {
    Initalize-Request
    if ($inputType -eq "nameVersion") {
        $packageIds = Get-VstsInput -Name packageIds -Require
        $packageVersion = Get-VstsInput -Name version -Require

        $ids = $packageIds -Split ',|;'
        Write-Host "Promoting $($ids.Length) package(s) named '$packageIds' with version '$packageVersion'"
        foreach ($id in $ids) {
            $packageId = $id
            Set-PackageQuality
        }
    } else { # ($inputType -eq "packageFiles")
        $packagesDirectory = Get-VstsInput -Name packagesDirectory -Require
        $packagesPatternParse = Get-VstsInput -Name packagesPatternParse -Require

        if (!(Test-Path $packagesDirectory)) {
            Write-Error "The path '$packagesDirectory' doesn't exist."
        }
        $patterns = $packagesPatternParse -Split '\n|;'
        Write-Host "Promoting package(s) by reading metadata from package file(s) matching pattern '$patterns' from root directory '$packagesDirectory'"

        $paths = Find-VstsMatch -DefaultRoot $packagesDirectory -Pattern $patterns
        Write-Host "Matching paths found:`n$paths"
        foreach ($path in $paths) {
            $package = Get-PackageMetadata $path
            $packageId = $package.Name
            $packageVersion = $package.Version
            Set-PackageQuality
        }
    }
}

if ($localRun -eq $false)
{   
    $feedName = Get-VstsInput -Name feed -Require
    $inputType = Get-VstsInput -Name inputType -Require
    $releaseView = Get-VstsInput -Name releaseView -Require
    Run
}
