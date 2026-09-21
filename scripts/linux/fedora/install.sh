#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo
echo "=============================================="
echo "Samaritan Installer - Fedora"
echo "=============================================="
echo

if [[ ! -f /etc/fedora-release ]]; then
    echo "[FAIL] This installer is intended for Fedora."
    echo
    echo "Detected system:"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$PRETTY_NAME"
    else
        echo "Unknown"
    fi
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "[FAIL] sudo was not found."
    exit 1
fi

if ! sudo -v; then
    echo "[FAIL] sudo authentication failed."
    exit 1
fi

echo "[ OK ] Fedora detected."
echo

echo "=============================================="
echo "Checking Samaritan project"
echo "=============================================="
echo

if [[ ! -f "$ROOT/package.json" ]]; then
    echo "[FAIL] package.json was not found."
    echo "Expected:"
    echo "$ROOT/package.json"
    exit 1
fi

if [[ ! -f "$ROOT/backend/composer.json" ]]; then
    echo "[FAIL] composer.json was not found."
    echo "Expected:"
    echo "$ROOT/backend/composer.json"
    exit 1
fi

if [[ ! -f "$ROOT/backend/code/arduino/embedded-code/platformio.ini" ]]; then
    echo "[FAIL] platformio.ini was not found."
    echo "Expected:"
    echo "$ROOT/backend/code/arduino/embedded-code/platformio.ini"
    exit 1
fi

if [[ ! -f "$ROOT/samaritan.conf" ]]; then
    echo "[FAIL] samaritan.conf was not found."
    echo "Expected:"
    echo "$ROOT/samaritan.conf"
    exit 1
fi

echo "[ OK ] package.json found."
echo "[ OK ] backend/composer.json found."
echo "[ OK ] platformio.ini found."
echo "[ OK ] samaritan.conf found."
echo

echo "=============================================="
echo "Installing Fedora prerequisites"
echo "=============================================="
echo

echo "[INFO] Refreshing Fedora package metadata..."

if ! sudo dnf makecache; then
    echo
    echo "[FAIL] Failed to refresh Fedora package metadata."
    exit 1
fi

echo
echo "[INFO] Installing required packages..."

if ! sudo dnf install -y \
    git \
    nodejs \
    npm \
    composer \
    php-cli \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    python3 \
    python3-pip \
    openssh-clients \
    rsync \
    gcc \
    gcc-c++ \
    make \
    unzip; then

    echo
    echo "[FAIL] Failed to install Fedora prerequisites."
    exit 1
fi

echo
echo "[ OK ] Fedora prerequisites installed."
echo

echo "=============================================="
echo "Checking Node.js"
echo "=============================================="
echo

if ! command -v node >/dev/null 2>&1; then
    echo "[FAIL] Node.js was installed but could not be found."
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "[FAIL] npm was installed but could not be found."
    exit 1
fi

echo "[ OK ] Node.js available."
echo "[ OK ] npm available."
echo

echo "=============================================="
echo "Checking Composer"
echo "=============================================="
echo

if ! command -v composer >/dev/null 2>&1; then
    echo "[FAIL] Composer was installed but could not be found."
    exit 1
fi

echo "[ OK ] Composer available."
echo

echo "=============================================="
echo "Checking Python"
echo "=============================================="
echo

if ! command -v python3 >/dev/null 2>&1; then
    echo "[FAIL] Python 3 was installed but could not be found."
    exit 1
fi

echo "[ OK ] Python 3 available."
echo

echo "=============================================="
echo "Checking PlatformIO"
echo "=============================================="
echo

if ! python3 -m platformio --version >/dev/null 2>&1; then
    echo "[INFO] PlatformIO is not installed."
    echo "[INFO] Installing PlatformIO CLI..."

    if ! python3 -m pip install \
        --user \
        --break-system-packages \
        --upgrade \
        platformio; then

        echo
        echo "[FAIL] Failed to install PlatformIO."
        exit 1
    fi

    echo "[ OK ] PlatformIO installed."
else
    echo "[ OK ] PlatformIO already installed."
fi

if ! python3 -m platformio --version >/dev/null 2>&1; then
    echo
    echo "[FAIL] PlatformIO could not be started."
    exit 1
fi

echo "[ OK ] PlatformIO CLI available."
echo

echo "=============================================="
echo "Installing JavaScript dependencies"
echo "=============================================="
echo

cd "$ROOT"

if [[ -f "$ROOT/package-lock.json" ]]; then
    echo "[INFO] package-lock.json found."
    echo "[INFO] Running npm ci..."

    if ! npm ci; then
        echo
        echo "[FAIL] npm dependency installation failed."
        exit 1
    fi
else
    echo "[INFO] No package-lock.json found."
    echo "[INFO] Running npm install..."

    if ! npm install; then
        echo
        echo "[FAIL] npm dependency installation failed."
        exit 1
    fi
fi

echo "[ OK ] JavaScript dependencies installed."
echo

echo "=============================================="
echo "Installing PHP dependencies"
echo "=============================================="
echo

cd "$ROOT/backend"

echo "[INFO] Running composer install..."

if ! composer install; then
    echo
    echo "[FAIL] Composer dependency installation failed."
    exit 1
fi

echo "[ OK ] PHP dependencies installed."
echo

echo "=============================================="
echo "Raspberry Pi Connection"
echo "=============================================="
echo

if ! command -v ssh >/dev/null 2>&1; then
    echo "[FAIL] OpenSSH client was not found."
    exit 1
fi

if ! command -v scp >/dev/null 2>&1; then
    echo "[FAIL] SCP was not found."
    exit 1
fi

echo "[ OK ] OpenSSH found."
echo "[ OK ] SCP found."
echo

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

STAGE1_SCRIPT="$ROOT/scripts/install-stage1.sh"
STAGE2_SCRIPT="$ROOT/scripts/install-stage2.sh"

DAEMON_SERVICE_FILE="$ROOT/daemon/samaritan-daemon.service"
SPEECH_SERVICE_FILE="$ROOT/speech-service/samaritan-speech-service.service"
APACHE_FILE="$ROOT/samaritan.conf"

if [[ ! -f "$STAGE1_SCRIPT" ]]; then
    echo "[FAIL] install-stage1.sh was not found."
    exit 1
fi

if [[ ! -f "$STAGE2_SCRIPT" ]]; then
    echo "[FAIL] install-stage2.sh was not found."
    exit 1
fi

if [[ ! -f "$DAEMON_SERVICE_FILE" ]]; then
    echo "[FAIL] samaritan-daemon.service was not found."
    exit 1
fi

if [[ ! -f "$SPEECH_SERVICE_FILE" ]]; then
    echo "[FAIL] samaritan-speech-service.service was not found."
    exit 1
fi

if [[ ! -f "$APACHE_FILE" ]]; then
    echo "[FAIL] samaritan.conf was not found."
    exit 1
fi

echo "[ OK ] Stage 1 installer found."
echo "[ OK ] Stage 2 installer found."
echo "[ OK ] Samaritan daemon service found."
echo "[ OK ] Samaritan speech service found."
echo "[ OK ] Samaritan Apache configuration found."

REMOTE_STAGE1="/tmp/samaritan-install-stage1.sh"

REMOTE_STAGE2_DIR="/tmp/samaritan-install-stage2"
REMOTE_STAGE2="$REMOTE_STAGE2_DIR/install-stage2.sh"
REMOTE_DAEMON_SERVICE="$REMOTE_STAGE2_DIR/samaritan-daemon.service"
REMOTE_SPEECH_SERVICE="$REMOTE_STAGE2_DIR/samaritan-speech-service.service"
REMOTE_APACHE="$REMOTE_STAGE2_DIR/samaritan.conf"

echo
echo "=============================================="
echo "Stage 1 - Raspberry Pi Environment"
echo "=============================================="
echo

echo "[INFO] Uploading Stage 1 installer..."

if ! scp -P "$PI_PORT" \
    "$STAGE1_SCRIPT" \
    "$PI_HOST:$REMOTE_STAGE1"; then

    echo
    echo "[FAIL] Failed to upload Stage 1 installer."
    ssh -p "$PI_PORT" "$PI_HOST" \
        "rm -f '$REMOTE_STAGE1'" >/dev/null 2>&1 || true
    exit 1
fi

echo "[ OK ] Stage 1 installer uploaded."
echo
echo "[INFO] Running Stage 1..."

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    chmod +x '$REMOTE_STAGE1' &&
    sudo '$REMOTE_STAGE1'
    STATUS=\$?
    rm -f '$REMOTE_STAGE1'
    exit \$STATUS
"; then

    echo
    echo "[FAIL] Stage 1 installation failed."
    ssh -p "$PI_PORT" "$PI_HOST" \
        "rm -f '$REMOTE_STAGE1'" >/dev/null 2>&1 || true
    exit 1
fi

echo "[ OK ] Stage 1 completed successfully."

echo
echo "=============================================="
echo "Stage 2 - Raspberry Pi Configuration"
echo "=============================================="
echo

echo "[INFO] Creating temporary Stage 2 directory..."

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    rm -rf '$REMOTE_STAGE2_DIR' &&
    mkdir -p '$REMOTE_STAGE2_DIR'
"; then

    echo
    echo "[FAIL] Failed to create temporary Stage 2 directory."
    exit 1
fi

echo "[ OK ] Temporary Stage 2 directory created."
echo

echo "[INFO] Uploading Stage 2 installer..."

if ! scp -P "$PI_PORT" \
    "$STAGE2_SCRIPT" \
    "$PI_HOST:$REMOTE_STAGE2"; then

    echo
    echo "[FAIL] Failed to upload Stage 2 installer."
    ssh -p "$PI_PORT" "$PI_HOST" \
        "rm -rf '$REMOTE_STAGE2_DIR'" >/dev/null 2>&1 || true
    exit 1
fi

echo "[ OK ] Stage 2 installer uploaded."
echo

echo "[INFO] Uploading Samaritan daemon service..."

if ! scp -P "$PI_PORT" \
    "$DAEMON_SERVICE_FILE" \
    "$PI_HOST:$REMOTE_DAEMON_SERVICE"; then

    echo
    echo "[FAIL] Failed to upload Samaritan daemon service."
    ssh -p "$PI_PORT" "$PI_HOST" \
        "rm -rf '$REMOTE_STAGE2_DIR'" >/dev/null 2>&1 || true
    exit 1
fi

echo "[ OK ] Samaritan daemon service uploaded."
echo

echo "[INFO] Uploading Samaritan speech service..."

if ! scp -P "$PI_PORT" \
    "$SPEECH_SERVICE_FILE" \
    "$PI_HOST:$REMOTE_SPEECH_SERVICE"; then

    echo
    echo "[FAIL] Failed to upload Samaritan speech service."
    ssh -p "$PI_PORT" "$PI_HOST" \
        "rm -rf '$REMOTE_STAGE2_DIR'" >/dev/null 2>&1 || true
    exit 1
fi

echo "[ OK ] Samaritan speech service uploaded."
echo

echo "[INFO] Uploading Samaritan Apache configuration..."

if ! scp -P "$PI_PORT" \
    "$APACHE_FILE" \
    "$PI_HOST:$REMOTE_APACHE"; then

    echo
    echo "[FAIL] Failed to upload Samaritan Apache configuration."
    ssh -p "$PI_PORT" "$PI_HOST" \
        "rm -rf '$REMOTE_STAGE2_DIR'" >/dev/null 2>&1 || true
    exit 1
fi

echo "[ OK ] Samaritan Apache configuration uploaded."
echo

echo "[INFO] Running Stage 2..."

if ! ssh -p "$PI_PORT" "$PI_HOST" "
    chmod +x '$REMOTE_STAGE2' &&
    sudo '$REMOTE_STAGE2'
    STATUS=\$?
    rm -rf '$REMOTE_STAGE2_DIR'
    exit \$STATUS
"; then

    echo
    echo "[FAIL] Stage 2 installation failed."
    ssh -p "$PI_PORT" "$PI_HOST" \
        "rm -rf '$REMOTE_STAGE2_DIR'" >/dev/null 2>&1 || true
    exit 1
fi

echo "[ OK ] Stage 2 completed successfully."

echo
echo "=============================================="
echo "Samaritan Installation Complete"
echo "=============================================="
echo

echo "PC:"
echo "Node.js [ OK ]"
echo "npm      [ OK ]"
echo "Composer [ OK ]"
echo "Python   [ OK ]"
echo "PlatformIO [ OK ]"
echo "Project deps [ OK ]"
echo

echo "Raspberry Pi:"
echo "Environment [ OK ]"
echo "Server config [ OK ]"
echo "Apache [ OK ]"
echo "Systemd [ OK ]"
echo

echo "Samaritan is ready for deployment."
echo
echo "Run:"
echo
echo "  ./deploy.sh"
echo
echo "to build and deploy Samaritan."
echo

exit 0