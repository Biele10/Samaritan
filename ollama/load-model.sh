#!/usr/bin/env bash

set -e

OLLAMA_URL="http://localhost:11434"

echo "Waiting for Ollama..."

until /usr/bin/curl -fs "$OLLAMA_URL/" >/dev/null; do
    sleep 1
done

echo "Ollama is ready."

echo "Loading Samaritan model..."

if ! /usr/bin/curl -fS \
    "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "samaritan",
        "prompt": "",
        "stream": false,
        "think": false,
        "keep_alive": -1
    }' >/dev/null; then

    echo
    echo "Failed to load Samaritan model."
    exit 1
fi

echo "Samaritan model loaded."

echo "Warming up Samaritan inference..."

if ! /usr/bin/curl -fS \
    "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "samaritan",
        "prompt": "Ready.",
        "stream": false,
        "think": false,
        "keep_alive": -1
    }' >/dev/null; then

    echo
    echo "Failed to warm up Samaritan model."
    exit 1
fi

echo
echo "Samaritan model is ready."