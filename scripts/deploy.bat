@echo off
setlocal

set "ROOT=%~dp0"

echo.
echo ==========================================
echo Samaritan - Full Deployment
echo ==========================================
echo.

call "%ROOT%create-build.bat"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo Build stage failed.
    echo Deployment stopped.
    echo ==========================================
    exit /b 1
)

call "%ROOT%build-upload.bat"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo Server deployment failed.
    echo ==========================================
    exit /b 1
)

echo.
echo ==========================================
echo.
echo [1;32mSamaritan deployment complete.[0m
echo.
echo ==========================================
echo.

endlocal
exit /b 0