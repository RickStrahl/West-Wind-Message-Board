SET PROCEDURE TO wwBusinessObject ADDITIVE
SET PROCEDURE TO wwUtils ADDITIVE
SET PROCEDURE TO wwt_user.prg ADDITIVE

*************************************************************
DEFINE CLASS wwt_user AS wwBusinessObject
*************************************************************

cAlias = "wwusers"
cDataPath = ""
cFileName = "wwusers"

cPkField = "CookieId"
cIdTable = "wwt_id.dbf"

*** Sql Connection String
cConnectString = ""

*** 0 - fox 2 - Sql 4-Web
nDataMode = 0


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
*   CreateNewId

************************************************************************
*  Save
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Save()
this.oData.Email = LOWER(TRIM(this.oData.Email))
RETURN DODEFAULT()
ENDFUNC
*   Save


************************************************************************
*  LoadFromEmail
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadFromEmail(lcEmail)
PRIVATE pcEmail
pcEmail = LOWER(lcEmail)
RETURN this.LoadBase("Email == ?pcEmail")
ENDFUNC
*   LoadFromEmail

************************************************************************
*  Authenticate
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION AuthenticateAndLoad
PARAMETERS lcEmail, lcPassword

IF EMPTY(lcEmail) OR EMPTY(lcPassword)
	this.SetError("Empty username or password is not supported")
	RETURN .F.
ENDIF

lcUsername = LOWER(lcEmail)

IF !this.LoadBase("Email == ?lcEmail AND Password == ?lcPassword")
  this.SetError("Invalid username or password")
  RETURN .F.
ENDIF 

RETURN .T.
ENDFUNC
*   Authenticate


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

IF EMPTY(this.oData.Name)
   THIS.AddValidationError("Name can't be left empty.","Name")   
ENDIF
IF EMPTY(this.oData.Email)
   THIS.AddValidationError("Email can't be left empty.","Email")   
ENDIF
IF EMPTY(this.oData.Password) OR LEN(this.oData.Password) < 5
   THIS.AddValidationError("Password can't be left empty and must be at least 5 characters in length.","Password")   
ENDIF

*** if new
IF this.nUpdateMode = 2
   this.Open()
   LOCATE FOR Email == LOWER(this.oData.Email)
   IF FOUND()
   	  this.AddValidationError("User account already exists. Please log in using that account or try to recover your password.","Email")
   ENDIF
ENDIF

IF this.oValidationErrors.Count > 0
   this.cErrorMsg = this.oValidationErrors.ToString()
   RETURN .F.
ENDIF   

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

*** Generated on: 2016/03/09
DIMENSION lxFields[ 14,4]

lxFields[  1,1]='COOKIEID'
lxFields[  1,2]='C'
lxFields[  1,3]=  8
lxFields[  1,4]=  0
lxFields[  2,1]='NAME'
lxFields[  2,2]='C'
lxFields[  2,3]= 45
lxFields[  2,4]=  0
lxFields[  3,1]='LASTON'
lxFields[  3,2]='T'
lxFields[  3,3]=  8
lxFields[  3,4]=  0
lxFields[  4,1]='EMAIL'
lxFields[  4,2]='V'
lxFields[  4,3]=128
lxFields[  4,4]=  0
lxFields[  5,1]='FORUM'
lxFields[  5,2]='C'
lxFields[  5,3]= 30
lxFields[  5,4]=  0
lxFields[  6,1]='LISTDATE'
lxFields[  6,2]='D'
lxFields[  6,3]=  8
lxFields[  6,4]=  0
lxFields[  7,1]='FILTER'
lxFields[  7,2]='M'
lxFields[  7,3]=  4
lxFields[  7,4]=  0
lxFields[  8,1]='SIGNATURE'
lxFields[  8,2]='M'
lxFields[  8,3]=  4
lxFields[  8,4]=  0
lxFields[  9,1]='VARS'
lxFields[  9,2]='M'
lxFields[  9,3]=  4
lxFields[  9,4]=  0
lxFields[ 10,1]='USERNAME'
lxFields[ 10,2]='C'
lxFields[ 10,3]= 20
lxFields[ 10,4]=  0
lxFields[ 11,1]='PASSWORD'
lxFields[ 11,2]='C'
lxFields[ 11,3]= 40
lxFields[ 11,4]=  0
lxFields[ 12,1]='ADMIN'
lxFields[ 12,2]='N'
lxFields[ 12,3]=  1
lxFields[ 12,4]=  0
lxFields[ 13,1]='USEDREADER'
lxFields[ 13,2]='L'
lxFields[ 13,3]=  1
lxFields[ 13,4]=  0
lxFields[ 14,1]='WEBSITE'
lxFields[ 14,2]='M'
lxFields[ 14,3]=  4
lxFields[ 14,4]=  0

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
   
   DELETE FOR EMPTY(NAME)

   PACK
   INDEX ON CookieId TAG CookieId
   INDEX ON Email TAG Email   

   USE
ENDIF
ENDFUNC
* Reindex

ENDDEFINE
* wwt_user
