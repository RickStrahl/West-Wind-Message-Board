SET CLASSLIB TO wwBusiness ADDITIVE
SET CLASSLIB TO wwUtils ADDITIVE
SET PROCEDURE TO wwCollections ADDITIVE
SET PROCEDURE TO wwt_user.prg ADDITIVE

*************************************************************
DEFINE CLASS wwt_user AS wwbusiness
*************************************************************

cAlias = "wwusers"
cDataPath = ".\data\"
cFileName = "wwusers"

cPkField = "CookieId"
cIdTable = ".\data\wwt_id.dbf"

*** Sql Connection String
cConnectString = ""

*** 0 - fox 2 - Sql 4-Web
nDataMode = 0


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
lcPassword = LOWER(lcPassword)

IF !this.LoadBase("Email == ?lcEmail AND Password == ?lcPassword")
  this.SetError("Invalid username or password")
  RETURN .F.
ENDIF 

RETURN .T.
ENDFUNC
*   Authenticate


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
   PACK



   USE
ENDIF
ENDFUNC
* Reindex

ENDDEFINE
* wwt_user
