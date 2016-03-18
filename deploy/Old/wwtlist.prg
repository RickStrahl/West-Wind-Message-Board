#INCLUDE WCONNECT.H

*** MessageXXXXXX.wwt (.t.)  or ShowMessage.wwt?Id=XXXXXX (.f.)
#DEFINE USE_EMBEDDED_MESSAGEID    !WWC_DEMO

*************************************************************
DEFINE CLASS wwThreadList AS Relation
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1997
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 10/01/97
***  Function: Responsible for creating the Message List
***            Creates TwwMsgList cursor with RunSQL().
*************************************************************
PROTECTED oHTML, cDownloadFileName

cFilter = ""
lAdmin = .F.
lDownload = .F.
cDownloadFileName = ""
*cCursorName = "TwwMsgList"

oHTML = .NULL.
oProcess = .NULL.
oUser = .NULL.

dFromDate = date() - 7
dToDate = date()
cForum = ""

cMode = ""

nMaxListSize = 500
cMessage = ""

************************************************************************
* wwThreadList :: Init
*********************************
***  Function: Assigns the local HTML object
***    Assume: If no HTML object is passed one is created. 
***            In that case use GetOutput() to retrieve the output.
***      Pass: loHTML  -   An HTML object to output to (Optional)
************************************************************************
FUNCTION Init
LPARAMETER loHTML

IF VARTYPE(loHTML)="O" 
  THIS.oHTML = loHTML
ELSE
  THIS.oHTML = CREATEOBJECT([WWC_RESPONSESTRING])
ENDIF
  
ENDFUNC
* wwThreadList :: Init

FUNCTION Open
LPARAMETERS lcPath

IF EMPTY(lcPath)
   lcPath = THIS.oProcess.cDataPath 
ELSE
   lcPath = ADDBS(lcPath)
ENDIF

IF !USED("wwthreads")
   USE (lcPath + "wwThreads") IN 0
ENDIF

SELECT wwThreads

ENDFUNC

************************************************************************
* wwThreadList :: AddDefaultFilter
*********************************
***  Function: Default Filter for 'standard' page requests
***    Assume: Looks at date and forum only
************************************************************************
FUNCTION AddDefaultFilter

THIS.AddDateFilter()
THIS.AddForumFilter()

ENDFUNC
* wwThreadList :: AddDefaultFilter


************************************************************************
* wwThreadList :: AddDateFilter
************************************
***  Function: Adds a date range to the query
***    Assume:
***      Pass: ldFromDate    -   Optional (THIS.dFromDate)
***            ldToDate          Optional (THIS.dToDate)
***            llAllowBlank  -   Determines whether blank input dates
***                              are converted to a 'real' date.
***                              Queries allow blanks.
************************************************************************
FUNCTION AddDateFilter
LPARAMETER ldFromDate, ldToDate, llAllowBlank

ldFromDate=IIF(vartype(ldFromDate)$"DT",ldFromDate,THIS.dFromDate)
ldToDate=IIF(vartype(ldToDate)$"DT",ldToDate,THIS.dToDate)

*** Set the display date in the text box
IF !llAllowBlank and EMPTY(ldFromDate)
   IF THIS.oUser.tLastOn < DATETIME() - 60
      ldFromDate=THIS.oUser.tLastOn
   ENDIF
   IF EMPTY(ldFromDate)
      ldFromDate=loUser.dListDate
   ENDIF
   IF EMPTY(ldFromDate)
      ldFromDate=DATE() - 2
   ENDIF
   THIS.dFromDate=ldFromdate
ENDIF
IF !llAllowBlank AND EMPTY(ldToDate)
   ldToDate=DATE()
   THIS.dToDate=ldToDate
ENDIF
IF EMPTY(ldFromDate) and EMPTY(ldToDate)
   RETURN
ENDIF   

IF VARTYPE(ldToDate) = "D"
	ldToDate = DTOT(ldToDate)
ENDIF
ldToDate=ldToDate + 86400

THIS.cFilter=THIS.cFilter + "AND (Pinned OR (TIMESTAMP >= "+ TimeToCStrict(ldFromDate)+;
                            " AND TIMESTAMP <= "+TimeToCStrict( ldToDate) + ")) " 

ENDFUNC
* wwThreadList :: AddDateFilter

************************************************************************
* wwThreadList :: AddForumFilter
*********************************
***  Function: Add a forum to the filter string
************************************************************************
FUNCTION AddForumFilter
LPARAMETERS lcForum

lcForum=IIF(!EMPTY(lcForum),lcForum,THIS.cForum)

THIS.cFilter = THIS.cFilter + "AND wwThreads.FORUM=wwt_forums.ForumName and !wwt_forums.NoDownload "

*** Show Everything
IF EMPTY(lcForum) OR lcForum = "All Forums"
  RETURN
ENDIF  

THIS.cFilter = THIS.cFilter + " AND wwThreads.Forum = [" + lcForum +"] "
                           
ENDFUNC
* wwThreadList :: AddForumFilter


************************************************************************
* wwThreadList :: AddCustomFilter
*********************************
***  Function: Adds a custom filter item to the existing filter
************************************************************************
FUNCTION AddCustomFilter
LPARAMETERS lcFilter, llOr

IF EMPTY(lcFilter)
   RETURN
ENDIF   

IF !llOr
  THIS.cFilter = THIS.cFilter + "AND " + lcFilter + " "
ELSE
  THIS.cFilter = THIS.cFilter + "OR " + lcFilter + " "
ENDIF    

ENDFUNC
* wwThreadList :: AddCustomFilter


************************************************************************
* wwThreadList :: RunSQL
*********************************
***  Function: Run the SQL statement to generate TwwMsgList cursor
***            based on the Filter specified.
***      Pass: lcWhere    -   A Complete WHERE clause for SQL statement
***    Return: Query Record Count
************************************************************************
PROCEDURE RunSQL
LPARAMETER lcWhere, lnTime, lnTemp

IF !EMPTY(this.cMessage)
   RETURN 0
ENDIF   

lcWhere=IIF(empty(lcWhere),THIS.cFilter,lcWhere)

*** Fix up into full where statement
IF !EMPTY(lcWhere)
  *** Strip off AND/OR
  DO CASE 
  CASE LEFT(lcWhere,4) = "AND "
     lcWhere = SUBSTR(lcWhere, 4)
  CASE LEFT(lcWhere,3) = "OR "
     lcWhere = SUBSTR(lcWhere, 3)
  ENDCASE
  
	*** Do a filter check first before retrieving data
	IF !USED("wwthreads")
	   USE (THIS.oProcess.cDataPath + "wwthreads") IN 0
	ENDIF
	SELECT wwThreads
	lnTime = SECONDS()
	COUNT FOR &lcWhere to lnTemp
	IF SECONDS() - lnTime > 5 or lnTemp > 2000
	   RETURN -1
	ENDIF
   
   lcWhere = "WHERE " + lcWhere
ELSE
   RETURN -1
ENDIF

SELECT  fromname,  subject, TIMESTAMP, threadid, Msgid, IIF(THIS.lDownLoad,Message,"") as Message, ;
        Forum, Pinned, threadid + TRANSFORM(pinned) as ComputedSortOrder  ;
   FROM (THIS.oProcess.cDataPath + "wwThreads"),(THIS.oProcess.cDataPath + "wwt_forums")  ;
   ORDER BY Forum, ComputedSortorder DESC,  TIMESTAMP ;
   &lcWhere ;
   INTO CURSOR TwwMsgList
   

IF THIS.lDownload
   THIS.cDownloadFileName = THIS.oProcess.CreateZip()
   RETURN _TALLY
ENDIF   

RETURN _Tally   
* RunSQL

************************************************************************
* wwThreadList :: BuildList
*********************************
***  Function: Actually creates the HTML output for the list
***    Assume: Output sent to HTML object
************************************************************************
FUNCTION BuildList
LOCAL lnRecCount, lcThreadID, lcForum, lcTimeStamp, lcName

* THIS.oHTML.Send(THIS.cFilter + "<p>")

IF THIS.lDownload
   THIS.oHTML.Write([<div class="errormessage">]+;
   THIS.oHTML.Href(JustFname(THIS.cDownloadFileName),"Download Messages",.T.)+;
   [</div>]+CRLF )
ENDIF


lnReccount = RECCOUNT()
DO CASE
CASE !EMPTY(this.cMessage)
   this.oHtml.Write([<div class="errormessage">] + ;
       this.cMessage + "</div>" + CRLF)       
CASE lnReccount > This.nMaxListSize
   THIS.oHTML.Write([<div class="errormessage">]+;
      [The query was too complex or returned too many records</b><br />] +;
      [<small>Records returned: ] + TRANSFORM(lnRecCount) +  [</small><p>] + ;
      [<b>Please make sure you simplify the query or limit the date range.] +;
      [<div>]+CRLF)
CASE lnReccount > 0
   lcThreadId="xx"
   lcForum = "xx"
   
   SCAN
      lcTimeStamp=lower(TTOC(TwwMsgList.TIMESTAMP))
      lcName=TwwMsgList.fromname


      IF NOT TwwMsgList.Forum == m.lcForum
        IF lcForum != "xx"
        	*** Write closing Div for forum container
        	this.oHtml.Write([	</div>] + CRLF)
        ENDIF
      
       * Write out a new forum name
        THIS.oHTML.Write(;
				CRLF + CRLF +;
				[	<div class="threadforumheader">]  + ;
				[<span>-</span> ] + ;
				TRIM(TwwMsgList.Forum) + ;
				[</div>]  + CRLF +;
				[	<div class="threadforumcontent">] + CRLF) 
      ENDIF      

      IF NOT TwwMsgList.threadid == lcThreadId 
      	IF lcThreadID # "xx"
          *** End of this thread - end of grouping via table
          this.oHtml.Write( CRLF)
          * THIS.oHTML.Write("	</div>" + CRLF)  
        ENDIF

		*** Thread Header
        THIS.oHTML.Write([	<div class="threadheader" title="Click to show entire thread" onclick="gt('] + TwwMsgList.ThreadId + [')">]  + CRLF + [		] +  TRIM(TwwMsgList.subject) + CRLF + [	</div>] + CRLF)
	  ENDIF


      *** Thread Detail
	  THIS.oHTML.Write(;
		[	<div class="threaddetail" data-id="] + TRIM(TwwMsgList.MsgId) +[" onclick="gm('] + TRIM(TwwMsgList.MsgId) + [')">] +;
		IIF(TwwMsgList.Pinned,[<div class="pinned"></div>] + CRLF,[]) +;
		[<a href="Message] + TwwMsgList.Msgid + [.wwt" target="Message">] + TRIM(lcName) + [</a><br />]  +;
		lcTimeStamp +;
		[	</div>]  + CRLF )
      
      lcThreadId=TwwMsgList.threadid
      lcForum = TwwMsgList.Forum
   ENDSCAN


   *** write out the close for the forum group
   IF lcForum != "xx"
	   this.oHtml.Write([	</div>] + CRLF)
   ENDIF
	
   *** Thread list display footer
OTHERWISE
   THIS.oHTML.Write([<div class="errormessage">]+;
      [No Messages posted since<br />]+ DTOC(THIS.dFromDate)+[!</div>]+CRLF)
ENDCASE


ENDPROC
* wwThreadList :: BuildList

************************************************************************
* wwThreadList :: GetOutput
*********************************
***  Function: Returns output string of an wwResponseString object.
***    Assume: Should only be called if an wwResponse object was not 
***            passed to the Init
************************************************************************
PROCEDURE GetOutput
RETURN THIS.oHTML.GetOutput()
* wwThreadList :: Getoutput

ENDDEFINE


