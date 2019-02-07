. .\vsts-promotepackage-task\vsts-promotepackage-task.ps1 -localRun $true

#get these values, by running the task in the pipeline with system.debug true 
$feedName = "Guid of Feed" 
$packageId = "Guid of package"
$packageVersion = "version of package"
$releaseView = "Guid of release view"
$connectedServiceName="localrun"
$env:pat="pat"

Describe 'Test Promote Release View' {
    It 'Uses a Azure DevOps Account' {

        $env:SYSTEM_TEAMFOUNDATIONSERVERURI="https://dev.azure.com/$($azdoaccount)/"
        Run
    }
    It 'Uses a Visual Studio Account' {
        $env:SYSTEM_TEAMFOUNDATIONSERVERURI="https://$($azdoaccount).visualstudio.com/"
        Run
    }
}