# 3rd party notice

* This task has been developed by René van Osnabrugge and is not associated directly with Microsoft

# Release Notes

> **10-05-2017**
> - Added: Initial preview release

# Description

This task enables you to check if a build has changed since the last time it has succesfully built. Sometimes a build did not change, but is scheduled for every night. Building is not a big deal, but you do not want 
to trigger a new release when the build did not change. This task enables you to check if a build changed by checking if the CommitID (Git) that triggered it is different than the last succesful build before.
You can set an outut variable which contains a true or false, that you can use in subsequent tasks or in a [custom condition](https://www.visualstudio.com/en-us/docs/build/concepts/process/conditions). 
You can also set a tag to the build that if the build changed or did not change.


This task supports:

 * Check if build changed
 * Setting an output variable with the value 
 * Setting one or multiple tags when the build did not change
 * Setting one or multiple tags when the build changed
  
Enable the OAuth token in options Tab the build pipeline to access the TFS/VSTS REST API
 
Find the task in the Utility category of Build

# Known issues
 * TFVC not yet supported

# Documentation

This task was inspired by a [blogpost](https://roadtoalm.com/2017/05/01/only-trigger-a-release-when-the-build-changed/) that I wrote for checking if a Build changed.
Please check the [Wiki](https://github.com/renevanosnabrugge/vsts-buildchanged-task/wiki) (coming soon).

If you have ideas or improvements, don't hestitate to leave feedback or [file an issue](https://github.com/renevanosnabrugge/vsts-buildchanged-task/issues).

This task is to check whether to execute a subsequent task when a build changed or not. You can do this with [custom condition](https://www.visualstudio.com/en-us/docs/build/concepts/process/conditions). 

To execute a task only when the build did not change use the following statement in the Custom Condition

`and(always(), eq(variables['vars.buildchanged'], 'true'))`
