#!/usr/bin/env python3

import os
import subprocess
import sys

def main():
    """Update CA certificates from CUSTOM_CA_CERT environment variable."""
    if not os.getenv('CUSTOM_CA_CERT'):
        print("No CUSTOM_CA_CERT found, skipping certificate update")
        return 0
    
    cert_path_root = '/usr/local/share/ca-certificates/'
    
    # Ensure the directory exists
    os.makedirs(cert_path_root, exist_ok=True)
    
    # Split certificates
    certs = [cert
             for cert in os.getenv('CUSTOM_CA_CERT').split('-----END CERTIFICATE-----')
             if cert.strip()]
    
    # Write each certificate to a separate file
    for idx in range(len(certs)):
        cert_path = os.path.join(cert_path_root, 'custom-ca-cert-{}.crt'.format(idx))
        with open(cert_path, 'w') as cert_file:
            cert_file.write((certs[idx] + '-----END CERTIFICATE-----').strip())
        print(f"Written certificate to {cert_path}")
    
    # Update CA certificates
    subprocess.check_call(['update-ca-certificates'])
    print(f"Self-signed certificates installed to {cert_path_root}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())