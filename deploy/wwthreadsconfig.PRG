*************************************************************
DEFINE CLASS wwThreadsConfig AS wwConfig
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 20016
*:Contact: http://www.west-wind.com
*:Created: 3/11/2016
*************************************************************

cFileName = "wwThreadsConfig.ini"
cMode = "INI"
cSubName = "wwThreads"

cApplicationName = "Wind Message Board"
cCompanyName = "West Wind Technologies"

nDefaultMessageDays = 10

*** The data connection mode
nDataMode = 0

************************************************************************
*  Destrory
****************************************
FUNCTION Destroy()
this.Save()
ENDFUNC
*   Destroy

ENDDEFINE
*EOC ttConfig 