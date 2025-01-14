@echo off
set DIR=%~dp0
set CWD=%cd%
rem echo "%DIR%"
rem echo "%CWD%"
cd "%DIR% 
lua.exe src/main.lua zbstudio -cwd "%CWD%" %*
