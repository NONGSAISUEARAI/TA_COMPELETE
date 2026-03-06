@echo off
chcp 65001 >nul
setlocal

REM ===== ชื่อโฟลเดอร์ปัจจุบัน =====
for %%i in ("%~dp0\..\..\..") do set FolderName=%%~nxi

REM ===== ไฟล์ output =====
set OutputFile=Z_email_draft.txt

REM ===== เขียนหัวอีเมล =====
(
echo เรียนคุณ ทรงยศ ปวุฒิพันธุ์ และ คุณ รสสุคนธ์ แก้วแสนวงศ์
echo.
echo ขอนำส่ง %FolderName%
) > "%OutputFile%"

REM ===== ใช้ PowerShell นับไฟล์ =====
for /f %%c in ('
  powershell -NoProfile -Command "(Get-ChildItem -File).Count"
') do set FileCount=%%c

set /a FileCount-=2
if %FileCount% LSS 0 set FileCount=0

REM ===== เขียนจำนวนไฟล์ =====
(
echo จำนวนไฟล์แนบ %FileCount% ไฟล์
echo.
) >> "%OutputFile%"

REM ===== ใช้ PowerShell เขียนรายชื่อไฟล์ (Unicode) =====
powershell -NoProfile -Command ^
  "Get-ChildItem -File | ForEach-Object { $_.Name }" >> "%OutputFile%"

REM ===== เปิดดู =====
notepad "%OutputFile%"