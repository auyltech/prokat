@echo off
setlocal
cd /d "%~dp0"

flutter build appbundle --release --dart-define-from-file=.env
exit /b %ERRORLEVEL%
