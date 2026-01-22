@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Running flutter pub get...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Error running flutter pub get
    pause
    exit /b %ERRORLEVEL%
)
echo.
echo Generating Hive adapters...
flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo Error running build_runner
    pause
    exit /b %ERRORLEVEL%
)
echo.
echo Done! You can now run your Flutter app.
pause
