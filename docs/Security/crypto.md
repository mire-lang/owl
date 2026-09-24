# Security - Crypto v1.1.0

## Ed25519 Signing v1.1.0

Owl uses Ed25519 cryptography for package signing and verification.

### Key Generation v1.1.0

```bash
# Generate a new Ed25519 key pair
owl genpkey -algorithm ed25519 -out <privkey_file>
```

### Signing an Archive v1.1.0

```bash
# Sign the archive file
owl pkeyutl -sign -inkey <privkey> -in <archive> -rawin -out <sig_file>
```

### Base64 Encoding v1.1.0

The signature and public key are encoded in base64 without line wrapping:

```bash
# Encode signature
base64 -w0 <sig_file> > <sig_file>.b64

# Encode public key
base64 -w0 <privkey_pub> > <pubkey>.b64
```

### Verification v1.1.0

```bash
# Verify a package signature
crypto::verify::ed25519(pubkey_b64 data_file sig_b64)
```

Returns `true` if the signature is valid, `false` otherwise.

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
