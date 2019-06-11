# Release Notes

[![Build status](https://osnabrugge.visualstudio.com/RVO-VSTSExtensions/_apis/build/status/vsts-promotepackage-task/vsts-promotepackage-task)](https://osnabrugge.visualstudio.com/RVO-VSTSExtensions/_build/latest?definitionId=118)

> **11-06-2019**
> - Reverted to older version because of Bug. published changes in new version 2.0. Does not work with Universal Packages

> **28-05-2019**
> - Added ability to select only packages in local feed ([fix issue #19](https://github.com/renevanosnabrugge/vsts-promotepackage-task/issues/19))
> - Fixed an issue when versions contain semver 2.0 compatible parts (e.g. 1.0.19133.1-beta+master.69f88edb)
> - Thanks Michael Zehnder!

> **11-02-2019**
> - Bug in running the task in Release Management due to url 

> **07-02-2019**
> - Accounts natively created in Azure DevOps (dev.azure.com) threw an error when promoting the package ([fix issue #16](https://github.com/renevanosnabrugge/vsts-promotepackage-task/issues/16))
> - Fixed Urls ([fix issue #6](https://github.com/renevanosnabrugge/vsts-promotepackage-task/issues/16),[#9](https://github.com/renevanosnabrugge/vsts-promotepackage-task/issues/9), [#3](https://github.com/renevanosnabrugge/vsts-promotepackage-task/issues/3))
> - Added Support for Pyhton, Maven and Universal Packages
> - Added a Local Test Runner to test easily 

> **10-01-2019**
> - The feed, package and view to promote can now be specified via variables (thanks dhuessmann)

> **02-01-2019**
> - Fixed an issue with editable package version (thanks dhuessmann)

> **18-05-2017**
> - Added: Initial preview release

# Description

**BEWARE: This task does not work for on-prem TFS / Azure DevOps Server**
This task enables you to promote a package in VSTS Package Management to a specific Release View. You can use Release Views to communicate Package Quality as [described here](https://www.visualstudio.com/en-us/docs/package/feeds/views). 
In this task, you select the package feed from your account, the package, the version and the Release View to which you want to promote your package. 

* Supports NuGet and NPM
 
Find the task in the Utility category of Build

# Known issues
 * No support for other feedTypes than NuGet and npm

# Documentation

This task was inspired by a [blogpost](https://roadtoalm.com/2017/01/16/programmatically-promote-your-package-quality-with-release-views-in-vsts/) that I wrote for promoting a package to a Release View
Please check the [Wiki](https://github.com/renevanosnabrugge/vsts-promotepackage-task/wiki) (coming soon).

If you have ideas or improvements, don't hestitate to leave feedback or [file an issue](https://github.com/renevanosnabrugge/vsts-promotepackage-task/issues).
