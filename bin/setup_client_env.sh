#!/bin/bash
# Set SSL-related environment variables for client applications

echo "Setting client SSL environment variables..."

# If your client application still encounters certificate issues with self-signed certificates,
# use the following environment variables:

# 1. Disable Node.js SSL verification (not recommended, for testing only)
export NODE_TLS_REJECT_UNAUTHORIZED=0

# 2. Set custom CA certificate path
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs

# 3. Set additional CA certificates for Node.js
export NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/api.openai.com.crt

echo "Environment variables set:"
echo "NODE_TLS_REJECT_UNAUTHORIZED=${NODE_TLS_REJECT_UNAUTHORIZED}"
echo "SSL_CERT_FILE=${SSL_CERT_FILE}"
echo "NODE_EXTRA_CA_CERTS=${NODE_EXTRA_CA_CERTS}"
echo ""
echo "You can now start your client application"
