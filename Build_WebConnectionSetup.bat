set live=c:\webconnectionprojects\wwthreads
set src=c:\webconnection\fox\samples\wwthreads

robocopy %live%\deploy %src%\deploy /MIR
robocopy %live%\web %src%\web /MIR

deletefiles %src%\*.fxp -r
deletefiles %src%\web\*.prg -r
deletefiles %src%\web\postimages -r -f

deletefiles %src%\*.bak -r
deletefiles %src%\*.tbk -r

deletefiles %src%\deploy\old\*.* -r -f
rd %src%\deploy\old

del %src%\deploy\*.dbf
del %src%\deploy\*.fpt
del %src%\deploy\*.cdx

del %src%\deploy\tests\*.* /q
rd %src%\deploy\tests
del %src%\deploy\temp\*.* /q
del %src%\deploy\wwthreads.vbr
del %src%\deploy\wwthreads.tlb

del %src%\deploy\wwthreads_update.exe

del %src%\deploy\data\*.* /q
copy %live%\Templates\EmptyData\*.* %src%\deploy\data

copy %live%\Templates\*.* %src%\deploy


pause