************************************************************************
* Project Build routine
****************************************
***  Function: Builds EXE, configures DCOM and optionally uploads
***            
***    Assume:
***      Pass:
***    Return:
************************************************************************
LPARAMETER llCopyToServer
LOCAL lcFile, lcTemplate, lcOLEFlag, lcNewFile

DO wwUtils


*** Configure these options to perform tasks automatically
EXE_FILE		  =		  	"Wwthreads"
DCOM_ProgId       =			"Wwthreads.WwthreadsServer"
DCOM_UserId		  =			"Interactive User"

*** Server Update Urls - fix these to point at your production Server/Virtual
HTTP_UPLOADURL    =         "http://support.west-wind.com/UploadExe.wc"
HTTP_UPDATEURL 	  =         "http://support.west-wind.com/UpdateExe.wc"

*** for ISAPI use this url
* HTTP_UPLOADURL    =         "http://localhost/Wwthreads/wc.wc?wwmaint~FileUpload"

*** Optional - User name to pre-seed username dialog
WEB_USERNAME     =         StrExtract(sys(0),"# ","")

*** Make sure classes is in the path
DO PATH WITH ".\classes"

SET PROCEDURE TO 
SET CLASSLIB TO

BUILD EXE (EXE_FILE) FROM (EXE_FILE) recompile

*** Released during build
DO wwHttp

IF FILE(EXE_FILE + ".err")
   MODIFY COMMAND (EXE_FILE + ".err")
   RETURN
ENDIF

DO DCOMCnfgServer with DCOM_PROGID, DCOM_USERID

IF llCopyToServer
   lcUserNameHttp = InputForm(PADR(WEB_USERNAME,15),"Http Username","Code Update")
   IF EMPTY(lcUsernameHttp)
      RETURN
   ENDIF
   
   lcPasswordHttp = GetPassword("Please enter your HTTP password") 
   IF EMPTY(lcPasswordHttp)
      RETURN
   ENDIF  
         
   WAIT WINDOW "Uploading file to server." + CHR(13) + ;
               "This could take a bit..." NOWAIT
   
   loHttp = CREATEOBJECT("wwHttp")
   IF !EMPTY(lcUsernameHttp)
       loHttp.cUsername = lcUsernameHttp
       loHttp.cPassword = lcPasswordHttp
   ENDIF
   loHttp.nHttpPostMode = 2
   loHttp.AddPostKey("File",FULLPATH(EXE_FILE + ".exe"),.T.)
   lcHtml = loHttp.HttpGet(HTTP_UPLOADURL)
   IF (loHttp.nError != 0) OR ATC("File has been uploaded",lcHtml) = 0
      MESSAGEBOX("Upload failed." + CHR(13) + ;
                 loHttp.cErrorMsg)
      RETURN
   ENDIF

   WAIT WINDOW "File upload completed..." nowait
   
   lcURL = InputForm(PADR(HTTP_UPDATEURL,100),"URL to update Exe","Update")
   
   wait window nowait "Updating Exe File on Web Server..."
   loHttp = CREATEOBJECT("wwHttp")
   lcHTML = loHttp.HTTPGet(lcUrl,lcUserNameHttp, lcPasswordHttp)
   
   wait clear
   IF !"Exe Updated" $ lcHTML
      ShowHTML(lchTML)
   ELSE
      MESSAGEBOX("Update completed",64,"Web Connection Server Code Update")
   ENDIF
ENDIF