************************************************************************
*PROCEDURE wwThreadProcess
****************************
***  Function: Processes incoming Web Requests for wwThreadProcess
***            requests. This function is called from the wwServer 
***            process.
***      Pass: loServer -   wwServer object reference
*************************************************************************
LPARAMETER loServer
LOCAL loProcess
PRIVATE Request, Response, Server, Session, Process
STORE NULL TO Request, Response, Server, Session, Process

#INCLUDE WCONNECT.H

loProcess = CREATEOBJECT("wwThreadProcess", loServer)
loProcess.lShowRequestData = loServer.lShowRequestData

IF VARTYPE(loProcess)#"O"
   *** All we can do is return...
   RETURN .F.
ENDIF

*** Call the Process Method that handles the request
loProcess.Process()

*** Explicitly force process class to release
loProcess.Dispose()

RETURN

*************************************************************
DEFINE CLASS wwThreadProcess AS WWC_PROCESS
*************************************************************

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse, Server as wwServer, ;
      THIS as wwProcess, Process as wwProcess, Session as wwSession
#ENDIF


*** Response class used - override as needed
cResponseClass = [WWC_PAGERESPONSE]

*** Default for how pages are processed for file only scripts
*** 1 - MVC Template (ExpandTemplate()) 
*** 2 - Web Control Framework Pages
*** 3 - MVC Script (ExpandScript())
nPageScriptMode = 3

*** Custom Error Page
cErrorTemplate = "~/Views/_ErrorTemplate.wcs"

cAuthenticationMode = "UserSecurity"
cAuthenticatedUserId = ""
lAuthenticatedAdmin = .F.

*********************************************************************
* Function wwThreadProcess :: OnProcessInit
************************************
*** If you need to hook up generic functionality that occurs on
*** every hit against this process class , implement this method.
*********************************************************************
FUNCTION OnProcessInit
LOCAL lcThreadId

*!* LOCAL lcScriptName, llForceLogin
THIS.InitSession("wwt",24000 * 30,.T.)

*** AUthenticate so we get user info - we then use
*** specific checks for specific requests
this.Authenticate("ANY","",.T.)

*!*
*!*	lcScriptName = LOWER(JUSTFNAME(Request.GetPhysicalPath()))
*!*	llIgnoreLoginRequest = INLIST(lcScriptName,"default","login","logout")
*!*
*!*	IF !THIS.Authenticate("any","",llIgnoreLoginRequest) 
*!*	   IF !llIgnoreLoginRequest
*!*		  RETURN .F.
*!*	   ENDIF
*!*	ENDIF

*** Explicitly specify that pages should encode to UTF-8 
*** Assume all form and query request data is UTF-8
Response.Encoding = "UTF8"
Request.lUtf8Encoding = .T.


*** Handle urls like ShowMessage131231.wwt 
lcScript = LOWER( JUSTSTEM(this.oRequest.GetPhysicalPath()) )
IF (lcScript != "threads" AND lcScript = "thread" AND lcScript != "threadlist" ) 
   lcThreadId = SUBSTR(lcScript,LEN("thread")+1)
   IF !EMPTY(lcThreadId)
	   this.Thread(lcThreadId)
	   return .F.
   ENDIF
ENDIF


*** Add CORS header to allow x-site access from other domains/mobile devices
*** Uncomment for JSON Services and change * to allowed domain list
*!*  Response.AppendHeader("Access-Control-Allow-Origin","*")

RETURN .T.
ENDFUNC

************************************************************************
*  OnAuthenticateUser
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION OnAuthenticateUser(lcEmail, lcPassword, lcErrorMsg)

*** THIS IS THE DEFAULT IMPLEMENTATION 
*** To override behavior override this method
IF EMPTY(lcEmail)
   lcEmail = ""
ENDIF 
IF EMPTY(lcPassword)
   lcPassword = ""
ENDIF

loUserBus = CREATEOBJECT("wwt_user")

*** Default implementation is not case sensitive
IF !loUserBus.AuthenticateAndLoad(LOWER(lcEmail),lcPassword)
	*** Set lcErrorMsg to pass back via REF parm
	lcErrorMsg = loUserBus.cErrorMsg
	RETURN .F.
ENDIF	

*** Assign the user
this.cAuthenticatedUser = lcEmail && email
this.cAuthenticatedName = loUserBus.oData.Name

*** Add a custom sessionvar we can pick up on each request
Session.SetSessionVar("_authenticatedUserId",loUserBus.oData.CookieId)
Session.SetSessionVar("_authenticatedName",loUserBus.oData.Name)
Session.SetSessionVar("_authenticatedAdmin",IIF(loUserBus.oData.Admin != 0,"True",""))

ENDFUNC
*   OnAuthenticateUser


************************************************************************
*  OnAuthenticated
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION OnAuthenticated()

*** Set our custom properties from Session
this.cAuthenticatedName = Session.GetSessionVar("_authenticatedName")
this.cAuthenticatedUserId = Session.GetSessionVar("_authenticatedUserId")
this.lAuthenticatedAdmin = !EMPTY(Session.GetSessionVar("_authenticatedAdmin"))

ENDFUNC
*   OnAuthenticated

************************************************************************
*  Login
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Login()

PRIVATE pcErrorMessage
pcDisplayMessage = [No account? <a href="~/Profile.wwt">Click here to quickly create one</a>.]
pcErrorMessage = ""
pcRedirectUrl = "~/"
          
IF !Request.IsPostBack()
	THIS.Authenticate("Login")
ELSE
    IF Request.IsFormVar("WebLogin_btnRecover")
		THIS.EmailPassword()
		Response.ExpandScript("~/views/_login.wcs")
		RETURN
	ELSE
	    pcRedirectUrl = Request.QueryString("ReturnUrl")
	    IF EMPTY(pcRedirectUrl)
	       pcRedirectUrl = "~/"
	    ENDIF
	    IF THIS.Authenticate("ANY",@pcErrorMessage)
	       Response.Redirect(pcRedirectUrl)
	    ENDIF
	ENDIF
ENDIF
    	
ENDFUNC
*   Login

************************************************************************
*  EmailPassword
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION EmailPassword(lcRecipient)

lcEmail = Request.Form("WebLogin_txtUsername")
IF EMPTY(lcEmail)
   pcErrorMessage = "Please specify an email address to recover password for."
   RETURN
ENDIF
   
loUserBus = CREATEOBJECT("wwt_user")
IF !loUserBus.LoadFromEmail(lcEmail)
   pcErrorMessage = "Invalid email address."
   RETURN
ENDIF

loUserBus.oData.Password = SUBSTR(SYS(2015),2)
loUserBUs.Save()

loIP = CREATEOBJECT([WWC_WWSMTP])
loIP.nMailMode = 0 
loIP.lUseSsl = .T.

loIP.cMailServer = Server.oConfig.cAdminMailServer
loIp.cUsername = Server.oConfig.cAdminMailUserName
loIP.cPassword = Server.oConfig.cAdminMailPassword
   
loIP.cSenderName = "West Wind Message Board"
loIP.cSenderEmail = "admin@west-wind.com"
loIp.cReplyTo = "noreply@west-wind.com"
loIP.cRecipient = lcEmail
loIP.cSubject =  "West Wind Message Board Password recovery"
   
loIP.cMessage =  ;
  	"Your new password for your message board account is: " + TRIM(loUserBus.oData.Password) + CRLF + CRLF +;
  	"You can sign in and change your password in your profile. " +CRLF + CRLF +;
  	THIS.ResolveServerUrl("~/login.wwt")
 
loIP.SendMailAsync() 

pcErrorMessage = "Password recovery email has been sent."
   
ENDFUNC
*   EmailPassword


************************************************************************
*  Logout
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Logout()
THIS.Authenticate("Logout")
Response.Redirect("~/")
ENDFUNC
*   Logout


************************************************************************
*  ThreadList
****************************************
***  Function: ThreadList partial page
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ThreadList()

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse, Server as wwServer, ;
      THIS as wwProcess, Process as wwProcess, Session as wwSession
#ENDIF

PRIVATE poError as HtmlErrorDisplayConfig
poError = CREATEOBJECT("HtmlErrorDisplayConfig")

LOCAL loMsgBus as wwt_Message
loMsgBus = CREATEOBJECT("wwt_Message")

poFilter = loMsgBus.CreateMessageQueryParms()
Request.UnbindFormVars(poFilter)

loMsgBus.GetForumList() && TForums
lnResult = loMsgBus.GetThreads(poFilter) && TMessages


IF lnResult > 1000
	poError.Message = "This query returned too many records. Please refine your query to retrieve fewer result messages."
	poError.Header = "Too many Messages"

    *** Create empty cursor
	SELECT * FROM wwthreads WHERE .F. INTO CURSOR TMessages
ENDIF

Response.GzipCompression = .T.

Response.ExpandScript("~/threadList.wwt")
RETURN
ENDFUNC
*   ThreadList

************************************************************************
*  CreateMessageFilter
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION CreateMessageFilter()
LOCAL loFilter

loFilter = CREATEOBJECT("EMPTY")
ADDPROPERTY(loFilter,"FromDate",DATE() - 366 * 2)
ADDPROPERTY(loFilter,"ToDate",DATE())
ADDPROPERTY(loFilter,"Forum","")
ADDPROPERTY(loFilter,"Search","")
ADDPROPERTY(loFilter,"Search2","")
ADDPROPERTY(loFilter,"MsgId","")

RETURN loFilter
ENDFUNC
*   CreateMessageFilter

************************************************************************
*  Threads
****************************************
***  Function: Default Threads page used for display
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Threads()

pcThreadId = Request.QueryString("id")
IF !EMPTY(pcThreadId)
   THIS.Thread(pcThreadId)
   RETURN
ENDIF

Response.ExpandScript("~/threads.wwt")
ENDFUNC
*   Threads


************************************************************************
*  Thread
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Thread(lcThreadId)
LOCAL loMsgBus

loMsgBus = CREATEOBJECT("wwt_Message")
loMsgBus.GetThreadMessages(lcThreadId)

PRIVATE poMarkdown
poMarkdown = THIS.GetMarkdownParser()

Response.GzipCompression = .T.

poUser = loMsgBus.oData

Response.ExpandScript("~/thread.wwt")
ENDFUNC
*   Thread


************************************************************************
*  Profile
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Profile()
LOCAL loUserBus

PRIVATE plNewUser, poUser
plNewUser = .F.
poError = CREATEOBJECT("HtmlErrorDisplayConfig")

loUserBUs = CREATEOBJECT("wwt_User")

IF EMPTY(THIS.cAuthenticatedUserId) OR !loUserBus.Load(this.cAuthenticatedUserId)
   loUserBus.New()
   plNewUser = .T.
ENDIF   
poUser = loUserBus.oData

IF (Request.IsPostBack())
   poError.Errors = Request.UnbindFormVars(loUserBus.oData)

   IF !loUserBus.Validate()
       poError.Errors.AddErrors( loUserBus.oValidationErrors )
   ENDIF
   
   IF poError.Errors.Count < 1 
       IF !loUserBus.Save() 
	      poError.Message = loUserBus.cErrorMsg      
       ENDIF  
   ENDIF

   IF (poError.Errors.Count > 0)
   	  poError.Message = poError.Errors.ToHtml()
   	   poError.Header = "Please fix the following form entry errors"
   ELSE
       poError.Message = "Your user info has been saved."
       poError.Icon = "info"
       Response.AppendHeader("refresh","2;login.wwt")
   ENDIF               
ENDIF

Response.ExpandScript("~/Profile.wwt")
ENDFUNC
*   Profile



************************************************************************
*   MessagePrint
****************************************
***  Function: Display a message by Id
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Message()

loMsgBus = CREATEOBJECT("wwt_Message")

lcMsgId = Request.QueryString("id")
loMsgBus.GetThreadMessages(lcMsgId,2)

PRIVATE poMarkdown
poMarkdown = THIS.GetMarkdownParser()

Response.ExpandScript("~/thread.wwt")
ENDFUNC
*    MessagePrint



************************************************************************
*  WriteMessage
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteMessage(pcMsgId)
LOCAL lcOrigId, loConfig

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse, Server as wwServer, ;
      THIS as wwProcess, Process as wwProcess, Session as wwSession
#ENDIF

IF !this.Authenticate("ANY","",.T.) OR EMPTY(this.cAuthenticatedUserId)
   Response.Redirect("~/Login.wwt?returnurl=WriteMessage.wwt")
ENDIF

IF VARTYPE(pnMsgMode) # "N"
	pnMsgMode = VAL(Request.Params("MsgMode"))
	IF pnMsgMode = 0
	   pnMsgMode = 1
	ENDIF
ENDIF
IF VARTYPE(plEditing) # "L"
   plEditing = .F.
ENDIF


poError = CREATEOBJECT("HtmlErrorDisplayConfig")

LOCAL loMsgBus as wwt_Message
loMsgBus = CREATEOBJECT("wwt_Message")
loMsgBus.GetForumList() && TForums

IF !EMPTY(pcMsgId)
   loMsgBus.Load(pcMsgId)
ELSE
   loMsgBus.New()   
ENDIF

poMsg = loMsgBus.oData

lcOrigId = poMsg.MsgId

*** Override for a new message
poMsg.MsgId = loMsgBus.CreateNewId()
IF !plEditing
	poMsg.Message = ""
ENDIF
IF pnMsgMode = 2
   poMsg.To = ["] + TRIM(poMsg.FromName) + [" <] + TRIM(poMsg.FromEmail) + [>]
   IF ATC("re:",poMsg.Subject) = 0
      poMsg.Subject = "re: " + TRIM(poMsg.Subject)
   ENDIF
ENDIF

poUser = CREATEOBJECT("wwt_user")
IF !poUser.Load(this.cAuthenticatedUserId)
   poError.Message = "You're not logged in or your account info is invalid. Please log in again."
   RETURN Response.ExpandScript("~/WriteMessage.wwt")
ENDIF

IF plEditing AND !(poMsg.UserId == this.cAuthenticatedUserId)
   this.ErrorMsg("Access Denied","You can only edit your own messages.")
   RETURN
ENDIF

IF (Request.IsPostBack())
   poError.Errors = Request.UnbindFormVars(loMsgBus.oData)

   IF !loMsgBus.Validate()
       poError.Errors.AddErrors( loMsgBus.oValidationErrors )
   ENDIF
   
   IF poError.Errors.Count < 1 
   	    poMsg.FromName = TRIM(poUser.oData.Name)
   	    poMsg.FromEmail = TRIM(poUser.oData.Email)
   	    poMsg.UserId = poUser.oData.CookieId
   
       IF !loMsgBus.Save() 
	      poError.Message = loMsgBus.cErrorMsg      
       ENDIF  
   ENDIF

   IF (poError.Errors.Count > 0)
   	   poError.Message = poError.Errors.ToHtml()
   	   poError.Header = "Please fix the following form entry errors"   	   
   ELSE
   	   loConfig = Server.oConfig
   	   loMsgBus.Sendemail(loConfig.cAdminMailServer,loConfig.cAdminMailUsername, loConfig.cAdminMailPassword, .T.)   
   	   Response.Redirect("Thread" + TRIM(poMsg.ThreadId) + ".wwt#" + TRIM(poMsg.MsgId))   	      	      	   
	   return
   ENDIF               
ELSE

ENDIF

IF pnMsgMode = 2
	loMsgBus = CREATEOBJECT("wwt_Message")
	loMsgBus.GetThreadMessages(lcOrigId, 2)
	
	PRIVATE poMarkdown
	poMarkdown = THIS.GetMarkdownParser()	
ENDIF


RETURN Response.ExpandScript("~/WriteMessage.wwt")
ENDFUNC
*   WriteMessage

************************************************************************
*  ReplyMessage
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ReplyMessage()
pcMsgId = Request.QueryString("id")
pnMsgMode = 2
RETURN THIS.WriteMessage(pcMsgId)
ENDFUNC
*   ReplyMsg

************************************************************************
*  EditMessage
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION EditMessage()
plEditing = .T.
RETURN THIS.WriteMessage(Request.QueryString("id"))
ENDFUNC
*   EditMessage


*** ADMIN METHODS

************************************************************************
*  Reindex
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Reindex()

IF !this.Authenticate("ANY","",.T.) OR EMPTY(this.cAuthenticatedUserId) 
   Response.Redirect("~/Login.wwt?returnurl=Reindex.wwt")
ENDIF
IF !THIS.lAuthenticatedAdmin
   this.ErrorMsg("Access denied","You have to be an administrator in order to access this task.")
   RETURN
ENDIF

loMsgBus = CREATEOBJECT("wwt_Message")
IF !loMsgBus.Reindex()
   this.ErrorMsg("Unable to reindex Messages", ;
     "The messages table most likely is locked. Try unloading all but one instance of the server and retry this operation.")
   RETURN
ENDIF

THIS.StandardPage("Messages Reindexed","Messages have been reindexed and packed successfully.")
ENDFUNC
*   Reindex


*** HELPER METHODS

************************************************************************
*  GetRecipient
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetRecipient(lcTo)
RETURN STRTRAN(EXTRACT("!" + lcTo,"!","<","[",.T.),["],[])
ENDFUNC
*   GetRecipient

************************************************************************
*  GetMarkdownParser
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION GetMarkdownParser()
LOCAL poMarkdown

PUBLIC __wwThreadsMarkdownParser
IF VARTYPE(__wwThreadsMarkdownParser) = "O"
   poMarkdown = __wwThreadsMarkdownParser
ELSE
	poMarkDown =  CreateObject("MarkdownParserExtended")
	poMarkdown.cCodeBlockStartHtml = [<pre lang="###language###">]  + CHR(13) + CHR(10) 
	poMarkdown.cCodeBlockEndHtml = [</pre>]
ENDIF

RETURN poMarkdown
ENDFUNC
*   GetMarkdownParser

ENDDEFINE