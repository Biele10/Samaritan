@echo off
setlocal EnableDelayedExpansion

set "ROOT=%~dp0.."

echo.
echo ==========================================
echo Samaritan - Build and Upload
echo ==========================================
echo.

set "PI_HOST=ubuntu@192.168.1.88"
set /p "PI_HOST=Enter Raspberry Pi SSH host [ubuntu@192.168.1.88]: "

set "PI_PORT=22"
set /p "PI_PORT=Enter SSH port [22]: "

echo.
echo Raspberry Pi:
echo   Host: %PI_HOST%
echo   Port: %PI_PORT%
echo.

set "PI_WEB=/var/www/Samaritan"
set "LOCAL_BUILD=%ROOT%\Samaritan-Build"

where ssh >nul 2>&1
if errorlevel 1 (
    echo.
    echo [FAIL] OpenSSH client was not found.
    echo.
    echo Install/enable the Windows OpenSSH Client and try again.
    exit /b 1
)

where scp >nul 2>&1
if errorlevel 1 (
    echo.
    echo [FAIL] SCP was not found.
    echo.
    echo Install/enable the Windows OpenSSH Client and try again.
    exit /b 1
)

echo [ OK ] OpenSSH found.
echo [ OK ] SCP found.

if not exist "%LOCAL_BUILD%" (
    echo.
    echo [FAIL] Samaritan-Build does not exist.
    echo.
    echo Run create-build.bat first.
    exit /b 1
)

echo [ OK ] Samaritan-Build found.

if not exist "%LOCAL_BUILD%\firmware\firmware.hex" (
    echo.
    echo [FAIL] Arduino firmware was not found.
    echo.
    echo Run create-build.bat first.
    exit /b 1
)

echo [ OK ] Arduino firmware found.

if not exist "%LOCAL_BUILD%\speech-service\code\speech.cpp" (
    echo.
    echo [FAIL] Speech service source was not found.
    echo.
    echo Run create-build.bat first.
    exit /b 1
)

if not exist "%LOCAL_BUILD%\speech-service\samaritan-speech-service.service" (
    echo.
    echo [FAIL] Speech service systemd file was not found.
    echo.
    echo Run create-build.bat first.
    exit /b 1
)

echo [ OK ] Speech service found.

echo.
echo ==========================================
echo Checking Arduino configuration...
echo ==========================================
echo.

set "CONFIGURED=0"

ssh -p "%PI_PORT%" "%PI_HOST%" "if [ -f %PI_WEB%/daemon/code/config.hpp ] && grep -q 'SERIAL_PATH' %PI_WEB%/daemon/code/config.hpp && ! grep -q '{{SERIAL_PATH}}' %PI_WEB%/daemon/code/config.hpp; then exit 0; else exit 1; fi"

if not errorlevel 1 (
    set "CONFIGURED=1"
    echo [ OK ] Existing Arduino configuration found.
    echo [INFO] Existing SERIAL_PATH will be preserved.
) else (
    echo [INFO] Arduino SERIAL_PATH is not configured.
    echo [INFO] Arduino will be detected automatically.
)

echo.
echo ==========================================
echo Checking speech configuration...
echo ==========================================
echo.

set "SPEECH_CONFIGURED=0"

ssh -p "%PI_PORT%" "%PI_HOST%" "if [ -f %PI_WEB%/speech-service/code/config/config.hpp ]; then if grep -q 'ALSA_INPUT_NAME = \"{{ALSA_INPUT_NAME}}\"' %PI_WEB%/speech-service/code/config/config.hpp; then exit 1; fi; if grep -q 'VOSK_MODEL_LOCATION = \"{{VOSK_MODEL_LOCATION}}\"' %PI_WEB%/speech-service/code/config/config.hpp; then exit 1; fi; if grep -q 'ALSA_INPUT_NAME' %PI_WEB%/speech-service/code/config/config.hpp && grep -q 'VOSK_MODEL_LOCATION' %PI_WEB%/speech-service/code/config/config.hpp; then exit 0; fi; fi; exit 1"

if not errorlevel 1 (
    set "SPEECH_CONFIGURED=1"
    echo [ OK ] Existing speech configuration found.
    echo [INFO] Existing ALSA_INPUT_NAME will be preserved.
) else (
    echo [INFO] No valid speech configuration found.
    echo [INFO] Microphone detection will be performed.
)

if "!CONFIGURED!"=="1" (
    echo.
    echo [INFO] Preserving existing Arduino config.hpp...

    ssh -p "%PI_PORT%" "%PI_HOST%" "sudo cp %PI_WEB%/daemon/code/config.hpp /home/ubuntu/samaritan-config-existing.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to preserve existing Arduino config.hpp.
        exit /b 1
    )

    echo [ OK ] Existing Arduino config.hpp preserved.
)

if "!SPEECH_CONFIGURED!"=="1" (
    echo.
    echo [INFO] Preserving existing speech config.hpp...

    ssh -p "%PI_PORT%" "%PI_HOST%" "sudo cp %PI_WEB%/speech-service/code/config/config.hpp /home/ubuntu/samaritan-speech-config-existing.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to preserve existing speech config.hpp.
        exit /b 1
    )

    echo [ OK ] Existing speech config.hpp preserved.
)

echo.
echo ==========================================
echo Preparing Samaritan deployment...
echo ==========================================
echo.

echo [INFO] Stopping Samaritan services...

ssh -p "%PI_PORT%" "%PI_HOST%" "sudo systemctl stop samaritan-daemon 2>/dev/null || true; sudo systemctl stop samaritan-speech-service 2>/dev/null || true"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to stop Samaritan services.
    exit /b 1
)

echo [ OK ] Samaritan services stopped.
echo.
echo [INFO] Replacing deployment directory...

ssh -p "%PI_PORT%" "%PI_HOST%" "sudo rm -rf %PI_WEB% && sudo mkdir -p %PI_WEB% && sudo chown ubuntu:ubuntu %PI_WEB% && sudo chmod 755 %PI_WEB%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to prepare Samaritan deployment directory.
    exit /b 1
)

echo [ OK ] Deployment directory prepared.

echo.
echo ==========================================
echo Uploading Samaritan...
echo ==========================================
echo.

scp -P "%PI_PORT%" -r "%LOCAL_BUILD%\." "%PI_HOST%:%PI_WEB%/"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to deploy Samaritan.
    exit /b 1
)

echo.
echo [ OK ] Samaritan deployed.

echo.
echo ==========================================
echo Adjusting deployment permissions...
echo ==========================================
echo.

ssh -p "%PI_PORT%" "%PI_HOST%" "sudo chmod -R a+rX %PI_WEB%"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to set deployment permissions.
    exit /b 1
)

echo [ OK ] Deployment permissions configured.

if "!CONFIGURED!"=="1" (
    echo.
    echo ==========================================
    echo Restoring Arduino configuration...
    echo ==========================================
    echo.

    ssh -p "%PI_PORT%" "%PI_HOST%" "sudo mv /home/ubuntu/samaritan-config-existing.hpp %PI_WEB%/daemon/code/config.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to restore Arduino config.hpp.
        exit /b 1
    )

    echo [ OK ] Existing Arduino config.hpp restored.
)

if "!SPEECH_CONFIGURED!"=="1" (
    echo.
    echo ==========================================
    echo Restoring speech configuration...
    echo ==========================================
    echo.

    ssh -p "%PI_PORT%" "%PI_HOST%" "sudo mv /home/ubuntu/samaritan-speech-config-existing.hpp %PI_WEB%/speech-service/code/config/config.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to restore speech config.hpp.
        exit /b 1
    )

    echo [ OK ] Existing speech config.hpp restored.
)

echo.
echo ==========================================
echo Detecting Arduino...
echo ==========================================
echo.

set "ARDUINO_COUNT=0"
set "ARDUINO_SERIAL="

for /f "delims=" %%A in ('ssh -p "%PI_PORT%" "%PI_HOST%" "find /dev/serial/by-id -maxdepth 1 -type l -name '*Arduino*' -print"') do (
    set /a ARDUINO_COUNT+=1
    set "ARDUINO_SERIAL=%%A"
)

if "!ARDUINO_COUNT!"=="0" (
    echo.
    echo [FAIL] No Arduino was detected.
    echo.
    echo Connect the Arduino to the Raspberry Pi and run deployment again.
    exit /b 1
)

if not "!ARDUINO_COUNT!"=="1" (
    echo.
    echo [FAIL] Multiple Arduino devices were detected.
    echo.
    echo Detected devices:

    ssh -p "%PI_PORT%" "%PI_HOST%" "find /dev/serial/by-id -maxdepth 1 -type l -name '*Arduino*' -print"

    echo.
    echo Please leave only one Arduino connected and try again.
    exit /b 1
)

echo [ OK ] Arduino detected:
echo        !ARDUINO_SERIAL!

if "!CONFIGURED!"=="0" (
    echo.
    echo ==========================================
    echo Generating Arduino configuration...
    echo ==========================================
    echo.

    set "CONFIG_FILE=%TEMP%\samaritan-config.hpp"

    (
        echo #pragma once
        echo.
        echo constexpr const char* SERIAL_PATH = "!ARDUINO_SERIAL!";
        echo.
        echo constexpr const char* SOCKET_PATH = "/run/samaritan/samaritan.sock";
    ) > "!CONFIG_FILE!"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to generate temporary Arduino config.hpp.
        exit /b 1
    )

    echo [ OK ] Temporary Arduino config.hpp generated.
    echo [INFO] Uploading Arduino config.hpp...

    scp -P "%PI_PORT%" "!CONFIG_FILE!" "%PI_HOST%:/home/ubuntu/samaritan-config.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to upload Arduino config.hpp.
        del /q "!CONFIG_FILE!" >nul 2>&1
        exit /b 1
    )

    echo [ OK ] Arduino config.hpp uploaded.
    echo [INFO] Installing Arduino config.hpp...

    ssh -p "%PI_PORT%" "%PI_HOST%" "sudo mv /home/ubuntu/samaritan-config.hpp %PI_WEB%/daemon/code/config.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to install Arduino config.hpp.
        del /q "!CONFIG_FILE!" >nul 2>&1
        exit /b 1
    )

    del /q "!CONFIG_FILE!" >nul 2>&1

    echo [ OK ] Arduino config.hpp installed.
)

if "!SPEECH_CONFIGURED!"=="0" (
    echo.
    echo ==========================================
    echo Detecting microphone...
    echo ==========================================
    echo.

    set "MIC_COUNT=0"
    set "MIC_NAME="

    for /f "delims=" %%A in ('ssh -p "%PI_PORT%" "%PI_HOST%" "arecord -L" ^| findstr /B /C:"plughw:CARD="') do (
        set /a MIC_COUNT+=1
        set "MIC_NAME=%%A"
    )

    if "!MIC_COUNT!"=="0" (
        echo.
        echo [FAIL] No ALSA capture devices were found.
        echo.
        echo ALSA reported no plughw capture devices.
        echo.
        echo Run:
        echo   ssh -p "%PI_PORT%" "%PI_HOST%" "arecord -L"
        echo.
        echo and check that your microphone is connected.
        exit /b 1
    )

    if not "!MIC_COUNT!"=="1" (
        echo.
        echo [FAIL] Multiple ALSA capture devices were detected.
        echo.
        echo Detected devices:

        ssh -p "%PI_PORT%" "%PI_HOST%" "arecord -L"

        echo.
        echo Please leave only one microphone connected and try again.
        exit /b 1
    )

    echo [ OK ] Microphone detected:
    echo        !MIC_NAME!
    echo.
    echo [INFO] Verifying microphone...

    ssh -p "%PI_PORT%" "%PI_HOST%" "arecord -D '!MIC_NAME!' -f S16_LE -c 1 -r 16000 -d 1 /dev/null >/dev/null 2>&1"

    if errorlevel 1 (
        echo.
        echo [FAIL] The detected microphone could not be opened.
        echo.
        echo ALSA input: !MIC_NAME!
        exit /b 1
    )

    echo [ OK ] Microphone detected and verified.

    echo.
    echo ==========================================
    echo Generating speech configuration...
    echo ==========================================
    echo.

    set "SPEECH_CONFIG_FILE=%TEMP%\samaritan-speech-config.hpp"

    (
        echo #pragma once
        echo.
        echo constexpr const char* ALSA_INPUT_NAME = "!MIC_NAME!";
        echo.
        echo constexpr const char* VOSK_MODEL_LOCATION = "/opt/samaritan/vosk-model-small-en-us-0.15";
    ) > "!SPEECH_CONFIG_FILE!"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to generate temporary speech config.hpp.
        exit /b 1
    )

    echo [ OK ] Temporary speech config.hpp generated.
    echo [INFO] Uploading speech config.hpp...

    scp -P "%PI_PORT%" "!SPEECH_CONFIG_FILE!" "%PI_HOST%:/home/ubuntu/samaritan-speech-config.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to upload speech config.hpp.
        del /q "!SPEECH_CONFIG_FILE!" >nul 2>&1
        exit /b 1
    )

    echo [ OK ] Speech config.hpp uploaded.
    echo [INFO] Installing speech config.hpp...

    ssh -p "%PI_PORT%" "%PI_HOST%" "sudo mkdir -p %PI_WEB%/speech-service/code/config && sudo mv /home/ubuntu/samaritan-speech-config.hpp %PI_WEB%/speech-service/code/config/config.hpp"

    if errorlevel 1 (
        echo.
        echo [FAIL] Failed to install speech config.hpp.
        del /q "!SPEECH_CONFIG_FILE!" >nul 2>&1
        exit /b 1
    )

    del /q "!SPEECH_CONFIG_FILE!" >nul 2>&1

    echo [ OK ] Speech config.hpp installed.
)

echo.
echo ==========================================
echo Uploading Arduino firmware...
echo ==========================================
echo.

ssh -p "%PI_PORT%" "%PI_HOST%" "sudo avrdude -p atmega328p -c arduino -P '!ARDUINO_SERIAL!' -b 115200 -D -U flash:w:%PI_WEB%/firmware/firmware.hex:i"

if errorlevel 1 (
    echo.
    echo [FAIL] Arduino firmware upload failed.
    exit /b 1
)

echo.
echo [ OK ] Arduino firmware uploaded.

echo.
echo ==========================================
echo Compiling C++ daemon...
echo ==========================================
echo.

ssh -p "%PI_PORT%" "%PI_HOST%" "cd %PI_WEB%/daemon && sudo mkdir -p build && sudo g++ -std=c++17 code/main.cpp code/UnixSocket/UnixSocket.cpp code/ArduinoSerial/ArduinoSerial.cpp -o build/samaritan-daemon"

if errorlevel 1 (
    echo.
    echo [FAIL] C++ daemon compilation failed.
    exit /b 1
)

echo [ OK ] C++ daemon compiled.

echo.
echo ==========================================
echo Compiling speech recognition service...
echo ==========================================
echo.

ssh -p "%PI_PORT%" "%PI_HOST%" "cd %PI_WEB%/speech-service && sudo mkdir -p build && sudo g++ -std=c++17 code/speech.cpp -I/opt/samaritan/vosk-linux-aarch64-0.3.45 -L/opt/samaritan/vosk-linux-aarch64-0.3.45 -Wl,-rpath,/opt/samaritan/vosk-linux-aarch64-0.3.45 -lvosk -lasound -o build/samaritan-speech-service"

if errorlevel 1 (
    echo.
    echo [FAIL] Speech recognition service compilation failed.
    exit /b 1
)

echo [ OK ] Speech recognition service compiled.

echo.
echo ==========================================
echo Restarting Samaritan daemon...
echo ==========================================
echo.

ssh -p "%PI_PORT%" "%PI_HOST%" "sudo systemctl restart samaritan-daemon"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to restart Samaritan daemon.
    exit /b 1
)

echo [ OK ] Samaritan daemon restarted.

echo.
echo ==========================================
echo Restarting Samaritan speech service...
echo ==========================================
echo.

ssh -p "%PI_PORT%" "%PI_HOST%" "sudo systemctl restart samaritan-speech-service"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to restart Samaritan speech service.
    exit /b 1
)

echo [ OK ] Samaritan speech service restarted.

echo.
echo ==========================================
echo Restarting Apache...
echo ==========================================
echo.

ssh -p "%PI_PORT%" "%PI_HOST%" "sudo systemctl restart apache2"

if errorlevel 1 (
    echo.
    echo [FAIL] Failed to restart Apache.
    exit /b 1
)

echo [ OK ] Apache restarted.

echo.
echo ==========================================
echo Samaritan deployment complete.
echo ==========================================
echo.

echo React application: deployed
echo PHP backend: deployed
echo Arduino firmware: uploaded
echo Arduino configuration: preserved/generated
echo C++ daemon: compiled and restarted
echo Speech service: compiled and restarted
echo Speech configuration: preserved/generated
echo Apache: restarted

echo.

endlocal
exit /b 0