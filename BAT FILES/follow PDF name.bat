@echo off
setlocal EnableDelayedExpansion

set i=0

for %%p in (*.pdf) do (
    set /a i+=1
    call :rename "%%~np"
)

echo Done
pause
exit /b

:rename
set name=%~1
set j=0

for %%d in (*.dwg) do (
    set /a j+=1
    if !j! == %i% ren "%%d" "%name%.dwg"
)

exit /b