#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[ OK ]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

die() {
    echo -e "${RED}[FAIL]${NC} $1" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

info "Checking operating system..."
[[ "$(uname -s)" == "Linux" ]] ||
    die "This installer must be run on Linux."
success "Linux detected."

info "Checking root privileges..."
[[ "${EUID}" -eq 0 ]] ||
    die "Please run this script with sudo."
success "Running as root."

if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
else
    die "Cannot determine Linux distribution."
fi

info "Detected: ${PRETTY_NAME:-unknown Linux distribution}"

info "Checking for ubuntu user..."
if id ubuntu >/dev/null 2>&1; then
    success "User 'ubuntu' found."
else
    die "User 'ubuntu' does not exist."
fi

info "Checking system architecture..."
[[ "$(uname -m)" == "aarch64" ]] ||
    die "Samaritan speech recognition currently requires an ARM64 (aarch64) system."
success "ARM64 architecture detected."

VOSK_VERSION="0.3.45"
VOSK_ROOT="/opt/samaritan"
VOSK_DIR="$VOSK_ROOT/vosk-linux-aarch64-$VOSK_VERSION"
VOSK_LIBRARY="$VOSK_DIR/libvosk.so"
VOSK_HEADER="$VOSK_DIR/vosk_api.h"
VOSK_MODEL_DIR="$VOSK_ROOT/vosk-model-small-en-us-0.15"
VOSK_LIBRARY_URL="https://github.com/alphacep/vosk-api/releases/download/v${VOSK_VERSION}/vosk-linux-aarch64-${VOSK_VERSION}.zip"
VOSK_MODEL_URL="https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
VOSK_LIBRARY_ARCHIVE="/tmp/vosk-linux-aarch64-${VOSK_VERSION}.zip"
VOSK_MODEL_ARCHIVE="/tmp/vosk-model-small-en-us-0.15.zip"

info "Updating package lists..."
apt-get update
success "Package lists updated."

info "Installing required packages..."
apt-get install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    build-essential \
    g++ \
    pkg-config \
    libasound2-dev \
    alsa-utils \
    libatomic1 \
    avrdude \
    libcurl4-openssl-dev \
    apache2 \
    php-cli \
    php-curl \
    php-mbstring \
    php-xml \
    php-zip
success "Required packages installed."

info "Checking PHP..."
command_exists php ||
    die "PHP was not installed."
success "PHP: $(php --version | head -n 1)"

info "Checking C++ compiler..."
command_exists g++ ||
    die "g++ was not installed."
success "g++: $(g++ --version | head -n 1)"

info "Checking ALSA development library..."
pkg-config --exists alsa ||
    die "ALSA development library was not installed."
success "ALSA development library installed."

info "Checking ALSA utilities..."
command_exists arecord ||
    die "arecord was not installed."
success "ALSA utilities installed."

info "Checking avrdude..."
command_exists avrdude ||
    die "avrdude was not installed."
success "avrdude installed."

info "Checking Apache..."
command_exists apache2ctl ||
    die "Apache was not installed."
success "Apache installed."

info "Verifying installed tools..."

REQUIRED_COMMANDS=(
    curl
    git
    unzip
    gcc
    g++
    php
    avrdude
    apache2ctl
    arecord
)

for command in "${REQUIRED_COMMANDS[@]}"; do
    command_exists "$command" ||
        die "Required command '$command' is not available."
done

success "All required system tools are available."

info "Checking Vosk installation..."
mkdir -p "$VOSK_ROOT"

if [[ -f "$VOSK_LIBRARY" && -f "$VOSK_HEADER" ]]; then
    success "Vosk library already installed."
else
    info "Downloading Vosk ${VOSK_VERSION}..."
    rm -f "$VOSK_LIBRARY_ARCHIVE"
    curl -fL \
        "$VOSK_LIBRARY_URL" \
        -o "$VOSK_LIBRARY_ARCHIVE"
    success "Vosk library downloaded."

    info "Extracting Vosk library..."
    rm -rf "$VOSK_DIR"
    unzip -q \
        "$VOSK_LIBRARY_ARCHIVE" \
        -d "$VOSK_ROOT"

    [[ -f "$VOSK_LIBRARY" ]] ||
        die "Vosk library was not found after extraction."

    [[ -f "$VOSK_HEADER" ]] ||
        die "Vosk header was not found after extraction."

    success "Vosk library installed."
fi

if [[ -d "$VOSK_MODEL_DIR" ]]; then
    success "Vosk speech model already installed."
else
    info "Downloading Vosk speech model..."
    rm -f "$VOSK_MODEL_ARCHIVE"
    curl -fL \
        "$VOSK_MODEL_URL" \
        -o "$VOSK_MODEL_ARCHIVE"
    success "Vosk speech model downloaded."

    info "Extracting Vosk speech model..."
    unzip -q \
        "$VOSK_MODEL_ARCHIVE" \
        -d "$VOSK_ROOT"

    [[ -d "$VOSK_MODEL_DIR" ]] ||
        die "Vosk speech model was not found after extraction."

    success "Vosk speech model installed."
fi

info "Configuring Vosk permissions..."
chown -R root:root "$VOSK_ROOT"
chmod 755 "$VOSK_ROOT"
chmod 755 "$VOSK_DIR"
chmod 755 "$VOSK_MODEL_DIR"
success "Vosk permissions configured."

info "Checking Vosk library dependencies..."
if ldd "$VOSK_LIBRARY" | grep -q "not found"; then
    echo
    ldd "$VOSK_LIBRARY"
    echo
    die "Vosk has unresolved shared-library dependencies."
fi
success "Vosk library dependencies satisfied."

rm -f "$VOSK_LIBRARY_ARCHIVE"
rm -f "$VOSK_MODEL_ARCHIVE"

success "Vosk installation complete."

echo
echo "=============================================="
echo " Samaritan - Stage 1 Installation Complete"
echo "=============================================="
echo
echo "Installed:"
echo "  Apache"
echo "  PHP"
echo "  g++"
echo "  ALSA development library"
echo "  ALSA utilities"
echo "  avrdude"
echo "  Vosk ${VOSK_VERSION}"
echo "  Vosk small English model"
echo
echo "Vosk library:"
echo "  $VOSK_DIR"
echo
echo "Vosk model:"
echo "  $VOSK_MODEL_DIR"
echo
echo "=============================================="