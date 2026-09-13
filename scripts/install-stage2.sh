#!/bin/bash

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

install -o root -g root -m 644 "$DAEMON_SERVICE_SOURCE" "$DAEMON_SERVICE_DEST"
success "Daemon service installed."

info "Installing Samaritan speech service..."

if [ ! -f "$SPEECH_SERVICE_SOURCE" ]; then
    die "Speech service file not found: $SPEECH_SERVICE_SOURCE"
fi

install -o root -g root -m 644 "$SPEECH_SERVICE_SOURCE" "$SPEECH_SERVICE_DEST"
success "Speech service installed."

info "Configuring Apache..."

if [ ! -f "$APACHE_SOURCE" ]; then
    die "Apache configuration file not found: $APACHE_SOURCE"
fi

mkdir -p /var/log/apache2
install -o root -g root -m 644 "$APACHE_SOURCE" "$APACHE_DEST"

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
systemctl enable samaritan-daemon
systemctl enable samaritan-speech-service
success "Samaritan services enabled."

echo
echo "============================================================"
echo " Samaritan Stage 2 installation complete"
echo "============================================================"
echo
echo "Samaritan root:"
echo "  $SAMARITAN_ROOT"
echo
echo "Services configured:"
echo "  samaritan-daemon"
echo "  samaritan-speech-service"
echo "  apache2"
echo
echo "============================================================"