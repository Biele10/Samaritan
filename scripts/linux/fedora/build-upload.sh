#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PI_WEB="/var/www/Samaritan"
LOCAL_BUILD="$ROOT/Samaritan-Build"

PI_HOST="ubuntu@192.168.1.88"
read -r -p "Enter Raspberry Pi SSH host [$PI_HOST]: " INPUT_PI_HOST

if [[ -n "$INPUT_PI_HOST" ]]; then
    PI_HOST="$INPUT_PI_HOST"
fi

PI_PORT="22"
read -r -p "Enter SSH port [$PI_PORT]: " INPUT_PI_PORT

if [[ -n "$INPUT_PI_PORT" ]]; then
    PI_PORT="$INPUT_PI_PORT"
fi

echo
echo "Raspberry Pi:"
echo "Host: $PI_HOST"
echo "Port: $PI_PORT"
echo

echo "=========================================="
echo "Samaritan - Build and Upload"
echo "=========================================="
echo

if ! command -v ssh >/dev/null 2>&1; then
    echo
    echo "[FAIL] OpenSSH client was not found."
    echo
    echo "Install openssh-clients and try again."
    exit 1
fi

if ! command -v scp >/dev/null 2>&1; then
    echo
    echo "[FAIL] SCP was not found."
    echo
    echo "Install openssh-clients and try again."
    exit 1
fi

echo "[ OK ] OpenSSH found."
echo "[ OK ] SCP found."

if [[ ! -d "$LOCAL_BUILD" ]]; then
    echo
    echo "[FAIL] Samaritan-Build does not exist."
    echo
    echo "Run create-build.sh first."
    exit 1
fi

echo "[ OK ] Samaritan-Build found."

if [[ ! -f "$LOCAL_BUILD/firmware/firmware.hex" ]]; then
    echo
    echo "[FAIL] Arduino firmware was not found."
    echo
    echo "Run create-build.sh first."
    exit 1
fi

echo "[ OK ] Arduino firmware found."

if [[ ! -d "$LOCAL_BUILD/speech-service" ]]; then
    echo
    echo "[FAIL] Speech service was not found."
    echo
    echo "Run create-build.sh first."
    exit 1
fi

if [[ ! -f "$LOCAL_BUILD/speech-service/code/speech.cpp" ]]; then
    echo
    echo "[FAIL] speech.cpp was not found."
    echo
    echo "Run create-build.sh first."
    exit 1
fi

if [[ ! -f "$LOCAL_BUILD/speech-service/code/processTranscription.cpp" ]]; then
    echo
    echo "[FAIL] processTranscription.cpp was not found."
    echo
    echo "Run create-build.sh first."
    exit 1
fi

if [[ ! -f "$LOCAL_BUILD/speech-service/code/config/config.hpp" ]]; then
    echo
    echo "[FAIL] Speech service config.hpp was not found."
    echo
    echo "Run create-build.sh first."
    exit 1
fi

if [[ ! -f "$LOCAL_BUILD/speech-service/samaritan-speech-service.service" ]]; then
    echo
    echo "[FAIL] Speech service systemd file was not found."
    echo
    echo "Run create-build.sh first."
    exit 1
fi

echo "[ OK ] Speech service found."
echo

echo "=========================================="
echo "Checking Arduino configuration..."
echo "=========================================="
echo

CONFIGURED=0

if ssh -p "$PI_PORT" "$PI_HOST" "
    if [ -f '$PI_WEB/daemon/code/config.hpp' ] &&
       grep -q 'SERIAL_PATH' '$PI_WEB/daemon/code/config.hpp' &&
       ! grep -q '{{SERIAL_PATH}}' '$PI_WEB/daemon/code/config.hpp';
    then
        exit 0
    else
        exit 1
    fi
"; then

    CONFIGURED=1

    echo "[ OK ] Existing Arduino configuration found."
    echo "[INFO] Existing SERIAL_PATH will be preserved."
else
    echo "[INFO] Arduino SERIAL_PATH is not configured."
    echo "[INFO] Arduino will be detected automatically."
fi

echo
echo "=========================================="
echo "Checking speech configuration..."
echo "=========================================="
echo

SPEECH_CONFIGURED=0

if ssh -p "$PI_PORT" "$PI_HOST" "
    if [ -f '$PI_WEB/speech-service/code/config/config.hpp' ] &&
       grep -q 'ALSA_INPUT_NAME' '$PI_WEB/speech-service/code/config/config.hpp' &&
       grep -q 'VOSK_MODEL_LOCATION' '$PI_WEB/speech-service/code/config/config.hpp' &&
       grep -q 'WAKE_WORD' '$PI_WEB/speech-service/code/config/config.hpp' &&
       grep -q 'PARTIAL_FIRST_LETTER_INDEX' '$PI_WEB/speech-service/code/config/config.hpp' &&
       grep -q 'END_OF_PARTIAL' '$PI_WEB/speech-service/code/config/config.hpp' &&
       grep -q 'SPEECH_CHAR_CAP' '$PI_WEB/speech-service/code/config/config.hpp' &&
       grep -q 'enum class SpeechState' '$PI_WEB/speech-service/code/config/config.hpp' &&
       ! grep -q '{{ALSA_INPUT_NAME}}' '$PI_WEB/speech-service/code/config/config.hpp' &&
       ! grep -q '{{VOSK_MODEL_LOCATION}}' '$PI_WEB/speech-service/code/config/config.hpp';
    then
        exit 0
    else
        exit 1
    fi
"; then

    SPEECH_CONFIGURED=1

    echo "[ OK ] Complete existing speech configuration found."
    echo "[INFO] Existing machine-specific speech values will be preserved."
else
    echo "[INFO] Existing speech configuration is missing or incomplete."
    echo "[INFO] Speech configuration will be generated from the complete build template."
fi

if [[ "$CONFIGURED" == "1" ]]; then
    echo
    echo "[INFO] Preserving existing Arduino config.hpp..."

    if ! ssh -p "$PI_PORT" "$PI_HOST" \
        "sudo cp '$PI_WEB/daemon/code/config.hpp' '/home/ubuntu/samaritan-config-existing.hpp'"; then

        echo
        echo "[FAIL] Failed to preserve existing Arduino config.hpp."
        exit 1
    fi

    echo "[ OK ] Existing Arduino config.hpp preserved."
fi

if [[ "$SPEECH_CONFIGURED" == "1" ]]; then
    echo
    echo "[INFO] Preserving existing speech config.hpp..."

    if ! ssh -p "$PI_PORT" "$PI_HOST" \
        "sudo cp '$PI_WEB/speech-service/code/config/config.hpp' '/home/ubuntu/samaritan-speech-config-existing.hpp'"; then

        echo
        echo "[FAIL] Failed to preserve existing speech config.hpp."
        exit 1
    fi

    echo "[ OK ] Existing speech config.hpp preserved."
fi

echo
echo "=========================================="
echo "Preparing Samaritan deployment..."
echo "=========================================="
echo

echo "[INFO] Stopping Samaritan services..."

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    sudo systemctl stop samaritan-daemon 2>/dev/null || true
    sudo systemctl stop samaritan-speech-service 2>/dev/null || true
"; then

    echo
    echo "[FAIL] Failed to stop Samaritan services."
    exit 1
fi

echo "[ OK ] Samaritan services stopped."

echo
echo "[INFO] Replacing deployment directory..."

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    sudo rm -rf '$PI_WEB' &&
    sudo mkdir -p '$PI_WEB' &&
    sudo chown ubuntu:ubuntu '$PI_WEB' &&
    sudo chmod 755 '$PI_WEB'
"; then

    echo
    echo "[FAIL] Failed to prepare Samaritan deployment directory."
    exit 1
fi

echo "[ OK ] Deployment directory prepared."

echo
echo "=========================================="
echo "Uploading Samaritan..."
echo "=========================================="
echo

if ! scp -P "$PI_PORT" -r \
    "$LOCAL_BUILD/." \
    "$PI_HOST:$PI_WEB/"; then

    echo
    echo "[FAIL] Failed to deploy Samaritan."
    exit 1
fi

echo
echo "[ OK ] Samaritan deployed."

echo
echo "=========================================="
echo "Adjusting deployment permissions..."
echo "=========================================="
echo

if ! ssh -p "$PI_PORT" "$PI_HOST" \
    "sudo chmod -R a+rX '$PI_WEB'"; then

    echo
    echo "[FAIL] Failed to set deployment permissions."
    exit 1
fi

echo "[ OK ] Deployment permissions configured."

if [[ "$CONFIGURED" == "1" ]]; then
    echo
    echo "=========================================="
    echo "Restoring Arduino configuration..."
    echo "=========================================="
    echo

    if ! ssh -p "$PI_PORT" "$PI_HOST" \
        "sudo mv '/home/ubuntu/samaritan-config-existing.hpp' '$PI_WEB/daemon/code/config.hpp'"; then

        echo
        echo "[FAIL] Failed to restore Arduino config.hpp."
        exit 1
    fi

    echo "[ OK ] Existing Arduino config.hpp restored."
fi

if [[ "$SPEECH_CONFIGURED" == "1" ]]; then
    echo
    echo "=========================================="
    echo "Restoring speech configuration..."
    echo "=========================================="
    echo

    if ! ssh -p "$PI_PORT" "$PI_HOST" \
        "sudo mv '/home/ubuntu/samaritan-speech-config-existing.hpp' '$PI_WEB/speech-service/code/config/config.hpp'"; then

        echo
        echo "[FAIL] Failed to restore speech config.hpp."
        exit 1
    fi

    echo "[ OK ] Existing speech config.hpp restored."
fi

echo
echo "=========================================="
echo "Detecting Arduino..."
echo "=========================================="
echo

ARDUINO_OUTPUT="$(
    ssh -p "$PI_PORT" "$PI_HOST" \
    "find /dev/serial/by-id -maxdepth 1 -type l -name '*Arduino*' -print 2>/dev/null || true"
)"

mapfile -t ARDUINO_DEVICES < <(printf '%s\n' "$ARDUINO_OUTPUT" | sed '/^[[:space:]]*$/d')

ARDUINO_COUNT="${#ARDUINO_DEVICES[@]}"

if [[ "$ARDUINO_COUNT" == "0" ]]; then
    echo
    echo "[FAIL] No Arduino was detected."
    echo
    echo "Connect the Arduino to the Raspberry Pi and run deployment again."
    exit 1
fi

if [[ "$ARDUINO_COUNT" != "1" ]]; then
    echo
    echo "[FAIL] Multiple Arduino devices were detected."
    echo
    echo "Detected devices:"
    printf '%s\n' "${ARDUINO_DEVICES[@]}"
    echo
    echo "Please leave only one Arduino connected and try again."
    exit 1
fi

ARDUINO_SERIAL="${ARDUINO_DEVICES[0]}"

echo "[ OK ] Arduino detected:"
echo "       $ARDUINO_SERIAL"

if [[ "$CONFIGURED" == "0" ]]; then
    echo
    echo "=========================================="
    echo "Generating Arduino configuration..."
    echo "=========================================="
    echo

    CONFIG_FILE="$(mktemp)"

    cat > "$CONFIG_FILE" <<EOF
#pragma once

constexpr const char* SERIAL_PATH = "$ARDUINO_SERIAL";

constexpr const char* SOCKET_PATH = "/run/samaritan/samaritan.sock";
EOF

    echo "[ OK ] Temporary Arduino config.hpp generated."
    echo "[INFO] Uploading Arduino config.hpp..."

    if ! scp -P "$PI_PORT" \
        "$CONFIG_FILE" \
        "$PI_HOST:/home/ubuntu/samaritan-config.hpp"; then

        echo
        echo "[FAIL] Failed to upload Arduino config.hpp."
        rm -f "$CONFIG_FILE"
        exit 1
    fi

    echo "[ OK ] Arduino config.hpp uploaded."
    echo "[INFO] Installing Arduino config.hpp..."

    if ! ssh -p "$PI_PORT" "$PI_HOST" \
        "sudo mv '/home/ubuntu/samaritan-config.hpp' '$PI_WEB/daemon/code/config.hpp'"; then

        echo
        echo "[FAIL] Failed to install Arduino config.hpp."
        rm -f "$CONFIG_FILE"
        exit 1
    fi

    rm -f "$CONFIG_FILE"

    echo "[ OK ] Arduino config.hpp installed."
fi

if [[ "$SPEECH_CONFIGURED" == "0" ]]; then
    echo
    echo "=========================================="
    echo "Detecting microphone..."
    echo "=========================================="
    echo

    MIC_OUTPUT="$(
        ssh -p "$PI_PORT" "$PI_HOST" \
        "arecord -L 2>/dev/null | grep '^plughw:CARD=' || true"
    )"

    mapfile -t MIC_DEVICES < <(printf '%s\n' "$MIC_OUTPUT" | sed '/^[[:space:]]*$/d')

    MIC_COUNT="${#MIC_DEVICES[@]}"

    if [[ "$MIC_COUNT" == "0" ]]; then
        echo
        echo "[FAIL] No ALSA capture devices were found."
        echo
        echo "ALSA reported no plughw capture devices."
        echo
        echo "Run:"
        echo "  ssh -p $PI_PORT $PI_HOST \"arecord -L\""
        echo
        echo "and check that your microphone is connected."
        exit 1
    fi

    if [[ "$MIC_COUNT" != "1" ]]; then
        echo
        echo "[FAIL] Multiple ALSA capture devices were detected."
        echo
        echo "Detected devices:"
        printf '%s\n' "${MIC_DEVICES[@]}"
        echo
        echo "Complete ALSA device list:"
        ssh -p "$PI_PORT" "$PI_HOST" "arecord -L"
        echo
        echo "Please leave only one microphone connected and try again."
        exit 1
    fi

    MIC_NAME="${MIC_DEVICES[0]}"

    echo "[ OK ] Microphone detected:"
    echo "       $MIC_NAME"
    echo

    echo "[INFO] Verifying microphone..."

    if ! ssh -p "$PI_PORT" "$PI_HOST" \
        "arecord -D '$MIC_NAME' -f S16_LE -c 1 -r 16000 -d 1 /dev/null >/dev/null 2>&1"; then

        echo
        echo "[FAIL] The detected microphone could not be opened."
        echo
        echo "ALSA input: $MIC_NAME"
        exit 1
    fi

    echo "[ OK ] Microphone detected and verified."
    echo

    echo "=========================================="
    echo "Configuring speech service..."
    echo "=========================================="
    echo

    SPEECH_CONFIG_FILE="$(mktemp)"
    SPEECH_TEMPLATE="$LOCAL_BUILD/speech-service/code/config/config.hpp"

    if [[ ! -f "$SPEECH_TEMPLATE" ]]; then
        echo
        echo "[FAIL] Speech configuration template was not found."
        echo
        echo "Expected:"
        echo "$SPEECH_TEMPLATE"
        rm -f "$SPEECH_CONFIG_FILE"
        exit 1
    fi

    echo "[INFO] Copying complete speech configuration template..."

    if ! cp "$SPEECH_TEMPLATE" "$SPEECH_CONFIG_FILE"; then
        echo
        echo "[FAIL] Failed to copy speech configuration template."
        rm -f "$SPEECH_CONFIG_FILE"
        exit 1
    fi

    echo "[ OK ] Complete speech configuration template copied."
    echo
    echo "[INFO] Applying machine-specific speech configuration..."

    ESCAPED_MIC_NAME="$(printf '%s' "$MIC_NAME" | sed 's/[&|\\]/\\&/g')"

    if ! sed -i \
        -e "s|{{ALSA_INPUT_NAME}}|$ESCAPED_MIC_NAME|g" \
        -e "s|{{VOSK_MODEL_LOCATION}}|/opt/samaritan/vosk-model-small-en-us-0.15|g" \
        "$SPEECH_CONFIG_FILE"; then

        echo
        echo "[FAIL] Failed to configure speech config.hpp."
        rm -f "$SPEECH_CONFIG_FILE"
        exit 1
    fi

    echo "[ OK ] Speech configuration values applied."
    echo
    echo "[INFO] Uploading complete speech config.hpp..."

    if ! scp -P "$PI_PORT" \
        "$SPEECH_CONFIG_FILE" \
        "$PI_HOST:/home/ubuntu/samaritan-speech-config.hpp"; then

        echo
        echo "[FAIL] Failed to upload speech config.hpp."
        rm -f "$SPEECH_CONFIG_FILE"
        exit 1
    fi

    echo "[ OK ] Speech config.hpp uploaded."
    echo
    echo "[INFO] Installing speech config.hpp..."

    if ! ssh -p "$PI_PORT" "$PI_HOST" "
        sudo mkdir -p '$PI_WEB/speech-service/code/config' &&
        sudo mv '/home/ubuntu/samaritan-speech-config.hpp' '$PI_WEB/speech-service/code/config/config.hpp'
    "; then

        echo
        echo "[FAIL] Failed to install speech config.hpp."
        rm -f "$SPEECH_CONFIG_FILE"
        exit 1
    fi

    rm -f "$SPEECH_CONFIG_FILE"

    echo "[ OK ] Complete speech config.hpp installed."
fi

echo
echo "=========================================="
echo "Uploading Arduino firmware..."
echo "=========================================="
echo

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    sudo avrdude \
        -p atmega328p \
        -c arduino \
        -P '$ARDUINO_SERIAL' \
        -b 115200 \
        -D \
        -U 'flash:w:$PI_WEB/firmware/firmware.hex:i'
"; then

    echo
    echo "[FAIL] Arduino firmware upload failed."
    exit 1
fi

echo
echo "[ OK ] Arduino firmware uploaded."

echo
echo "=========================================="
echo "Compiling C++ daemon..."
echo "=========================================="
echo

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    cd '$PI_WEB/daemon' &&
    sudo mkdir -p build &&
    sudo g++ \
        -std=c++17 \
        code/main.cpp \
        code/UnixSocket/UnixSocket.cpp \
        code/ArduinoSerial/ArduinoSerial.cpp \
        -o build/samaritan-daemon
"; then

    echo
    echo "[FAIL] C++ daemon compilation failed."
    exit 1
fi

echo "[ OK ] C++ daemon compiled."

echo
echo "=========================================="
echo "Compiling speech recognition service..."
echo "=========================================="
echo

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    cd '$PI_WEB/speech-service' &&
    sudo mkdir -p build &&
    sudo g++ \
        -std=c++17 \
        code/speech.cpp \
        code/processTranscription.cpp \
        -I/opt/samaritan/vosk-linux-aarch64-0.3.45 \
        -L/opt/samaritan/vosk-linux-aarch64-0.3.45 \
        -Wl,-rpath,/opt/samaritan/vosk-linux-aarch64-0.3.45 \
        -lvosk \
        -lasound \
        -lcurl \
        -pthread \
        -o build/samaritan-speech-service
"; then

    echo
    echo "[FAIL] Speech recognition service compilation failed."
    exit 1
fi

echo "[ OK ] Speech recognition service compiled."

echo
echo "=========================================="
echo "Restarting Samaritan daemon..."
echo "=========================================="
echo

if ! ssh -p "$PI_PORT" "$PI_HOST" \
    "sudo systemctl restart samaritan-daemon"; then

    echo
    echo "[FAIL] Failed to restart Samaritan daemon."
    exit 1
fi

echo "[ OK ] Samaritan daemon restarted."

echo
echo "=========================================="
echo "Restarting Samaritan speech service..."
echo "=========================================="
echo

if ! ssh -p "$PI_PORT" "$PI_HOST" \
    "sudo systemctl restart samaritan-speech-service"; then

    echo
    echo "[FAIL] Failed to restart Samaritan speech service."
    exit 1
fi

echo "[ OK ] Samaritan speech service restarted."

echo
echo "=========================================="
echo "Restarting Apache..."
echo "=========================================="
echo

if ! ssh -p "$PI_PORT" "$PI_HOST" \
    "sudo systemctl restart apache2"; then

    echo
    echo "[FAIL] Failed to restart Apache."
    exit 1
fi

echo "[ OK ] Apache restarted."

echo
echo "=========================================="
echo "Samaritan deployment complete."
echo "=========================================="
echo

echo "React application: deployed"
echo "PHP backend: deployed"
echo "Arduino firmware: uploaded"
echo "Arduino configuration: preserved/generated"
echo "C++ daemon: compiled and restarted"
echo "Speech service: compiled and restarted"
echo "Speech configuration: preserved/generated"
echo "Apache: restarted"
echo

exit 0