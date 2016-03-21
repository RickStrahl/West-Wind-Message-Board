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

cAuthenticationMode = "UserSecurity"

cAuthenticatedUserId = ""

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
IF !loUserBus.AuthenticateAndLoad(LOWER(lcEmail),LOWER(lcPassword))
	*** Set lcErrorMsg to pass back via REF parm
	lcErrorMsg = loUserBus.cErrorMsg
	RETURN .F.
ENDIF	

*** Assign the user
this.cAuthenticatedUser = lcEmail && email
this.cAuthenticatedName = loUserBus.oData.Name

*** Add a custom sessionvar we can pick up on each request
Session.SetSessionVar("_authenticatedUserId",loUserBus.oData.CookieId)

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
this.cAuthenticatedName = Session.GetSessionVar("_authenticatedName")
this.cAuthenticatedUserId = Session.GetSessionVar("_authenticatedUserId")
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

pcDisplayMessage = [No account? <a href="~/Profile.wwt">Click here to create one</a>.]
pcErrorMessage = ""
pcRedirectUrl = "~/"
          
IF !Request.IsPostBack()
	THIS.Authenticate("Login")
ELSE
    pcRedirectUrl = Request.QueryString("ReturnUrl")
    IF EMPTY(pcRedirectUrl)
       pcRedirectUrl = "~/"
    ENDIF
    IF THIS.Authenticate("ANY",@pcErrorMessage)
       Response.Redirect(pcRedirectUrl)
    ENDIF
ENDIF
    	
ENDFUNC
*   Login

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

LOCAL loMsgBus as wwt_Message
loMsgBus = CREATEOBJECT("wwt_Message")

poFilter = loMsgBus.CreateMessageQueryParms()
Request.UnbindFormVars(poFilter)

loMsgBus.GetForumList() && TForums
loMsgBus.GetThreads(poFilter) && TMessages

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

loMsgBus = CREATEOBJECT("wwt_Message")
loMsgBus.GetThreadMessages(lcThreadId)

PRIVATE poMarkdown
poMarkdown = THIS.GetMarkdownParser()

Response.ExpandScript("~/thread.wwt")
ENDFUNC
*   Thread


************************************************************************
*  WriteMessage
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteMessage(pcMsgId)

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

loMsgBus = CREATEOBJECT("wwt_Message")
loMsgBus.GetForumList() && TForums

IF !EMPTY(pcMsgId)
   loMsgBus.Load(pcMsgId)
ELSE
   loMsgBus.New()   
ENDIF

poMsg = loMsgBus.oData

*** Override for a new message
poMsg.MsgId = loMsgBus.CreateNewId()
poMsg.Message = ""
IF pnMsgMode = 2
   poMsg.To = TRIM(poMsg.FromName) + " <" + TRIM(poMsg.FromEmail) + ">"
ENDIF

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse, Server as wwServer, ;
      THIS as wwProcess, Process as wwProcess, Session as wwSession
#ENDIF

poUser = CREATEOBJECT("wwt_user")
IF !poUser.Load(this.cAuthenticatedUserId)
   poError.Message = "You're not logged in or your account info is invalid. Please log in again."
   RETURN Response.ExpandScript("~/WriteMessage.wwt")
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
   	   Response.Redirect("Thread" + TRIM(poMsg.ThreadId) + ".wwt#" + TRIM(poMsg.MsgId))
	   return
   ENDIF               
ELSE

ENDIF

IF pnMsgMode = 2
	loMsgBus = CREATEOBJECT("wwt_Message")
	loMsgBus.GetThreadMessages(poMsg.ThreadId)
	
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
RETURN THIS.WriteMessage()
ENDFUNC
*   EditMessage

*********************************************************************
FUNCTION TestPage()
************************

THIS.StandardPage("Hello World from the wwThreadProcess process",;
                  "If you got here, everything is working fine.<p>" + ;
                  "Server Time: <b>" + TIME()+ "</b>")
                  
ENDFUNC
* EOF TestPage

************************************************************************
*  GetMarkdownParser
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetMarkdownParser()
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