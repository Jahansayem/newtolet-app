@echo off
setlocal
cd /d "%~dp0\.."
flutter build apk --release --split-per-abi
echo.
echo Split APKs generated in build\app\outputs\flutter-apk
