#!/bin/bash

CERT_DIR=./certbot/conf/live/golem-dev.biodata.ceitec.cz

if [[ ! -f "$CERT_DIR/fullchain.pem" || ! -f "$CERT_DIR/privkey.pem" ]]; then
    echo "Generating self-signed certificate for local dev..."
    mkdir -p "$CERT_DIR"
    openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem" \
        -days 365 \
        -subj "/CN=localhost"
    echo "✔️  Self-signed certificate generated at $CERT_DIR"
else
    echo "✅ Self-signed certificate already exists."
fi
