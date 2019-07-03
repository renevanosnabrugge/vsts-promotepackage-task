Import-Module $PSScriptRoot\vsts-promotepackage-task\ps_modules\VsTsTaskSdk

#get these values, by running the task in the pipeline with system.debug true 
$env:INPUT_FEED = "Guid or name of Feed" 
$env:INPUT_INPUTTYPE = "nameVersion" # nameVersion or packageFiles

# nameVersion inputs:
$env:INPUT_PACKAGEIDS = "Guids or names of package(s)" # comma or semicolon separated
$env:INPUT_VERSION = "version of package"

# packageFiles inputs:
$env:INPUT_PACKAGESDIRECTORY = "Root directory of package files"
$env:INPUT_PACKAGESPATTERN = "**\*.nupkg`n!**\*.symbols.nupkg`n**\*.tgz" # newline or semicolon separated

$env:INPUT_RELEASEVIEW = "Guid or name of release view"

# Info required to make the task run in test mode
$env:PROMOTEPACKAGE_PAT = "pat"
$azdoaccount = "Azure DevOps account name"
$connectedServiceName="localrun"

Describe 'Test Promote Release View' {
    It 'Uses a Azure DevOps Account' {

        $env:SYSTEM_TEAMFOUNDATIONSERVERURI="https://dev.azure.com/$($azdoaccount)/"
        Invoke-VsTsTaskScript -ScriptBlock { . $PSScriptRoot\vsts-promotepackage-task\vsts-promotepackage-task.ps1 } -Verbose
    }
    It 'Uses a Visual Studio Account' {
        $env:SYSTEM_TEAMFOUNDATIONSERVERURI="https://$($azdoaccount).visualstudio.com/"
        Invoke-VsTsTaskScript -ScriptBlock { . $PSScriptRoot\vsts-promotepackage-task\vsts-promotepackage-task.ps1 } -Verbose
    }
}