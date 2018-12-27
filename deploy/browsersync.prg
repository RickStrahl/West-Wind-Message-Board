************************************************************************
*  BrowserSync
****************************************
***  Function: Live Reload of Web Browser on save operations
***            for files in the Web folder. Make a change,
***            save, and the browser reloads the active page
***            Typically runs on:
***            http://localhost:3000/SecurityTest 
***    Assume: Install Browser Sync requires Node/NPM:
***            npm install -g browser-sync
***            https://browsersync.io/
***      Pass: lcUrl   -  your local Web url
***            lcPath  -  local path to the Web site
***            lcFiles -  file specs for files to monitor
***
***            all parameters are optional
************************************************************************
FUNCTION BrowserSync(lcUrl, lcPath, lcFiles)
LOCAL lcBrowserSyncCommand

IF EMPTY(lcUrl)
   lcUrl = "localhost/wwthreads"
ENDIF
IF EMPTY(lcPath)
   lcPath = LOWER(FULLPATH("..\web"))
ENDIF
IF EMPTY(lcFiles)
   lcFiles = "**/*.wwt, **/*.wcs,**/*.wc, **/*.md, css/*.css, scripts/*.js, **/*.htm*"
ENDIF

lcOldPath = CURDIR()
CD (lcPath)

lcBrowserSyncCommand = "browser-sync start " +;
                       "--proxy " + lcUrl + " " + ;
                       "--files '" + lcFiles + "'"
                       
RUN /n cmd /k &lcBrowserSyncCommand

*!*	? lcBrowserSyncCommand
*!*	_cliptext = lcBrowserSyncCommand

WAIT WINDOW "" TIMEOUT 1.5
CD (lcOldPath)

DO wwThreadsMain
ENDFUNC
*   BrowserSync