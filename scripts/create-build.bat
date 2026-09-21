@echo off
setlocal EnableExtensions

set "ROOT=%~dp0.."
set "BUILD=%ROOT%\Samaritan-Build"

echo.
echo ==========================================
echo Samaritan - Create Build
echo ==========================================
echo.

echo Checking required build tools...
echo.

where npm >nul 2>&1
if errorlevel 1 (
    echo [FAIL] npm was not found.
    echo.
    echo Run install.bat first.
    exit /b 1
)

where composer >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Composer was not found.
    echo.
    echo Run install.bat first.
    exit /b 1
)

where py >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Python was not found.
    echo.
    echo Run install.bat first.
    exit /b 1
)

py -m platformio --version >nul 2>&1
if errorlevel 1 (
    echo [FAIL] PlatformIO was not found.
    echo.
    echo Run install.bat first.
    exit /b 1
)

echo [ OK ] npm found.
echo [ OK ] Composer found.
echo [ OK ] Python found.
echo [ OK ] PlatformIO found.

echo.
echo ==========================================
echo Checking project files...
echo ==========================================
echo.

if not exist "%ROOT%\package.json" (
    echo [FAIL] package.json was not found.
    exit /b 1
)

if not exist "%ROOT%\backend\composer.json" (
    echo [FAIL] composer.json was not found.
    exit /b 1
)

if not exist "%ROOT%\backend\code\arduino\embedded-code\platformio.ini" (
    echo [FAIL] platformio.ini was not found.
    exit /b 1
)

echo [ OK ] package.json found.
echo [ OK ] composer.json found.
echo [ OK ] platformio.ini found.

echo.
echo ==========================================
echo Preparing build directory...
echo ==========================================
echo.

if exist "%BUILD%" (
    echo Removing previous Samaritan-Build...
    rmdir /s /q "%BUILD%"
    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to remove previous build directory.
        exit /b 1
    )
)

mkdir "%BUILD%"
if errorlevel 1 (
    echo.
    echo [FAIL] Failed to create build directory.
    exit /b 1
)

echo [ OK ] Build directory prepared.

echo.
echo ==========================================
echo Preparing JavaScript dependencies...
echo ==========================================
echo.

cd /d "%ROOT%"

if exist "%ROOT%\package-lock.json" (
    call npm ci
) else (
    call npm install
)

if errorlevel 1 (
    echo.
    echo [FAIL] JavaScript dependency installation failed.
    exit /b 1
)

echo [ OK ] JavaScript dependencies ready.

echo.
echo ==========================================
echo Building React application...
echo ==========================================
echo.

call npm run build

if errorlevel 1 (
    echo.
    echo [FAIL] React build failed.
    exit /b 1
)

echo [ OK ] React application built.

echo.
echo ==========================================
echo Copying frontend build...
echo ==========================================
echo.

if not exist "%ROOT%\dist" (
    echo.
    echo [FAIL] Vite build directory was not found.
    exit /b 1
)

robocopy "%ROOT%\dist" "%BUILD%\public_html" /E /IS /IT

if errorlevel 8 (
    echo.
    echo [FAIL] Frontend copy failed.
    exit /b 1
)

echo [ OK ] Frontend copied.

echo.
echo ==========================================
echo Preparing PHP dependencies...
echo ==========================================
echo.

cd /d "%ROOT%\backend"

call composer install --no-dev --optimize-autoloader

if errorlevel 1 (
    echo.
    echo [FAIL] Composer dependency installation failed.
    exit /b 1
)

echo [ OK ] PHP dependencies ready.

echo.
echo ==========================================
echo Copying backend...
echo ==========================================
echo.

robocopy "%ROOT%\backend" "%BUILD%\backend" /E /IS /IT /XD "%ROOT%\backend\code\arduino"

if errorlevel 8 (
    echo.
    echo [FAIL] Backend copy failed.
    exit /b 1
)

echo [ OK ] Backend copied.

echo.
echo ==========================================
echo Building Arduino firmware...
echo ==========================================
echo.

cd /d "%ROOT%\backend\code\arduino\embedded-code"

call py -m platformio run

if errorlevel 1 (
    echo.
    echo [FAIL] Arduino firmware build failed.
    exit /b 1
)

echo [ OK ] Arduino firmware built.

echo.
echo ==========================================
echo Packaging Arduino firmware...
echo ==========================================
echo.

if not exist "%ROOT%\backend\code\arduino\embedded-code\.pio\build\uno\firmware.hex" (
    echo.
    echo [FAIL] firmware.hex was not found.
    echo.
    echo Expected:
    echo %ROOT%\backend\code\arduino\embedded-code\.pio\build\uno\firmware.hex
    exit /b 1
)

mkdir "%BUILD%\firmware"

copy /Y "%ROOT%\backend\code\arduino\embedded-code\.pio\build\uno\firmware.hex" "%BUILD%\firmware\firmware.hex" >nul

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to copy firmware.hex.
    exit /b 1
)

echo [ OK ] Arduino firmware packaged.

echo.
echo ==========================================
echo Copying daemon source...
echo ==========================================
echo.

robocopy "%ROOT%\daemon\code" "%BUILD%\daemon\code" /E /IS /IT

if errorlevel 8 (
    echo.
    echo [FAIL] Daemon source copy failed.
    exit /b 1
)

echo [ OK ] Daemon source copied.

if not exist "%BUILD%\daemon\build" (
    mkdir "%BUILD%\daemon\build"
)

echo.
echo ==========================================
echo Copying speech service source...
echo ==========================================
echo.

if not exist "%ROOT%\speech-service\code\speech.cpp" (
    echo.
    echo [FAIL] speech.cpp was not found.
    exit /b 1
)

if not exist "%ROOT%\speech-service\samaritan-speech-service.service" (
    echo.
    echo [FAIL] samaritan-speech-service.service was not found.
    exit /b 1
)

robocopy "%ROOT%\speech-service" "%BUILD%\speech-service" /E /IS /IT /XD "%ROOT%\speech-service\build"

if errorlevel 8 (
    echo.
    echo [FAIL] Speech service source copy failed.
    exit /b 1
)

echo [ OK ] Speech service source copied.

if not exist "%BUILD%\speech-service\build" (
    mkdir "%BUILD%\speech-service\build"
)

echo.
echo ==========================================
echo Samaritan build created successfully.
echo ==========================================
echo.

echo Build location:
echo %BUILD%
echo.

echo Contents:
echo   public_html\      React application
echo   backend\          PHP application
echo   daemon\code\      C++ daemon source
echo   speech-service\   C++ speech service
echo   firmware\         Pre-built Arduino firmware
echo.

endlocal
exit /b 0