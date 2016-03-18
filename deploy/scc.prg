*** Generates SCC XML files from project and vcx,scx and mnx files
*** Uses Christof Wollenhaupt's TwoFox tools to two way convert
*** http://www.foxpert.com/downloads.htm

*** Pass a parameter of .T. to restore from XML files
*** back to vcx,scx,mnx etc.
LPARAMETERS llToCode

IF !llToCode
    CLOSE ALL
    SET CLASSLIB TO 
	DO GENXML WITH "Wwthreads.pjx"
ELSE
    DO GENCODE WITH "Wwthreads.twofox"
ENDIF


