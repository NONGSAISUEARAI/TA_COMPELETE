@echo off

REM ดึงชื่อโฟลเดอร์ที่ไฟล์ .bat อยู่
for %%i in ("%~dp0.") do set CurrentFolder=%%~nxi

REM สร้างโฟลเดอร์
mkdir "CAD" 2>nul
mkdir "PDF" 2>nul
exit
