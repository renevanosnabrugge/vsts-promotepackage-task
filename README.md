# Release Notes

[![Build status](https://osnabrugge.visualstudio.com/RVO-VSTSExtensions/_apis/build/status/vsts-promotepackage-task/vsts-promotepackage-task)](https://osnabrugge.visualstudio.com/RVO-VSTSExtensions/_build/latest?definitionId=118)

>>**01-20-2020**
> -Support for project scoped package feeds[Click for details](https://github.com/renevanosnabrugge/vsts-promotepackage-task/pull/42)


> - All credits go to [amrock-my](https://github.com/amrock-my) for contributing and [jzserai](https://github.com/jzserai) for testing

>>**01-03-2020**
> -Add --force-local to tar flags on Windows (issue #33 with npm packages [Click for details](https://github.com/renevanosnabrugge/vsts-promotepackage-task/pull/41)
> -Azure Devops Server (On-Premise) Support [Click for details](https://github.com/renevanosnabrugge/vsts-promotepackage-task/pull/37) 

> - All credits go to [KocamanFaruk](https://github.com/KocamanFaruk) and [richieto](https://github.com/richieto)

>>**10-16-2019**
> -Fix encoding issue in feed url with possible prerelease package versions (for example 1.1.0+2). When promoting packages with the "+" character, a 404 error occurred (not found). [Click for details](https://github.com/renevanosnabrugge/vsts-promotepackage-task/pull/34)

> - All credits go to [Pieter Gheysens](https://github.com/pietergheysens) 

>>**8-13-2019**
> -Removed dependency on .nuspec XML namespace described in detail in this [Pull Request](https://github.com/renevanosnabrugge/vsts-promotepackage-task/pull/30)
> - All credits go to [Shad Storhaug](https://github.com/NightOwl888) for all his hard work on this

>>**7-19-2019**
> - Major update for Promotion of multiple packages in one go (by specifying the package ids separated by semicolons) described in detail in this [Pull Request](https://github.com/renevanosnabrugge/vsts-promotepackage-task/pull/25)
> - All credits go to [Shad Storhaug](https://github.com/NightOwl888) for all his hard work on this
> - Changed this update to a major update (2.x) and reverted to old version for the 1.x update 

> **11-06-2019**
> - Reverted to older version because of Bug. 

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
