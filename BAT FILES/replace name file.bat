@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ===== รับค่าจากผู้ใช้ =====
set /p OLD=Input OLD text : 
set /p NEW=Input NEW text : 

echo.
echo Replace "%OLD%" -> "%NEW%"
echo.

:: ===== loop ทีละไฟล์ =====
for %%F in (*) do (
    if /I not "%%~nxF"=="%~nx0" (
        set "FILENAME=%%~nF"
        set "EXT=%%~xF"

        echo Processing: %%~nxF

        :: substitute ชื่อไฟล์
        set "NEWNAME=!FILENAME:%OLD%=%NEW%!!EXT!"

        ren "%%F" "!NEWNAME!"
    )
)

echo.
echo === DONE ===
pause