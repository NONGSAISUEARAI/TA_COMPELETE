@echo off

REM ดึงชื่อโฟลเดอร์ที่ไฟล์ .bat อยู่
for %%i in ("%~dp0.") do set CurrentFolder=%%~nxi

REM สร้างโฟลเดอร์
mkdir "%CurrentFolder%_RCL" 2>nul
mkdir "%CurrentFolder%_F&H" 2>nul
mkdir "%CurrentFolder%_STAIR" 2>nul
exit
