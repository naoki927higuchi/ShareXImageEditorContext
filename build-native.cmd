@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d "%~dp0"
if not exist dist mkdir dist
cl /nologo /utf-8 /std:c++17 /EHsc /W4 /MT /LD Command.cpp /Fodist\Command.obj /Fedist\ShareXCommand.dll /link /DEF:Command.def ole32.lib shlwapi.lib advapi32.lib runtimeobject.lib
exit /b %errorlevel%
