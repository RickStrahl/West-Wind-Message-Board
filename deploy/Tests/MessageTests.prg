**********************************************************************
DEFINE CLASS MessageTests as FxuTestCase OF FxuTestCase.prg
**********************************************************************

#IF .F.
   LOCAL THIS as MessageTests in MessageTests.prg
#ENDIF
	
	********************************************************************
	FUNCTION Setup
	*****************************************************************
	
	SET ENGINEBEHAVIOR 70
	DO wconnect
	DO ..\load_libs
	

	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION TearDown
	********************************************************************

	********************************************************************
	ENDFUNC
	********************************************************************	

************************************************************************
*  GetMessageList
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetMessageList()

loMsgBus = CREATEOBJECT("wwt_message")
lnResult = loMsgBus.GetThreads()

THIS.AssertTrue(lnResult > 0,"No threads found")

this.Messageout(TRANSFORM(lnResult) + " threads")
this.MessageOut(loMsgBus.cErrorMsg)
ENDFUNC
*   GetMessageList

************************************************************************
*  GetThreadMessages
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetThreadMessages()

lcThreadid = "4KX0QIWGZ"

loMsgBus = CREATEOBJECT("wwt_Message")
lnResult = loMsgBus.GetThreadMessages(lcThreadId)

this.AssertTrue(lnResult > 0,"results returned")

ENDFUNC
*   GetThreadMessages

************************************************************************
*  GetForumList
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetForumList()

loMsgBus = CREATEOBJECT("wwt_Message")
lnResult = loMsgBus.GetForumList()
this.AssertTrue(lnResult > 0,"results returned")
this.MessageOut(TRANSFORM(lnResult))

ENDFUNC
*   GetForumList


************************************************************************
*  Function RenderMessage
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION RenderMessage()
LOCAL lcOutput, loMsgBus

loMsgBus = CREATEOBJECT("wwt_Message")
lcThreadid = "4KX0QIWGZ"
lcOutput = loMsgBus.RenderMessage(lcThreadId)

THIS.MessageOut(lcOutput)

ENDFUNC
*   Function RenderMessage

************************************************************************
*  AuthenticateAndLoadUser
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION AuthenticateAndLoadUser(l)

loUserBus = CREATEOBJECT("wwt_user")
llResult = loUserBus.AuthenticateAndLoad("rstrahl@west-wind.com","ww")

this.AssertTrue(llResult,"Load failed")
this.MessageOut(loUserBus.oData.Name)

ENDFUNC
*   AuthenticateAndLoadUser

**********************************************************************
ENDDEFINE
**********************************************************************
