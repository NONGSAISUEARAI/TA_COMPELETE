@echo off
setlocal EnableDelayedExpansion

set /p ST=Input station no: 
set /p N=Input drawing no: 



rem ===== ตั้งค่า prefix ตรงนี้ =====
set PREFIX=W-1-PP!ST!-AR-
set SUBFIX=-01-A
rem ================================

for %%F in (*) do (
    if /I not "%%~nxF"=="%~nx0" (
        ren "%%F" "!PREFIX!!N!!SUBFIX!%%~xF"
        set /a N+=1
    )
)

echo sed law
pause
