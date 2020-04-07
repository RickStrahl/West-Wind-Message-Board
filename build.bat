REM assumes you have 7zip (7z.exe) in your path 
REM to build the final zip file. Otherwise you can
REM manually zip uo the contents of the build folder

echo off

REM Your Web Connection Install Path
set src="C:\WEBCONNECTION\FOX"

REM The Project Path
set tgt="c:\WebConnectionProjects\wwThreads"
set appname="wwThreads"


REM Remove the Build folder
rd %tgt%\build /s /q

REM force to current path even when running as Admin
md %tgt%\build
md %tgt%\build\deploy
cd %tgt%\build\deploy


REM  copy EXE and config file and IIS Install
copy %tgt%\deploy\%appname%.exe
copy %tgt%\deploy\%appname%.ini
copy %tgt%\deploy\config.fpw
copy %tgt%\deploy\install-iis-features.ps1 

REM copy Web Connection DLLs from WWWC install
copy %src%\*.dll

REM change back to build folder
cd %tgt%\build

REM Copy data and Web Folders
REM Comment if you don't want to package those
robocopy %tgt%\data data /MIR
robocopy %tgt%\web web /MIR
robocopy %tgt%\WebConnectionWebServer WebConnectionWebServer /MIR

REM Deployed apps shouldn't have prg/fxp files
REM Let them re-compile on the server
del /s web\*.bak 
del /s web\*.fxp
del /s web\*.prg

REM add 7zip to your path or in this folder for this to work
7z a -r %appname%_Packaged.zip *.*

pause