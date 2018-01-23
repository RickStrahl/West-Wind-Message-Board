echo off

REM Make sure you run this as an Administrator
cd %~dp0deploy
echo %~dp0
c:\wconnect\console "LAUNCHIISEXPRESS" "%~dp0web" 8081


start http://localhost:8081/

wwThreads.exe
