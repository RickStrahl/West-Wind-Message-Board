*** Override file for wconnect.h. Called from
*** wconnect.h
***
*** This file is not overridden by updates
*** while wconnect.h is...

*** Common things you might want to set here
*!*	#UNDEFINE WWC_USE_SQL_SYSTEMFILES    
*!*	#DEFINE WWC_USE_SQL_SYSTEMFILES     .F.

*!*	#UNDEFINE SERVER_IN_DESKTOP
*!*	#DEFINE SERVER_IN_DESKTOP			.F.

*!*	#UNDEFINE DEFAULT_HTTP_VERSION
*!*	#DEFINE DEFAULT_HTTP_VERSION		"1.1"

*** If you don't use Web Controls uncomment this
*!* #UNDEFINE WWC_LOAD_WEBCONTROLS
*!* #DEFINE WWC_LOAD_WEBCONTROLS			.F.

*** If you use Old (v4 and older) Response class methods
*** enables Form methods, HttpHeader etc.
*!* #UNDEFINE INCLUDE_LEGACY_RESPONSEMETHODS
*!* #DEFINE INCLUDE_LEGACY_RESPONSEMETHODS  .T.