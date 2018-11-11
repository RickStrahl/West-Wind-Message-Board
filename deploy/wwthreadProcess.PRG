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

*** User related short cut values
cAuthenticationMode = "UserSecurity"
cAuthenticatedUserId = ""
lAuthenticatedAdmin = .F.

*** oThreadUser data instance (wwt_User)
oThreadUser = .null.

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
	   return .F. && No further routing
   ENDIF
ENDIF

*** Handle messageXXXX.wwt scripts
IF lcScript = "message" 
   this.Message()
   RETURN .F.  && No further routing
ENDIF

*** Add CORS header to allow x-site access from other domains/mobile devices
*** Uncomment for JSON Services and change * to allowed domain list
*!*  Response.AppendHeader("Access-Control-Allow-Origin","*")

RETURN .T.
ENDFUNC

************************************************************************
*  CompleteResponse
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION CompleteResponse()

DODEFAULT()

ENDFUNC
*   CompleteResponse



FUNCTION Status()

Response.Write("<pre>")
Response.Writeln("Path: " + Request.GetPhysicalPath())
Response.Writeln("Resolve Error" + THIS.ResolvePath("~/Views/_ErrorTemplate.wcs"))
Response.Write("</pre>")

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
this.cAuthenticatedName = TRIM(loUserBus.oData.Name)

*** Add a custom sessionvar we can pick up on each request
Session.SetSessionVar("_authenticatedUserId",loUserBus.oData.CookieId)
Session.SetSessionVar("_authenticatedName",TRIM(loUserBus.oData.Name))
Session.SetSessionVar("_authenticatedAdmin",IIF(loUserBus.oData.Admin != 0,"True",""))

RETURN .T.
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

LOCAL loUser as wwt_user, loData
loUser = CREATEOBJECT("wwt_user")
IF loUser.LoadFromEmail(this.cAutHENTICATEDUSER)
   this.oThreadUser = loUser
   loData = loUser.oData
   loData.LastOn = DATETIME()
   this.oThreadUser.Save()   

   this.cAuthenticatedName = TRIM(loData.Name)
   this.cAuthenticatedUserId = TRIM(loData.CookieId)
   this.lAuthenticatedAdmin = IIF(loData.Admin # 0,.t.,.f.)
ELSE
	*** get our custom properties from Session
	this.cAuthenticatedName = Session.GetSessionVar("_authenticatedName")
	this.cAuthenticatedUserId = Session.GetSessionVar("_authenticatedUserId")
	this.lAuthenticatedAdmin = !EMPTY(Session.GetSessionVar("_authenticatedAdmin"))
ENDIF

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
   pcErrorMessage = "We've sent password recovery information to your email address: " + lcEmail
   RETURN
ENDIF

loUserBus.oData.Password = GetUniqueId()
loUserBUs.Save()

loIP = CREATEOBJECT([WWC_WWSMTP])
loIP.nMailMode = 0 

loIP.lUseSsl = Server.oConfig.lAdminMailUseSsl
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
 
if(!loIP.SendMail())
   pcErrorMessage = "Failed to send confirmation email: " + loIP.cErrorMsg
ELSE
   pcErrorMessage = "We've sent password recovery information to your email address: " + lcEmail
ENDIF
   
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
this.oThreadUser = null
Response.Redirect("~/")
ENDFUNC
*   Logout


************************************************************************
*  ThreadList
****************************************
FUNCTION ThreadList()
LOCAL lcLastAccess, ltLastAccess

PRIVATE poError as HtmlErrorDisplayConfig
poError = CREATEOBJECT("HtmlErrorDisplayConfig")

LOCAL loMsgBus as wwt_Message
loMsgBus = CREATEOBJECT("wwt_Message")

poFilter = loMsgBus.CreateMessageQueryParms()
IF Request.IsPostBack()
	Request.UnbindFormVars(poFilter)
ELSE
	ltLastAccess = DATE() - 30
	lcLastAccess = Session.GetSessionVar("LastThreadListAccess")	
	IF !EMPTY(lcLastAccess)
	   ltLastAccess = TTOD(CTOT(lcLastAccess)) -1
	ENDIF
    poFilter.StartDate = ltLastAccess
	poFilter.Forum = Request.QueryString("Forum")
ENDIF

loMsgBus.GetForumList() && TForums
lnResult = loMsgBus.GetThreads(poFilter) && TMessages

IF lnResult < 1
	poError.Message = "<p>This search returned no matching threads, so there's nothing to show here.<p>" +;
	                  "<p>Please retry searching with broader search terms.</p>"
	poError.Header = "No messages to display"

ENDIF
IF lnResult > 1000
	poError.Message = "This query returned too many records. Please refine your query to retrieve fewer result messages."
	poError.Header = "Too many Messages"

    *** Create empty cursor
	SELECT * FROM wwthreads WHERE .F. INTO CURSOR TMessages
ENDIF

Response.GzipCompression = .T.

Session.SetSessionVar("LastThreadListAccess",TTOC(DATETIME(),3))

Response.ExpandScript("~/threadList.wwt")
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

pcMsgId = Request.QueryString("msgId")

loMsgBus = CREATEOBJECT("wwt_Message")
lnResult = loMsgBus.GetThreadMessages(lcThreadId)

IF lnResult < 1
   Response.Redirect("~/threads.wwt")
   RETURN
ENDIF

PRIVATE poMarkdown
poMarkdown = THIS.GetMarkdownParser()

Response.GzipCompression = .T.

*** Don't auto-encode - we manually encode everything
*** so that emojii's and other extendeds work in the
*** markdown text
Response.Encoding = ""
Response.ContentType = "text/html; charset=utf-8"

Response.ExpandScript("~/thread.wwt")
ENDFUNC
*   Thread


************************************************************************
*  ShowThread
****************************************
***  Function: Legacy for forwarding of old requests
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ShowThreadMessages()
Response.Redirect("~/Thread" + Request.QueryString("ThreadId") + ".wwt",.T.)
ENDFUNC
*   ShowThread


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

loUserBus = CREATEOBJECT("wwt_User")

IF ISNULL(this.oThreadUser)
   loUserBus.New()
   plNewUser = .T.
ELSE
   loUserBus.Load(this.cAuthenticatedUserId)
ENDIF   
poUser = loUserBus.oData

IF (Request.IsPostBack())
   lcOldPassword = poUser.Password
   poError.Errors = Request.UnbindFormVars(loUserBus.oData)

   *** Only set password if it's not empty
   IF !EMPTY(loUserBus.oData.Password)
      loUserBus.oData.Password = poUser.Password
      lcConfirm = Request.Form("PasswordConfirm")
      IF NOT (TRIM(poUser.Password) == lcConfirm)
         poError.Errors.AddError("Passwords entered don't match","Password")
      ENDIF
   ENDIF

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

poUser.Password = ""
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
IF EMPTY(lcMsgId) 
   lcMsgId = STRTRAN(JUSTSTEM(Request.GetPhysicalPath()),"message","",1,1,1)   
ENDIF

lcThreadId = loMsgBus.GetThreadIdFromMsgId(lcMsgId)
IF EMPTY(lcThreadId)
   THIS.ErrorMsg("Invalid Message Id","The message you're trying to access, has been removed or is no longer accessible. Please select another message to view.")
   RETURN
ENDIF

loMsgBus.GetThreadMessages(lcThreadId)

PRIVATE poMarkdown, pcMsgId, poMessage
poMarkdown = THIS.GetMarkdownParser()
pcMsgId = lcMsgId  && try to select the message

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
   return
ENDIF

PRIVATE poMarkdown
poMarkdown = THIS.GetMarkdownParser()	

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

*** Force to markdown
poMsg.Format = 2 && Markdown

lcOrigId = poMsg.MsgId

*** Override for a new message
IF !plEditing
	poMsg.Message = ""
	poMsg.MsgId = loMsgBus.CreateNewId()
ENDIF
IF pnMsgMode = 2
   poMsg.To = ["] + TRIM(poMsg.FromName) + [" <] + TRIM(poMsg.FromEmail) + [>]
   IF ATC("re:",poMsg.Subject) = 0
      poMsg.Subject = "re: " + TRIM(poMsg.Subject)
   ENDIF
   poMsg.TimeStamp = DATETIME()
ENDIF

poUser = this.oThreadUser
IF ISNULL(poUser)
   poError.Message = "You're not logged in or your account info is invalid. Please log in again."
   RETURN Response.ExpandScript("~/WriteMessage.wwt")
ENDIF

IF plEditing AND !(poMsg.UserId == this.cAuthenticatedUserId OR this.lAuthenticatedAdmin)
   this.ErrorMsg("Access Denied","You can only edit your own messages.")
   RETURN
ENDIF

IF (Request.IsPostBack())
   poError.Errors = Request.UnbindFormVars(loMsgBus.oData)

   IF !loMsgBus.Validate()
       poError.Errors.AddErrors( loMsgBus.oValidationErrors )
   ENDIF
   
   IF poError.Errors.Count < 1 
        IF !plEditing
	   	    poMsg.FromName = TRIM(poUser.oData.Name)
	   	    poMsg.FromEmail = TRIM(poUser.oData.Email)
	   	    poMsg.UserId = poUser.oData.CookieId
   		ENDIF
   		
       IF !loMsgBus.Save() 
	      poError.Message = loMsgBus.cErrorMsg      
       ENDIF  
   ENDIF

   IF (poError.Errors.Count > 0)
   	   poError.Message = poError.Errors.ToHtml()
   	   poError.Header = "Please fix the following form entry errors"   	   
   ELSE
   	   loConfig = Server.oConfig
   	   IF !plEditing
	   	   loMsgBus.SendEmail(loConfig.cAdminMailServer,loConfig.cAdminMailUsername, loConfig.cAdminMailPassword, .T.)   
	   ENDIF
	   
	   *** ?rl=1   - force list refresh
   	   Response.Redirect("Thread" + TRIM(poMsg.ThreadId) + ".wwt?rl=1#" + TRIM(poMsg.MsgId))   	      	      	   
	   return
   ENDIF               
ELSE

ENDIF

IF pnMsgMode = 2
	loMsgBus = CREATEOBJECT("wwt_Message")
	loMsgBus.GetThreadMessages(poMsg.ThreadId)	
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
PRIVATE pcMsgId, pnMsgMode
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

************************************************************************
*  DeleteMessage
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION DeleteMessage()

lcMsgId = Request.QueryString("id")

poUser = CREATEOBJECT("wwt_user")
IF !this.lAuthenticatedAdmin AND ;
   (EMPTY(lcMsgId) OR ISNULL(poUser))
   Response.Redirect("~/threads.wwt")
   RETURN
ENDIF

lcThreadId = ""

LOCAL loMsgBus as wwt_Message
loMsgBus = CREATEOBJECT("wwt_Message")
IF loMsgBus.Load(lcMsgId)
   lcThreadId = TRIM(loMsgBus.oData.ThreadId)
   IF (this.lAuthenticatedAdmin OR TRIM(loMsgBus.oData.UserId) == this.cAuthenticatedUserId)
   	  loMsgBus.Delete(lcMsgId)
   ENDIF
ENDIF

IF !EMPTY(lcThreadId)
   Response.Redirect("~/Thread" + lcThreadId + ".wwt")
ELSE
   this.StandardPage("Message has been deleted.","The message has been removed from the message board.")
ENDIF
   
ENDFUNC
*   DeleteMessage

************************************************************************
*  ImageUpload
****************************************
***  Function: AjaxImage Upload
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ImageUpload()
LOCAL lcExt, loFile, lcNewFile, lcNewPath

IF ISNULL(THIS.oThreadUser)
   ERROR "You have to be signed in to upload images."
ENDIF

loFiles = Request.GetMultiPartFiles("ImageUpload")
IF loFiles.Count < 1
	ERROR "No files uploaded."
ENDIF

loFile = loFiles.Item(1)

IF LEN(loFile.Content) > 360000
   ERROR "Error: Image is too large. Max size: 350k. Please resize or compress the image before uploading."
   RETURN
ENDIF

lcExt = LOWER(JUSTEXT(loFile.FileName))
IF !INLIST(lcExt,"png","jpg","jpeg","gif")
	ERROR "Invalid image extension."
ENDIF


lcNewFile =  SYS(2015) + "." + lcExt
lcNewPath = this.ResolvePath("~/PostImages/" + TRANSFORM(YEAR(DATETIME())) + "/")
IF !ISDIR(lcNewPath)
    MD (lcNewPath)
ENDIF
lcFileName = lcNewPath + lcNewFile
lcExt = LOWER(JUSTEXT(lcFileName))

STRTOFILE(loFile.Content,lcFileName)	

IF (lcExt = "png")
  lcCmd = [pngout.exe "] + lcFilename  + ["]
  RUN /n7 &lcCmd
ENDIF

lcUrl = this.ResolveServerUrl("~/PostImages/"  + TRANSFORM(YEAR(DATETIME())) + "/" + lcNewFile)

lcUrl = STRTRAN(lcUrl,"http://","//",1,1,1)

Response.ContentType = "application/json"
Response.Write( JsonString(lcUrl) )
ENDFUNC
*   ImageUpload


************************************************************************
*  ImagePasteUpload
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ImagePasteUpload()
LOCAL lcData, lcNewFile, lcNewPath, lcFilename, lcUrl, lcImageFormat

lcData = Request.Form()
Response.ContentType = "application/json"

IF (lcData != "data:image")
   Response.Write(JsonString("Error: Invalid data format for upload."))
   RETURN
ENDIF

lnAt = AT(",",lcData)
IF lnAt <1
   Response.Write(JsonString("Error: Invalid data format for upload."))
   RETURN
ENDIF

lcFileData = SUBSTR(lcData,lnAt+1)

lcImageFormat = STREXTRACT(lcData,"data:",";")

lcExt = "png"
DO CASE 
CASE (lcImageFormat = "image/png")
  lcExt = "png"
CASE (lcImageFormat = "image/jpeg")
  lcExt = "jpg"
CASE (lcImageFormat = "image/gif")
  lcExt = "gif"
OTHERWISE
   Response.Write(JsonString("Error: Invalid image format."))
   return
ENDCASE

lcNewFile =  "_" + GetUniqueId() + "." + lcExt
lcNewPath = this.ResolvePath("~/PostImages/" + TRANSFORM(YEAR(DATETIME())) + "/")
IF !ISDIR(lcNewPath)
    MD (lcNewPath)
ENDIF
lcFileName = lcNewPath + lcNewFile

STRTOFILE(STRCONV(lcFileData,14),lcFileName)


IF (lcExt = "png")
  llToJpg = .f.
  IF LEN(lcFileData) > 100000
        lcJpgFilename = FORCEEXT(lcFilename,"jpg")
		loBridge = GetwwDotnetBridge()
		TRY
			*** Make sure image is not too big
			*infile, outfile, jpeg quality, dpi
			llResult = loBridge.InvokeStaticMethod("Westwind.Utilities.ImageUtils","ConvertImageFile",lcFilename, lcJpgFilename, 85, 96)
		CATCH
		ENDTRY
				
		IF FILE(lcJpgFilename)
			IF FileSize(lcFileName) > FileSize(lcJpgFileName)
			   ERASE (lcFilename)
			   llToJpg = .T.
               lcFilename = lcJpgFilename
               lcNewFile = FORCEEXT(lcNewFile,"jpg")
			ELSE
			   ERASE (lcJpgFilename)
			ENDIF
		ENDIF
  ENDIF

  
  IF !llToJpg
	  lcCmd = [pngout.exe "] + lcFilename  + ["]
	  RUN /N7 &lcCmd
  ENDIF
ENDIF

lcUrl = this.ResolveServerUrl("~/PostImages/"  + TRANSFORM(YEAR(DATETIME())) + "/" + lcNewFile)

lcUrl = STRTRAN(lcUrl,"http://","//",1,1,1)

Response.ContentType = "application/json"
Response.Write( JsonString(lcUrl) )
ENDFUNC
*   ImagePasteUpload

*** ADMIN METHODS

************************************************************************
FUNCTION  Backup()
****************************************
***  Function:
***    Assume:
************************************************************************
LOCAL lcPath

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse
#ENDIF

IF !this.lAuthenticatedAdmin
  Response.Redirect("~/")	
  RETURN
ENDIF

IF EMPTY(Request.Querystring("instancing"))
   Response.Redirect("backup.wwt?instancing=single")
   RETURN
ENDIF

lcPath = JUSTPATH(Request.GetPhysicalPath()) + "\backup\"
IF !ISDIR(lcPATH)
   MD (lcPath)
ENDIF
ERASE (lcPath + "*.*")

IF !USED("wwThreads")
   USE wwThreads 
ENDIF
SELECT wwThreads

COPY TO (lcPath + "wwThreads") FOR timestamp > DATE() - 1500

IF !USED("wwUsers")
   USE wwUsers 
ENDIF
SELECT wwUsers
COPY TO (lcPath + "wwUsers") FOR Name # "  "

IF !USED("wwt_forums")
   USE wwt_forums IN 0
ENDIF
SELECT wwt_forums
COPY TO (lcPath + "wwt_fourms")


lcZipFileName = lcPath +  "wwThreads_"+DTOS(DATE()) + ".zip"

IF ZipFiles(lcZipFileName,lcPath + "*.*") # 0
   THIS.StandardPage("Problem Zipping files","This either means there's a permissions problem in the ~/admin/backup folder or the dzip/dunzip DLLs are not present in the application folder.")
   RETURN
ENDIF

ERASE (lcPath + "wwThreads.*")
ERASE (lcPath + "wwUsers.*")

lnFileSize = FILESIZE(lcZipFileName)
IF lnFileSize < 1
   THIS.StandardPage("Failure backing up files")
   RETURN
ENDIF

THIS.StandardPage("Backup file created",;
                  "You can download it from here:<p>" + ;
                  "<a href='backup/" + JUSTFNAME(lcZipFileName) + "'>Download backup file.")
RETURN

Response.AppendHeader("Content-length",TRANSFORM( lnFileSize) )
Response.AppendHeader("Content-type","application/x-zip-compressed")
Response.AppendHeader("Content-disposition","attachment; filename="+;
                      JUSTSTEM(lcZipFileName)+".zip")

Response.Write( FILETOSTR( lcZipFileName ) )                               
ENDFUNC
*  wwThreads :: Backup


************************************************************************
*  CleanupUnreferencedImages
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION CleanupUnreferencedImages()
LOCAL lcSourcePath, llError, lcPath, lcYear, ldStartDate, ldEndDate,;
      lnCount, lnX, lcFile, lnDeleted

IF !THIS.lAuthenticatedAdmin
   this.ErrorMsg("Access denied","You have to be an administrator in order to access this task.")
   RETURN
ENDIF

lcSourcePath = this.ResolvePath("~/PostImages/")
llError = .F.

CREATE CURSOR TDirs( Path c(128) )

GetDirs(ADDBS(lcSourcePath),lcSourcePath)
INDEX ON Path DESCENDING TAG PATH

lnDeleted = 0

*** Delete files for the current year
SCAN
   lcPath = lcSourcePath + ADDBS(TRIM(path))
   lcYear = STREXTRACT(lcPath,"PostImages\","\")
   
   ldStartDate = CTOT( lcYear + "-01-01T00:00" )
   ldEndDate = CTOT( TRANSFORM(VAL(lcYear)+1) + "-01-01T00:00" )
   
   lnCount = ADIR(laFiles,lcPath + "*.*")
   FOR lnX = 1 TO lnCount
       lcFile = JUSTFNAME(laFiles[lnX,1])
       SELECT msgId FROM wwThreads ;
           WHERE timestamp >= ldStartDate AND ;
                 timestamp < ldEndDate AND ;           		
	             ATC(lcFile,Message) > 0 ;
           INTO ARRAY laMsgs
           
       IF _tally = 0
          DELETE FILE (lcPath + lcFile)
          lnDeleted = lnDeleted + 1 
       ENDIF
   ENDFOR   
ENDSCAN

USE IN TDirs

THIS.ErrorMsg("Images cleanup complete",;
   "Removed " + TRANSFORM(lnDeleted) + " unreferenced images from PostImages folder.")
   
ENDFUNC
*   CleanupUnreferencedImages

************************************************************************
*  Reindex
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Reindex()

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

loUserBus = CREATEOBJECT("wwt_User")
IF !loUserBus.Reindex()
   this.ErrorMsg("Unable to reindex Users", ;
     "The user table most likely is locked. Try unloading all but one instance of the server and retry this operation.")
   RETURN
ENDIF


THIS.StandardPage("Message Board Tables Reindexed","Messages and Users have been reindexed and packed successfully.")
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
LOCAL loMarkdown

PUBLIC __wwThreadsMarkdownParser
IF VARTYPE(__wwThreadsMarkdownParser) = "O"
   loMarkdown = __wwThreadsMarkdownParser
ELSE
	loMarkdown =  CreateObject("MarkdownParserExtended")
	loMarkdown.cLinkTarget = "wwt"
	__wwThreadsMarkdownParser = loMarkdown
ENDIF

RETURN loMarkdown
ENDFUNC
*   GetMarkdownParser

ENDDEFINE