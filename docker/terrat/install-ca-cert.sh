#!/bin/sh
# This script is owned by root and can only be executed (not modified) by the terrat user
# It safely installs a CA certificate passed via stdin

set -e

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

# Read the certificate path and content from stdin
# Format expected: <cert_path>|<cert_content>
read -r input

cert_path=$(echo "$input" | cut -d'|' -f1)
cert_content=$(echo "$input" | cut -d'|' -f2-)

# Validate the certificate path
if ! echo "$cert_path" | grep -q "^/usr/local/share/ca-certificates/custom-ca-cert-[0-9]*\.crt$"; then
    echo "Error: Invalid certificate path. Must match /usr/local/share/ca-certificates/custom-ca-cert-*.crt" >&2
    exit 1
fi

# Write the certificate content to the specified path
echo "$cert_content" > "$cert_path"

# Update CA certificates
/usr/sbin/update-ca-certificates

echo "Certificate installed successfully at $cert_path"