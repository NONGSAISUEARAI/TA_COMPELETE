@echo off
setlocal EnableDelayedExpansion

for %%F in (*2025*) do (
    set "oldname=%%F"
    set "newname=!oldname:2025=2026!"
    ren "%%F" "!newname!"
)

echo Done.
pause