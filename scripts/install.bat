@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Samaritan - Installer
set "ROOT=%~dp0.."

echo.
echo ==============================================
echo            Samaritan Installer
echo ==============================================
echo.

echo Checking Windows environment...
echo.

where winget >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Windows Package Manager ^(winget^) was not found.
    echo.
    echo Samaritan uses winget to install missing PC prerequisites.
    echo Please install/enable App Installer from Microsoft and try again.
    exit /b 1
)

echo [ OK ] winget found.

echo.
echo ==============================================
echo Checking Samaritan project
echo ==============================================
echo.

if not exist "%ROOT%\package.json" (
    echo [FAIL] package.json was not found.
    echo Expected:
    echo %ROOT%\package.json
    exit /b 1
)

if not exist "%ROOT%\backend\composer.json" (
    echo [FAIL] composer.json was not found.
    echo Expected:
    echo %ROOT%\backend\composer.json
    exit /b 1
)

if not exist "%ROOT%\backend\code\arduino\embedded-code\platformio.ini" (
    echo [FAIL] platformio.ini was not found.
    echo Expected:
    echo %ROOT%\backend\code\arduino\embedded-code\platformio.ini
    exit /b 1
)

if not exist "%ROOT%\samaritan.conf" (
    echo [FAIL] samaritan.conf was not found.
    echo Expected:
    echo %ROOT%\samaritan.conf
    exit /b 1
)

echo [ OK ] package.json found.
echo [ OK ] backend\composer.json found.
echo [ OK ] platformio.ini found.
echo [ OK ] samaritan.conf found.

echo.
echo ==============================================
echo Checking Git
echo ==============================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo [INFO] Git is not installed.
    echo [INFO] Installing Git...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to install Git.
        exit /b 1
    )
    echo [ OK ] Git installed.
) else (
    echo [ OK ] Git already installed.
)

echo.
echo ==============================================
echo Checking Node.js
echo ==============================================
echo.

where node >nul 2>&1
if errorlevel 1 (
    echo [INFO] Node.js is not installed.
    echo [INFO] Installing Node.js LTS...
    winget install --id OpenJS.NodeJS.LTS -e --source winget --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to install Node.js.
        exit /b 1
    )
    echo [ OK ] Node.js installed.
) else (
    echo [ OK ] Node.js already installed.
)

set "PATH=%PATH%;%ProgramFiles%\nodejs"

where node >nul 2>&1
if errorlevel 1 (
    echo.
    echo [FAIL] Node.js was installed but could not be found.
    echo.
    echo Please restart this installer after restarting Windows.
    exit /b 1
)

where npm >nul 2>&1
if errorlevel 1 (
    echo.
    echo [FAIL] npm was installed but could not be found.
    exit /b 1
)

echo [ OK ] Node.js available.
echo [ OK ] npm available.

echo.
echo ==============================================
echo Checking Composer
echo ==============================================
echo.

where composer >nul 2>&1
if errorlevel 1 (
    echo [INFO] Composer is not installed.
    echo [INFO] Installing Composer...
    winget install --id Composer.Composer -e --source winget --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to install Composer.
        exit /b 1
    )
    echo [ OK ] Composer installed.
) else (
    echo [ OK ] Composer already installed.
)

where composer >nul 2>&1
if errorlevel 1 (
    echo.
    echo [FAIL] Composer was installed but could not be found.
    echo.
    echo Please restart this installer and try again.
    exit /b 1
)

echo [ OK ] Composer available.

echo.
echo ==============================================
echo Checking Python
echo ==============================================
echo.

where py >nul 2>&1
if errorlevel 1 (
    echo [INFO] Python is not installed.
    echo [INFO] Installing Python...
    winget install --id Python.Python.3.12 -e --source winget --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to install Python.
        exit /b 1
    )
    echo [ OK ] Python installed.
) else (
    echo [ OK ] Python already installed.
)

where py >nul 2>&1
if errorlevel 1 (
    echo.
    echo [FAIL] Python was installed but could not be found.
    echo.
    echo Please restart this installer and try again.
    exit /b 1
)

echo.
echo ==============================================
echo Checking PlatformIO
echo ==============================================
echo.

py -m platformio --version >nul 2>&1
if errorlevel 1 (
    echo [INFO] PlatformIO is not installed.
    echo [INFO] Installing PlatformIO CLI...
    py -m pip install --upgrade platformio
    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to install PlatformIO.
        exit /b 1
    )
    echo [ OK ] PlatformIO installed.
) else (
    echo [ OK ] PlatformIO already installed.
)

py -m platformio --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo [FAIL] PlatformIO could not be started.
    exit /b 1
)

echo [ OK ] PlatformIO CLI available.

echo.
echo ==============================================
echo Installing JavaScript dependencies
echo ==============================================
echo.

cd /d "%ROOT%"

if exist "%ROOT%\package-lock.json" (
    echo [INFO] package-lock.json found.
    echo [INFO] Running npm ci...
    call npm ci
    if errorlevel 1 (
        echo.
        echo [FAIL] npm dependency installation failed.
        exit /b 1
    )
) else (
    echo [INFO] No package-lock.json found.
    echo [INFO] Running npm install...
    call npm install
    if errorlevel 1 (
        echo.
        echo [FAIL] npm dependency installation failed.
        exit /b 1
    )
)

echo [ OK ] JavaScript dependencies installed.

echo.
echo ==============================================
echo Installing PHP dependencies
echo ==============================================
echo.

cd /d "%ROOT%\backend"
echo [INFO] Running composer install...
call composer install

if errorlevel 1 (
    echo.
    echo [FAIL] Composer dependency installation failed.
    exit /b 1
)

echo [ OK ] PHP dependencies installed.

echo.
echo ==============================================
echo Raspberry Pi Connection
echo ==============================================
echo.

where ssh >nul 2>&1
if errorlevel 1 (
    echo [FAIL] OpenSSH client was not found.
    echo.
    echo Install/enable the Windows OpenSSH Client and try again.
    exit /b 1
)

where scp >nul 2>&1
if errorlevel 1 (
    echo [FAIL] SCP was not found.
    echo.
    echo Install/enable the Windows OpenSSH Client and try again.
    exit /b 1
)

echo [ OK ] OpenSSH found.
echo [ OK ] SCP found.

echo.

set "PI_HOST=ubuntu@192.168.1.88"
set /p "PI_HOST=Enter Raspberry Pi SSH host [ubuntu@192.168.1.88]: "

set "PI_PORT=22"
set /p "PI_PORT=Enter SSH port [22]: "

if "%PI_PORT%"=="" (
    set "PI_PORT=22"
)

set "STAGE1_SCRIPT=%ROOT%\scripts\install-stage1.sh"
set "STAGE2_SCRIPT=%ROOT%\scripts\install-stage2.sh"
set "DAEMON_SERVICE_FILE=%ROOT%\daemon\samaritan-daemon.service"
set "SPEECH_SERVICE_FILE=%ROOT%\speech-service\samaritan-speech-service.service"
set "APACHE_FILE=%ROOT%\samaritan.conf"

if not exist "%STAGE1_SCRIPT%" (
    echo.
    echo [FAIL] install-stage1.sh was not found.
    exit /b 1
)

if not exist "%STAGE2_SCRIPT%" (
    echo.
    echo [FAIL] install-stage2.sh was not found.
    exit /b 1
)

if not exist "%DAEMON_SERVICE_FILE%" (
    echo.
    echo [FAIL] samaritan-daemon.service was not found.
    exit /b 1
)

if not exist "%SPEECH_SERVICE_FILE%" (
    echo.
    echo [FAIL] samaritan-speech-service.service was not found.
    exit /b 1
)

if not exist "%APACHE_FILE%" (
    echo.
    echo [FAIL] samaritan.conf was not found.
    exit /b 1
)

echo [ OK ] Stage 1 installer found.
echo [ OK ] Stage 2 installer found.
echo [ OK ] Samaritan daemon service found.
echo [ OK ] Samaritan speech service found.
echo [ OK ] Samaritan Apache configuration found.

set "REMOTE_STAGE1=/tmp/samaritan-install-stage1.sh"
set "REMOTE_STAGE2_DIR=/tmp/samaritan-install-stage2"
set "REMOTE_STAGE2=%REMOTE_STAGE2_DIR%/install-stage2.sh"
set "REMOTE_DAEMON_SERVICE=%REMOTE_STAGE2_DIR%/samaritan-daemon.service"
set "REMOTE_SPEECH_SERVICE=%REMOTE_STAGE2_DIR%/samaritan-speech-service.service"
set "REMOTE_APACHE=%REMOTE_STAGE2_DIR%/samaritan.conf"

echo.
echo ==============================================
echo Stage 1 - Raspberry Pi Environment
echo ==============================================
echo.

echo [INFO] Uploading Stage 1 installer...
scp -P %PI_PORT% "%STAGE1_SCRIPT%" "%PI_HOST%:%REMOTE_STAGE1%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to upload Stage 1 installer.
    ssh -p %PI_PORT% "%PI_HOST%" "rm -f %REMOTE_STAGE1%" >nul 2>&1
    exit /b 1
)

echo [ OK ] Stage 1 installer uploaded.
echo.
echo [INFO] Running Stage 1...

ssh -p %PI_PORT% "%PI_HOST%" "chmod +x %REMOTE_STAGE1% && sudo %REMOTE_STAGE1%; STATUS=$?; rm -f %REMOTE_STAGE1%; exit $STATUS"

if errorlevel 1 (
    echo.
    echo [FAIL] Stage 1 installation failed.
    ssh -p %PI_PORT% "%PI_HOST%" "rm -f %REMOTE_STAGE1%" >nul 2>&1
    exit /b 1
)

echo [ OK ] Stage 1 completed successfully.

echo.
echo ==============================================
echo Stage 2 - Raspberry Pi Configuration
echo ==============================================
echo.

echo [INFO] Creating temporary Stage 2 directory...

ssh -p %PI_PORT% "%PI_HOST%" "rm -rf %REMOTE_STAGE2_DIR% && mkdir -p %REMOTE_STAGE2_DIR%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to create temporary Stage 2 directory.
    exit /b 1
)

echo [ OK ] Temporary Stage 2 directory created.
echo.
echo [INFO] Uploading Stage 2 installer...

scp -P %PI_PORT% "%STAGE2_SCRIPT%" "%PI_HOST%:%REMOTE_STAGE2%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to upload Stage 2 installer.
    ssh -p %PI_PORT% "%PI_HOST%" "rm -rf %REMOTE_STAGE2_DIR%" >nul 2>&1
    exit /b 1
)

echo [ OK ] Stage 2 installer uploaded.
echo.
echo [INFO] Uploading Samaritan daemon service...

scp -P %PI_PORT% "%DAEMON_SERVICE_FILE%" "%PI_HOST%:%REMOTE_DAEMON_SERVICE%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to upload Samaritan daemon service.
    ssh -p %PI_PORT% "%PI_HOST%" "rm -rf %REMOTE_STAGE2_DIR%" >nul 2>&1
    exit /b 1
)

echo [ OK ] Samaritan daemon service uploaded.
echo.
echo [INFO] Uploading Samaritan speech service...

scp -P %PI_PORT% "%SPEECH_SERVICE_FILE%" "%PI_HOST%:%REMOTE_SPEECH_SERVICE%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to upload Samaritan speech service.
    ssh -p %PI_PORT% "%PI_HOST%" "rm -rf %REMOTE_STAGE2_DIR%" >nul 2>&1
    exit /b 1
)

echo [ OK ] Samaritan speech service uploaded.
echo.
echo [INFO] Uploading Samaritan Apache configuration...

scp -P %PI_PORT% "%APACHE_FILE%" "%PI_HOST%:%REMOTE_APACHE%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to upload Samaritan Apache configuration.
    ssh -p %PI_PORT% "%PI_HOST%" "rm -rf %REMOTE_STAGE2_DIR%" >nul 2>&1
    exit /b 1
)

echo [ OK ] Samaritan Apache configuration uploaded.
echo.
echo [INFO] Running Stage 2...

ssh -p %PI_PORT% "%PI_HOST%" "chmod +x %REMOTE_STAGE2% && sudo %REMOTE_STAGE2%; STATUS=$?; rm -rf %REMOTE_STAGE2_DIR%; exit $STATUS"

if errorlevel 1 (
    echo.
    echo [FAIL] Stage 2 installation failed.
    ssh -p %PI_PORT% "%PI_HOST%" "rm -rf %REMOTE_STAGE2_DIR%" >nul 2>&1
    exit /b 1
)

echo [ OK ] Stage 2 completed successfully.

echo.
echo ==============================================
echo       Samaritan Installation Complete
echo ==============================================
echo.

echo PC:
echo   Node.js        [ OK ]
echo   npm            [ OK ]
echo   Composer       [ OK ]
echo   Python         [ OK ]
echo   PlatformIO     [ OK ]
echo   Project deps   [ OK ]
echo.

echo Raspberry Pi:
echo   Environment    [ OK ]
echo   Server config  [ OK ]
echo   Apache         [ OK ]
echo   Systemd        [ OK ]
echo.

echo Samaritan is ready for deployment.
echo.
echo Run:
echo.
echo     deploy.bat
echo.
echo to build and deploy Samaritan.
echo.

endlocal
exit /b 0