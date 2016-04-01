echo off

REM Make sure you run this as an Administrator
cd %~dp0\deploy
wwThreads "CONFIG"


echo "Press any key once the configuration has completed."
echo "This will open the Message Board Web Page on http://localhost/wwthreads/"
echo "and start the wwThreads.exe server."

pause

start http://localhost/wwthreads/

wwThreads.exe
