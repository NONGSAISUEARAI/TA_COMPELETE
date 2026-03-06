@echo off

REM current folder
for %%i in ("%~dp0.") do set F0=%%~nxi

REM parent 1
for %%i in ("%~dp0..") do set F1=%%~nxi

REM parent 2
for %%i in ("%~dp0..\..") do set F2=%%~nxi

REM รวมชื่อ
set FolderName=%F2%_%F1%_%F0%

echo Result = %FolderName%

REM ตัวอย่างเอาไปสร้างโฟลเดอร์
mkdir "%FolderName%_TA_EDIT-FOR_CKST" 2>nul


exit
