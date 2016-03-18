*************************************************************************
* wwThreads.PRG
*************************************************************************
* (c) Rick Strahl, West Wind Technologies
*
* Contains:
*
*     wwThreads       -   Class that handles message board operation
*     ThreadMessage   -   Message Class that handles loading, saving
*                         formatting etc. of messages.
*     ThreadUser      -   Handles Users of the message board. Load, Save
*                         etc.
************************************************************************
LPARAMETER loServer 

#INCLUDE WCONNECT.H
*#INCLUDE WWTHREADS.H

*** Use String based output - output is returned to the OLE server
loProcess=CREATE("wwThreads",loServer)
loProcess.lShowRequestData = loServer.lShowRequestData

*** Load configuration settings from wwt_cfg
*loProcess.LoadProperties()

*** Call the Process Method that handles the request
loProcess.Process()

RETURN
* eop wwThreads

*************************************************************
DEFINE CLASS wwThreads AS wwProcess
**************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 06/20/96
***
***  Function: Threaded Message Class for use on WWW
*************************************************************

*** Custom Properties
cDefaultForum="Web Connection Support"

lUseLogins = .F.
nMaxMessages = 350
cEmailFooter = ""

cScriptPath="wc.wwt"
cDefaultForum="Web Connection Support"
cMailserver = "somemail.server.net"
cMailUsername = ""
cMailPassword = ""
cMailingListCC=""

cHomePath = "/"
cThreadHomePath = "/wwthreads/"
cBACKIMG = ""

cHTMLPagePath = "d:\westwind\wwthreads\"
cDataPath = "d:\wwapps\wc3\wwthreads\"
cDefaultReplyTo = "All"
cAdminPage = "admin_cl.htm"
cAdminUsers = ""  && CR delimited list

cResponseClass = [WWC_PAGERESPONSE]
nPageScriptMode = 2

************************************************************************
* wwThreads :: LoadProperties
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadProperties
LOCAL loConfig

loConfig = this.oConfig

THIS.cHTMLPagePath = loConfig.cHTMLPagePath
THIS.cDataPath = loConfig.cDataPath

THIS.cDefaultForum = loConfig.cDefaultForum
THIS.cScriptPath = loConfig.cScriptPath
THIS.cMailserver = loConfig.cMailServer
this.cMailUsername = this.oServer.oConfig.cAdminMailUsername
this.cMailPassword = this.oServer.oConfig.cAdminMailPassword
THIS.cMailingListCC = loConfig.cMailingListCC

THIS.lUseLogins = loConfig.lUseLogins

THIS.cHomePath = loConfig.cHomePath
THIS.cThreadHomePath = loConfig.cThreadHomePath
THIS.cAdminPage = loConfig.cAdminPage
THIS.cAdminUsers = loConfig.cAdminUsers

this.cEmailFooter = ;
[<div class="messagedetailheader" style="text-align: center">] + CRLF +;
[<b style="font-size: 10pt">Do not reply to this email message</b><br />] + CRLF +;
[This message has been forwarded to you from the West Wind Message Board<br />]  + CRLF +;
[<b><a href="http://] + this.oRequest.ServerVariables("SERVER_NAME") + this.cHomePath + [default.asp?msgid=<%= pcMsgId %>" target="_message">Click here to reply to this message</a></b>]  + CRLF +;
[</div>]  + CRLF

ENDFUNC
* LoadProperties


************************************************************************
* wwThreads :: OnProcessInit
****************************
***  Function: This is the callback program file that handles
***            processing a CGI request
***      Pass: THIS.oRequest	-	Object containing CGI information
***    Return: .T. to erase Temp File .F. to keep it
************************************************************************
FUNCTION OnProcessInit
LOCAL lcParameter, lcOutFile, lcIniFile, lcOldError

THIS.LoadProperties()

Response.cStyleSheet = "wwthreads.css"

*** Handle urls like ShowMessage131231.wwt 
lcScript = LOWER( JUSTSTEM(this.oRequest.GetPhysicalPath()) )
IF (lcScript = "message" ) 
   lcMsgId = SUBSTR(lcScript,LEN("message")+1)
   this.ShowMsg(lcMsgId)
   return .F.  
ENDIF

*** We need Session only for a posting related tasks
IF lcScript = "writemsg" OR lcScript = "postmsg" OR lcScript = "replymsg" OR lcScript = "editmsg"
	this.InitSession("__wwThreads",30)
ENDIF

RETURN .T.



************************************************************************
*  Login
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Login()

#IF .F. 
LOCAL Request as wwRequest, Response as wwPageResponse
#ENDIF

Response.ExpandPage(JUSTPATH(Request.GetPhysicalpath()) + "\Login.wcsx")

ENDFUNC
*   Login

************************************************************************
* wwThreads ::  Mobile
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Mobile()
THIS.ShowMessages()
ENDFUNC
*  wwThreads ::  Mobile

************************************************************************
* wwThreads :: ShowMessages
***************************
***  Function: Displays Message List
***    Assume: NOTE: This routine is called from various internal
***                  links like the thread view, search etc.
***                  updating the list. In that case a poList object
***                  that is ready to go is sent. This code will
***                  guarantee that poList.BuildList() and poList.RunSQL()
***                  are run.
***      Pass: lcID      -  User Id to look message up for
***            poList    -  wwThreadList Object that holds SQL string
***                         for query (see wwtList.prg)
************************************************************************
FUNCTION ShowMessages
LPARAMETER lcId, loList
LOCAL lcNextId, lcLastId, ldDate, lnLoc, lcForum,  lcWhere, lcId

** lcCookieId=IIF(TYPE("lcId")="C",lcId,"")
lcWhere=IIF(EMPTY(lcWhere),"",lcWhere)

*** Retrieve Form Variables
ldDate=FromIsoDateString(Request.Form("FromDate"))
ldDate2=FromIsoDateString(Request.Form("ToDate"))
lcForum=Request.Form("Forum")
IF EMPTY(lcForum)
   lcForum = Request.QueryString("Forum")
ENDIF
lcMsgId=Request.QueryString("MsgId")


*** Handle Messages To You
llMail = .F.
IF lcForum = "Messages to"
   llMail = .T.
   lcForum = "All Forums"  && All Forums
ENDIF

*** Create User Object to check validity
loUser=CREATEOBJECT("ThreadUser")
loUser.cDataPath = THIS.cDataPath
*** See if we have cookie for WWTHREADID
IF EMPTY(lcId)
   lcId=Request.GetCookie("WWTHREADID")
ENDIF

*** Load User or create new anonymous user
loUser.GetUser(lcId)

PRIVATE poUser
poUser = loUser

*** No List Object - we're just refreshing off the page
***                  or accessing for the first time
IF VARTYPE(loList) # "O"
   *** Create List Query/HTML object
   loList = CREATE("wwThreadList")
   loList.oProcess = THIS
   loList.oUser = loUser
   loList.dFromDate = ldDate
   loList.dToDate = ldDate2
   loList.cForum = lcForum
   loList.AddDefaultFilter()
ENDIF

IF loUser.Admin # 0
   loList.lAdmin = .T.
ENDIF

*** Special Handling: Your EMail
IF llMail
   SELE wwUsers
   IF EMPTY(Email)
      lcEmail=SPACE(FSIZE(Email))
   ELSE
      lcEmail=TRIM(Email)
   ENDIF

   loList.AddCustomFilter("ATC('" + lcEmail + "',To)>0")
ENDIF

*** CREATE THE PRIVATE STRING VARS TO DISPLAY IN TEMPLATE PAGE

*** Send header and add cookie after posting if necessary
	pcFromDate = IIF(EMPTY(ldDate),ToIsoDateString(loList.dFromDate),ToIsoDateString(ldDate))
	pcToDate = IIF(EMPTY(ldDate2),ToIsoDateString(loList.dToDate),ToIsoDateString(ldDate2))

*** Build the forum list and output
SELECT ForumName ;
       FROM (THIS.cDataPath + "wwt_forums") ;
       WHERE !NoDownload ;
       Order by 1 ;
       INTO CURSOR TForums  
       
pcForumPopup = HtmlDropDown("Forum",TRIM(lcForum),"TForums","TRIM(ForumName)","TRIM(ForumName)",;
							[onchange="this.form.submit();return true;"],;
							[All Forums] + CRLF + ;
	                        [<option] + IIF(llMail," SELECTED","") + [>Messages to you] + CRLF + ;
	                        "<option>------------------" +CRLF)
USE IN TForums


	*** Now run the query and gen the HTML for the actual List
	lnResult = loList.RunSql()
	loList.BuildList()

	*** Store the output to a string that gets embedded in the template!
	pcListHtml = loList.GetOutput()


*** Assign forum to private var
pcForum = lcForum

*** And render the message into HTML 
Response.ExpandTemplate(THIS.cHTMLPagePath + "ShowMessages.wwt") &&,loHeader)

*** Update user info and save
loUser.tLastOn=DATETIME()
loUser.cVars=Request.GetIPAddress()
IF !EMPTY(ldDate)
   loUser.dListDate=ldDate
ENDIF
loUser.SaveUser()

IF USED("TwwMsgList")
   USE IN TwwMsgList
ENDIF

RETURN
ENDFUNC
* ShowMessages

************************************************************************
* wwThreads :: MessageIndex
****************************************
***  Function: This page is meant to be left for Search Engines
***            so that the message board can be indexed. You should
***			   reference this link prominently so that search engines
*** 		   will find it and eventually end up indexing all messages.
***    Assume:
************************************************************************
FUNCTION  ShowMessageIndex(lcArchive)

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse
#ENDIF

ldStartDate = DATE() - 90
ldEndDate = DATE()
IF EMPTY(lcArchive)
	lcArchive = Request.QueryString("Archive")
	IF !EMPTY(lcArchive)
		lcOldDate = SET("DATE")
		SET DATE ANSI
		lnYear = VAL(LEFT(lcArchive,4))
		lnMonth = VAL(SUBSTR(lcArchive,5,2))

		lcStartDate = TRANSFORM(lnYear) + "." + TRANSFORM(lnMonth) + ".01"

		IF lnMonth = 12
			lnMonth = 1
			lnYear = lnYear +1
		ELSE
			lnMonth = lnMonth + 1
		ENDIF
		lcEndDate = TRANSFORM(lnYear) + "." + TRANSFORM(lnMonth) + ".01"
			
		lcDate = LEFT(lcArchive,4) + "/" + SUBSTR(lcArchive,5,2) + "/01"
		ldStartDate = CTOD(lcStartDate)
		ldEndDate = CTOD(lcEndDate)
		SET DATE (lcOldDate)
	ENDIF
ENDIF

SELECT MsgId,Subject,FromName,TimeStamp FROM wwThreads ORDER BY TimeStamp Desc ;
	INTO CURSOR TQuery ;
	WHERE TimeStamp => ldStartDate AND TimeStamp <= ldEndDate

lcOutput = ""
SCAN
	lcOutput = lcOutput + [<a href="Message] + TRIM(MsgId) + [.wwt">] + TRIM(Subject) + [</a>] + CRLF + ;
			   [<br> posted by <i>] + TRIM(FromName) + [</i> on ] + TimeToC(Timestamp) + [<p>] + CRLF + CRLF
ENDSCAN	

Response.HtmlHeader("Complete Message Board Post Listing")

Response.Write("<small>from " + TRANSFORM(ldStartDate) + " to " + TRANSFORM(ldEndDate) + "</small><p>")

Response.Write(lcOutput)

Response.HtmlFooter()
ENDFUNC
*  wwThreads :: ShowMessageLinks


************************************************************************
* wwThreads :: ShowMessageArchive
****************************************
***  Function:
***    Assume:
************************************************************************
FUNCTION  ShowMessageArchive()

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse
#ENDIF

SELECT YEAR(TimeStamp) as Year, MONTH(TimeStamp) as Month, COUNT(timestamp) as Count ;
	FROM wwThreads GROUP BY 1,2 ORDER BY 1 desc, 2 DESC ;
	INTO CURSOR TQuery

lcOutput = "<style> .navigationlink {display:block;} .navigationlink:hover {background:blue;color:cornsilk;}</style>"
SCAN
	ldDate = EVALUATE("{^" + TRANSFORM(Year) + "/" + TRANSFORM(Month) + "/01 }")
	lcOutput = lcOutput + "<a href='ShowMessageIndex.wwt?Archive=" + ;
								TRANSFORM(TQuery.Year) + PADL(TQuery.Month,2,"0") +;
								"'>" + CMONTH(ldDate) + ", " + TRANSFORM(TQuery.Year) + ;
								"</a> (" + TRANSFORM(Count) + ")<br />" + CRLF
ENDSCAN	
	
	
Response.HtmlHeader("Message Board Archive")
 
Response.Write(lcOutput)

Response.HtmlFooter()

ENDFUNC
*  wwThreads :: ShowMessageArchive



************************************************************************
* wwThreads :: RssFeed
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION wwThreadsRssFeed()
LOCAL lcXML 

*** Days to return in the feed
lnDays = VAL( Request.QueryString("Days") )
IF (lnDays = 0 )
  lnDays = 2  && 3 days default
ENDIF  
lcForum = Request.QueryString("Forum")


*** Retrieve Request specific item (Request specific key)
lcXML = Server.oCache.GetItem("wwThreads_" + lcForum)

IF ISNULL(lcXML)
   loMessage = CREATEOBJECT("ThreadMessage")
   loMessage.cDataPath = THIS.cDataPath
   loMessage.cHTMLPagePath = THIS.cHTMLPagePath

   lnCount = loMessage.GetRssMessages(lnDays)

   TEXT TO lcXML NOSHOW
<rss version="2.0">
   <channel>
      <title>West Wind Message Board Messages</title>
      <link>http://www.foxcentral.net</link>
      <description>West Wind Message Board New Messages</description>
      <language>en-us</language>
      <ttl>1440</ttl>  
   ENDTEXT

   LOCAL loXML as wwXML
   loXML = CREATEOBJECT("wwXML")

   SCAN
      IF !loMessage.LoadMessage(MsgId) 
         LOOP
      ENDIF

      MimeDate = MimeDateTime(loMessage.TTimeStamp,.T.)
      
      lcItem = "     <item>" + CRLF +;
                     loXML.AddElement("title",TRIM(loMessage.cSubject),3)
      lcItem = lcItem + loXML.AddElement("pubDate",MimeDate,3)
      lcItem = lcItem + loXML.AddElement("guid", MsgId,3,[isPermaLink="false"])
      lcItem = lcItem + loXML.AddElement("description",loMessage.RenderMessage(),3)  && this.cHtmlPagePath+"rssmessage.wwt"),
      lcItem = lcItem + loXML.AddElement("link","http://www.west-wind.com/wwThreads/default.asp?msgid=" + loMessage.cMsgId,3)
      lcItem = lcItem + loXML.AddElement("author",TRIM(loMessage.cFromName),3)
      lcItem = lcItem + "     </item>" +CRLF
    
      lcXML = lcXML + lcItem
   ENDSCAN

   lcXML = lcXML + "</channel>" + CRLF +;
                   "</rss>"
   *** Write it into the Cache with Request Specific Key
   Server.oCache.AddItem("wwThreads_" + lcForum ,lcXML,600)
ENDIF

*** Write a cache header out - public cache
Response.ContentType = "text/xml"
Response.AddCacheHeader(300)
Response.Write( STRCONV(lcXML,9) )
ENDFUNC
*  wwThreads :: RssFeed

************************************************************************
* wwThreads :: ShowThread
*********************************
***  Function: Shows a specific thread. Calls ShowMessages to display.
************************************************************************
FUNCTION ShowThread
LOCAL lcWhere
PRIVATE  ThreadId

pcThreadId = THIS.oRequest.QueryString("ThreadID")

loList = CREATE("wwThreadList")
loList.oProcess = THIS
loList.AddForumFilter()
loList.AddCustomFilter( "ThreadId = pcThreadId ")

THIS.ShowMessages(,loList)
ENDFUNC
* ShowThread

************************************************************************
* wwThreads :: QueryForm
*********************************
***  Function: Display the Search form online
************************************************************************
FUNCTION QueryForm
LOCAL oHTMLForm, loThreadQuery, lcForum, loPopup
PRIVATE pcForumPopup

*** Retrieve a date from the top of the form
ldDate=CTOD(THIS.oRequest.Form("FromDate"))
ldDate2=CTOD(THIS.oRequest.Form("ToDate"))
IF EMPTY(ldDate2)
   ldDate2=DATE()
ENDIF
IF EMPTY(ldDate)
   ldDate = CTOD( "01/01/" + TRANSFORM(YEAR(DATE())) )
ENDIF
lcForum=Request.Form("Forum")

*** State Popup
SELECT ForumName ;
   FROM (THIS.cDataPath + "wwt_Forums") WHERE !NoDownload ;
   INTO CURSOR TList

pcForumPopup = HtmlDropDown("cmbForum",Request.FormOrValue("cmbForum",""),;
	"TList",;
	"TList.ForumName",;
	"TList.ForumName",;
	[class="textfields"],;
	"","")

Response.ExpandTemplate(THIS.cHTMLPagePath + "queryform.wwt")

RETURN


************************************************************************
* wwThreads :: FilterQuery
*********************************
***  Function: Submit a Search Request
************************************************************************
FUNCTION FilterQuery
LOCAL lcWhere, ldDate, ldate2, lcForum, lcSearch1, lcSearch2, lcSearch3, ;
      lcMsgId, loList, lcSearch, lcFrom, lcTo

lcXML = Request.FormXML()
IF lcXML = "<?xml"
   llXML = .T.
   Request.lUseXMLFormVars = .T.
ELSE
   llXML = .F.
ENDIF 

*** Retrieve a date from the top of the form
ldDate=FromIsoDateString(Request.Form("FromDate"))
ldDate2=FromIsoDateString(Request.Form("ToDate"))
lcForum=Request.Form("cmbForum")

lcSearch1=Request.Form("txtSearchText1")
lcSearch2=Request.Form("txtSearchText2")
lcSearch3=Request.Form("txtSearchText3")

lcBy = Request.Form("txtBy")
lcTo = REquest.Form("txtTo")

lcMsgId = Request.Form("txtMsgId")

*** If a filter wasn't passed create one
loList = CREATE("wwThreadList")
loList.oProcess = THIS

loList.AddDateFilter(ldDate,ldDate2,.t.)
loList.AddForumFilter(lcForum)

lcSearch=""
*** Build Search String separately with Parens for compound expression
IF !EMPTY(lcSearch1)
   lcSearch=lcSearch + " ( ATC(["+ lcSearch1 + "],Subject)>0 OR  ATC(["+ lcSearch1 + "],Message)>0 ) "
   IF !EMPTY(lcSearch2)
      lcSearch= lcSearch + Request.Form("cmbAndOr1")
   ENDIF
ENDIF
IF !EMPTY(lcSearch2)
   lcSearch=lcSearch + " ( ATC(["+ lcSearch2 + "],Subject)>0 OR  ATC(["+ lcSearch2 + "],Message) >0 ) "
ENDIF

IF LEFT(lcSearch,3)="AND" 
   lcSearch = SUBSTR(lcSearch,1,LEN(lcSearch)-3)
ENDIF   
IF LEFT(lcSearch,2)="OR" 
   lcSearch = SUBSTR(lcSearch,1,LEN(lcSearch)-2)
ENDIF   

loList.AddCustomFilter(lcSearch)

IF !EMPTY(lcMsgId)
   loList.AddCustomFilter("MsgId = '" + lcMsgId + "'")
ENDIF
IF !EMPTY(lcBy)
   loList.AddCustomFilter(" lower(fromname) = lower('" + lcBy + "') ")
ENDIF 


   
IF EMPTY(lcSearch) AND EMPTY(lcBy) AND EMPTY(lcMsgId)
   loList.cMessage = "Insufficient search criteria.<hr />" + ;
                     "<small>Please provide a search term, id, or poster name</small>"

   *** Set the query filter to return no data
   THIS.ShowMessages(" .F. ",loList)
   RETURN
ENDIF

*** Download Button - Zip up the result
IF !EMPTY(Request.Form("btnDownload"))
  loList.lDownload = .T.
ENDIF  

IF llXML
   lnCount = loList.RunSQL()   
   loXML = CREATE("wwXML")
   IF lnCount = -1
      lcOutput = loXML.cXMLHeader + loXML.CreateErrorXML("Filter too complex.")
   ENDIF
   IF lnCount = 0
      lcOutput = loXML.cXMLHeader + loXML.CreateErrorXML("No messages found.")
   ELSE
      loXML.cDocRootName = "wwthreadquery"   
      lcOutput = loXML.CursorToXML("messages","message")
   ENDIF
   Response.Write(lcOutput)
ELSE

   THIS.ShowMessages(,loList)
ENDIF

ENDFUNC
* FilterQuery


***********************************************************************
* wwThreads :: ShowMsg
**********************
***  Function: Displays a message in a table view.
************************************************************************
FUNCTION ShowMsg
LPARAMETER lcMsgId, lcHTML
LOCAL lcMsgId, ldDate, loUser, lnRecno, lcHTML
PRIVATE pcPageFoot, pcNextId, pcPreviousId

IF EMPTY(lcMsgId)
   lcMsgId=Request.QueryString("MsgId")
ENDIF
lcMsgId = UPPER(lcMsgId)

lcId=Request.GetCookie("WWTHREADID")

llNoFilter=Request.QueryString("NoFilter")
llNoFilter=IIF(UPPER(llNoFilter)="NOFILTER",.T.,.F.)

loUser=CREATEOBJECT("ThreadUser")
loUser.cDataPath = THIS.cDataPath

plAllowEdit = .F.

*** Get User
loUser.GetUser(lcId)

IF !USED("wwThreads")
   USE ("wwThreads") IN 0
ENDIF
SELE wwThreads

*** Now locate the actual message
IF EMPTY(lcMsgId)
   *** No Id specified - Show Top
   SELECT MsgId, MAX(TimeStamp) FROM wwThreads,(THIS.cDataPath + "wwt_forums") ;
          WHERE TimeStamp > DATE() -1 AND ;
                wwthreads.forum = wwt_forums.forumname AND ; 
                !wwt_forums.NoDownload ;
          GROUP BY 1 ;
          INTO ARRAY laTemp
          
   IF _Tally = 1
      LOCATE for MsgId = laTemp[1]
   ELSE 
      LOCATE      
   ENDIF
ELSE
  LOCATE FOR Msgid=lcMsgId  && Gotta be Ok since we found it above
  IF !Found()
	 THIS.ErrorMsg("Can't Find Specified Message",;
	               "The message that you specified is not available to view at this time...")
    RETURN
  ENDIF
ENDIF


IF loUser.Admin # 0 or wwThreads.UserId == lcId 
   plAllowEdit=.T.
ENDIF

*** Pass user to template
poUser = loUser

*** Render the HTML for the message
poMsg=CREATEOBJECT("ThreadMessage")
poMsg.cDataPath = THIS.cDataPath
poMsg.cHTMLPagePath = THIS.cHTMLPagePath
poMsg.LoadMessage()

lcHTML = poMsg.RenderMessage()

Response.Write(lcHTML)

ENDFUNC
* ShowMsg
*!*	*** Add a banner to the bottom of the page
*!*	loBanner = create("wwBanner")
*!*	loBanner.cBannerFile = "wwSiteBanners"
*!*	loBanner.cAlias = "wwSiteBanners"
*!*	pcBannerText = "<!-- BEGIN BANNER -->" + loBanner.GetBanner(-1) + "<!-- END BANNER -->"

*!*	*** Now render the page
*!*	Response.ExpandTemplate( THIS.cHTMLPagePath + "showmsg.wwt")

*!*	ENDFUNC



***********************************************************************
* wwThreads :: ShowThreadMessage
**********************
***  Function: Displays a message in a table view.
***********************************************************************
FUNCTION ShowThreadMessages
LPARAMETER lcThreadId, lcHTML
LOCAL  ldDate, loUser, lnRecno, lcHTML
PRIVATE pcPageFoot, pcNextId, pcPreviousId

IF EMPTY(lcThreadId)
   lcThreadId=Request.QueryString("ThreadId")
ENDIF
lcThreadId = UPPER(lcThreadId)

loUser=CREATEOBJECT("ThreadUser")
loUser.cDataPath = THIS.cDataPath

plAllowEdit = .F.

lcId=Request.GetCookie("WWTHREADID")

*** Get User
loUser.GetUser(lcId)

IF !USED("wwThreads")
   USE ("wwThreads") IN 0
ENDIF
SELE wwThreads

SELECT * FROM wwThreads ;
   WHERE threadId = lcthreadId ;   
   ORDER BY TimeStamp ;
   INTO CURSOR TMessages 

IF loUser.Admin # 0 or wwThreads.UserId == lcId 
   plAllowEdit=.T.
ENDIF

*** Pass user to template
poUser = loUser
pcBannerText = ""

Response.ExpandScript(THIS.cHTMLPagePath+"ShowThreadMessages.wwt")
ENDFUNC
* ShowMsg

************************************************************************
* wwThreads :: UpdateToolbar
*********************************
***  Function: Shows the page header and tool bar. This hit is loaded
***            each time a new message is displayed.
************************************************************************
FUNCTION UpdateToolbar
LOCAL lcMsgId, loUser
PRIVATE pcForum, plAllowEdit, pcMsgId

lcMsgId=Request.QueryString("MsgId")
lcId=Request.GetCookie("WWTHREADID")

loUser=CREATEOBJECT("ThreadUser")
loUser.cDataPath = THIS.cDataPath

*** Check if the user exists
IF !loUser.GetUser(lcId)
   *** Nope - let's create a cookie and save
   lcId=loUser.SaveNewUser()
   loUser.cForum=THIS.cDefaultForum
   loUser.SaveUser()
ENDIF

pcForum=loUser.cForum
pcHomePath=THIS.cHomePath

ldDate=loUser.dListDate
pcMsgId=lcMsgId

IF !USED("wwThreads")			
   USE (THIS.cDATAPATH+"wwThreads") IN 0
ENDIF

SELE wwThreads
LOCATE FOR Msgid=lcMsgId
IF !FOUND()
   pcMsgId=lcMsgId
   Response.ExpandTemplate(THIS.cHTMLPagePath+"updateToolbar.wwt")
   RETURN
ENDIF

*** Allow editing of the record if the Cookie Id matches or user is Admin
plAllowEdit=.F.
IF loUser.Admin # 0 or wwThreads.USERID == lcId 
   plAllowEdit=.T.
ENDIF

**Response.AddForceReload()
Response.ExpandScript(THIS.cHTMLPagePath+"updatetoolbar.wwt")
ENDFUNC
* UpdateToolbar

************************************************************************
* wwThreads :: KillMessage
**************************
***  Function: Deletes a message - asks for authentication first
************************************************************************
FUNCTION KillMessage
LOCAL lcId, loUser, lcMsgId

lcMsgId=THIS.oRequest.QueryString("MsgId")

lcId=Request.GetCookie("WWTHREADID")

loUser=CREATEOBJECT("ThreadUser")
loUser.cDataPath = THIS.cDataPath

*** Check if the user exists
IF !loUser.GetUser(lcId) 
   *** Nope - let's create a cookie and save
   THIS.ErrorMsg("Invalid Logon",[Please enter the message <A HREF="]+THIS.cThreadHomePath+[">here</a>.])
   RETURN
ENDIF

IF !USED("wwThreads")
   USE (THIS.cDataPath+"wwThreads") IN 0
ENDIF

SELE wwThreads
LOCATE FOR Msgid=lcMsgId
IF !FOUND()
   THIS.ErrorMsg("Couldn't Delete Message")
   USE IN wwThreads
ELSE
   *** Only allow deleting for Msg Author or Admin user
   IF loUser.Admin # 0 or wwThreads.USERID == lcId 
      THIS.ErrorMsg("Message Deleted","Message ID: "+wwThreads.MsgId+"<P>"+;
                                      "The message list has not been updated. Click 'Refresh' to update the list.")
      DELETE
   ELSE
      THIS.ErrorMsg("Access Denied",[Please enter the message <A HREF="]+THIS.cThreadHomePath+[" TARGET="_top">here</a>.])
      RETURN
   ENDIF
ENDIF

ENDFUNC
* KillMessage

************************************************************************
* wwThreads :: WriteMsg
***********************
***  Function: Brings up the entry form
************************************************************************
FUNCTION WriteMsg

#IF .F. 
LOCAL Request as wwRequest, Response as wwPageResponse
#ENDIF

*** Defer to Web Control Page
Response.Expandpage(THIS.cHTMLPagePath+"writemessage.wcsx")
RETURN

ENDFUNC
* WriteMsg

************************************************************************
* wwThreads :: ReplyMsg
***********************
***  Function: Replies to an existing message. Loads existing message
***            and provides REply text. Displays WRITEMSG.WC for editing
************************************************************************
FUNCTION ReplyMsg

#IF .F. 
LOCAL Request as wwRequest, Response as wwPageResponse
#ENDIF

*** Defer to Web Control Page
Response.Expandpage(THIS.cHTMLPagePath+"writemessage.wcsx")
RETURN

ENDFUNC
* ReplyMsg

************************************************************************
* ThreadProcess :: EditMsg
*********************************
***  Function: Edits a an existing message. Message can be edited in
***            user mode or Admin mode.
************************************************************************
FUNCTION EditMsg

#IF .F. 
LOCAL Request as wwRequest, Response as wwPageResponse
#ENDIF

Response.Expandpage(THIS.cHTMLPagePath+"writemessage.wcsx")
RETURN

*!*	*** These two are used for replies only
*!*	lcMsgId=Request.QueryString("MsgId")

*!*	*** Create a unique id and embed into page for WriteMsg to capture
*!*	pcUniqueId = SYS(2015)
*!*	Session.SetSessionVar("WriteMsgId",pcUniqueId)

*!*	lcId=Request.GetCookie("WWTHREADID")

*!*	lojQueryConfig = CREATEOBJECT("jQueryConfig")
*!*	pcjQueryInclude = lojQueryConfig.IncludejQuery("Default",.t.)

*!*	loUser=CREATEOBJECT("ThreadUser")
*!*	loUser.cDataPath = THIS.cDataPath

*!*	*** Check if the user exists
*!*	IF !loUser.GetUser(lcId)
*!*	   *** Nope - let's create a cookie and save
*!*	   lcId=loUser.SaveNewUser()
*!*	   loUser.cForum=THIS.cDefaultForum
*!*	ENDIF

*!*	IF !USED("wwThreads")
*!*	   USE (THIS.cDataPath+"wwThreads") IN 0
*!*	ENDIF

*!*	SELE wwThreads

*!*	LOCATE FOR Msgid=lcMsgId  
*!*	IF !FOUND() OR ( loUser.Admin = 0 AND wwThreads.USERID <> lcId )
*!*	   THIS.ErrorMsg("Unable to edit message.",;
*!*	      "Message can't be accessed at the moment.")
*!*	   RETURN
*!*	ENDIF

*!*	*** Now load message into object
*!*	poMessage=CREATEOBJECT("ThreadMessage")
*!*	poMessage.cDataPath = THIS.cDataPath
*!*	poMessage.LoadMessage()

*!*	IF !poMessage.lNoFormat
*!*	   poMessage.FixNoFormat(.T.)
*!*	ENDIF

*!*	*** Display standard Page footer on the page
*!*	*pcPageFoot=THIS.cListFooter

*!*	SELECT ForumName FROM (THIS.cDataPath + "wwt_forums") ;
*!*	       WHERE !NoDownload ORDER BY ForumName INTO CURSOR TForums
*!*	       
*!*	loPopup=CREATEOBJECT("wwDBFPOPUP")
*!*	loPopup.cFormVarName="txtForum"
*!*	loPopup.cDisplayExpression="TRIM(ForumName)"
*!*	loPopup.cKeyValueExpression="TRIM(ForumName)"
*!*	loPopup.cSelectedValue=poMessage.cForum
*!*	loPopup.cAddFirstItem = "Please select a forum"
*!*	loPopup.cExtraSELECTTags=[class="fields"] 
*!*	loPopup.BuildList()
*!*	USE IN TForums

*!*	pcForumPopup = loPopup.GetOutput()

*!*	*** Now call WriteMsg for editing
*!*	THIS.oResponse.ExpandTemplate(THIS.cHTMLPagePath+"writemsg.wwt")

*!*	ENDFUNC
*!*	* EditMessage


*!*	************************************************************************
*!*	* wwThreads :: PostMsg
*!*	*********************************
*!*	***  Function: Actually post the message on the board
*!*	************************************************************************
*!*	FUNCTION PostMsg
*!*	LOCAL lcMsgId, lcThreadId, loMessage, loHeader, lcSendto,;
*!*	   lcOrigMessage, lcHTML
*!*	   
*!*	#IF .F. 
*!*	LOCAL Request as wwRequest, Response as wwPageResponse
*!*	#ENDIF

*!*	Response.Expandpage(THIS.cHTMLPagePath+"writemessage.wcsx")
*!*	RETURN

*!*	*** Must have session object for spam prevention
*!*	IF VARTYPE(Session) # "O"
*!*		Response.Redirect("writemsg.wwt")
*!*		Response.End()
*!*		return
*!*	ENDIF

*!*	*** Create a unique id and embed into page for WriteMsg to capture
*!*	pcUniqueId = Session.GetSessionVar("WriteMsgId")

*!*	lcXId = Request.Form("xxid")
*!*	IF EMPTY(lcXid) OR Request.Form("xxid") != pcUniqueId
*!*		this.Errormsg("Invalid Message Id","Message posting is invalid.")
*!*		return
*!*	ENDIF

*!*	*** We're reading in data here that may contain unsafe text
*!*	*** but it's never queried here
*!*	Request.lFilterUnsafeCommands = .F.

*!*	*** These two are used for replies only
*!*	lcMsgId=Request.QueryString("MsgId")
*!*	lcThreadId=Request.QueryString("ThreadId")
*!*	lcParentId=Request.QueryString("Parent")

*!*	lcId=Request.GetCookie("WWTHREADID")

*!*	loUser=CREATEOBJECT("ThreadUser")
*!*	loUser.cDataPath = THIS.cDataPath

*!*	llEditing=.F.
*!*	IF !EMPTY(lcMsgId)
*!*	   llEditing=.T.
*!*	ENDIF

*!*	*** Check if the user exists
*!*	IF !loUser.GetUser(lcId)
*!*	   *** Nope - let's create a cookie and save
*!*	   lcId=loUser.SaveNewUser()
*!*	   loUser.cForum=THIS.cDefaultForum
*!*	ENDIF

*!*	loMessage=CREATEOBJECT("ThreadMessage")
*!*	loMessage.cDataPath = THIS.cDataPath
*!*	loMessage.cHTMLPagePath = THIS.cHTMLPagePath
*!*	lcName=Request.Form("txtFrom")
*!*	lcEmail=Request.Form("txtFromEmail")

*!*	loMessage.cUserId=lcId

*!*	DO CASE
*!*	   CASE EMPTY(lcEmail)
*!*	      loMessage.cFromname=lcName
*!*	   CASE EMPTY(lcName)
*!*	      loMessage.cFromEmail=lcEmail
*!*	   OTHERWISE
*!*	      loMessage.cFromname=lcName
*!*	      loMessage.cFromEmail=lcEmail
*!*	ENDCASE

*!*	loMessage.cTo=Request.Form("txtTo")
*!*	loMessage.cSubject=Request.Form("txtSubject")
*!*	loMessage.cForum=Request.Form("txtForum")

*!*	IF EMPTY(loMessage.cFromName)
*!*	   THIS.ErrorMsg("Name cannot be blank",;
*!*	                 "Please provide a name so we know who you are. Please use the back button to fill in the information.")
*!*	   RETURN                
*!*	ENDIF   
*!*	IF EMPTY(loMessage.cSubject)
*!*	   THIS.ErrorMsg("Subject is missing",;
*!*	                 "The subject cannot be left blank. Please use the back button to fill in the information.")
*!*	   RETURN
*!*	ENDIF   
*!*	IF loMessage.cForum = "Please select"
*!*	   this.ErrorMsg("Forum selection is missing","Make sure you select a forum to post the message into")
*!*	   RETURN
*!*	ENDIF

*!*	*!*   IF UPPER(Request.Form("chkFormat")) = "HTML"
*!*	*!*      loMessage.lNoFormat=.T.   && Leave as HTML
*!*	*!*   ENDIF

*!*	*** Retrieve message text and store as original text
*!*	lcOrigMessage=Request.Form("txtMessage")

*!*	IF loMessage.IsSpam(lcOrigMessage)
*!*	   this.Errormsg("Invalid Message Content","The message content posted includes invalid content and has been rejected.")
*!*	   RETURN
*!*	ENDIF

*!*	LOCAL loRegEx as wwRegEx in wwRegEx.prg
*!*	loRegEx = CREATEOBJECT("wwRegex")
*!*	lcOrigMessage = loRegEx.Replace(lcOrigMessage,[(<code lang=.*?>)],;
*!*					["<" + lcMatch + ">"],.t.)				
*!*	lcOrigMessage = STRTRAN(lcOrigMessage,[</code>],[<</code>>])

*!*	loMessage.cMessage=lcOrigMessage
*!*	IF EMPTY(loMessage.cMessage)
*!*	   THIS.ErrorMsg("No Content","The body of the the message cannot be left blank. Please use the back button to add your message body.")
*!*	   RETURN
*!*	ENDIF

*!*	*** Format message if plain text
*!*	IF !loMessage.lNoFormat
*!*	   loMessage.FixNoFormat()
*!*	ELSE
*!*	   loMessage.cMessage=lcOrigMessage
*!*	ENDIF

*!*	*** Add Signature
*!*	IF !llEditing and !EMPTY(loMessage.cMessage)
*!*	   loMessage.AddSignature(TRIM(loUser.cSignature))
*!*	ENDIF


*!*	loMessage.cThreadId=lcThreadId
*!*	loMessage.cParentId=lcParentId

*!*	IF EMPTY(loMessage.cForum) OR loMessage.cForum="Please select a Forum"
*!*	   THIS.ErrorMsg("Invalid Forum",;
*!*	      "Please select a forum from the forum list.<P>"+;
*!*	      "Use the <b>Back</b> button on your browser to return to the input form...")
*!*	   RETURN
*!*	ENDIF


*!*	IF !llEditing
*!*	   *** Check and make sure they're not entering the same message more than once
*!*	   SELECT Msgid ;
*!*	      FROM (THIS.cDataPath + "wwThreads") ;
*!*	      WHERE fromname=loMessage.cFromname AND MESSAGE=loMessage.cMessage AND ;
*!*	            TIMESTAMP > date() -1 ;
*!*	      INTO ARRAY laTemp

*!*	   IF _TALLY > 0
*!*	      THIS.ErrorMsg("This Message was already entered!",;
*!*	         "Most likely this was caused by pressing the Post button more than once before "+;
*!*	         "receiving a result page...")
*!*	      USE IN wwThreads
*!*	      RETURN
*!*	   ENDIF

*!*	   loMessage.SaveMessage()
*!*	ELSE
*!*	   IF !USED("wwThreads")
*!*	      USE (THIS.cDataPath + "wwThreads") IN 0
*!*	   ENDIF

*!*	   SELE wwThreads
*!*	   LOCATE FOR Msgid=lcMsgId
*!*	   IF FOUND()
*!*	      llEditing=.T.
*!*	      loMessage.cMsgId=lcMsgId
*!*	      loMessage.cThreadId=lcThreadId
*!*	      loMessage.SaveMessage(.T.)
*!*	   ENDIF
*!*	ENDIF

*!*	*** Clear out the WriteMsgId so it can't be used again
*!*	Session.SetSessionVar("WriteMsgId","")

*!*	*** Add cookie with the name used for this message
*!*	*loHeader=CREATEOBJECT("wwHTTPHeader")
*!*	*loHeader.Redirect( "ShowMsg.wwt?MsgId="+loMessage.cMsgId)

*!*	*** Render the HTML for the message
*!*	lcHTML = loMessage.RenderMessage()

*!*	IF !llEditing
*!*	   *** Note we're accessing the GLOBAL (PUBLIC) oServer here
*!*	   lcSendto=""
*!*	   IF !EMPTY(Request.Form("ChkEmail")) AND AT("@",loMessage.cTo)>0
*!*	      SplitNames(loMessage.cTo,"",@lcSendto)
*!*	   ENDIF

*!*	   *** If ALL was used then just send to mailing list...
*!*	   IF EMPTY(lcSendTo) AND !EMPTY(THIS.cMailingListcc)
*!*	      lcSendTo=THIS.cMailingListCC
*!*	      THIS.cMailingListCC = ""
*!*	   ENDIF

*!*	   lctMessage=loMessage.cMessage
*!*	   loMessage.StripSignature()
*!*	   lcHtml = loMessage.InlineStyles(lcHtml)
*!*	   
*!*	   LOCAL loIP as wwSmtp
*!*	   loIp = CREATEOBJECT([WWC_WWSMTP])
*!*	   loIp.nMailMode = 2 && Classic

*!*	    
*!*	   loIP.cMailServer = THIS.cMailServer
*!*	   loIp.cUsername = this.cMailUsername
*!*	   loIP.cPassword = this.cMailPassword
*!*	   loIP.cSenderName = loMessage.cFromname
*!*	   loIP.cSenderEmail = loMessage.cFromEmail
*!*	   loIP.cReplyto = "noreply@west-wind.com"    
*!*	   loIP.cRecipient = lcSendto
*!*	   loIP.cCCList = THIS.cMailingListCC
*!*	   loIP.cSubject =  loMessage.cSubject
*!*	   
*!*	   pcMsgId = loMessage.cMsgId 
*!*	   lcFooter = MergeText(THIS.cEmailFooter) 
*!*	   loIP.cMessage = lcFooter + ;
*!*	                   lcHTML + CRLF + ;
*!*	                   lcFooter
*!*	   
*!*	   loIP.cContentType = "text/html"

*!*	   loIP.SendMailAsync()
*!*	    
*!*	   loMessage.cMessage=lctMessage
*!*	ENDIF

*!*	*** Now save all the user info to the user file
*!*	IF !llEditing
*!*	  loUser.cName=loMessage.cFromname
*!*	  loUser.cEmail=loMessage.cFromEmail
*!*	  loUser.cForum=loMessage.cForum  && Need to change forum in order to display message
*!*	ENDIF

*!*	loUser.SaveUser()

*!*	*** And finally just display the message
*!*	Response.ContentTypeHeader()
*!*	Response.Write(lcHTML)

RETURN
* PostMsg

************************************************************************
*  UploadImage
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ImageUpload()

*** Make sure plUploadHandler is loaded
SET PROCEDURE TO plUploadHandler ADDITIVE 

LOCAL loUpload as plUploadHandler
loUpload = CREATEOBJECT("plUploadHandler")

*** Upload to temp folder
loUpload.cUploadPath = ADDBS(THIS.oConfig.cHtmlPagePath) + "temp"
IF(!IsDir(loUpload.cUploadPath))
    MD (loUpload.cUploadPath)
ENDIF    

BINDEVENT(loUpload,"OnUploadComplete",THIS,"OnImageUploadComplete",1)

*** Constrain the extensions allowed on the server
loUpload.cAllowedExtensions = "jpg,jpeg,png,gif"

*** Process the file or chunk
loUpload.ProcessRequest()

ENDFUNC


FUNCTION OnImageUploadComplete(lcFilename, loUpload)
************************************************************************
*  OnUploadComplete
****************************************
***  Function: The plUpload OnCompletion function that is called
***            when one of the uploaded files is complete. 
***            Resizes the image and clear out timed out files
************************************************************************
LOCAL lcUrl, lcFile

lcUrl = this.ResolveUrl("~/temp/" + lcFileName)

*** Resize the image
lcFile = ADDBS(loUpload.cUploadPath) + lcFileName

*** Delete expired files - only for 10 minutes
DeleteFiles(ADDBS(JUSTPATH(lcFile)) + "*.*",600)

lcNewFile =  SYS(2015) + "." + JUSTEXT(lcFile)
lcNewPath = this.cHtmlPagePath + "PostImages\" + TRANSFORM(YEAR(DATETIME())) + "\"
IF !ISDIR(lcNewPath)
    MD (lcNewPath)
ENDIF

lcFileName = lcNewPath + lcNewFile
*ResizeImage(lcFile,lcFileName,1024,768)
COPY FILE (lcFile) TO (lcFileName)
DELETE FILE (lcFile)

lcUrl = this.ResolveUrl("~/PostImages/" + + TRANSFORM(YEAR(DATETIME())) + "/" + lcNewFile)
lcUrl = "http://" + Request.GetServerName() + lcUrl

*** Write out the response for the client (if any)
*** In this case the URL to the uploaded image
loUpload.WriteCompletionResponse(lcUrl)

ENDFUNC
*   OnUploadComplete


************************************************************************
* wwThreads :: CreateZip
*********************************
***  Function: Zip up files from the currently open cursor/table
***    Assume: Function requires DynaZip or else pass llUsePKZIP
************************************************************************
FUNCTION CREATEZIP
LPARAMETER llUsePKZIP

*** First of all check the temp path and delete old files
DeleteFiles(THIS.cHTMLPagePath + "wwt*.zip",1800 )

lcFile="wwt"+SYS(2015)
lcTempFilePath=SYS(2023)+"\"+lcFile
COPY ALL TO (lcTempFilePath )

IF llUsePKZip
  lcRun="RUN pkZIP -ex "+THIS.cHTMLPagePath+lcFile+" "+lcTempFilePath+".*"
  &lcRun
ELSE  
  IF ZipFiles(THIS.cHTMLPagePath+lcFile,lcTempFilePath +".*",9) # 0
      RETURN ""
   ENDIF
ENDIF

ERASE (lcTempFilePath + ".*")

RETURN THIS.cHTMLPagePath + lcFile + ".Zip"
* DownloadMessages


************************************************************************
* wwThreads :: DownLoadXmlMessages
*********************************
***  Function: MessageReader Download of messages
************************************************************************
FUNCTION DownloadXmlMessages
LOCAL lcXML, lodownloadMessages, loUser, __x, lcFilter, loBanner

*** Retrieve the XML input
lcXML = Request.FormXml()

*** Check if we have an XML input
IF (lcXML != "<?xml")
   this.ErrorXmlResponse("Non XML Input provided")
   RETURN 
ENDIF

*** We'll deserialize this message object
loDownloadMessages = CREATEOBJECT("DownloadMessagesRequest")

*** By using wwXML::XmlToObject
loXML = CREATEOBJECT("wwXML")
loXML.lRecurseObjects = .t.
loXML.XmlToObject(lcXML,loDownloadMessages)

*** Check for deserialization Error
IF loXML.lError
   this.ErrorXmlResponse("Unable to parse input XML data")
   RETURN 
ENDIF

*** Update the user's status based on his UserId
*** Online this will allow us to remember what messages where dl
IF !EMPTY(loDownloadMessages.UserId)
  loUser=CREATE("ThreadUser")
  IF !loUser.GetUser(loDownloadMessages.UserId) 
     loUser.NewUser()
     loUser.cCookieId = loDownloadMessages.UserId
  ENDIF     
ENDIF 

*** Figure out the Date range for the query
IF EMPTY(loDownloadMessages.FromDate)
   loDownloadMessages.FromDate = loUser.tLastOn
   loDownloadMessages.ToDate = DATETIME()
ENDIF

*** Update the user if provided
IF VARTYPE(loUser) = "O"
   loUser.tLastOn = DATETIME()
   loUser.cVars = Request.GetIPAddress()
   loUser.lUsedReader = .T.
   loUser.SaveUser()
ENDIF

*** Create the filter from times, user and forums
lcFilter = "timestamp >= loDownloadMessages.FromDate AND timestamp <= loDownloadMessages.ToDate "

lcForums = ""
FOR __x = 1 TO loDownloadMessages.Forums.Count
    lcForums = lcForums + "Forum=PADR(loDownloadMessages.Forums[" + TRANSFORM(__x) + "],30)"
    IF __x < loDownloadMessages.Forums.Count
        lcForums = lcForums + " OR "
    ENDIF   
ENDFOR

IF !EMPTY(lcForums)
   lcFilter = lcFilter + " AND (" + lcForums + ")"
ENDIF

*** We need to add banners to messages
loBanner = CREATE("wwBanner")
loBanner.cBannerFile = "wwSiteBanners"
loBanner.cAlias = "wwSiteBanners"

*** Do a filter check first before retrieving data
IF !USED("wwthreads")
   USE (THIS.cDataPath + "wwthreads") IN 0
ENDIF
SELECT wwThreads

*** Do a filter check first before retrieving data
COUNT FOR &lcFilter to lnTemp
IF lnTemp > 1000
   this.ErrorXmlResponse("Error: File is too large to send (" + TRANSFORM(lnTemp) + " messages - limit is 1000 messages)")
   RETURN
ENDIF

*** Create a cursor with our filter   
SELECT threadid, Msgid, subject,  MESSAGE, Attachnm,;
   fromname, fromemail, TO,forum,TIMESTAMP, NoFormat ;
   FROM (THIS.cDataPath + "wwThreads") READWRITE ;
   WHERE &lcFilter ;
   INTO CURSOR TMessages

*** Fix up for banners   
IF _tally < 100
   REPLACE ALL Message with Message + CRLF + ;
               "<p><CENTER><!-- BEGIN BANNER -->" + loBanner.GetBanner(-1)+ "<!-- END BANNER --></CENTER>"
ENDIF

IF _TALLY < 1
   this.ErrorXmlResponse("No messages to download")
   use
   RETURN
ENDIF

*** Convert the cursor to XMl
lcXML = ""
CURSORTOXML(ALIAS(),"lcXML",1,0,0,"1")  && Use Windows-1252 (most efficient)

*** Make sure we got a result
IF EMPTY(lcXml)
   this.ErrorXmlResponse("Failure converting results to XML")
   use
   RETURN
ENDIF

*** Send the XML back to the client - 
*** note Content-Length to allow client to stream data
Response.ContentType = "text/xml"
Response.GZipCompression = .T.
Response.Write(lcXml)

USE

ENDFUNC
* DownLoadMsgs

************************************************************************
* DownloadMessagesRequest :: ErrorXmlResponse
****************************************
***  Function: Used to return an error message in simple XML format
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ErrorXmlResponse(lcMessage) 

Response.ContentTypeHeader("text/xml")

TEXT TO lcXML TEXTMERGE NOSHOW
<?xml version="1.0"?>
<wwthreads>
   <errormessage><<lcMessage>></errormessage>
</wwthreads>
ENDTEXT

Response.Write(lcXML)
RETURN



************************************************************************
* wwThreads :: DownLoadMsgs
*********************************
***  Function: MessageReader Download of messages
************************************************************************
FUNCTION DownLoadMessages
LOCAL lcFilter, lcToDate, lcFromDate, lcForum, lnTemp, lntime

lcFilter = THIS.oRequest.Form("Filter")
lcUseZip = THIS.oRequest.Form("UseZip")
lcUserId = THIS.oRequest.Form("Userid")

llXML = !EMPTY(THIS.oRequest.Form("ReturnXML"))

IF !EMPTY(lcUserId)
  *** Update User's Last On Status
  loUser=CREATE("ThreadUser")
  IF loUser.GetUser(lcUserId) 
     loUser.tLastOn = DATETIME()
	 loUser.cVars = Request.GetIPAddress()
     loUser.lUsedReader = .T.
     loUser.SaveUser()
  ENDIF     
ENDIF  

IF EMPTY(lcFilter)
   lcForum = THIS.oRequest.Form("Forum")
   lcFromDate = THIS.oRequest.Form("FromDate")
   lcToDate = THIS.oRequest.Form("ToDate")

   lcFilter="Forum='"+PADR(lcForum,30) +"' AND " +;
      "timestamp >= {" + lcFromDate +"} AND "+;
      "timestamp <= {" + lcToDate + "} + 1"
ENDIF

loBanner = CREATE("wwBanner")
loBanner.cBannerFile = "wwSiteBanners"
loBanner.cAlias = "wwSiteBanners"

*** Do a filter check first before retrieving data
IF !USED("wwthreads")
   USE (THIS.cDataPath + "wwthreads") IN 0
ENDIF
SELECT wwThreads

*** Do a filter check first before retrieving data
COUNT FOR &lcFilter to lnTemp
IF lnTemp > 3000
   Response.Write("Error: File is too large to send (" + TRANSFORM(lnTemp) + " messages - limit is 3000 messages)")
   RETURN
ENDIF
   
lcFile = SYS(2023) + "\" + SYS(2015)
lnTime = SECONDS()
SELECT threadid, Msgid, subject, ;
       MESSAGE,;
      Attachnm,;
   fromname, fromemail, TO,forum,TIMESTAMP, NoFormat ;
   FROM (THIS.cDataPath + "wwThreads") ;
   WHERE &lcFilter ;
   INTO DBF (lcFile)

*** Fix up for banners   
IF _tally < 200
	REPLACE ALL Message with Message + CRLF + ;
	            "<p><CENTER><!-- BEGIN BANNER -->" + loBanner.GetBanner(-1)+ "<!-- END BANNER --></CENTER>"
ENDIF

IF _TALLY < 1
   Response.ContentTypeHeader()
   Response.Write("ERROR - No Records")
   USE
   ERASE (lcFile + ".*")
   RETURN
ENDIF

IF llXML
   loXML = CREATE("wwXML")
   loXML.cDocRootName = "wwthreads"
   lcFileText = loXML.CursorToXML("messages","message")
ELSE
    USE

	IF !EMPTY(lcUseZip)
	   IF ZipFiles(lcFile+".zip",;
	                    lcFile+".*",9) # 0
	      THIS.oResponse.Write("Error: Unable to zip the file on the server.")
	      RETURN
	   ENDIF
	   lcFileText = EncodeDBF(lcFile+".zip")
	ELSE
	   lcFileText= EncodeDBF(lcFile+".dbf",.T.)
	ENDIF
ENDIF

IF EMPTY(lcFileText)
   Response.Write("Error: File not encoded on server.")
   ERASE (lcFile + ".*")
   RETURN
ENDIF

*** Send the data back into the HTTP stream
IF !llXml
	Response.ContentType = "application/x-zip-compressed"
ELSE
	Response.ContentType = "text/xml"
ENDIF

Response.Write(lcFileText)

*** Clean up the work files files
TRY
	ERASE (lcFile + ".*")
CATCH
ENDTRY
ENDFUNC
* DownLoadMsgs

************************************************************************
* wwThreads :: DownloadAttachment
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION DownloadAttachment

lcMsgId = Request.QueryString("MsgId")

loMsg = CREATEOBJECT("ThreadMessage")
IF !loMsg.LoadMessage(lcMsgId)
   THIS.ErrorMsg("Message not found","This message is currently unavailable")
   RETURN
ENDIF   

lcExt = JUSTEXT(wwThreads.Attachnm)

Response.AppendHeader("Content-length",TRANSFORM(LEN(wwThreads.Attachmt)) )
Response.AppendHeader("Content-type",ContentTypeFromExtension(lcExt))
Response.AppendHeader("Content-disposition","attachment; filename="+TRIM(wwThreads.Attachnm))
   
Response.Write(wwThreads.Attachmt)

ENDFUNC
* wwThreads :: DownloadAttachment

************************************************************************
* wwThreads :: UploadMessages
*********************************
***  Function: Message Reader Upload OPeration
************************************************************************
FUNCTION UploadMessages
LOCAL lcSendto, loMessage, loIP, lcFileText, lcFile

CLOSE TABLES

lcFile=SYS(2015)

Request.lFilterUnsafeCommands = .F.
lcFileText=THIS.oRequest.Form("FileText")
llUseZip = !EMPTY(THIS.oRequest.Form("UseZip"))

IF !IsDir("TEMP")
  MD TEMP
ENDIF

IF llUseZip
   lcFile =  JustStem(TRIM(SUBSTR(lcFileText,6,40)))
   IF !DecodeDBF(lcFileText,"TEMP\"+lcFile+".zip")
	   Response.Write("Error: File unpacking error (Zip)")
	   ERASE ("TEMP"+lcFile+".*")
	   RETURN
	ENDIF
	IF UnzipFiles(SYS(5)+CURDIR()+"TEMP\"+lcFile+".zip",SYS(5)+CURDIR()+"TEMP\") # 0
	   Response.Write("Error: File unpacking error 2 (Zip)")
	   ERASE ("TEMP\"+lcFile+".*")
	   RETURN
	ENDIF
ELSE
	IF !DecodeDbf(lcFileText,"TEMP\"+lcFile+".dbf")
	   THIS.oResponse.Write("Error: File unpacking error (Dbf)")
	   ERASE ("TEMP\"+lcFile+".*")
	   RETURN
	ENDIF
ENDIF

IF !USED("wwt_forums")
   USE (THIS.cDatapath+"wwt_forums") in 0
ENDIF
IF !USED("wwThreads")
   USE (THIS.cDataPath+"wwThreads") IN 0
ENDIF

SELE wwThreads

USE ("TEMP\"+lcFile) ALIAS IMPORT
llNewFile = TYPE("IMPORT.Attachmt") # "U"
SCAN
   loMessage=CREATEOBJECT("ThreadMessage")
   loMessage.cDataPath = THIS.cDataPath
   loMessage.cHTMLPagePath = THIS.cHTMLPagePath
   loMessage.lNewMessage=.T.
   loMessage.cUserId = IMPORT.USERID
   loMessage.cThreadId = IMPORT.threadid
   loMessage.cSubject = TRIM(IMPORT.subject)
   loMessage.cMessage = IMPORT.MESSAGE
   loMessage.cFromname = IMPORT.fromname
   loMessage.cFromEmail = IMPORT.fromemail
   loMessage.cTo = TRIM(IMPORT.TO)
   loMessage.cForum = IMPORT.forum
   loMessage.lNoFormat = Import.NoFormat
   loMessage.tTimeStamp = DATETIME()
   IF llNewFile
     loMessage.cAttachmt = IMPORT.Attachmt
     loMessage.cAttachnm = IMPORT.Attachnm
   ENDIF

   loMessage.SaveMessage()

   *** Private Forums can't post to mailing list
   SELECT NoDownload FROM WWT_FORUMS ;
          WHERE ForumName = loMessage.cForum AND NoDownload ;
          INTO ARRAY laTemp
   IF _TALLY > 0 
      *** Forum is private so don't CC List but still send
      *** to actual recipient
      THIS.cMailingListCC = ""
   ENDIF

   IF IMPORT.Email OR !EMPTY(THIS.cMailingListCC)
      IF Import.Email  
         lcSendto=""   && SUBSTR(loMessage.cTo,RAT(" ",loMessage.cTo)+1)
         SplitNames(loMessage.cTo,"",@lcSendto)
      ELSE
         lcSendTo="All"
      ENDIF

      IF lcSendto == "All" OR EMPTY(lcSendTo)
         lcSendto = THIS.cMailingListCC
         THIS.cMailingListCC = ""
      ENDIF

      * loMessage.StripSignature()

	   loIP = CREATEOBJECT([WWC_WWSMTP])
	   loIP.nMailMode = 2 && Classic
	    
	   loIP.cMailServer = THIS.cMailServer
       loIp.cUsername = this.cMailUsername
       loIP.cPassword = this.cMailPassword
       
	   loIP.cSenderName = loMessage.cFromname
	   loIP.cSenderEmail = loMessage.cFromEmail
	   loIp.cReplyTo = "noreply@west-wind.com"
	   loIP.cRecipient = lcSendto
	   loIP.cCCList = THIS.cMailingListCC
	   loIP.cSubject =  loMessage.cSubject
	   loIP.cContentType = "text/html"

       pcMsgId = loMessage.cMsgId
       lcFooter =  MergeText(THIS.cEmailFooter)
	   loIP.cMessage = STRTRAN(loMessage.RenderMessage(),"<body>","<body>" + lcFooter)
	   loIP.cMessage = STRTRAN(loIP.cMessage,"</body>",lcFooter + "</body>")

         
     loIP.SendMailAsync()
   ENDIF
   
ENDSCAN

USE IN IMPORT
USE IN wwThreads

*ERASE (lcFile+".*")
ERASE ("TEMP\"+lcFile+".*")

THIS.oResponse.Write("OK")
RETURN
ENDFUNC
* UploadMessages


************************************************************************
* ThreadProcess :: DownloadForums
*********************************
***  Function: Downloads the forum list.
************************************************************************
FUNCTION DownloadForums

llXML = IIF(UPPER(Request.QueryString("Display"))="XML",.T.,.F.)

IF llXML
	SELECT forumid,forumname, nodownload ;
      FROM wwt_Forums where !NoDownload ;
	   INTO CURSOR TQuery

    loXML = CREATE("wwXML")
    loXML.cDocRootName = "forumlist"
    lcXML = loXML.CursorToXML("forums","forum")
    lcXML = STRTRAN(lcXML,[<forums>],[<forums timezone="]+TRANS(GetTimeZoneHours())+[">])
    Response.ContentTypeHeader("text/xml")
    Response.Write(lcXML)
ELSE
	lcFile = SYS(2015)
	SELECT * FROM wwt_Forums where !NoDownload ;
	   INTO TABLE (lcFile)
	USE
	lcFileText = EncodeDBF(lcFile+".dbf")

	IF EMPTY(lcFileText)
	   THIS.oResponse.Write("ERROR - File not encoded.")
	   ERASE (lcFile + ".*")
	   RETURN
	ENDIF
	THIS.oResponse.Write(lcFileText)

	ERASE (lcFile + ".*")
ENDIF

ENDFUNC
* GetForumFile

************************************************************************
* ThreadProcess :: Welcome
*********************************
***  Function: Simply displays the 'Help'/'Welcome' page.
************************************************************************
FUNCTION Welcome
PRIVATE pcUserId
pcUserId=THIS.oRequest.GetCookie("WWTHREADID")
THIS.oResponse.ExpandTemplate(THIS.cHTMLPAGEPATH + "Welcome.wwt")
ENDFUNC
* ThreadProcess :: Welcome


************************************************************************
* ThreadProcess ::  Profile
****************************************
***  Function: Displays a user profile
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Profile()

Response.ExpandPage( this.cHtmlPagePath + "Profile.wcsx")


ENDFUNC
*  ThreadProcess ::  Profile


************************************************************************
* ThreadProcess :: SetUserId
*********************************
***  Function: Sets the User's Cookie to a specific UserID.
***            Email address confirmation required.
************************************************************************
FUNCTION SetUserId

lcid = UPPER(PADR(Request.Form("txtUserId"),8))
lcEmail = Request.Form("txtEmail")

IF EMPTY(lcEmail)
   lcEmail = "xx"
ENDIF

SELECT CookieId ;
  FROM (THIS.cDataPath + "wwUsers") ;
  WHERE CookieId = lcId and UPPER(TRIM(Email)) = UPPER(lcEmail) ;
  INTO ARRAY laTemp

IF _TALLY = 1
  Response.AddCookie("WWTHREADID",laTemp[1],"/","NEVER")
  pcUserId = laTemp[1]
ELSE
  THIS.ErrorMsg("Invalid Account Info","Your user id and email address don't match")
  RETURN   
ENDIF
   
Response.ExpandTemplate(THIS.cHTMLPAGEPATH + "Welcome.wwt")
ENDFUNC
* ThreadProcess :: SetUserId

************************************************************************
* ThreadProcess :: GetUserId
*********************************
***  Function: Retrieves and displays the online UserID
************************************************************************
FUNCTION GetUserId
LOCAL loHeader, loUser, lcCookie

lcCookie=THIS.oRequest.GetCookie("WWTHREADID")
IF !EMPTY(lcCookie)
   THIS.ErrorMsg("Message Board User Id","Your user Id is: <b>"+lcCookie+"</b><p>"+;
      "Please enter this value into the configuration user Id for the reader.")
   RETURN
ENDIF

loUser = CREATEOBJECT("ThreadUser")
loUser.cDataPath = THIS.cDataPath

*** Nope - let's create a cookie/userId and save
lcId=loUser.SaveNewUser()

loUser.cForum=THIS.cDefaultForum

*** Create HTTP header to add Cookies
*** NOTE: An existing header might be passed as a parameter
***       mainly from PostMsg which contains a COOKIE for WWTHREADID
Response.AddCookie("WWTHREADID",lcId,"/","NEVER")

THIS.StandardPage("Message Board User Id",;
   "Your <i>new</i> User Id is: <b>" + lcId + "</b><p>"+;
   "This Id was created for you since you have not visited the message board with "+;
   "this browser before. If this is not your primary browser and you want to synch "+;
   "the message reader with the browser access the link above with the appropriate browser "+;
   "and use the Id returned from it.<p>" +;
   "Please enter this value into the configuration user Id for the reader.")
ENDFUNC
* GetUserId


*!*	************************************************************************
*!*	* ThreadProcess :: UserSettings
*!*	*********************************
*!*	***  Function: Sets user settings. Uses wwHTMLForm to render wwUser.scx
*!*	************************************************************************
*!*	FUNCTION UserSettings
*!*	LOCAL 	 oForm, lcId

*!*	*!*   IF !Request.IsIE4()
*!*	*!*      THIS.IERequired()
*!*	*!*      RETURN
*!*	*!*   ENDIF

*!*	DIMENSION laFormVars[1]
*!*	lnFormVars = Request.aFormVars(@laFormVars)

*!*	lcAction = UPPER(Request.Form("btnSubmit"))
*!*	llAdmin = IIF(!EMPTY(Request.QueryString("Admin")),.T.,.F.)
*!*	IF llAdmin
*!*	   lcId = Request.QueryString("Id")

*!*	   *** Coming in through Admin Interface - check validation
*!*	   IF !THIS.IsThreadAdmin()
*!*		  RETURN
*!*	   ENDIF
*!*	ELSE   
*!*	   *** Coming in through message board - just check the Cookie when 
*!*	   *** the form loads
*!*	   lcId = Request.GetCookie("WWTHREADID")
*!*	ENDIF   
*!*	lcFormAction = "UserSettings.wwt?Id=" + lcId +  IIF(llAdmin,"&Admin=True","")

*!*	IF lcAction = "CANCEL"
*!*	   IF llAdmin
*!*	      THIS.oResponse.Redirect("ShowUsers.wwt")
*!*	   ELSE
*!*	      THIS.ShowMsg(" ")
*!*	   ENDIF
*!*	   RETURN
*!*	ENDIF
*!*	   
*!*	IF EMPTY(lcId)
*!*	   THIS.ErrorMsg("No User ID","You don't have a user id. Please re-enter the Message board and make sure you accept the Cookie that identifies you")
*!*	   RETURN
*!*	ENDIF

*!*	SET PROCEDURE TO wwForm additive
*!*	SET PROCEDURE TO wwCtls Additive   

*!*	DO FORM wwUser NAME oForm LINKED WITH lcId NOSHOW

*!*	IF TYPE("oForm") # "O"
*!*	   THIS.ErrorMsg("Invalid User Id","Please re-enter the Message Board and try again")
*!*	   RETURN
*!*	ENDIF

*!*	*** Enable UserId
*!*	if llAdmin  
*!*	   oForm.txtCookieId.enabled = .T.
*!*	   oForm.SetAdminMode(.T.)
*!*	endif

*!*	*** Create the rendering object
*!*	oHTMLForm=CREATEOBJECT("wwDHTMLForm",oForm,Response)
*!*	oHTMLForm.lUseConstantButtonName = .T.

*!*	IF lcAction = "SAVE"
*!*	     *** First let's make sure these values are *NOT* updated by setting them to 'Null'
*!*	     *** Now update the rest
*!*	     oHTMLForm.SetValues(Request)
*!*	     oForm.oDataEnv.Save()
*!*	ENDIF

*!*	Response.HTMLHeader()
*!*	Response.WriteLn(" <br> <br><CENTER>")

*!*	oHTMLForm.lShowAsFullHTML=.F.
*!*	oHTMLForm.lShowFormCaption=.T.
*!*	oHTMLForm.lAbsolutePosition=.F.
*!*	oHTMLForm.cFormAction=lcFormAction


*!*	oHTMLForm.ShowContainer()   

*!*	Response.WriteLn("</CENTER>")
*!*	Response.HTMLFooter()

*!*	RETURN

*!*	ENDFUNC
*!*	* ThreadProcess :: UserSettings 


************************************************************************
* ThreadProcess :: ShowUsers
*********************************
***  Function: Shows a list of all users with Edit/Delete options
************************************************************************
FUNCTION ShowUsers

IF !THIS.IsThreadAdmin()
   RETURN
ENDIF

llShowAll =  !EMPTY(Request.Form("chkShowAll"))
IF llShowAll
   lcWhere = [WHERE LastOn > date() - 5]
ELSE   
   lcWhere = [WHERE NAME # "  "]
ENDIF

SELECT CookieID as UserId,;
        Name, Email, LastOn, UsedReader as Reader, Vars as IP, ;
        [<A HREF="]+THIS.cScriptPath+[?wwThreads~UserSettings~]+CookieId+[~Admin">Edit</a> | ]+;
        [<A HREF="]+THIS.cScriptPath+[?wwThreads~KillUser~]+CookieId+[">Delete</a>] as Action ;
  FROM (THIS.cDataPath + "wwUsers") ;
  &lcWhere ;
  ORDER BY LastOn DESC ;
  INTO CURSOR TQUery

Response.HTMLHeader("Message Board User List")
Response.WriteLn([<FORM METHOD=POST Action="]+Request.GetCurrenturl() + [">])
Response.Write([<input type="checkbox" id="chkShowAll" name="chkShowAll" onclick="this.form.submit();return true;" ] + IIF(llShowAll," CHECKED ","") + [ /> All entries for the last five days])
*Response.FormCheckBox("chkShowAll",llShowAll,"All entries for last five days",[onclick="this.form.submit();return true;"])
Response.Write("<br>")
*Response.FormButton("btnSubmit","Update List","SUBMIT")
Response.WriteLn("</FORM>")

loSC = CREATEOBJECT("wwShowCursor")
loSc.lAlternateRows = .T.
loSC.cExtraTableTags = [ STYLE="font:normal normal 8pt Verdana" ]
loSC.ShowCursor()

Response.Write( loSC.GetOutput() )


Response.HTMLFooter("<HR>"+  HRef(THIS.cAdminPage,"[Back to Admin Page]")) 
  
ENDFUNC
* ThreadProcess :: ShowUsers

************************************************************************
* ThreadProcess :: KillUser
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION KillUser

IF !THIS.IsThreadAdmin()
   RETURN
ENDIF   

lcId = THIS.oRequest.QueryString(3)

IF !USED("wwUsers")			
   USE (THIS.cDATAPATH+"wwUsers") IN 0
ENDIF

SELE wwUsers
LOCATE FOR COOKIEID = PADR(lcId,8)
IF !FOUND()
   THIS.ErrorMsg("User Not Found","User might already be deleted...")
   RETURN
ENDIF   

DELETE
USE

THIS.ShowUsers()

ENDFUNC
* ThreadProcess :: KillUser 


************************************************************************
* ThreadProcess ::
*********************************
***  Function: Logs in a user so that messages can be deleted or
***            edited.
************************************************************************
FUNCTION ADMINLOGIN
LOCAL lcUserName

lcUserName=Request.GetAuthenticatedUser() 

IF EMPTY(lcUserName)   && Any validations against password here...
   *** Send Password Dialog
   THIS.oResponse.Authenticate(Request.GetServername())
   RETURN
ENDIF

THIS.ErrorMsg("You are now Authenticated",;
   "You're now logged in as <b>"+lcUserName+" </b> and you can access links on the Admin page...<p>"+;
   THIS.oResponse.HREF(THIS.cThreadHomePath + THIS.cAdminPage,"Admin Page",.T.) )
ENDFUNC
* ADMINLOGIN

************************************************************************
* wwThreadProcess :: CatManager
*********************************
***  Function: Shows all banners in a table with options to add
***            or delete entries.
************************************************************************
FUNCTION CatManager
LPARAMETERS lcPageFooter
LOCAL llNoDownload

IF !THIS.IsThreadAdmin()
   RETURN
ENDIF   

lcForum=""
llNoDownload=.F.
lcMessages=""
lcAction ="Add"

IF UPPER(Request.QueryString(3))="ADD"  AND ;
      !EMPTY(Request.Form("Category"))
   lnMsgs=VAL(Request.Form("250"))
   IF EMPTY(lnMsgs)
      lnMsgs=250
   ENDIF
   INSERT INTO (THIS.cDataPath + "wwt_forums") ;
      (ForumId,ForumName,maxmsgs) VALUES (SUBSTR(SYS(2015),3),Request.Form("Category"),lnMsgs)
ENDIF
IF UPPER(Request.QueryString(3))="EDIT"
   lcCategory=Request.QueryString(4)
   IF !USED("wwt_forums")			
      USE (THIS.cDATAPATH+"wwt_forums") IN 0
   ENDIF
   
   SELE wwt_forums
   
   LOCATE FOR ForumID = lcCateGory
   IF !FOUND()
      lcForum = ""
      lcMessages = ""
   ELSE
      lcForum = ForumName
      lcMessages = LTRIM(STR(MaxMsgs))
      llNoDownload = NoDownload
      lcAction = "Save~"+ForumId
   ENDIF
ENDIF
IF UPPER(Request.QueryString(3)) = "SAVE"
   IF !USED("wwt_forums")			
      USE (THIS.cDATAPATH+"wwt_forums") IN 0
   ENDIF

   SELE wwt_forums
   lcCategory=Request.QueryString(4)
   LOCATE FOR ForumId = lcCategory
   IF !FOUND() OR EMPTY(Forumname)
      lcForum = ""
      lcMessages = ""
   ELSE
      lcOldForum = TRIM(ForumName)
      lcNewForum = Request.Form("Category")
      llNoDownload = !EMPTY(Request.Form("NoDownload"))
      IF !USED("wwThreads")			
         USE (THIS.cDATAPATH+"wwThreads") IN 0
      ENDIF
      SELE wwThreads
      REPLACE Forum with lcNewForum for Forum = lcOldForum
     
      SELE wwt_forums
      REPLACE ForumName with lcNewForum,;
              MaxMsgs with VAL(Request.Form("MaxMsgs") ),;
              NoDownload with llNoDownload
       
      llNoDownload = .F.        
   ENDIF
ENDIF
IF UPPER(Request.QueryString(3))="DELETE"
   IF !USED("wwt_forums")			
      USE (THIS.cDATAPATH+"wwt_forums") IN 0
   ENDIF
   SELE wwt_forums
   lcCategory=Request.QueryString(4)
   LOCATE FOR ForumId = lcCategory
   IF FOUND()
      lcCategory = TRIM(ForumName)
      DELETE FROM (THIS.cDataPath + "wwThreads") WHERE FORUM = lcCategory
      DELETE FROM (THIS.cDataPath + "wwt_Forums") WHERE ForumName=lcCategory
   ENDIF
ENDIF

Response.HTMLHeader("Message Board Forum Management")

Response.WriteLn([<FORM METHOD="POST" ACTION="] + THIS.cScriptPath +[?wwThreads~CatManager~]+lcAction+[">])
Response.WriteLn([<PRE>])
Response.WriteLn([<b>       Forum:</b> <INPUT TYPE="TEXT" NAME="Category" SIZE=50 VALUE="]+lcForum+[">])
Response.WriteLn([<b>Max Messages:</b> <INPUT TYPE="TEXT" NAME="MaxMsgs" VALUE="]+lcMessages+[" SIZE=5>   <INPUT NAME="NoDownload" TYPE="CHECKBOX" ]+IIF(llNoDownload,"CHECKED ","")+[>Private Forum (not listed)<br>] )
Response.WriteLn([<INPUT TYPE="Submit" NAME="btnSubmit" VALUE="Add Forum">])
Response.WriteLn([</PRE><FORM>])

Response.Write("<p>" + CRLF)

SELECT ForumName, maxmsgs,NoDownload as Private, ;
   IIF(ForumName # "All Forums",[<A HREF="] + THIS.cScriptPath +[?wwThreads~CatManager~Delete~]+;
   ForumId+[">Remove</a> | <A HREF="] + THIS.cScriptPath +[?wwThreads~CatManager~Edit~]+;
   ForumId+[">Edit</a>],"") AS Action ;
   FROM (THIS.cDataPath + "wwt_Forums") ;
   ORDER BY 1 ;
   INTO CURSOR Tquery

LOCAL loSC as wwShowCursor
loSC = CREATEOBJECT("wwShowCursor")
loSc.ShowCursor()
Response.Write(loSc.GetOutput())

Response.HTMLFooter( "<HR>" + HRef(THIS.cAdminPage,"[Back to Admin page]") )

USE IN Tquery
USE IN wwt_Forums

ENDFUNC
* HTMLShow


************************************************************************
* ThreadProcess :: Reindex
*********************************
FUNCTION Reindex
LOCAL lnMaxMsgs, lnMsgCount, lcForumName, lnZapCount

IF !THIS.IsThreadAdmin()
  RETURN
ENDIF

CLOSE DATA
IF !OPENEXCLUSIVE(THIS.cDataPath+"wwthreads") OR !OPENEXCLUSIVE(THIS.cDataPath + "wwt_forums")
   THIS.ErrorMsg("Unable to open Thread Table",;
      "The file is in use by other users or sessions...")
   RETURN
ENDIF

SELE wwThreads
DELETE TAG ALL
INDEX ON forum + DTOS(TIMESTAMP) TAG ForumPack

*** Pack forums to size
SELE wwt_Forums
SCAN
   lcForumName=wwt_Forums.ForumName
   lnMaxMsgs=wwt_Forums.maxmsgs
   SELE wwThreads
   COUNT FOR wwThreads.forum =  lcForumName TO lnMsgCount
   IF lnMsgCount > lnMaxMsgs
      LOCATE FOR wwThreads.forum = lcForumName
      lnZapCount = lnMsgCount - lnMaxMsgs + 20
      DELETE  NEXT (lnZapCount)
   ENDIF
ENDSCAN

SELE wwThreads
DELETE TAG ALL
PACK

INDEX ON Msgid TAG Msgid
INDEX ON threadid TAG threadid
INDEX ON forum TAG forum
INDEX ON USERID TAG USERID
INDEX ON TIMESTAMP TAG TIMESTAMP
*INDEX ON DELETED() TAG DELETED
USE

*** Delete 'Empty' Users and users who've been gone for a 3 months
IF !OPENEXCLUSIVE(THIS.cDataPath+"wwusers")
   THIS.ErrorMsg("Unable to open Users Table",;
      "The file is in use by other users or sessions...")
   RETURN
ENDIF

SELE wwUsers
DELETE TAG ALL
DELETE FOR NAME="   " OR laston < date() - 100
PACK
INDEX ON COOKIEID TAG COOKIEID
INDEX on Email TAG Email
INDEX on Password TAG Password
*INDEX ON DELETED() TAG DELETED

CLOSE DATA

THIS.ErrorMsg("Reindexing Complete!",;
   "The thread file has been packed and reindexed...<p><HR>" + ;
   HREF(THIS.cAdminPage,"[Back to Admin page]") )

ENDFUNC
* Reindex

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

lcSourcePath = LOWER(FULLPATH(ADDBS(this.cHtmlPagePath))) + "PostImages\"
llError = .F.

CREATE CURSOR TDirs( Path c(128) )

GetDirs(ADDBS(lcSourcePath),lcSourcePath)
INDEX ON Path DESCENDING TAG PATH

lnDeleted = 0

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
   "Removed " + TRANSFORM(lnDeleted) + " unreferenced images from PostImages folder. <hr/>" + ;
   HREF(THIS.cAdminPage,"[Back to Admin page]") )

ENDFUNC
*   CleanupUnreferencedImages

************************************************************************
* wwThreads :: Backup
****************************************
***  Function:
***    Assume:
************************************************************************
FUNCTION  Backup()
LOCAL lcPath

#IF .F. 
LOCAL Request as wwRequest, Response as wwResponse
#ENDIF

IF !THIS.IsThreadAdmin()
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

COPY TO (lcPath + "wwThreads") FOR timestamp > DATE() - 1000

IF !USED("wwUsers")
   USE wwUsers 
ENDIF

SELECT wwUsers

COPY TO (lcPath + "wwUsers") FOR Name # "  "

lcZipFileName = lcPath +  "wwThreads_"+DTOS(DATE()) + ".zip"

IF ZipFiles(lcZipFileName,lcPath + "*.*") # 0
   THIS.StandardPage("Problem Zipping files",loIP.cErrormsg)
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
* ThreadProcess :: TranslateMessage
****************************************
***  Function: Translates the current message into the selected language
***      Pass: lcMsgId -  ID of the message to translate
***            lcTranslate - The language to translate to/from
************************************************************************
FUNCTION TranslateMessage
LOCAL lcMsgId, lcTranslate

lcMsgId = Request.QueryString("MsgId")
lcTranslate = Request.QueryString("Translate")

loMsg = CREATEOBJECT("ThreadMessage")
loMsg.cDataPath = THIS.cDataPath
loMsg.cHTMLPagePath = THIS.cHTMLPagePath

IF !loMsg.LoadMessage(lcMsgId)
   THIS.errormsg("Invalid Message Id","This message could not be translated")
   RETURN
ENDIF

IF !loMsg.Translate(lcTranslate)
   THIS.ErrorMsg("Unable to translate message",;
                 "The Babel Fish Translation service is not responding at the moment. This may mean you're not online or the service is too slow at the moment. <p>" +;
                 [For more info go to the <a href="http://babel.altavista.com/translate.dyn">Babel Fish Web Site</a>.])
   RETURN
ENDIF

pcCharSet = "UTF-8"
Response.Write(loMsg.RenderMessage(,.T.))

ENDFUNC
*  ThreadProcess :: TranslatePage

************************************************************************
* ThreadProcess :: IsThreadAdmin
*********************************
***  Function: Checks whether a user is part of the ThreadAdmin
***            group via Basic Authentication. 
***    Assume: This Method sends an error message to HTML output!!!
***      Pass: lcErrorMsg  (Optional)
************************************************************************
FUNCTION IsThreadAdmin
LPARAMETER lcErrorMsg

lcErrorMsg=IIF(!EMPTY(lcErrorMsg),lcErrorMsg,;
               "You must be logged in to access this page.")

*!*	IF  ("ALL" + CHR(13) ) $ THIS.cAdminUsers 
*!*	   RETURN .T.
*!*	ENDIF

lcUserName=Request.GetAuthenticatedUser()

IF EMPTY(lcUserName)   
   THIS.Authenticate(this.cAdminUsers)
   RETURN .F.
ENDIF

IF UPPER(THIS.cAdminUsers) = "ANY"
   RETURN .T.
ENDIF   

IF NOT (lcUserName + CHR(13)) $ THIS.cAdminUsers 
   THIS.ErrorMsg("Access Denied",lcErrorMsg)
   RETURN .F.
ENDIF   

RETURN .T.
ENDFUNC
* ThreadProcess :: IsThreadAdmin



************************************************************************
* ThreadProcess :: IERequired
*********************************
***  Function: Sends IE Required Error Message to output
************************************************************************
FUNCTION IERequired

   THIS.ErrorMsg("Internet Explorer 4.0 required",;
                 "This request uses Internet Explorer 4.0's Dynamic HTML features to allow "+ ;
                 "rendering VFP forms to look very much like Visual FoxPro forms including "+;
                 "font, color, size, enabled and visibility settings."+;
                 [You can download <a HREF="http://www.microsoft.com/ie">Internet Explorer 4.0</a> from the MS website<p>]+;
                 [<CENTER><a HREF="http://www.microsoft.com/ie/"><IMG SRC="/images/ielogo.gif" BORDER=0></a></CENTER>])
   RETURN


ENDFUNC
* ThreadProcess :: IERequired


#IF .F. 

*** NOT USED AT THIS TIME - template override
FUNCTION ErrorMsg
************************************************************************
***  Function: Overridden ErrorMsg method that provides a customized
***            error message and simple HTML page display.
***
***            Use icons etc. here to allow people to go back to
***            common places in your application.
***      Pass: lcMessage  -  Error Message to display (detail)
***            THIS.oRequest      -  Current CGI object
***            Response     -  Existing HTML object
*************************************************************************
LPARAMETER lcMessage, lcMessage2, lvHeader
PRIVATE pcMessage, pcMessage2

lcMessage=IIF(!EMPTY(lcMessage),lcMessage,;
   "The server was unable to respond to the CGI request.")
lcMessage2=IIF(!EMPTY(lcMessage2),lcMessage2,;
   "The server was unable to create the requested document.<BR>"+CHR(13)+;
   "This message was generated by Visual FoxPro...")

*** Reset the HTML output
Response.Rewind()

pcMessage=lcMessage
pcMessage2=lcMessage2

Response.ExpandTemplate(THIS.cHTMLPagePath+"error.wwt",lvHeader)

Response.NoOutput(.T.)

RETURN
ENDFUNC
* EOP ErrorMsg
#ENDIF


ENDDEFINE


**** Support Functions

************************************************************************
PROCEDURE BreakLines
********************
***  Function:
***    Assume:
***      Pass:
***    Return:
*************************************************************************
LPARAMETER lcText,lnWidth
lnWidth=IIF(TYPE("lnWidth")="N",lnWidth,78)

*** Convert all double CRs into ~~
lcText=STRTRAN(lcText,CHR(13)+CHR(10)+CHR(13)+CHR(10),"~~")
lcText=STRTRAN(lcText,CHR(13)+CHR(13),"~~")

*** Strip all single CRs
lcText=STRTRAN(lcText,CHR(13)+CHR(10)," ")
lcText=STRTRAN(lcText,CHR(13)," ")


SET MEMOWIDTH TO lnWidth
lcOutput=""
FOR x=1 TO MEMLINES(lcText)
   lcOutput=lcOutput+MLINE(lcText,x)+CHR(13)
ENDFOR && x=1 to MEMLINES(lcFileName)

lcOutput=STRTRAN(lcOutput,"~~",CHR(13)+CHR(13))
RETURN lcOutput


************************************************************************
*  LoadPages
****************************************
***  Function: Dummy routine to pull in WCF pages into the project
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadPages
SET PROCEDURE TO Chat_page ADDITIVE
SET PROCEDURE TO UserConfiguration_Page ADDITIVE
SET PROCEDURE TO Login_Page ADDITIVE
SET PROCEDURE TO Profile_Page ADDITIVE
SET PROCEDURE TO WriteMessage_Page ADDITIVE
ENDFUN