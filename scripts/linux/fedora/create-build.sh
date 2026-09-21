#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD="$ROOT/Samaritan-Build"

echo
echo "=========================================="
echo "Samaritan - Create Build"
echo "=========================================="
echo

echo "Checking required build tools..."
echo

if ! command -v npm >/dev/null 2>&1; then
    echo "[FAIL] npm was not found."
    echo
    echo "Run install.sh first."
    exit 1
fi

if ! command -v composer >/dev/null 2>&1; then
    echo "[FAIL] Composer was not found."
    echo
    echo "Run install.sh first."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "[FAIL] Python 3 was not found."
    echo
    echo "Run install.sh first."
    exit 1
fi

if ! python3 -m platformio --version >/dev/null 2>&1; then
    echo "[FAIL] PlatformIO was not found."
    echo
    echo "Run install.sh first."
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    echo "[FAIL] rsync was not found."
    echo
    echo "Run install.sh first."
    exit 1
fi

echo "[ OK ] npm found."
echo "[ OK ] Composer found."
echo "[ OK ] Python 3 found."
echo "[ OK ] PlatformIO found."
echo "[ OK ] rsync found."
echo

echo "=========================================="
echo "Checking project files..."
echo "=========================================="
echo

if [[ ! -f "$ROOT/package.json" ]]; then
    echo "[FAIL] package.json was not found."
    exit 1
fi

if [[ ! -f "$ROOT/backend/composer.json" ]]; then
    echo "[FAIL] composer.json was not found."
    exit 1
fi

if [[ ! -f "$ROOT/backend/code/arduino/embedded-code/platformio.ini" ]]; then
    echo "[FAIL] platformio.ini was not found."
    exit 1
fi

if [[ ! -f "$ROOT/speech-service/code/speech.cpp" ]]; then
    echo "[FAIL] speech.cpp was not found."
    exit 1
fi

if [[ ! -f "$ROOT/speech-service/code/processTranscription.cpp" ]]; then
    echo "[FAIL] processTranscription.cpp was not found."
    exit 1
fi

if [[ ! -f "$ROOT/speech-service/code/config/config.hpp" ]]; then
    echo "[FAIL] speech-service config.hpp was not found."
    exit 1
fi

if [[ ! -f "$ROOT/speech-service/samaritan-speech-service.service" ]]; then
    echo "[FAIL] samaritan-speech-service.service was not found."
    exit 1
fi

echo "[ OK ] package.json found."
echo "[ OK ] composer.json found."
echo "[ OK ] platformio.ini found."
echo "[ OK ] speech.cpp found."
echo "[ OK ] processTranscription.cpp found."
echo "[ OK ] speech config.hpp found."
echo "[ OK ] Speech service systemd file found."
echo

echo "=========================================="
echo "Preparing build directory..."
echo "=========================================="
echo

if [[ -d "$BUILD" ]]; then
    echo "Removing previous Samaritan-Build..."

    if ! rm -rf "$BUILD"; then
        echo
        echo "[FAIL] Failed to remove previous build directory."
        exit 1
    fi
fi

if ! mkdir -p "$BUILD"; then
    echo
    echo "[FAIL] Failed to create build directory."
    exit 1
fi

echo "[ OK ] Build directory prepared."
echo

echo "=========================================="
echo "Preparing JavaScript dependencies..."
echo "=========================================="
echo

cd "$ROOT"

if [[ -f "$ROOT/package-lock.json" ]]; then
    echo "[INFO] package-lock.json found."
    echo "[INFO] Running npm ci..."

    if ! npm ci; then
        echo
        echo "[FAIL] JavaScript dependency installation failed."
        exit 1
    fi
else
    echo "[INFO] No package-lock.json found."
    echo "[INFO] Running npm install..."

    if ! npm install; then
        echo
        echo "[FAIL] JavaScript dependency installation failed."
        exit 1
    fi
fi

echo "[ OK ] JavaScript dependencies ready."
echo

echo "=========================================="
echo "Building React application..."
echo "=========================================="
echo

if ! npm run build; then
    echo
    echo "[FAIL] React build failed."
    exit 1
fi

echo "[ OK ] React application built."
echo

echo "=========================================="
echo "Copying frontend build..."
echo "=========================================="
echo

if [[ ! -d "$ROOT/dist" ]]; then
    echo
    echo "[FAIL] Vite build directory was not found."
    exit 1
fi

mkdir -p "$BUILD/public_html"

if ! rsync -a "$ROOT/dist/" "$BUILD/public_html/"; then
    echo
    echo "[FAIL] Frontend copy failed."
    exit 1
fi

echo "[ OK ] Frontend copied."
echo

echo "=========================================="
echo "Preparing PHP dependencies..."
echo "=========================================="
echo

cd "$ROOT/backend"

if ! composer install --no-dev --optimize-autoloader; then
    echo
    echo "[FAIL] Composer dependency installation failed."
    exit 1
fi

echo "[ OK ] PHP dependencies ready."
echo

echo "[INFO] Copying backend..."

mkdir -p "$BUILD/backend"

# Copy the backend, excluding Arduino source
if ! rsync -a \
    --exclude="code/arduino/" \
    "$ROOT/backend/" \
    "$BUILD/backend/"; then

    echo "[ERROR] Failed to copy backend."
    exit 1
fi

# Copy Arduino PHP code, excluding PlatformIO firmware source
if ! rsync -a \
    --exclude="embedded-code/" \
    "$ROOT/backend/code/arduino/" \
    "$BUILD/backend/code/arduino/"; then

    echo "[ERROR] Failed to copy Arduino PHP code."
    exit 1
fi

echo "=========================================="
echo "Building Arduino firmware..."
echo "=========================================="
echo

cd "$ROOT/backend/code/arduino/embedded-code"

if ! python3 -m platformio run; then
    echo
    echo "[FAIL] Arduino firmware build failed."
    exit 1
fi

echo "[ OK ] Arduino firmware built."
echo

echo "=========================================="
echo "Packaging Arduino firmware..."
echo "=========================================="
echo

FIRMWARE="$ROOT/backend/code/arduino/embedded-code/.pio/build/uno/firmware.hex"

if [[ ! -f "$FIRMWARE" ]]; then
    echo
    echo "[FAIL] firmware.hex was not found."
    echo
    echo "Expected:"
    echo "$FIRMWARE"
    exit 1
fi

mkdir -p "$BUILD/firmware"

if ! cp "$FIRMWARE" "$BUILD/firmware/firmware.hex"; then
    echo
    echo "[FAIL] Failed to copy firmware.hex."
    exit 1
fi

echo "[ OK ] Arduino firmware packaged."
echo

echo "=========================================="
echo "Copying daemon source..."
echo "=========================================="
echo

mkdir -p "$BUILD/daemon/code"

if ! rsync -a \
    "$ROOT/daemon/code/" \
    "$BUILD/daemon/code/"; then
    echo
    echo "[FAIL] Daemon source copy failed."
    exit 1
fi

mkdir -p "$BUILD/daemon/build"

echo "[ OK ] Daemon source copied."
echo

echo "=========================================="
echo "Copying speech service source..."
echo "=========================================="
echo

mkdir -p "$BUILD/speech-service"

if ! rsync -a \
    --exclude="build/" \
    "$ROOT/speech-service/" \
    "$BUILD/speech-service/"; then
    echo
    echo "[FAIL] Speech service source copy failed."
    exit 1
fi

mkdir -p "$BUILD/speech-service/build"

echo "[ OK ] Speech service source copied."
echo

echo "[INFO] Applying SELinux context..."

sudo restorecon -Rv "$BUILD"

echo

echo "=========================================="
echo "Samaritan build created successfully."
echo "=========================================="
echo

echo "Build location:"
echo "$BUILD"
echo

echo "Contents:"
echo "public_html/       React application"
echo "backend/           PHP application"
echo "daemon/code/       C++ daemon source"
echo "speech-service/    C++ speech service"
echo "firmware/          Pre-built Arduino firmware"
echo

exit 0