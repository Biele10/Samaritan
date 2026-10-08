@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "ROOT=%SCRIPT_DIR%..\.."
for %%A in ("%ROOT%") do set "ROOT=%%~fA"
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
    echo [FAIL] Python 3 was not found.
    echo.
    echo Run install.bat first.
    exit /b 1
)

py -3 -m platformio --version >nul 2>&1
if errorlevel 1 (
    echo [FAIL] PlatformIO was not found.
    echo.
    echo Run install.bat first.
    exit /b 1
)

where robocopy >nul 2>&1
if errorlevel 1 (
    echo [FAIL] robocopy was not found.
    echo.
    echo Run install.bat first.
    exit /b 1
)

echo [ OK ] npm found.
echo [ OK ] Composer found.
echo [ OK ] Python 3 found.
echo [ OK ] PlatformIO found.
echo [ OK ] robocopy found.
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

if not exist "%ROOT%\speech-service\code\speech.cpp" (
    echo [FAIL] speech.cpp was not found.
    exit /b 1
)

if not exist "%ROOT%\speech-service\code\processTranscription.cpp" (
    echo [FAIL] processTranscription.cpp was not found.
    exit /b 1
)

if not exist "%ROOT%\speech-service\code\config\config.hpp" (
    echo [FAIL] speech-service config.hpp was not found.
    exit /b 1
)

if not exist "%ROOT%\speech-service\samaritan-speech-service.service" (
    echo [FAIL] samaritan-speech-service.service was not found.
    exit /b 1
)

if not exist "%ROOT%\ollama\Modelfile" (
    echo [FAIL] Ollama Modelfile was not found.
    exit /b 1
)

if not exist "%ROOT%\ollama\samaritan-model.service" (
    echo [FAIL] Samaritan Ollama model service was not found.
    exit /b 1
)

echo [ OK ] package.json found.
echo [ OK ] composer.json found.
echo [ OK ] platformio.ini found.
echo [ OK ] speech.cpp found.
echo [ OK ] processTranscription.cpp found.
echo [ OK ] speech config.hpp found.
echo [ OK ] Speech service systemd file found.
echo [ OK ] Ollama Modelfile found.
echo [ OK ] Samaritan model systemd file found.
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
    echo [INFO] package-lock.json found.
    echo [INFO] Running npm ci...
    call npm ci
    if errorlevel 1 (
        echo.
        echo [FAIL] JavaScript dependency installation failed.
        exit /b 1
    )
) else (
    echo [INFO] No package-lock.json found.
    echo [INFO] Running npm install...
    call npm install
    if errorlevel 1 (
        echo.
        echo [FAIL] JavaScript dependency installation failed.
        exit /b 1
    )
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

mkdir "%BUILD%\public_html"

robocopy "%ROOT%\dist" "%BUILD%\public_html" /E
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
echo [INFO] Copying backend...

mkdir "%BUILD%\backend"

robocopy "%ROOT%\backend" "%BUILD%\backend" /E /XD "%ROOT%\backend\code\arduino"
if errorlevel 8 (
    echo [ERROR] Failed to copy backend.
    exit /b 1
)

robocopy "%ROOT%\backend\code\arduino" "%BUILD%\backend\code\arduino" /E /XD "%ROOT%\backend\code\arduino\embedded-code"
if errorlevel 8 (
    echo [ERROR] Failed to copy Arduino PHP code.
    exit /b 1
)

echo.
echo ==========================================
echo Building Arduino firmware...
echo ==========================================
echo.

cd /d "%ROOT%\backend\code\arduino\embedded-code"

py -3 -m platformio run
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

set "FIRMWARE=%ROOT%\backend\code\arduino\embedded-code\.pio\build\uno\firmware.hex"

if not exist "%FIRMWARE%" (
    echo.
    echo [FAIL] firmware.hex was not found.
    echo.
    echo Expected:
    echo %FIRMWARE%
    exit /b 1
)

mkdir "%BUILD%\firmware"

copy /Y "%FIRMWARE%" "%BUILD%\firmware\firmware.hex" >nul
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

mkdir "%BUILD%\daemon\code"

robocopy "%ROOT%\daemon\code" "%BUILD%\daemon\code" /E
if errorlevel 8 (
    echo.
    echo [FAIL] Daemon source copy failed.
    exit /b 1
)

mkdir "%BUILD%\daemon\build"

echo [ OK ] Daemon source copied.
echo.
echo ==========================================
echo Copying speech service source...
echo ==========================================
echo.

mkdir "%BUILD%\speech-service"

robocopy "%ROOT%\speech-service" "%BUILD%\speech-service" /E /XD "%ROOT%\speech-service\build"
if errorlevel 8 (
    echo.
    echo [FAIL] Speech service source copy failed.
    exit /b 1
)

mkdir "%BUILD%\speech-service\build"

echo [ OK ] Speech service source copied.
echo.
echo ==========================================
echo Copying Ollama configuration...
echo ==========================================
echo.

mkdir "%BUILD%\ollama"

robocopy "%ROOT%\ollama" "%BUILD%\ollama" /E
if errorlevel 8 (
    echo.
    echo [FAIL] Ollama configuration copy failed.
    exit /b 1
)

echo [ OK ] Ollama configuration copied.
echo.
echo ==========================================
echo Samaritan build created successfully.
echo ==========================================
echo.
echo Build location:
echo %BUILD%
echo.
echo Contents:
echo public_html/       React application
echo backend/           PHP application
echo daemon/code/       C++ daemon source
echo speech-service/    C++ speech service
echo ollama/            Samaritan AI
echo firmware/          Pre-built Arduino firmware
echo.

exit /b 0