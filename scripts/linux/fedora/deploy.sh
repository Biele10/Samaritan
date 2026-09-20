#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=========================================="
echo "Samaritan - Full Deployment"
echo "=========================================="
echo

if ! "$SCRIPT_DIR/create-build.sh"; then
    echo
    echo "=========================================="
    echo "Build stage failed."
    echo "Deployment stopped."
    echo "=========================================="
    exit 1
fi

if ! "$SCRIPT_DIR/build-upload.sh"; then
    echo
    echo "=========================================="
    echo "Server deployment failed."
    echo "=========================================="
    exit 1
fi

echo
echo "=========================================="
echo "Samaritan deployment complete."
echo "=========================================="
echo

exit 0