#INCLUDE WCONNECT.H


*************************************************************
DEFINE CLASS ThreadMessage AS RELATION
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 06/20/96
***  Function: 
*************************************************************

*** Google flags
lUseGoggleAds = .T. &&!WWC_DEMO    && In demo mode don't show ads
cGoogleAdId = "pub-2013123155768157"

lUseCustomAds = .F.

*** Custom Properties

cUserid=""
cTo=""
cToName=""
cToEmail=""
cFromName=""
cFromEmail=""
cThreadId=""
cMsgId=""
cParentId=""
cAuthor=""
cSubject=""
cMessage=""
tTimeStamp={}
cForum=""
cAttachmt = ""
cAttachnm = ""
lPinned = .F.

lRead = .f.
lSave = .f.

lNoFormat=.F.

lNewMessage=.F.
*lReplyMessage = .F.
nMaxMessages=150

cQuoteChars=" | "

cLTag = "<<"
cRTag = ">>"

cDataPath = ""
cHTMLPagePath = ""

*** Stock Properties

************************************************************************
* ThreadMessage :: Init
********************************
***  Function: Create a new empty message and create a new Id
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Init
LPARAMETERS lcThreadId

lcThreadid=IIF(type("lcThreadid")="C",lcThreadid,"")

THIS.cUserId=""
THIS.cTo=""

THIS.cToName=""      && Set only by calling Split
THIS.cToEmail=""

THIS.cFromName=""
THIS.cFromEmail=""

THIS.cThreadId=lcThreadId
THIS.cMsgId=""
THIS.cSubject=""
THIS.cMessage=""
THIS.cAttachmt=""
THIs.cAttachnm=""
THIS.tTimeStamp={}
THIS.cForum=""
this.lPinned = .F.

ENDFUNC
* Init

************************************************************************
* ThreadMessage :: Reply
*********************************
***  Function: Updates object from an existing message and
***            adds From and Message text as parameters
***      Pass: loOldMessage  -  Message object of message to reply to
***            lcFrom        -  Sender's name
***            lcNewText     -  Reply Message TExt
***    Return: nothing
************************************************************************
FUNCTION Reply
LPARAMETERS loOldMessage, lcFromName, lcFromEmail, lcNewText

lcFromName=IIF(type("lcFromName")="C",lcFromName,"")
lcFromEmail=IIF(type("lcFromEmail")="C",lcFromEmail,"")
lcNewText=IIF(type("lcNewText")="C",lcNewText,CRLF + CRLF + CRLF +loOldMessage.GetQuotedText())


llFullAddress = IIF(!EMPTY(loOldMessage.cFromEmail) AND !EMPTY(loOldMessage.cFromName),.t.,.f.)
THIS.cTo=TRIM(loOldMessage.cFromName) + IIF(llFullAddress,"  [","") +;
         TRIM(loOldMessage.cFromEmail)+ IIF(llFullAddress,"]","")
         
THIS.cFromName=lcFromName
THIS.cFromEmail=lcFromEmail
THIS.cThreadId=loOldMessage.cThreadId
THIS.cParentId=loOldMessage.cMsgid
THIS.cMsgId=""           && THIS.NewId() - this shouldn't happen until we save
THIS.cSubject=IIF(UPPER(LEFT(loOldMessage.cSubject,2))="RE","","Re: ")+loOldMessage.cSubject
THIS.cMessage=lcNewText
THIS.cForum=loOldMessage.cForum
* THIS.lNoFormat = loOldMessage.lNoFormat

ENDFUNC
* Reply

************************************************************************
* ThreadMessage :: GetQuotedText
*********************************
***  Function: Returns Quoted text from the current message text
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetQuotedText
LPARAMETERS lcText
LOCAL lcQuoted, lcTemp, lcOpen, lcClose

*** By default assign current message
lcText=IIF(!EMPTY(lcText),lcText,THIS.cMessage)

IF THIS.lNoFormat
   RETURN lcText 
   ***CHR(13)+CHR(13)+ "<HR><i>" + CHR(13) +lctext + "</i>"
ELSE
   lcQuoted = ;
   		[<div class="quotedmessagetext">] + CRLF +;
		   STRTRAN(lcText,[ class="quotedmessagetext"],[]) +;
	    CRLF + [</div>] + CRLF

ENDIF

RETURN lcQuoted
* GetQuotedText

************************************************************************
* ThreadMessage :: AddSignature
*********************************
***  Function: Adds a signature to the bottom of a message
***    Assume:
***      Pass: lcSignature  -  Text to use as signature
***    Return:
************************************************************************
FUNCTION AddSignature
LPARAMETERS lcSignature
LOCAL lc1, lc2

lc1="<"
lc2=">"
  
THIS.cMessage = THIS.cMessage + CR + ;
                 lc1 + "!-- BEGIN SIGNATURE --" + lc2 + CR +;
                 lcSignature + CR + ;
                 lc1 + "!-- END SIGNATURE --" + lc2
ENDFUNC
* ThreadMessage :: AddSignature

************************************************************************
* ThreadMessage :: StripSignature
*********************************
***  Function: Strips a signature from a message
************************************************************************
FUNCTION StripSignature
LOCAL lcSignature, lc2, lc1

lc1="<"
lc2=">"

lcSignature = Extract(THIS.cMessage,lc1 +"!-- BEGIN SIGNATURE --"+lc2,lc1+"!-- END SIGNATURE --"+lc2)
lcBanner = Extract(THIS.cMessage,lc1 +"!-- BEGIN BANNER --"+lc2,lc1+"!-- END BANNER --"+lc2)

*IF !EMPTY(lcSignature)
   THIS.cMessage = STRTRAN(THIS.cMessage,;
                   lc1 + "!-- BEGIN SIGNATURE --"+ lc2 + lcSignature+ lc1+"!-- END SIGNATURE --"+lc2,"")
   THIS.cMessage = STRTRAN(THIS.cMessage,;
                   lc1 + "!-- BEGIN BANNER --"+lc2 + lcBanner + lc1+"!-- END BANNER --"+lc2,"")
*ENDIF

ENDFUNC
* ThreadMessage :: StripSignature

************************************************************************
*  InlineStyles
****************************************
***  Function: Take the styles in wwThreads.css and inline
***    Assume: Styles are hardcoded
***      Pass: Html input
***    Return: Html output (doesn't update cMessage)
************************************************************************
FUNCTION InlineStyles(lcHtml)
LOCAL lcStyles

TEXT TO lcstyles NOSHOW
<style type="text/css">
body
{
	font-size: 10pt;
	font-family: Verdana,Arial;
	background-color: #ffffdd;
}
.messageheader
{
	color: White;
	font-family: Arial;
	font-size: 12pt;
	font-weight: bold;
	text-align: right;
	padding: 7px;
	background: #323232;
}
.quotedmessagetext
{	
	font-style: italic;
	padding: 10px;
	margin: 10px;
	background: WhiteSmoke;
	border: 1px solid lightgray; 
}
.messagetitle
{
	font-size: 14pt; 
	font-weight: bold; 
	color: darkred;	
	padding: 10px;
	font-family: Arial, Sans-Serif;
	background: #EBBC21;
    background: -moz-linear-gradient(top, rgba(235,188,33,1) 1%, rgba(252,252,252,1) 100%); /* FF3.6+ */
    background: -webkit-gradient(linear, left top, left bottom, color-stop(1%,rgba(235,188,33,1)), color-stop(100%,rgba(252,252,252,1))); /* Chrome,Safari4+ */
    background: -webkit-linear-gradient(top, rgba(235,188,33,1) 1%,rgba(252,252,252,1) 100%); /* Chrome10+,Safari5.1+ */
    background: -o-linear-gradient(top, rgba(235,188,33,1) 1%,rgba(252,252,252,1) 100%); /* Opera 11.10+ */
    background: -ms-linear-gradient(top, rgba(235,188,33,1) 1%,rgba(252,252,252,1) 100%); /* IE10+ */
    background: linear-gradient(top, rgba(235,188,33,1) 1%,rgba(252,252,252,1) 100%); /* W3C */
    filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ebbc21', endColorstr='#fcfcfc',GradientType=0 ); /* IE6-9 */
}
.messagedetailheader
{
	background-color: #D0D0D0;	
	padding: 10px;
	font-size: 8pt;
	font-family: Arial,  Sans-Serif;	
	margin: 6px;
	margin-top: 1px;
	box-shadow: 2px 2px 5px #535353;
	border-radius: 5px;
}
.msgtextbody 
{
	font-size:10pt;	
	padding: 10px 20px;
}
.data { font-weight: bold; }
.label {float: left; color: #505050; width: 85px; }
#rightheader { color: #505050; float: right; text-align: right; } 
</style>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
ENDTEXT

lcHtml = ReplaceTextAndDelimiters(lcHtml,[<link rel="],[/>],lcStyles)

RETURN lcHtml
ENDFUNC
*   InlineStyles

************************************************************************
* ThreadMessage :: GetRssMessages
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetRssMessages(lnDays,lcForum)

IF EMPTY(lnDays)
   lnDays = 2
ENDIF

lnDays = lnDays -1
IF lnDays < 0
   lnDays = 0
ENDIF
IF !EMPTY(lcForum)
  lcForum = " AND lcForum  = ?lcForum "
ELSE
  lcForum = ""  
ENDIF

IF !USED("wwThreads") 
   USE wwThreads IN 0
ENDIF

SELECT MsgId FROM wwThreads ;
   WHERE TimeStamp >= DATE() - lnDays ;
   &lcForum ;
   ORDER BY TimeStamp DESC INTO CURSOR TRSSMessages

RETURN _TALLY
ENDFUNC
*  ThreadMessage :: GetRssMessage


************************************************************************
* wwThreads ::  CheckSpam
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION IsSpam(lcMessage)

lcMessage = LOWER(lcMessage)
SELECT .T. FROM SpamFilter ;
   WHERE TRIM(LOWER(SpamFilter.Filter)) $ lcMessage ;
   INTO ARRAY TItems

IF _Tally > 0
   RETURN .T.
ENDIF

RETURN .F.      
ENDFUNC
*  wwThreads ::  CheckSpam




************************************************************************
* ThreadProcess :: Translate
****************************************
***  Function: Translates the current message into the selected language
***      Pass: lcMsgId -  ID of the message to translate
***            lcTranslate - The language to translate to/from
************************************************************************
FUNCTION Translate
LPARAMETERS lcTranslate

THIS.StripSignature()
THIS.cMessage = This.BabelFish(THIS.cMessage,lcTranslate)

IF EMPTY(THIS.cMessage)
   RETURN .F.
ENDIF

THIS.cSubject = THIS.BabelFish(THIS.cSubject,lcTranslate)

RETURN .T.
ENDFUNC
*  ThreadProcess :: Translate

************************************************************************
* ThreadProcess :: BabelFish
****************************************
***  Function: Translates text from one language to another
***      Pass: lcText       -  text to translate
***            lcTranslate  -  Language to translate to/from
***                            en_fr, en_es, en_it
***    Return: Translated text or "" on error/failure
************************************************************************
FUNCTION BabelFish
LPARAMETERS lcText, lcTranslate
LOCAL loIP, lcResult, lcTText

loIP = CREATEOBJECT(WWC_WWHTTP)
loIP.AddPostKey("enc","utf8")
loIP.AddPostKey("doit","done")
loIP.AddPostKey("BabelFishFrontPage","no")
loIP.AddPostKey("bblType","urltext")  && CheckBox
loIP.AddPostKey("urltext",lcText)
loIP.AddPostKey("lp",lcTranslate)

lcResult = loIP.HTTPGet("http://babel.altavista.com/translate.dyn")

IF loIP.nError # 0
   RETURN ""
ENDIF

lcTText = Extract(lcResult,[<td bgcolor=white>],;
                           [</td>])

IF EMPTY(lcTText)
    lcTText = Extract(lcResult,[<textarea rows="3" wrap=virtual cols="56" name="q">] + CHR(13) + CHR(10),;
                           CHR(13) + CHR(10) + [</textarea>])
ENDIF

             
RETURN lcTText
ENDFUNC
*  ThreadProcess :: BabelFish



************************************************************************
* ThreadMessage :: SaveMessage
******************************
***   Function: Saves a new message to disk into wwThreads 
***  Parameter: llNoNewMessage -  .T. if updating message
***                               .F. when creating a new message
************************************************************************
FUNCTION SaveMessage
LPARAMETER llEditing
LOCAL lnCount

IF EMPTY(THIS.cThreadId)
   THIS.cThreadId=THIS.NewId()
ENDIF
IF EMPTY(THIS.cMsgId)
   THIS.cMsgId=THIS.NewId()
ENDIF
IF EMPTY(THIS.tTimeStamp)   
   THIS.tTimeStamp=DATETIME()
ENDIF   
IF EMPTY(THIS.cSubject)
   THIS.cSubject="No Subject"
ENDIF
IF EMPTY(THIS.cTo)
   THIS.cTo="All"   
ENDIF   
IF EMPTY(THIS.cFromName)
   THIS.cFromName="Unknown"
ENDIF
IF EMPTY(THIS.cForum)
  THIS.cForum=DEFAULTFORUM
ENDIF

IF !USED("wwt_forums")			
   USE (THIS.cDataPath+"wwt_forums") IN 0
ENDIF

SELE wwt_forums  
LOCATE FOR ForumName=THIS.cForum
lnMaxMsgs=wwt_forums.maxmsgs
   
IF !USED("wwThreads")			
   USE (THIS.cDataPath+"wwThreads") IN 0
ENDIF

SELE wwThreads

lcForum=THIS.cForum

*** Add new record if flag is not set
*** Otherwise just update current record
IF !llEditing
   APPEND BLANK
ENDIF

*** Safety to disallow script code
THIS.cMessage = STRTRAN(THIS.cMessage,"<%=","&lt;%=")

REPLACE UserId with THIS.cUserId,;
        Threadid with THIS.cThreadId,;
        MsgId with THIS.cMsgId,;
        ParentId with THIS.cParentId,;
        FromName with THIS.cFromName,;
        FromEmail with THIS.cFromEmail,;
        TO with THIS.cTo,;
        Subject with THIS.cSubject,;
        Message with THIS.cMessage,;
        Attachmt with THIS.cAttachmt,;
        Attachnm with JustFname(THIS.cAttachnm),;
        Timestamp with THIS.tTimeStamp,;
        NoFormat with THIS.lNoFormat,;
        Forum with THIS.cForum,;
        Pinned WITH THIS.lPinned      

ENDFUNC
* SaveMessage

************************************************************************
* ThreadMessage :: LoadMessage
*********************************
***  Function: Loads a message from disk into object
***            Message must be selected in wwThreads
************************************************************************
FUNCTION LoadMessage
LPARAMETER lcMsgid

IF !USED("wwThreads") 
   IF EMPTY(lcMsgId)
      RETURN .F.
   ENDIF
   
   USE wwThreads IN 0
ENDIF

SELE wwThreads

IF !EMPTY(lcMsgid)
   LOCATE FOR Msgid = lcMsgid
   IF !FOUND()
      RETURN .F.
   ENDIF
ENDIF

THIS.cUserId=wwThreads.UserId
THIS.cTo=wwThreads.To
THIS.cFromName=wwThreads.Fromname
THIS.cFromEmail=wwThreads.FromEmail
THIS.cThreadId=wwThreads.ThreadId
THIS.cMsgId=wwThreads.MsgId
THIS.cParentId=wwThreads.ParentId
THIS.cSubject=wwThreads.Subject
THIS.cMessage=wwThreads.Message
THIS.cAttachmt=wwThreads.Attachmt
THIS.cAttachnm=wwThreads.AttachNm
THIS.tTimeStamp=wwThreads.Timestamp
THIS.lNoFormat=wwThreads.NoFormat
THIS.cForum=wwThreads.Forum
THIS.lPinned = wwThreads.Pinned

*** Reader Properties
this.lRead = wwThreads.Read

RETURN .T.
* LoadMessage


************************************************************************
* ThreadMessage :: RenderMessage
*********************************
***  Function: Renders the currently selected message as HTML
***    Assume:
************************************************************************
FUNCTION RenderMessage
LPARAMETER lcTemplate, llNoBanner
LOCAL loBanner, lcHTML

IF EMPTY(lcTemplate)
  lcTemplate = THIS.cHTMLPagePath + "showmsg.wwt"
ENDIF

*** Add a banner to the bottom of the page
IF !llNoBanner
   pcBannerText = ""
   
   *** Rotate Google and Custom Ads randomly
   lnRoundValue = ROUND(SECONDS() % 1,0)
   

*   IF THIS.lUseGoggleAds
	IF lnRoundValue = 1
      IF !EMPTY(pcBannerText)
         pcBannerText = pcBannerText + "<hr>"
      ENDIF
      
TEXT TO lcBText NOSHOW
<script type="text/javascript"><!--
google_ad_client = "ca-pub-2013123155768157";
/* wwThreads_Bottom_Message */
google_ad_slot = "1476055606";
google_ad_width = 728;
google_ad_height = 90;
//-->
</script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
<p>
ENDTEXT
		
		pcBannerText = pcBannerText + lcBText
          ENDIF

   pcBannerText = pcBannerText + ;
      "<!-- END BANNER -->"
ELSE
   pcBannerText = ""
ENDIF

poMsg = THIS

lcHTML = MergeText(File2Var(lcTemplate)) 
lcHTML = FixPreTags(@lcHTML)

RETURN lcHTML
ENDFUNC
* ThreadMessage :: RenderMessage

************************************************************************
* ThreadMessage :: FixNoFormat
*********************************
***  Function: Fixes a message that has no formatting. Convert
***            <> and quotes and {}.
***      Pass:
***    Return: Old Setting
************************************************************************
FUNCTION FixNoFormat
LPARAMETER llEdit

IF !llEdit
	*** Convert {} to HTML tags
    lcMessage = ExpandHyperLinks(THIS.cMessage)

   *** Create Code Syntax Coloring
   IF TYPE("SERVER.oCodeParser") = "O"
      loCodeParser = Server.oCodeParser
   ELSE
      loCodeParser = CREATEOBJECT("cswwPageCodeParser")
   ENDIF
   lcMessage = loCodeParser.Execute(lcMessage)

   *** Strip out RAWHTML blocks
   lnRawHTML=0
   DIMENSION aRawHTML[1]
   DO WHILE .T.
         lcBlock = Extract(lcMessage,"<RAWHTML>","</RAWHTML>")
         IF EMPTY(lcBlock)
            EXIT
         ENDIF
      lnRawHTML = lnRawHTML + 1
      
      lcMessage = STRTRAN(lcMessage,"<RAWHTML>" + lcBlock + "</RAWHTML>","###__RAWHTMLBLOCK" + TRANS(lnRawHTML) + "###",1,1,1)
      DIMENSION aRawHTML[lnRawHTML]
      aRawHTML[lnRawHTML] = lcBlock
    ENDDO
   
   *** Take all real HTML links and temporarily rename
	lcMessage=STRTRAN(lcMessage,THIS.cLTAG,"*#lt*")
	lcMessage=STRTRAN(lcMessage,THIS.cRTag,"*#gt*")

    *** Convert HTML to plain text with &gt &lt
	lcMessage=STRTRAN(lcMessage,"<","&lt;")
	lcMessage=STRTRAN(lcMessage,">","&gt;")

	*cMessage=STRTRAN(lcMessage,'"',"'")
	THIS.cSubject=STRTRAN(THIS.cSubject,'"',"'")

    *** Convert back real HTML tags
	lcMessage=STRTRAN(lcMessage,"*#lt*","<")
	lcMessage=STRTRAN(lcMessage,"*#gt*",">")
   
   *** Now put the RAWHTML blocks back in
   FOR x=1 to lnRawHTML
       lcMessage = STRTRAN(lcMessage,;
         "###__RAWHTMLBLOCK" + TRANS(x) + "###",;
         aRawHTML[x])
   ENDFOR

   this.cMessage = lcMessage
ELSE
   lcMessage=STRTRAN(THIS.cMessage,"<",THIS.cLTag)
   lcMessage=STRTRAN(lcMessage,">",THIS.cRTag)
   lcMessage=STRTRAN(lcMessage,"&lt;","<")
   
 
   THIS.cMessage=STRTRAN(lcMessage,"&gt;",">")
ENDIF	

RETURN
* EOF FixNoFormat	

FUNCTION SplitEmailToName

IF AT("[",THIS.cTo) = 0
   THIS.cToEmail = ""
   THIS.cToName = THIS.cTo
   RETURN THIS.cToName
ENDIF

THIS.cToEmail = EXTRACT(THIS.cTo,'[',']')
THIS.cToName = LEFT(THIS.cTo,AT("[",THIs.cTo)-1)
       
RETURN MailLink(THIS.cToEmail,THIS.cToName)

************************************************************************
* ThreadMessage ::  GetForumList
****************************************
***  Function: Returns a list of forums as a TForums cursor
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetForumList()

SELECT ForumName ;
       FROM (THIS.cDataPath + "wwt_forums") ;
       WHERE !NoDownload ;
       Order by 1 ;
       INTO CURSOR TForums 
     

ENDFUNC
*  ThreadMessage ::  GetForumList


************************************************************************
* ThreadMessage :: Newid
*********************************
***  Function: Creates a message or thread Id
***    Return: Id
************************************************************************
FUNCTION Newid
RETURN SUBSTR(SYS(2015),2)
* Newid

FUNCTION CheckForDuplicateMessage
LPARAMETERS lcFromName, lcMessage

   *** Check and make sure they're not entering the same message more than once
   SELECT Msgid ;
      FROM (THIS.cDataPath + "wwThreads") ;
      WHERE fromname=lcFromName AND MESSAGE=lcMessage AND ;
            TIMESTAMP > date() -1 ;
      INTO ARRAY laTemp

   IF _TALLY < 1
           RETURN .T.
   ENDIF

RETURN .F.
ENDFUNC

************************************************************************
* wwThreadMessage :: FixMessagesWithNoForum
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION FixMessagesWithNoForum(llSilent)

SELECT * from wwThreads WHERE Forum = "Please" INTO CURSOR TQuery

IF !llSilent
    MESSAGEBOX(TRANSFORM(_tally) + " Messages with problems found","Fix Messages",64)
ENDIF

SCAN
    lcThreadId = TQuery.ThreadId
    lcMsgId = TQuery.MSgId
    lcSubject = TQuery.Subject

    SELECT wwThreads
    LOCATE FOR ThreadId = lcThreadId
    IF FOUND()
       WAIT WINDOW "Fixing Subject " + lcSubject nowait
       lcForum = wwThreads.Forum
       IF lcForum = "Please "
          lcForum = "Chatter"
       ENDIF
    ELSE
       lcForum = "Chatter"
    ENDIF

    LOCATE FOR MsgId = lcMsgId
    REPLACE forum WITH lcForum
    
    SELECT TQuery
ENDSCAN
RETURN


ENDDEFINE
*EOC ThreadMessage

*************************************************************
DEFINE CLASS ThreadUser AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 11/03/96
***
***  Function:
*************************************************************


*** Custom Properties
cCookieId=""
tLastOn={}
lUsedReader=.F.
dListDate={}
cFilter=""
cName=""
cEmail=""
cForum=""
cSignature=""
cDataPath = ""
Admin = 0

cVars = ""
cDelimiter="#!#"


cErrorMsg = ""

*** Stock Properties

************************************************************************
* ThreadUser :: Init
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Init

this.Open()

ENDFUNC
* Init

************************************************************************
*  Open
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Open()

*** Make sure the user table is open
IF !USED("wwUsers")
   USE (THIS.cDataPath+"wwUsers") IN 0
ENDIF
SELECT wwUsers

ENDFUNC
*   Open


************************************************************************
* ThreadUser :: Destroy
*********************************
***  Function: Closes the wwUsers table
***      Pass:
***    Return:
************************************************************************
*-*FUNCTION Destroy
*-*
*-*IF USED("wwUsers")
*-*   USE IN wwUsers
*-*ENDIF   
*-*
*-*ENDFUNC
*-** Destroy

************************************************************************
* ThreadUser :: GetUser
*********************************
***  Function: Searches for a user and if found loads the User object
***            properties.
***    Assume:
***      Pass: 
***    Return: .T. if found .F. if not
************************************************************************
FUNCTION GetUser
LPARAMETERS lcCookieId

lcCookieId=PADR(lcCookieId,8)

this.open()

LOCATE FOR CookieId == lcCookieId
IF !FOUND()
   THIS.ClearUser()
   RETURN .F.
ENDIF

THIS.LoadUser()     
RETURN .T.
* GetUser


************************************************************************
*  Authenticate
****************************************
***  Function: Authenticates the user and selects the user record
***            in wwUsers
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Authenticate(lcEmail,lcPassword)

IF EMPTY(lcEmail)
   this.cErrorMsg = "Email address can't be blank"
   RETURN .F.
ENDIF   

IF EMPTY(lcPassword) OR LEN(lcPassword) < 5
   this.cErrorMsg = "Password must be at least 5 characters"
   RETURN .F.
ENDIF   

this.Open()

LOCATE FOR Email == lcEmail
IF !FOUND()
   this.cErrorMsg = "Invalid email address."
   RETURN .F.
ENDIF

IF wwUsers.Password != lcPassword
  this.cErrorMsg = "Invalid password."
  RETURN .F.
ENDIF  

RETURN .T.
ENDFUNC
*   Authenticate


************************************************************************
* ThreadUser :: LoadUser
*********************************
***  Function: Loads the properties from the selected record
***    Assume: Record is 
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadUser

THIS.cCookieId=wwUsers.CookieId
THIS.tLastOn=wwUsers.LastOn
IF EMPTY(this.tLastOn) OR this.tLastOn < DATE() - 60
   this.tLastOn = DATE() - 3
ENDIF

*THIS.dListDate=wwUsers.ListDate
THIS.cFilter=wwUsers.Filter
THIS.cName=wwUsers.Name
THIS.cEmail=wwUsers.Email
THIS.cForum=wwUsers.Forum
THIS.cSignature=wwUsers.Signature
THIS.cVars = wwUsers.Vars
THIS.Admin = wwUsers.Admin

ENDFUNC
* LoadUser

FUNCTION NewUser

SELECT wwUsers
APPEND BLANK
THIS.cCookieId=SUBSTR(SYS(2015),3)
this.LoadUser()

ENDFUN

************************************************************************
* ThreadUser :: SaveUser
*********************************
***  Function: Saves a user to disk
************************************************************************
FUNCTION SaveUser

IF EMPTY(THIS.cCookieid)
   THIS.SaveNewUser()
ENDIF
  
SELE wwUsers
REPLACE wwusers.CookieId with THIS.cCookieId,;
        wwUsers.LastOn with  THIS.tLastOn,;
        wwUsers.UsedReader with THIS.lUsedReader,;
        wwUsers.ListDate with THIS.dListDate,;
        wwUsers.Filter with THIS.cFilter,;
        wwUsers.Name with THIS.cName ,;
        wwUsers.Email with THIS.cEmail,;
        wwUsers.Forum with THIS.cForum,;
        wwUsers.Signature with THIS.cSignature,;
        wwUsers.Vars with THIS.cVars,;
        wwUsers.Admin with THIS.Admin
        
ENDFUNC
* SaveUser

************************************************************************
* ThreadUser :: SaveNewUser
*********************************
***  Function: Adds a new user to the database. Assigns a cookie and
***            returns it.
***    Return: New Cookie
************************************************************************
FUNCTION SaveNewUser

SELE wwUsers
APPEND BLANK
THIS.cCookieId=SUBSTR(SYS(2015),3)
THIS.SaveUser()

RETURN THIS.cCookieId
* NewUser

************************************************************************
* ThreadUser :: ClearUser
*********************************
***  Function: Clears the User object properties. Moves to EOF then
***            reloads with the blank entries there
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ClearUser

SELE wwUsers
LOCATE FOR .F.
THIS.LoadUser()

ENDFUNC
* ClearUser

************************************************************************
* wwSession :: SetSessionVar
*********************************
***  Function: Creates or sets an existing session variable. 
***            Session variables are dynamically created 
***    Assume: wwSession Table is located on Cookie
***            Variables must be in string format
***      Pass: lcVarName    -   Name of the Variable
***            lcValue      -   Text Value to assign to variable
************************************************************************
FUNCTION SetUserProperty
LPARAMETERS lcVarName, lcValue, llForceSave
LOCAL lctext, lcValue

lcText=THIS.cDelimiter+lcVarName+"="+lcValue+THIS.cDelimiter+CHR(13)

lcExtract=Extract(THIS.cVars,THIS.cDelimiter+lcVarName+"=",THIS.cDelimiter,,.t.)
IF !EMPTY(lcExtract)
   IF EMPTY(lcValue)
     THIS.cVars = STRTRAN(THIS.cVars,THIS.cDelimiter+lcVarName+"="+lcExtract+THIS.cDelimiter+CHR(13),"")
   ELSE
   *** Kill the existing one and replace it with the new one
     THIS.cVars = STRTRAN(THIS.cVars,THIS.cDelimiter+lcVarName+"="+lcExtract+THIS.cDelimiter+CHR(13),lctext)
   ENDIF
ELSE
   *** Simply append it
   IF !EMPTY(lcValue)
      THIS.cVars=THIS.cVars + lctext
   ENDIF
ENDIF   

ENDFUNC
* AddSessionVar


************************************************************************
* ThreadUser :: GetUserProperty
*********************************
***  Function: Retrieves a User Property
***      Pass: lcVarName  -   The variable to retrieve
***    Return: Result value string or "" if not found or empty
************************************************************************
FUNCTION GetUserProperty
LPARAMETERS lcVarName
RETURN Extract(THIS.cVars,THIS.cDelimiter+lcVarName+"=",THIS.cDelimiter,,.t.)
ENDFUNC
* GetSessionVar

ENDDEFINE
*EOC ThreadUser



*************************************************************
DEFINE CLASS DownloadMessagesRequest AS Relation
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2004
*:Contact: http://www.west-wind.com
*:Created: 05/31/04
************************************************

FromDate = {}
ToDate = {}

UserId = ""
TimeZone = -8   && PST - Server Time

Forums = .null.

cServerUrl = "http://www.west-wind.com/wwThreads/DownloadXmlMessages.wwt"

lError = .f.
cErrorMsg = ""

FUNCTION Init()
this.Forums = CREATEOBJECT("Collection")
ENDFUNC

************************************************************************
* DownloadMessageRequest :: Download
****************************************
***  Function: Downloads messages and returns them in a cursor
***            called TMessages.
***      Pass: loHttp - optional: An preconfigured wwHTTP instance
***    Return: .t. or .f.
************************************************************************
FUNCTION Download(loHttp)

*** Persist the properties to XML
lcXML = this.ToXml()

* ? lcXML 

IF VARTYPE(loHttp) # "O"
   loHTTP = CREATEOBJECT("wwHttp")
ENDIF

loHttp.nHttpPostMode = 4
loHTTP.AddPostKey(,lcXML)
lcResult = loHTTP.HttpGet(this.cServerUrl)

*** Handle any HTTP Errors
IF loHttp.nError != 0
   this.cErrorMsg = loHTTP.cErrorMsg
   RETURN .F.
ENDIF

*** Handle no data return
IF EMPTY(lcResult)
   this.cErrorMsg = "No data returned."
   RETURN .f.
ENDIF

* ShowXml(lcResult)

*** Handle Error Message Returned
IF "<errormessage>" $ lcResult 
   this.cErrormsg = STREXTRACT(lcResult,"<errormessage>","</errormessage>")
   RETURN .F.
ENDIF

XMLTOCURSOR(lcResult,"TMessages")

IF !USED("TMessages")
   this.ErrorMsg = "Data Conversion failed... Invalid XML"
   RETURN .f.
ENDIF   
   
RETURN .T.
ENDFUNC
*  DownloadMessageRequest :: Download

************************************************************************
* DownloadMessagesRequest :: ToXml()
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ToXml()
LOCAL loXML

IF EMPTY(this.UserId) AND EMPTY(this.FromDate)
   this.FromDate = DATETIME() - 170000
   this.ToDate = DATETIME()
ENDIF

loXML = CREATEOBJECT("wwXML")
loXML.lRecurseObjects = .t.
loXML.cDocRootName = "wwThreads"
lcXML = loXML.ObjectToXML(mr,"downloadmessagesrequest")

RETURN lcXML
*  DownloadMessagesRequest :: ToXml()

************************************************************************
* DownloadMessagesRequest :: LoadFromXml
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadFromXml(lcXML)
LOCAL loXML 

loXML = CREATEOBJECT("wwXML")
loXML.lRecurseObjects = .t.
loXML.XmlToObject(lcXML,this)

RETURN .t.
*  DownloadMessagesRequest :: LoadFromXml

ENDDEFINE





**** Generic Routines

************************************************************************
FUNCTION SplitNames
*******************
***  Function: Split names of a full name/email into its pieces
************************************************************************
LPARAMETER lcFull, lcName, lcEmail

IF ATC("[",lcFull)> 0
  lnLoc = ATC("[",lcFull)
  lcEmail = Extract(lcFull,"[","]")
  lcName = TRIM(LEFT(lcFull,lnLoc - 1))
  RETURN
ENDIF

lnLoc=RAT(" - ",TRIM(lcFull))
IF lnLoc > 1
   lcName=SUBSTR(lcFull,1,lnLoc-1)
   lcEmail=SUBSTR(lcFull, lnLoc+3)
   RETURN
ENDIF

*** Email Address only
lcName=lcFull
lcEmail=lcFull

ENDFUNC
* SplitNames

************************************************************************
PROCEDURE ExpandHyperLinks
**************************
***  Modified: 07/19/99
***  Function:
***    Assume:
***      Pass:
***    Return:
*************************************************************************
LPARAMETER lcText

loLE = CREATEOBJECT("wwLinkParser")
loLE.cHTML = lcText
loLE.cRTag = ">>"
loLE.cLTag = "<<"
loLE.ExpandLinksFromTable()

RETURN loLE.cHTML

*!*   lcText = ExpandLinks(lcText,"http://",[<>="'/])
*!*   lcText = ExpandLinks(lcText,"ftp://",[<>="'/])
*!*   lcText = ExpandLinks(lcText,"www.",[<>="'/])

*!*   lcText = ExpandLinks(lcText,"wc:",[<>="'/])
*!*   lcText = ExpandLinks(lcText,"fox:",[<>="'/])
*!*   lcText = ExpandLinks(lcText,"sql:",[<>="'/])
*!*   lcText = ExpandLinks(lcText,"msg:",[<>="'/])
*!*   lcText = ExpandLinks(lcText,"mskb:",[<>="'/])
*!*   lcText = ExpandLinks(lcText,"wchelp:",[<>="'/])
*!*   RETURN lcText


*!*   ************************************************************************
*!*   PROCEDURE ExpandLinks
*!*   *********************
*!*   ***  Modified: 07/19/99
*!*   ***  Function: Takes an existing block of text and expands
*!*   ***            any given hyperlinks to full clickable links
*!*   ***      Pass: lcText    -  Document to work with
*!*   ***            lcLookFor -  The expression to look for:
*!*   ***                         "www.","http://","ftp://" 
*!*   ***            lcNonValidPreceedingChars
*!*   ***                         Chars that can't proceed the link
*!*   ***                         or else the piece is not expanded
*!*   ***    Return: Updated text with expanded hyperlinks
*!*   *************************************************************************
*!*   LPARAMETER lcText,lcLookFor,lcNonValidPreceedingChars

*!*   lcLookfor=IIF(EMPTY(lcLookfor),"http://",lcLookfor)
*!*   lcNonValidPreceedingChars=IIF(EMPTY(lcNonValidPreceedingChars),[="'/],lcNonValidPreceedingChars)

*!*   lnCurPos = 0
*!*   lnHit = 1
*!*   lcResult =lcText
*!*   DO WHILE .T.
*!*      lnCurPos = ATC(lcLookFor,lcText,lnHit)
*!*      IF lnCurPos = 0
*!*         EXIT
*!*      ENDIF
*!*      
*!*      lnHit = lnHit + 1

*!*      IF lcLookFor = lcText
*!*         LOOP
*!*      ENDIF

*!*      lcWord = GetWord(lcText,lnCurPos,[ <"]+CHR(13))

*!*      *** If there's bracket in the 
*!*      IF [>] $ lcWord OR [<] $ lcWord
*!*         LOOP
*!*      ENDIF


*!*      lcWord = GetWord(lcText,lnCurPos,[ ,;"']+CHR(13))
*!*      IF SUBSTR(lcText,lnCurPos-1,1) $ lcNonValidPreceedingChars
*!*         LOOP
*!*      ENDIF
*!*      IF RIGHT(lcWord,1) = "."
*!*         lcWord = LEFT(lcWord,LEN(lcWord)-1)
*!*      ENDIF
*!*      lnStuff = LEN(lcWord)
*!*      lcLabel = lcWord
*!*      IF lower(left(lcWord,4))="www."
*!*         lcWord = "http://" + lcWord
*!*      ENDIF
*!*      IF lcLookfor = "http://"
*!*         lnHit = lnHit + 1
*!*      ENDIF
*!*      DO CASE
*!*      CASE lcLookfor = "wc:"
*!*         lcWikiWord = STRTRAN(lcWord,"wc:","")
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="http://www.west-wind.com/wiki/wc.dll?wc~] + lcWikiWord + [" target="top">>] +  ;
*!*                        lcWord + [<</a>>])
*!*      CASE lcLookFor = "fox:" 
*!*         lcWikiWord = STRTRAN(lcWord,"fox:","")
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="http://fox.wikis.com/wc.dll?fox~] + lcWikiWord + [" target="top">>] +  ;
*!*                        lcWord + [<</a>>])
*!*      CASE lcLookFor = "sql:" 
*!*         lcWikiWord = STRTRAN(lcWord,"sql:","")
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="http://sql.wikis.com/wc.dll?sql~] + lcWikiWord + [" target="top">>] +  ;
*!*                        lcWord + [<</a>>])
*!*      CASE lcLookFor = "msg:" 
*!*         lcWikiWord = STRTRAN(lcWord,"msg:","")
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="http://www.west-wind.com/wwthreads/showmsg.wwt?msgid=] + lcWikiWord + [">>] +  ;
*!*                        lcWord + [<</a>>])
*!*      CASE lcLookFor = "mskb:"
*!*         lcWikiWord = STRTRAN(lcWord,"mskb:","")
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="http://support.microsoft.com/default.aspx?scid=kb;EN-US;] + lcWikiWord + [" target="top">>] +  ;
*!*                        lcWord + [<</a>>])
*!*      CASE lcLookFor = "wchelp:"
*!*         lcWikiWord = STRTRAN(lcWord,"wcdocs:","")
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="http://www.west-wind.com/webconnection/docs/index.htm?page=] + lcWikiWord + [" target="top">>] +  ;
*!*                        lcWord + [<</a>>])
*!*                              
*!*      OTHERWISE
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="] + lcWord + [" target="top">>]+ lcLabel + [<</a>>])
*!*      ENDCASE
*!*   ENDDO

*!*   RETURN lcText



*!*   ************************************************************************
*!*   * Test :: ExpandLink
*!*   ****************************************
*!*   ***  Function:
*!*   ***    Assume:
*!*   ***      Pass:
*!*   ***    Return:
*!*   ************************************************************************
*!*   FUNCTION ExpandLink(lcText,lcLookFor,lcBaseUrl,lcNonValidPreceedingChars)
*!*   LOCAL lnHit, lnCurPos, lcResult, lcWord

*!*   lcLookfor=IIF(EMPTY(lcLookfor),"http://",lcLookfor)
*!*   lcNonValidPreceedingChars=IIF(EMPTY(lcNonValidPreceedingChars),[=>/"],lcNonValidPreceedingChars)

*!*   lnCurPos = 0
*!*   lnHit = 1
*!*   lcResult =lcText

*!*   DO WHILE .T.
*!*      lnCurPos = ATC(lcLookFor,lcText,lnHit)
*!*      IF lnCurPos = 0
*!*         EXIT
*!*      ENDIF

*!*      lnHit = lnHit + 1

*!*      IF lcLookFor = lcText
*!*         LOOP
*!*      ENDIF

*!*      lcWord = GetWord(lcText,lnCurPos,[ <"]+CHR(13))

*!*      *** If there's bracket in the 
*!*      IF [>] $ lcWord OR [<] $ lcWord
*!*         LOOP
*!*      ENDIF

*!*         lcWord = GetWord(lcText,lnCurPos,[ ,;"']+CHR(13))
*!*         IF SUBSTR(lcText,lnCurPos-1,1) $ lcNonValidPreceedingChars
*!*            LOOP
*!*         ENDIF
*!*         IF RIGHT(lcWord,1) = "."
*!*            lcWord = LEFT(lcWord,LEN(lcWord)-1)
*!*         ENDIF
*!*         lnStuff = LEN(lcWord)
*!*         lcLabel = lcWord
*!*         
*!*         IF lower(left(lcWord,4))="www."
*!*            lcWord = "http://" + lcWord
*!*            llRealUrl = .T.
*!*         ENDIF
*!*         IF lcLookfor = "http://"
*!*            lnHit = lnHit + 1
*!*         ENDIF

*!*      IF lclookfor $ "http://|ftp://|mailto:"
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="] + lcWord + [" target="top">>]+ lcLabel + [<</a>>])
*!*      ELSE
*!*         lcWikiWord = STRTRAN(lcWord,lcLookFor,"")
*!*         lcText = STUFF(lcText,lnCurPos,lnStuff,[<<a href="] + lcBaseUrl + lcWikiWord + [" target="top">>] +  ;
*!*                        lcWord + [<</a>>])
*!*      ENDIF
*!*   ENDDO

*!*   RETURN lcText


*!*   FUNCTION GetWord
*!*   LPARAMETER lcText, lnLocation, lcEndChars
*!*   LOCAL x
*!*   lcEndChars=IIF(VARTYPE(lcEndChars)#"C",[ ><.,;"'],lcEndChars)

*!*   FOR x=0 to 255
*!*     lcChar = substr(lcText,lnLocation + x,1)
*!*     IF LEN(lcChar) = 0
*!*        x=x-1
*!*        EXIT
*!*     ENDIF
*!*     IF lcChar $ lcEndChars
*!*        EXIT
*!*     ENDIF  
*!*   ENDFOR

*!*   if x=255 OR x < 2
*!*      RETURN ""
*!*   ENDIF


*!*   RETURN SUBSTR(lcText,lnLocation,x)
*!*   ENDFUNC


************************************************************************
* API :: GetTimeZoneHours
*********************************
***  Function: Returns the local time zone based on UTC
***    Return: hour offset or -1 on error
************************************************************************
FUNCTION GetTimeZoneHours
LOCAL lcStruct, lcBias, lnErr

RETURN GetTimeZone() / 60



