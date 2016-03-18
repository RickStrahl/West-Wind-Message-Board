**********************************************************************
DEFINE CLASS MessageTests as FxuTestCase OF FxuTestCase.prg
**********************************************************************
	#IF .f.
	*
	*  this LOCAL declaration enabled IntelliSense for
	*  the THIS object anywhere in this class
	*
	LOCAL THIS AS MessageTests OF MessageTests.PRG
	#ENDIF
	
	*  
	*  declare properties here that are used by one or
	*  more individual test methods of this class
	*
	*  for example, if you create an object to a custom
	*  THIS.Property in THIS.Setup(), estabish the property
	*  here, where it will be available (to IntelliSense)
	*  throughout:
	*
*!*		ioObjectToBeTested = .NULL.
*!*		icSetClassLib = SPACE(0)


	* the icTestPrefix property in the base FxuTestCase class defaults
	* to "TEST" (not case sensitive). There is a setting on the interface
	* tab of the options form (accessible via right-clicking on the
	* main FoxUnit form and choosing the options item) labeld as
	* "Load and run only tests with the specified icTestPrefix value in test classes"
	*
	* If this is checked, then only tests in any test class that start with the
	* prefix specified with the icTestPrefix property value will be loaded
	* into FoxUnit and run. You can override this prefix on a per-class basis.
	*
	* This makes it possible to create ancillary methods in your test classes
	* that can be shared amongst other test methods without being run as
	* tests themselves. Additionally, this means you can quickly and easily 
	* disable a test by modifying it and changing it's test prefix from
	* that specified by the icTestPrefix property
	
	* Additionally, you could set this in the INIT() method of your derived class
	* but make sure you dodefault() first. When the option to run only
	* tests with the icTestPrefix specified is checked in the options form,
	* the test classes are actually all instantiated individually to pull
	* the icTestPrefix value.

*!*		icTestPrefix = "<Your preferred prefix here>"
	
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
	*
	*  put common cleanup code here -- this method is called
	*  whenever THIS.Run() (inherited method) to run each
	*  of the custom test methods you add, specific test
	*  methods that are not inherited from FoxUnit
	*
	*  do NOT call THIS.Assert..() methods here -- this is
	*  NOT a test method
	*
    *  for example, you can release  all the object(s)
    *  you will be testing by the custom test methods of 
    *  this class:
*!*	    THIS.ioObjectToBeTested = .NULL.
*!*		LOCAL lcSetClassLib
*!*		lcSetClassLib = THIS.icSetClassLib
*!*		SET CLASSLIB TO &lcSetClassLib        

	********************************************************************
	ENDFUNC
	********************************************************************	

	*
	*  test methods can use any method name not already used by
	*  the parent FXUTestCase class
	*    MODIFY COMMAND FXUTestCase
	*  DO NOT override any test methods except for the abstract 
	*  test methods Setup() and TearDown(), as described above
	*
	*  the three important inherited methods that you call
	*  from your test methods are:
	*    THIS.AssertTrue("Failure message",<Expression>)
	*    THIS.AssertEquals("Failure message",<ExpectedValue>,<Expression>)
	*    THIS.AssertNotNull("Failure message",<Expression>)
	*  all test methods either pass or fail -- the assertions
	*  either succeed or fail
    
	*
	*  here's a simple AssertNotNull example test method
	*
*!*		*********************************************************************
*!*		FUNCTION TestObjectWasCreated
*!*		*********************************************************************
*!*		THIS.AssertNotNull(THIS.ioObjectToBeTested, ;
*!*			"Object was not instantiated during Setup()")
*!*		*********************************************************************
*!*		ENDFUNC
*!*		*********************************************************************

	*
	*  here's one for AssertTrue
	*



	*
	*  and one for AssertEquals
	*
*!*		*********************************************************************
*!*		FUNCTION TestObjectCustomMethod100ReturnValue 
*!*		*********************************************************************
*!*
*!*		* Please note that string Comparisons with AssertEquals are
*!*		* case sensitive. 
*!*
*!*		THIS.AssertEquals("John Smith", ;
*!*			            THIS.ioObjectToBeTested.Object.CustomMethod100(), ;
*!*			            "Object.CustomMethod100() did not return 'John Smith'",
*!*		*********************************************************************
*!*		ENDFUNC
*!*		*********************************************************************

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
