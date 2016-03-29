
SET CLASSLIB TO wwBusiness ADDITIVE
SET PROCEDURE TO wwUtils ADDITIVE
SET PROCEDURE TO wwCollections ADDITIVE
SET PROCEDURE TO wwt_message.prg ADDITIVE

#include wconnect.h

*************************************************************
DEFINE CLASS wwt_message AS wwbusiness
*************************************************************

cAlias = "wwthreads"
cDataPath = ""
cFileName = "wwthreads"

cPkField = "MsgId"
cIdTable = "wwt_id.dbf"

*** Sql Connection String
cConnectString = ""

*** 0 - fox 2 - Sql 4-Web
nDataMode = 0

************************************************************************
*  GetThreads()
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetThreads(loQueryParms)

IF IsNullOrEMPTY(loQueryParms)
   loQueryParms = THIS.CreateMessageQueryParms()
ENDIF   

THIS.Open()

pdStartDate = loQueryParms.StartDate
pdEndDate = loQueryParms.EndDate + 1
pcForum = loQueryParms.Forum
pcMsgId = PADR(loQueryParms.MsgId,FSIZE("MsgId","wwThreads"))
pcSearch = loQueryParms.Search

lcWhere = "(Pinned OR TimeStamp >= pdStartDate AND TimeStamp < pdEndDate) "
IF !EMPTY(pcForum)
   lcWhere = lcWhere + " AND (Forum == pcForum) "
ENDIF   
IF !EMPTY(pcSearch)
   lcWhere = lcWhere + " AND ( ATC(pcSearch,Subject)>0 OR  ATC(pcSearch,Message)>0 ) "   
ENDIF

IF !EMPTY(pcMsgId)
   lcWhere = " MsgId == pcMsgId "
ENDIF

* MIN(TTOC(TimeStamp,1) + "|" + Subject)  as Subject, 

TEXT TO lcSql NOSHOW TEXTMERGE
SELECT ThreadId,MsgId, TimeStamp,  STRTRAN(Subject,"re: ","",1,1,1) as Subject,
		FromName, FromEmail, Forum, MAX(Pinned) as pinned,
	   (SELECT COUNT(MsgId) WHERE ThreadId = wwt.ThreadId FROM wwThreads)  as MsgCount 
   FROM wwThreads as wwt 
   WHERE << lcWhere >>
   GROUP BY Forum, ThreadId    
ENDTEXT

lnResult = this.Query(lcSql,"TMessages2")

IF this.lError
   RETURN -1
ENDIF   

*(       SUBSTR(Subject,AT("|",Subject) + 1 ) as Subject ;   
*** Must refilter the list as ORDER BY 
*** gets hammered by the GROUP BY clause
SELECT ThreadId,MsgId,TimeStamp,FromName,FromEmail,Forum,Pinned, MsgCount, Subject ;
   FROM TMessages2 ;
   ORDER BY Forum, Pinned DESC, TimeStamp DESC ;
   INTO CURSOR TMessages
USE IN TMessages2

RETURN lnResult
ENDFUNC
*   GetMessages()

************************************************************************
*  CreateMessageQueryParms
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION CreateMessageQueryParms()

loQueryParms = CREATEOBJECT("empty")
ADDPROPERTY(loQueryParms,"StartDate",DATE() - 20)
ADDPROPERTY(loQUeryParms,"EndDate",DATE())
ADDPROPERTY(loQueryParms,"Forum","")
ADDPROPERTY(loQueryParms,"Search","")
ADDPROPERTY(loQueryParms,"Search2","")
ADDPROPERTY(loQueryParms,"MsgId","")

RETURN loQueryParms
ENDFUNC
*   CreateMessageQueryParms

************************************************************************
*  GetThreadList
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetThreadMessages
PARAMETERS pcId, lnMode

IF EMPTY(lnMode)
   lnMode = 0
ENDIF 

lcFilter = "ThreadId = pcId"
IF lnMode = 2
    lcFilter = "MsgId = pcId"
ENDIF
    
pcId = UPPER(pcId)

TEXT TO lcSql NOSHOW TEXTMERGE
SELECT *,
      (SELECT COUNT(*) WHERE ThreadId = wwt.ThreadId FROM wwThreads)  as MsgCount 
   FROM wwThreads as wwt 
   WHERE << lcFilter >>
   ORDER BY TimeStamp
   into cursor TMessages   
ENDTEXT

RETURN  this.Query(lcSql,"TMessages")
ENDFUNC
*   GetThreadList


************************************************************************
*  GetForumList
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetForumList()
RETURN this.Query("SELECT forumname from wwt_forums order by forumname","TForums")
ENDFUNC
*   GetForumList


************************************************************************
*  Reply
****************************************
***  Function: Creates a new Reply object
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Reply(lcMsgId)

this.Load(lcMsgId)


loReply = this.oData
this.oData.ParentId = this.oData.MsgId
this.oData.MsgId = this.CreateNewId()


RETURN this.oData
ENDFUNC
*   Reply

************************************************************************
*  SendEmail
****************************************
***  Function: Sends an email to the recipient (TO) of this message
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION SendEmail(lcMailServer, lcMailUserName, lcMailPassword,llSecure)

loIP = CREATEOBJECT([WWC_WWSMTP])
loIP.nMailMode = 0 && .NET
loIp.lUseSsl = llSecure
	    
loIP.cMailServer = lcMailServer
loIp.cUsername = lcMailUsername
loIP.cPassword = lcMailPassword
   
loIP.cSenderName = TRIM(THIS.oData.FromName)
loIP.cSenderEmail = TRIM(THIS.oData.FromEmail)
loIp.cReplyTo = "noreply@west-wind.com"
loIP.cRecipient = TRIM(this.oData.To)

loIP.cSubject =  TRIM(THIS.oData.Subject)
loIP.cContentType = "text/html"

pcMsgId = THIS.oData.MsgId
loIP.cMessage = this.RenderMessage(this.oData.MsgId,2)

*** Fix up - protocol agnostic links for email
loIP.cMessage = STRTRAN(loIp.cMessage,[="//],[="http://])

loIP.SendMailAsync()

ENDFUNC
*   SendEmail

************************************************************************
* wwThreads ::  IsSpam
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
*  RenderMessage
****************************************
***  Function: Renders the message to a string
***    Assume:
***      Pass: lcId    -  Thread or MsgId
***    Return:
************************************************************************
FUNCTION RenderMessage(lcThreadId, lnMode)

THIS.GetThreadMessages(lcThreadId, lnMode) && TMessages

PRIVATE poMarkdown
IF VARTYPE("PROCESS") = "O"
	poMarkdown = Process.GetMarkdownParser()
ELSE
    poMarkdown = CREATEOBJECT("MarkdownParserExtended")
ENDIF	

loResponse = CREATEOBJECT("wwPageResponse")
loResponse.ExpandScript("~/ThreadRender.wwt")

RETURN loResponse.cOutput
ENDFUNC
*   RenderMessage

************************************************************************
*  New
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION New()

DODEFAULT()

THIS.oData.ThreadId = THIS.CreateNewId()
THIS.oData.To = "All"
this.oData.TimeStamp = DATETIME()
this.oData.Format = 2   && Markdown

ENDFUNC
*   New

************************************************************************
*  CreateNewId
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION CreateNewId()
RETURN SUBSTR(SYS(2015),2)
ENDFUNC
*   New

************************************************************************
*  Validate
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Validate()

DODEFAULT()

IF EMPTY(this.oData.Subject)
   this.AddValidationError("Please enter a subject for this post.","Subject")
ENDIF
IF EMPTY(this.oData.Forum)
   this.AddValidationError("Please select a forum for this post.","Forum")
ENDIF
IF EMPTY(this.oData.Message) OR LEN(TRIM(this.oData.Message)) < 15
   this.AddValidationError("Please provide a longer message body.","Message")
ENDIF

IF this.nUpdateMode = 2  && new
   LOCAL ARRAY laMatches[1]
   SELECT msgid FROM wwThreads ;
   	   WHERE subject == this.oData.Subject AND message == this.oData.Message AND TimeStamp > DATE() - 1 ;
   	   into array laMatches
   IF _Tally > 0
      this.AddValidationError("You've already posted this message","Message")
   ENDIF
ENDIF


*** Determine whether we need to return an error
IF THIS.oValidationErrors.Count > 0
    *** Set an error message that summarizes all errors optionally
	this.SetError( this.oValidationErrors.ToString() )

	*** Validation errors exist
	RETURN .F. 
ENDIF

*** No Error
RETURN .T.
ENDFUNC
*   Validate

*************************************************************
FUNCTION CreateTable(lcFileName)
*************************************************************
LOCAL lxFields

IF EMPTY(lcFileName)
   lcFileName = THIS.cDataPath + THIS.cFileName
ENDIF

IF THIS.nDataMode = 0

*** Generated on: 03/04/2016
DIMENSION lxFields[ 18,4]

lxFields[  1,1]='USERID'
lxFields[  1,2]='C'
lxFields[  1,3]=  8
lxFields[  1,4]=  0
lxFields[  2,1]='THREADID'
lxFields[  2,2]='C'
lxFields[  2,3]=  9
lxFields[  2,4]=  0
lxFields[  3,1]='MSGID'
lxFields[  3,2]='C'
lxFields[  3,3]=  9
lxFields[  3,4]=  0
lxFields[  4,1]='PARENTID'
lxFields[  4,2]='C'
lxFields[  4,3]=  9
lxFields[  4,4]=  0
lxFields[  5,1]='TIMESTAMP'
lxFields[  5,2]='T'
lxFields[  5,3]=  8
lxFields[  5,4]=  0
lxFields[  6,1]='SUBJECT'
lxFields[  6,2]='M'
lxFields[  6,3]=  4
lxFields[  6,4]=  0
lxFields[  7,1]='ATTACHMT'
lxFields[  7,2]='M'
lxFields[  7,3]=  4
lxFields[  7,4]=  0
lxFields[  8,1]='ATTACHNM'
lxFields[  8,2]='M'
lxFields[  8,3]=  4
lxFields[  8,4]=  0
lxFields[  9,1]='MESSAGE'
lxFields[  9,2]='M'
lxFields[  9,3]=  4
lxFields[  9,4]=  0
lxFields[ 10,1]='FROMNAME'
lxFields[ 10,2]='C'
lxFields[ 10,3]= 35
lxFields[ 10,4]=  0
lxFields[ 11,1]='FORUMID'
lxFields[ 11,2]='C'
lxFields[ 11,3]=  8
lxFields[ 11,4]=  0
lxFields[ 12,1]='FROMEMAIL'
lxFields[ 12,2]='M'
lxFields[ 12,3]=  4
lxFields[ 12,4]=  0
lxFields[ 13,1]='TO'
lxFields[ 13,2]='C'
lxFields[ 13,3]= 55
lxFields[ 13,4]=  0
lxFields[ 14,1]='FORUM'
lxFields[ 14,2]='C'
lxFields[ 14,3]= 35
lxFields[ 14,4]=  0
lxFields[ 15,1]='NOFORMAT'
lxFields[ 15,2]='L'
lxFields[ 15,3]=  1
lxFields[ 15,4]=  0
lxFields[ 16,1]='READ'
lxFields[ 16,2]='L'
lxFields[ 16,3]=  1
lxFields[ 16,4]=  0
lxFields[ 17,1]='PINNED'
lxFields[ 17,2]='L'
lxFields[ 17,3]=  1
lxFields[ 17,4]=  0
lxFields[ 18,1]='FORMAT'
lxFields[ 18,2]='I'
lxFields[ 18,3]=  4
lxFields[ 18,4]=  0

CREATE TABLE (lcFileName) FROM ARRAY lxFields


  USE
ENDIF

ENDFUNC
* CreateTable

*************************************************************
FUNCTION Reindex()
*************************************************************

IF THIS.nDataMode = 0
   IF !OpenExclusive(THIS.cDataPath + THIS.cFileName,THIS.cAlias)
      THIS.SetError("Unable to open Customer file due to exclusive use.")
      RETURN .F.
   ENDIF

   DELETE TAG ALL
   PACK

   INDEX ON threadid TAG threadid
   INDEX ON forum TAG forum
   INDEX ON userid TAG userid
   INDEX ON msgid TAG msgid
   INDEX ON timestamp TAG timestamp

   USE
ENDIF

RETURN .T.
ENDFUNC
* Reindex

ENDDEFINE
* wwt_message
