************************************************************************
*FUNCTION WwthreadsMain
******************************
***   Created: 03/04/2016
***  Function: Web Connection Mainline program. Responsible for setting
***            up the Web Connection Server and get it ready to
***            receive requests in file messaging mode.
***
***            You can configure your server with
***            Wwthreads.exe "config"
***            Wwthreads.exe "config" "IIS://localhost/w3svc/21/root"
************************************************************************
LPARAMETER lcAction, lvParm1, lvParm2

*** This is the file based start up code that gets
*** the  server form up and running
#INCLUDE WCONNECT.H

* WAIT WINDOW "RICK3" Timeout 1

*** PUBLIC flag allows server to never quit
*** - unless EXIT button code is executed
RELEASE goWCServer 

SET TALK OFF
SET NOTIFY OFF


*** Load the Web Connection class libraries
IF FILE("WCONNECT.APP")
   DO ("WCONNECT.APP")
ELSE
      DO WCONNECT
ENDIF

*** Optionally add Server Config execution
IF VARTYPE(lcAction) = "C" AND StartsWith(LOWER(lcAction),"config")
         do Wwthreads_ServerConfig.prg with lvParm1
      RETURN 
ENDIF

*** Load the server - wc3DemoServer class below
goWCServer = CREATE("WwthreadsServer")

*** Live Reload Server if program files are changed on disk (File Watcher)  
IF goWCServer.oConfig.lLiveReloadServer AND Application.StartMode = 0
   DO LiveReloadServer
ENDIF

IF !goWCServer.lDebugMode   
   SET DEBUG OFF
   SET STATUS BAR OFF
   SET DEVELOP OFF
   SET SYSMENU OFF
ELSE
   SET DEBUG ON
   SET DEVELOP ON
ENDIF

IF TYPE("goWCServer")#"O"
   =MessageBox("Unable to load Web Connection Server",48,;
               "Web Connection Error")
   RETURN
ENDIF

*** Make the server live - Show puts the server online and in polling mode
READ EVENTS


*** Check if server wants to auto-restart
LOCAL llAutoRestart
llAutoRestart = goWcServer.lAutoRestart

ON ERROR
RELEASE goWCServer

SET SYSMENU ON
SET DEBUG ON
SET DEVELOP ON
SET STATUS BAR ON
SET TALK ON 
 
RELEASE ALL EXCEPT llAutoRestart
CLOSE DATA



IF llAutoRestart
   IF VARTYPE("__WWC_FILEWATCHER") = "O"
      __WWC_FILEWATCHER.Destroy()
      __WWC_FILEWATCHER = null
   ENDIF 
   CLEAR ALL   

    *** Try to restart this applications
   KEYBOARD [CLEAR PROGRAM{ENTER}] + ;
            [DO wwThreadsMain.prg{ENTER}]                
   
   *** If BrowserSync is running this will refresh the active page
   STRTOFILE(TRANSFORM(DateTime()),"..\Web\__CodeUpdated.html")            
ELSE
   *** USE THIS FOR DEBUGGING OBJECT HANGING - fires all outstanding DESTROY()
   *** and you should see which objects are hanging
   *SET STEP ON  
   CLEAR ALL      
ENDIF

IF Application.StartMode < 2
      ACTIVATE WINDOW COMMAND
ENDIF



RETURN


**************************************************************
****          YOUR SERVER CLASS DEFINITION                 ***
**************************************************************
DEFINE CLASS WwthreadsServer AS WWC_SERVER OLEPUBLIC
*************************************************************
***  Function: This is a subclass of the wwServer class
***            that is application specific. Each Web Connection
***            server you create *MUST* create a subclass of the
***            class and at least implement the Process and
***            SetServerEnvironment methods to  receive requests!
*************************************************************

*** Add any custom properties here
*** These can act as 'global' vars


************************************************************************
* WwthreadsServer :: OnInit
******************************************
***  Function: This method fires at the beginning of the server's
***            initialization sequence. It's fired from the Init
***            method and you can return .F. here to cause the
***            server to not load.
***
***            Use this method to setup any server configuration that
***            the server would need to configure itself, such as
***            pointing at the configuration file and configuring
***            the configuration object to use
***
***            THIS.cAppStartPath returns your application's startup
***            path as stored in the registry. If you need to override
***            this path in code you should do so here. This value
***            is used to SET DEFAULT TO in the Init(). You can
***            set this value on the WC Status form's Startup Path.
***
***    Assume: VIRTUAL METHOD - must ALWAYS be implemented!!!
************************************************************************
PROTECTED FUNCTION OnInit

*** Location of the startup INI file
THIS.cAppIniFile = addbs(THIS.cAppStartPath) + "Wwthreads.ini"
THIS.cAppName = "Wwthreads"

*** Custom Server Configuration object - created at bottom
*** wwServer::ReadConfiguration will read settings from INI
THIS.oConfig = CREATEOBJECT("WwthreadsConfig")
THIS.oConfig.cFileName = THIS.cAppIniFile

*** If you need to override your application's startup path
*** to something other than the current directory do it here:
*** THIS.cAppStartPath = <your custom path>

ENDFUNC
* OnInit


************************************************************************
* WwthreadsServer :: OnLoad
****************************************
***  Function: This Method should be used to set any server properties
***            and any relative paths. At this time the server has
***            changed directories to its startup path, so it's safe
***            to set relative paths from here.
***
***            This code runs just prior to showing the server window.
************************************************************************
PROTECTED FUNCTION OnLoad

*** Any settings you want to make to the server
IF THIS.lShowServerForm
  THIS.oServerForm.Caption =This.cServerId + " - wwThreads Support Message Board " + WWVERSION
ENDIF

*** Add persistent SQL Server Connection
#IF WWC_USE_SQL_SYSTEMFILES
    THIS.AddProperty("oSQL", CREATE("wwSQL"))
    IF !THIS.oSQL.Connect(THIS.oConfig.cSQLConnectString)
	   MESSAGEBOX("Couldn't connect to SQL Service. Check your SQL Connect string in the INI file.",48,"Web Connection")
	   CANCEL
    ENDIF
#ENDIF


*** Add any data paths - SET DEFAULT has already occurred so this is safe!
SET PATH TO (this.oConfig.owwThreadProcess.cDataPath) ADDITIVE

*** Load all application dependencies
DO Load_Libs
SET ENGINEBEHAVIOR 70

ENDFUNC
* OnLoad


************************************************************************
* WwthreadsServer :: Process
******************************
***  Function: This procedure's main purpose is to route incoming
***            requests to individual project PRGs/APPs.
***
***            Routings should be set up for both parameterized
***            urls (wc.dll?Process~Method~Parm1) and scriptmaps
***            (Method.map?Parm1=Value)
************************************************************************
PROTECTED FUNCTION Process
LOCAL lcParameter, lcExtension, lcPhysicalPath

*** Retrieve first parameter
lcParameter=UPPER(THIS.oRequest.Querystring(1))

*** Set up project types and call external processing programs:
DO CASE
      *** SUB APPLETS ADDED ABOVE - DO NOT MOVE THIS LINE ***

     CASE lcParameter == "WWMAINT"
        DO wwMaint with  THIS
OTHERWISE
     *** Check for Script Mapped files for: .WC, .WCS, .FXP
     lcExtension = Upper( JustExt(THIS.oRequest.GetPhysicalPath() ) )

     DO CASE

     CASE lcExtension == "WWT"

        DO wwThreadProcess with THIS

     *** ADD SCRIPTMAP EXTENSIONS ABOVE - DO NOT MOVE THIS LINE ***

     *** Generic Web Connection Script Template handling
     CASE lcExtension == "WC" OR lcExtension == "WCS" OR lcExtension == "FXP"
        DO wwScriptMaps with THIS
       
     OTHERWISE
         *** Error - No handler available. Create custom
	     Response=CREATE([WWC_RESPONSESTRING])
	     Response.StandardPage("Unhandled Request",;
	                       "The server is not setup to handle this type of Request: "+ EncodeHtml(lcParameter))

	     IF THIS.oConfig.lAdminSendErrorEmail
	       LOCAL loIP
           loIP = CREATEOBJECT("wwSmpt",2)
		   loIP.cMailServer = THIS.oConfig.cAdminMailServer
		   loIP.cSenderEmail = THIS.oConfig.cAdminEmail
		   loIP.cRecipient = THIS.oConfig.cAdminEmail
		   loIP.cSubject = "Web Connection Error Message - Unhandled request"
		   loIP.cMessage = CRLF + ;
	           "The request Query String is: " +THIS.oRequest.QueryString() + CRLF +;
	           "              DLL or Script: " +THIS.oRequest.ServerVariables("Executable Path") + CRLF+;
	           "                Server Name: " + THIS.oRequest.GetServerName() + CRLF + ;
	           "                 IP Address: " + THIS.oRequest.GetIPAddress()

           *** Send and immediately return
           loIP.SendMailAsync()
         ENDIF

	     IF THIS.lCOMObject
	         *** Simply assign to output property
	         THIS.cOutput=Response.GetOutput()
	     ELSE
	         *** FileBased - must output to file
	         File2Var(THIS.oRequest.GetOutputFile(),Response.GetOutput())
	     ENDIF
	 ENDCASE

ENDCASE

RETURN

ENDDEFINE
* EOC Wwthreads

***************************************************************
DEFINE CLASS WwthreadsConfig AS wwServerConfig
***************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 1999
*:Contact: http://www.west-wind.com
***************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class Wwthreads

*:Description:
This class is used as a global configuration object to
contain application global data that persists for the
lifetime of the server.

Optionally you can have sub-application objects for each
Process class implementation.
*:ENDHELP
#ENDIF
****************************************************************

owwThreadProcess = .NULL.

*** ADD CONFIG OBJECT TO CLASS ABOVE - DO NOT MOVE THIS LINE ***
owwMaint = .NULL.
owwWebPageHandler = .NULL.

FUNCTION Init

THIS.owwThreadProcess = CREATEOBJECT("wwThreadProcessConfig")

*** ADD CONFIG INIT CODE ABOVE - DO NOT MOVE THIS LINE ***

THIS.owwMaint = CREATEOBJECT("wwMaintConfig")
THIS.owwWebPageHandler = CREATEOBJECT("wwWebPageHandlerConfig")
ENDFUNC

ENDDEFINE
*EOC WwthreadsConfig


DEFINE CLASS wwMaintConfig as RELATION

cHTMLPagePath = "c:\WebConnectionProjects\wwThreads\Web\"
cDATAPath = ".\"
cVirtualPath = "/wwThreads/"

ENDDEFINE

DEFINE CLASS wwWebPageHandlerConfig as RELATION

cHTMLPagePath = "c:\WebConnectionProjects\wwThreads\Web\"
cDATAPath = ".\"
cVirtualPath = "/wwThreads/"

ENDDEFINE


*** Configuration class for the wwThreadProcess Process class
DEFINE CLASS wwThreadProcessConfig as wwConfig

cHTMLPagePath = "c:\WebConnectionProjects\wwThreads\Web\"
cDATAPath = ""
cVirtualPath = "/wwThreads/"

ENDDEFINE

*** ADD PROCESS CONFIG CLASSES ABOVE - DO NOT MOVE THIS LINE ***

