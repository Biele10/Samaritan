#!/usr/bin/env bash

set -e

info() {
    echo "[INFO] $1"
}

success() {
    echo "[ OK ] $1"
}

warning() {
    echo "[WARN] $1"
}

die() {
    echo "[ERROR] $1"
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    die "This script must be run as root. Use sudo."
fi

if [ ! -f /etc/os-release ]; then
    die "Unable to determine operating system."
fi

source /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    warning "This installer was designed for Ubuntu."
    warning "Detected operating system: $PRETTY_NAME"
fi

if ! id ubuntu >/dev/null 2>&1; then
    die "Required user 'ubuntu' does not exist."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SAMARITAN_ROOT="/var/www/Samaritan"

DAEMON_DIR="$SAMARITAN_ROOT/daemon"
DAEMON_BUILD_DIR="$DAEMON_DIR/build"

SPEECH_DIR="$SAMARITAN_ROOT/speech-service"
SPEECH_BUILD_DIR="$SPEECH_DIR/build"

DAEMON_SERVICE_SOURCE="$SCRIPT_DIR/samaritan-daemon.service"
DAEMON_SERVICE_DEST="/etc/systemd/system/samaritan-daemon.service"

SPEECH_SERVICE_SOURCE="$SCRIPT_DIR/samaritan-speech-service.service"
SPEECH_SERVICE_DEST="/etc/systemd/system/samaritan-speech-service.service"

OLLAMA_MODEL_FILE="$SCRIPT_DIR/Modelfile"
OLLAMA_MODEL_SERVICE_SOURCE="$SCRIPT_DIR/samaritan-model.service"
OLLAMA_MODEL_SERVICE_DEST="/etc/systemd/system/samaritan-model.service"

OLLAMA_LOAD_SCRIPT_SOURCE="$SCRIPT_DIR/load-model.sh"
OLLAMA_LOAD_SCRIPT_DEST="/usr/local/bin/samaritan-load-model.sh"

APACHE_SOURCE="$SCRIPT_DIR/samaritan.conf"
APACHE_DEST="/etc/apache2/sites-available/samaritan.conf"

info "Configuring Samaritan group..."

if ! getent group samaritan >/dev/null 2>&1; then
    groupadd samaritan
    success "Created samaritan group."
else
    success "samaritan group already exists."
fi

usermod -aG samaritan ubuntu
usermod -aG samaritan www-data

success "Configured Samaritan group membership."

info "Creating Samaritan directories..."

mkdir -p "$SAMARITAN_ROOT"
mkdir -p "$DAEMON_BUILD_DIR"
mkdir -p "$SPEECH_BUILD_DIR"

chown -R ubuntu:ubuntu "$SAMARITAN_ROOT"

success "Samaritan directories ready."

info "Installing Samaritan daemon service..."

if [ ! -f "$DAEMON_SERVICE_SOURCE" ]; then
    die "Daemon service file not found: $DAEMON_SERVICE_SOURCE"
fi

install \
    -o root \
    -g root \
    -m 644 \
    "$DAEMON_SERVICE_SOURCE" \
    "$DAEMON_SERVICE_DEST"

success "Samaritan daemon service installed."

info "Installing Samaritan speech service..."

if [ ! -f "$SPEECH_SERVICE_SOURCE" ]; then
    die "Speech service file not found: $SPEECH_SERVICE_SOURCE"
fi

install \
    -o root \
    -g root \
    -m 644 \
    "$SPEECH_SERVICE_SOURCE" \
    "$SPEECH_SERVICE_DEST"

success "Samaritan speech service installed."

info "Configuring Samaritan Ollama..."

if ! command -v ollama >/dev/null 2>&1; then
    die "Ollama is not installed."
fi

if ! command -v curl >/dev/null 2>&1; then
    die "curl is not installed."
fi

if [ ! -f "$OLLAMA_MODEL_FILE" ]; then
    die "Ollama Modelfile not found: $OLLAMA_MODEL_FILE"
fi

if [ ! -f "$OLLAMA_MODEL_SERVICE_SOURCE" ]; then
    die "Samaritan model service file not found: $OLLAMA_MODEL_SERVICE_SOURCE"
fi

if [ ! -f "$OLLAMA_LOAD_SCRIPT_SOURCE" ]; then
    die "Samaritan model loader not found: $OLLAMA_LOAD_SCRIPT_SOURCE"
fi

info "Starting Ollama service..."

systemctl enable ollama.service
systemctl start ollama.service

success "Ollama service started."

info "Waiting for Ollama HTTP API..."

until curl -fs http://localhost:11434/ >/dev/null; do
    sleep 1
done

success "Ollama HTTP API is ready."

info "Creating Samaritan Ollama model..."

ollama create samaritan -f "$OLLAMA_MODEL_FILE"

success "Samaritan Ollama model created."

info "Installing Samaritan model loader..."

install \
    -o root \
    -g root \
    -m 755 \
    "$OLLAMA_LOAD_SCRIPT_SOURCE" \
    "$OLLAMA_LOAD_SCRIPT_DEST"

success "Samaritan model loader installed."

info "Installing Samaritan model service..."

install \
    -o root \
    -g root \
    -m 644 \
    "$OLLAMA_MODEL_SERVICE_SOURCE" \
    "$OLLAMA_MODEL_SERVICE_DEST"

success "Samaritan model service installed."

info "Configuring Apache..."

if [ ! -f "$APACHE_SOURCE" ]; then
    die "Apache configuration file not found: $APACHE_SOURCE"
fi

mkdir -p /var/log/apache2

install \
    -o root \
    -g root \
    -m 644 \
    "$APACHE_SOURCE" \
    "$APACHE_DEST"

a2enmod rewrite >/dev/null
a2ensite samaritan.conf >/dev/null
a2dissite 000-default.conf >/dev/null 2>&1 || true

if ! apache2ctl configtest; then
    die "Apache configuration test failed."
fi

success "Apache configuration installed."

info "Reloading systemd..."

systemctl daemon-reload

success "systemd reloaded."

info "Enabling Samaritan services..."

systemctl enable samaritan-daemon.service
systemctl enable samaritan-speech-service.service
systemctl enable samaritan-model.service

success "Samaritan services enabled."

info "Loading Samaritan model..."

if ! systemctl restart samaritan-model.service; then
    echo
    echo "[ERROR] Samaritan model service failed."
    echo
    systemctl status samaritan-model.service --no-pager -l
    echo
    echo "Recent model service logs:"
    journalctl -u samaritan-model.service -n 50 --no-pager
    exit 1
fi

success "Samaritan model loaded and ready."

echo
echo "============================================================"
echo " Samaritan Stage 2 installation complete"
echo "============================================================"
echo

echo "Samaritan root:"
echo "  $SAMARITAN_ROOT"
echo

echo "Services configured:"
echo "  ollama"
echo "  samaritan-model"
echo "  samaritan-daemon"
echo "  samaritan-speech-service"
echo "  apache2"
echo

echo "============================================================"