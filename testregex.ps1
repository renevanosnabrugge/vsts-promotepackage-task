
function Get-Account() {
    param(
        $url
    )

    $uri = [uri]$url
    $hostName = $uri.Host

    if (($hostName -eq "dev.azure.com") -or ($hostName -eq "vsrm.dev.azure.com")) {
        #new style
        $account = $uri.Segments[1].TrimEnd('/') # First segment after hostname
        return $account
    } elseif ($hostName.EndsWith("visualstudio.com")) {
        #old style
        $account = $hostName.Split('.')[0] # First subdomain of hostname
        return $account
    } else {
        Write-Host "On-Premise TFS / Azure DevOps Server not supported"
    }
}


Describe 'Get Account' {
        It 'Uses a Azure DevOps Account' {
            $url="https://dev.azure.com/osnabrugge/"
            $env:SYSTEM_TEAMFOUNDATIONSERVERURI = $url
            $accountReturn = Get-Account -url $url

            $accountReturn | Should -Be "osnabrugge"
        }
        It 'Uses a Azure DevOps Account 2' {
            $url="https://vsrm.dev.azure.com/osnabrugge/"
            $env:SYSTEM_TEAMFOUNDATIONSERVERURI = $url
            $accountReturn = Get-Account -url $url

            $accountReturn | Should -Be "osnabrugge"
        }
        It 'Uses a vs Account' {
            $url="https://osnabrugge.visualstudio.com/"
            $env:SYSTEM_TEAMFOUNDATIONSERVERURI = $url
            $accountReturn = Get-Account -url $url

            $accountReturn | Should -Be "osnabrugge"
        }
        It 'Uses a Azure DevOps Account 2' {
            $url="https://osnabrugge.vsrm.visualstudio.com/"
            $env:SYSTEM_TEAMFOUNDATIONSERVERURI = $url
            $accountReturn = Get-Account -url $url

            $accountReturn | Should -Be "osnabrugge"
        }
    }