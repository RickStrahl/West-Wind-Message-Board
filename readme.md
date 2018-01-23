# West Wind Message Board Sample 
#### A sample application for the West Wind Web Connection FoxPro framework

This is the repository that contains the latest changes to the** West Wind Message Board Sample Application** that ships with West Wind Web Connection. We've removed the sample inside of the installation for a number of configuration issues, and instead have it published here so that the code is always up to date with what is actually running on the live site. 


You can check out the live, running application at:

* **<a href="http://support.west-wind.com" target="top">http://support.west-wind.com</a>**

Here's what it looks like:

![](http://support.west-wind.com/PostImages/2016/_4LF0SCEV7.png)

### Code Installation Notes
This is my live development setup so the build and various startup shortcut links have hard coded links to special locations for my Web Connection install which lives in a non-standard location. If you want to build or use the shortcuts you might have to double check the batch files and .lnk files to make sure they are pointing at the right locations.

### Updating an existing Installation
If you already have an installation of wwThreads and you are **updating** you can simply copy all the files on top of your existing installation **with the exception of** customized configuration files:

* deploy\config.fpw
* deploy\wwthreads.ini
* web\web.config

If this is a new installation, check these files and make sure that paths are set correctly and settings are configured. Ideally you will be using an existing Web Connection installation and these files should already be configured - simply don't update them and you should be fine.

### Configuring the Web Site (IIS)
If you want to run the message board under IIS, you can run a project configuration script that sets up the virtual, scriptmaps and other server configuration options. You need to use the FoxPro IDE, but make sure you run as an **Administrator**:

```foxpro
CD <wwThreadsInstallFolder>\deploy
DO wwthreads_serverconfig.prg
```

### Message Board Data
The repository doesn't include the data because binary files in the repo are a pain. You an use the files from the `Templates\EmptyData` and copy them into the `deploy\data` folder to get initial data. 

### No Project File
The repository doesn't include the binary project file, instead it's encoded by [Christof Wollenhaupt's TwoFox](http://www.foxpert.com/downloads.htm) using GenXml/GenCode.