#!/usr/bin/env python3
# This script is owned by root and can only be executed (not modified) by the terrat user
# It safely installs CA certificates from the CUSTOM_CA_CERT environment variable

import os
import sys
import subprocess
import re

def main():
    # Check if running as root
    if os.getuid() != 0:
        print("Error: This script must be run as root", file=sys.stderr)
        sys.exit(1)

    # Check if CUSTOM_CA_CERT is set
    custom_ca_cert = os.environ.get('CUSTOM_CA_CERT')
    if not custom_ca_cert:
        print("No custom CA certificates to install (CUSTOM_CA_CERT not set)")
        sys.exit(0)

    cert_dir = "/usr/local/share/ca-certificates"

    # Clean up any existing custom-ca-cert-*.crt files
    try:
        for filename in os.listdir(cert_dir):
            if filename.startswith("custom-ca-cert-") and filename.endswith(".crt"):
                os.remove(os.path.join(cert_dir, filename))
    except Exception as e:
        print(f"Warning: Could not clean up old certificates: {e}")

    # Split certificates on END CERTIFICATE markers
    # This handles certificates that may or may not have proper newlines
    cert_pattern = r'(-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----)'
    certs = re.findall(cert_pattern, custom_ca_cert, re.DOTALL)

    if not certs:
        print("No valid certificates found in CUSTOM_CA_CERT")
        sys.exit(1)

    print(f"Processing {len(certs)} certificate(s)...")

    # Write each certificate to a separate file
    for idx, cert in enumerate(certs):
        cert_path = os.path.join(cert_dir, f"custom-ca-cert-{idx}.crt")

        # Ensure the certificate has proper formatting
        # Clean up any extra whitespace and ensure proper line endings
        cert_lines = cert.strip().split('\n')
        clean_cert = '\n'.join(line.strip() for line in cert_lines)

        # Make sure certificate ends with a newline
        if not clean_cert.endswith('\n'):
            clean_cert += '\n'

        try:
            with open(cert_path, 'w') as f:
                f.write(clean_cert)
            print(f"Wrote certificate {idx} to {cert_path}")
        except Exception as e:
            print(f"Error writing certificate {idx}: {e}", file=sys.stderr)
            sys.exit(1)

    # Update CA certificates
    print(f"Installing {len(certs)} custom CA certificate(s)...")
    try:
        result = subprocess.run(['/usr/sbin/update-ca-certificates'],
                              capture_output=True,
                              text=True,
                              check=True)
        if result.stdout:
            print(result.stdout)
        print(f"Successfully installed {len(certs)} custom CA certificate(s)")
    except subprocess.CalledProcessError as e:
        print(f"Error updating CA certificates: {e}", file=sys.stderr)
        if e.stderr:
            print(e.stderr, file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()