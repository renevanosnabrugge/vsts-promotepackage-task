
function Get-Account() {
    param(
        $url
    )

    if ($url  -like "https://vsrm.dev.azure.com*") {
        #new style
        $account = ($env:SYSTEM_TEAMFOUNDATIONSERVERURI -replace "https://vsrm.dev.azure.com/(.*)(\/)", '$1').split('.')[0]
    return $account
    }
    elseif ($url -like "https://dev.azure.com*")
    {
            #new style
            $account = ($env:SYSTEM_TEAMFOUNDATIONSERVERURI -replace "https://dev.azure.com/(.*)(\/)", '$1').split('.')[0]
            return $account
        }
    elseif ($url -like "*visualstudio.com*")
    {
        #old style
        $account = ($env:SYSTEM_TEAMFOUNDATIONSERVERURI -replace "https://(.*)\.visualstudio\.com/", '$1').split('.')[0]
        return $account
    }
    else {
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