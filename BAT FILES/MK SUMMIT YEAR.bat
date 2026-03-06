@echo off

REM current folder
for %%i in ("%~dp0.") do set F0=%%~nxi

REM parent 1
for %%i in ("%~dp0..") do set F1=%%~nxi

REM parent 2
for %%i in ("%~dp0..\..") do set F2=%%~nxi

REM parent 3
for %%i in ("%~dp0..\..\..") do set F3=%%~nxi

REM รวมชื่อ
set FolderName=%F3%_%F2%_%F1%_%F0%

echo Result = %FolderName%

REM ตัวอย่างเอาไปสร้างโฟลเดอร์
mkdir "%FolderName%_2025" 2>nul
mkdir "%FolderName%_2026" 2>nul
mkdir "%FolderName%_2027" 2>nul

exit
