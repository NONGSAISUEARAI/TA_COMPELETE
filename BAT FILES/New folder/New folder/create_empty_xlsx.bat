@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

title Create empty XLSX file

:ASK_NUMBER
cls
echo ================================================================
echo Create an empty XLSX file
echo Example: enter 35 to create document number IT3-M3-2026-0035
echo ================================================================
echo.
set "DOC_INPUT="
set /p "DOC_INPUT=Enter document number (0-9999): "

if not defined DOC_INPUT (
    echo.
    echo No number was entered. Please try again.
    pause
    goto ASK_NUMBER
)

for /f "delims=0123456789" %%A in ("!DOC_INPUT!") do (
    echo.
    echo Invalid input. Numbers only are allowed.
    pause
    goto ASK_NUMBER
)

if not "!DOC_INPUT:~4,1!"=="" (
    echo.
    echo Invalid input. Enter a number from 0 to 9999.
    pause
    goto ASK_NUMBER
)

set "PADDED=0000!DOC_INPUT!"
set "PADDED=!PADDED:~-4!"
set "FILE_NAME=IT3-M3-2026-!PADDED!_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PURPLE LINE  4STATION (PP17 - PP20) C10 MOCKUP PP18.xlsx"
set "TARGET=%~dp0!FILE_NAME!"

echo.
echo File to create:
echo !FILE_NAME!
echo.
choice /c YN /n /m "Create this file? [Y/N]: "
if errorlevel 2 (
    echo.
    echo Cancelled. No file was created.
    pause
    exit /b 0
)

if exist "!TARGET!" (
    echo.
    echo The file already exists. It was not overwritten.
    echo !TARGET!
    pause
    exit /b 1
)

type nul > "!TARGET!"
if errorlevel 1 (
    echo.
    echo Could not create the file.
    pause
    exit /b 1
)

echo.
echo File created successfully:
echo !TARGET!
echo.
echo Note: This is a zero-byte placeholder with an XLSX extension.
pause
exit /b 0
