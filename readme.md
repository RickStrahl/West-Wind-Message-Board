## West Wind Message Board Sample
# A sample application for the West Wind Web Connection FoxPro framework

This is the repository that contains the latest changes to the West Wind Message Board sample application that ships with West Wind Web Connection. The code here will always be the most current and what will eventually be shipped.

You can check out the running application at:

* **<a href='http://support.west-wind.com' target='wwthreadsexternal'>http://support.west-wind.com</a>**

Here's what the running application looks like:
![](http://support.west-wind.com/PostImages/2016/_4LF0SCEV7.png)


### Code Installation Notes
This is my live development setup so the build and various startup shortcut links have hardcoded links to special locations for my Web Connection install which lives in a non-standard location. If you want to build or use the shortcuts you might have to double check the batch files and .lnk files to make sure they are pointing at the right locations.

### Configuration Files
If you already have an installation of wwThreads and you are updating you can simply copy all the files ontop of your existing installation **with the exception of**:

* deploy\config.fpw
* deploy\wwthreads.ini
* web\web.config
* web\scripts\wwEditor_settings.js

If this is a new installation, check these files and make sure that paths are set correctly and settings are configured. Ideally you will be using an existing Web Connection installation and these files should already be configured - simply don't update them and you should be fine.

### Restore Scripts with Bower
You'll also have to run Bower to restore the various script libraries. To do this you'll need to install NodeJs/NPM then use NPM to install Bower.

```cmd
cd web
bower install
```