************************************************************************
*  Wwthreads_ServerConfig
****************************************
***  Function: Templated Installation routine that can configure the
***            Web Server for you from this file.
***
***            You can modify this script to fit your exact needs
***
***            You can customize operation of this script in 
***            wwthreads.ini in the [ServerConfig] section.
***            
***    Assume: Called from WwthreadsMain.prg startup code
***            with lcAction parameter
***
***            Launch with from the Windows Command Line
***            Wwthreads.exe config
***            or with a specific IIS site/virtual
***            Wwthreads.exe config "IIS://localhost/w3svc/2/root"
***      Pass: lcIISPath  -  IIS Configuration Path (optional)
***                          IIS://localhost/w3svc/1/root
************************************************************************
LPARAMETERS lcIISPath

DO wwUtils	
TRY
	SET CLASSLIB TO WebServer ADDIT
	SET PROCEDURE TO wwXML ADdit
CATCH
ENDTRY

IF !IsAdmin() 
   MESSAGEBOX("Admin privileges are required to configure the Web Server." + CHR(13) +;
              "Please make sure you run this exe using 'Run As Administrator'",;
              48,"Wwthreads Server Configuration")
   RETURN
ENDIF

*** Try to read from Wwthreads.ini [ServerConfig] section
loApi = CREATEOBJECT("wwAPI")
lcIniPath = FULLPATH("Wwthreads.ini")
lcVirtual = loApi.GetProfileString(lcIniPath,"ServerConfig","Virtual")
IF ISNULL(lcVirtual)
  lcVirtual = "wwThreads"
ENDIF
lcScriptMaps = loApi.GetProfileString(lcIniPath,"ServerConfig","ScriptMaps")
IF ISNULLOREMPTY(lcScriptMaps)
  lcScriptMaps = "wc,wcs,wcsx,wwThreads2"  
ENDIF
IF EMPTY(lcIISPath)
  lcIISPath = loApi.GetProfileString(lcIniPath,"ServerConfig","IISPath")
  IF ISNULLOREMPTY(lcIISPath)
     *** Typically this is the root site path
    lcIISPath = "IIS://localhost/w3svc/1/root"
  ENDIF
ENDIF  


*** Other relative configurable settings
lcVirtualPath = LOWER(FULLPATH("..\Web"))
lcScriptPath = lcVirtualPath + "\bin\wc.dll"
lcTempPath = LOWER(FULLPATH(".\temp"))
lcApplicationPool = "WebConnection"
lcServerMode = "IIS7HANDLER"     && "IIS7" (ISAPI) / IISEXPRESS


loWebServer = CREATEOBJECT("wwWebServer")
loWebServer.cServerType = UPPER(lcServerMode)
loWebServer.cApplicationPool = lcApplicationPool
IF !EMPTY(lcIISPath)
   loWebServer.cIISVirtualPath = lcIISPath
ENDIF

WAIT WINDOW NOWAIT "Creating virtual directory " + lcVirtual + "..."
*** Create the virtual directory
IF !loWebServer.CreateVirtual(lcVirtual,lcVirtualPath)   
   WAIT WINDOW TIMEOUT 5 "Couldn't create virtual."
   RETURN
ENDIF


*** Create the Script Maps
lnMaps = ALINES(laMaps,lcScriptMaps,1 + 4,",")
FOR lnx=1 TO lnMaps
    lcMap = laMaps[lnX]
    WAIT WINDOW NOWAIT "Creating Scriptmap " + lcMap + "..."
	  llResult = loWebServer.CreateScriptMap(lcMap, lcScriptPath)	    
    IF !llResult
       WAIT WINDOW TIMEOUT 2 "Failed to create scriptmap " + lcMap
    ENDIF
ENDFOR


WAIT WINDOW NOWAIT "Setting folder permissions..."

lcAnonymousUserName = ""
loVirtual = GETOBJECT(lcIISPath)
lcAnonymousUserName = loVirtual.AnonymousUserName
loVirtual = .NULL.

*** Set access on the Web directory -  should match Application Pool identity
SetAcl(lcVirtualPath,"Administrators","F",.T.)
SetAcl(lcVirtualPath,"Interactive","F",.T.)
SetAcl(lcVirtualPath,"NETWORKSERVICE","F",.T.)
* SetAcl(lcVirtualPath,"OtherUser","F",.T.,"username","password")

*** IUSR Anonymous Access
IF !EMPTY(lcAnonymousUserName)
    llResult = SetAcl(lcVirtualPath,lcAnonymousUserName,"R",.T.)

    *** No unauthorized access to admin folder
    lcAdminPath = ADDBS(lcVirtualPath) + "Admin"
    IF DIRECTORY(lcAdminPath)
   	   llResult = SetAcl(lcAdminPath,lcAnonymousUserName,"N",.t.)
    ENDIF
ENDIF

*** Set access on the Temp directory - should match Application Pool Identity
SetAcl(lcTempPath,"Administrators","F",.T.)
SetAcl(lcVirtualPath,"Interactive","F",.T.)
SetAcl(lcTempPath,"NETWORK SERVICE","F",.T.)
* SetAcl(lcTempPath,"OtherUser","F",.T.,"username","password")

*** COM Server Registration
IF FILE("Wwthreads.exe")
   RUN /n4 "Wwthreads.exe" /regserver

   *** Optionally set DCOM permission - only set if needed
   *** requires that DComLaunchPermissions.exe is available
   * DCOMLaunchPermissions("Wwthreads.WwthreadsServer","INTERACTIVE")
   * DCOMLaunchPermissions("Wwthreads.WwthreadsServer","username","password")
ENDIF

WAIT WINDOW Nowait "Configuration completed..."
RETURN