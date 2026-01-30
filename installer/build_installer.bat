@echo off
setlocal
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%\.."

echo Building Windows release...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Flutter build failed.
    popd
    exit /b %ERRORLEVEL%
)

set "ISCC_PATH=%INNO_SETUP_PATH%"
if not defined ISCC_PATH set "ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "%ISCC_PATH%\" set "ISCC_PATH=%ISCC_PATH%\ISCC.exe"

if not exist "%ISCC_PATH%" (
    echo ISCC.exe not found at: %ISCC_PATH%
    echo Set INNO_SETUP_PATH to your Inno Setup folder or ISCC.exe path.
    popd
    exit /b 1
)

echo Building installer...
"%ISCC_PATH%" "%SCRIPT_DIR%ServiceIntervention.iss"
if %ERRORLEVEL% NEQ 0 (
    echo Inno Setup compilation failed.
    popd
    exit /b %ERRORLEVEL%
)

echo Installer created in installer\output
popd
exit /b 0
