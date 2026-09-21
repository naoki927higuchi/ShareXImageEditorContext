@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d "%~dp0"
cl /nologo /utf-8 /std:c++17 /EHsc /W4 /MT verify.cpp /Fodist\verify.obj /Fedist\verify.exe /link ole32.lib shell32.lib uuid.lib
if errorlevel 1 exit /b %errorlevel%
dist\verify.exe "%~dp0dist\Assets\Logo.png" "%~dp0README.md"
exit /b %errorlevel%
