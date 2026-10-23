@echo off
setlocal
cd /d "%~dp0"
set "FACADE_NODE=C:\Users\popul\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
if not exist "%FACADE_NODE%" (
  echo Node.js was not found at:
  echo %FACADE_NODE%
  pause
  exit /b 1
)
if not exist "%~dp0server.mjs" (
  echo server.mjs was not found. Keep this BAT file in the Facade Studio folder.
  pause
  exit /b 1
)
echo Facade Studio: http://127.0.0.1:4173/
echo Keep this window open while using Facade Studio.
echo Press Ctrl+C to stop the server.
echo.
rem Wait until the server responds, then open the default browser.
start "" /b powershell.exe -NoProfile -WindowStyle Hidden -Command "for ($attempt=0; $attempt -lt 30; $attempt++) { try { $response=Invoke-WebRequest -Uri 'http://127.0.0.1:4173/' -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop; if ($response.StatusCode -eq 200) { Start-Process 'http://127.0.0.1:4173/'; exit } } catch {}; Start-Sleep -Milliseconds 500 }"
"%FACADE_NODE%" "%~dp0server.mjs"
echo.
echo Server stopped or could not start. See the message above.
pause
endlocal

