# Security - Export Signing v1.1.0

## Owl v1.1.0 Release Notes

### Export Signing

Owl uses Ed25519 signatures for package exports. The signing process:

1. Generates an ED25519 key pair
2. Signs the archive file
3. Encodes the public key and signature in base64
4. Includes them in the `publish.toml` file

### Verification v1.1.0

Packages are verified by:
1. Decoding the base64-encoded public key
2. Decoding the base64-encoded signature
3. Using `crypto::verify::ed25519()` to validate the signature against the archive

### Security Notes v1.1.0

- Ed25519 provides 128 bits of security
- Keys are generated using `pal_secret_create` with algorithm 1
- Signatures are 64 bytes
- Public keys are encoded in PEM format for storage

### Registry Integration v1.1.0

When installing packages, Owl:
1. Downloads the package archive
2. Verifies the Ed25519 signature
3. Checks the SHA-256 or SHA-512 checksum
4. Extracts the package to the libraries directory
5. Sets the installed package as read-only

### Supported Operations v1.1.0

- Key pair generation
- Archive signing
- Signature verification
- Checksum validation
- Base64 encoding/decoding

No external `openssl` or `base64` commands are required - all operations use
the kioto crypto library internally.
