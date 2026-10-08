@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"

echo.
echo ==========================================
echo Samaritan - Full Deployment
echo ==========================================
echo.

call "%SCRIPT_DIR%create-build.bat"
if errorlevel 1 (
    echo.
    echo ==========================================
    echo Build stage failed.
    echo Deployment stopped.
    echo ==========================================
    exit /b 1
)

call "%SCRIPT_DIR%build-upload.bat"
if errorlevel 1 (
    echo.
    echo ==========================================
    echo Server deployment failed.
    echo ==========================================
    exit /b 1
)

echo.
echo ==========================================
echo Samaritan deployment complete.
echo ==========================================
echo.

exit /b 0