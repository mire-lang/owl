# Registry Protocol v1

A package registry is a static file server (or any URL that serves files) that
stores metadata, package indices, and signatures. Owl uses registries to
discover, download, and verify packages.

This document describes protocol v1. Anyone can implement a compatible registry
by hosting three files at any URL.

---

## Table of Contents

1. [Registry structure](#1-registry-structure)
2. [registry.json — registry descriptor](#2-registryjson--registry-descriptor)
3. [index.toml — package index](#3-indextoml--package-index)
4. [Signature scheme](#4-signature-scheme)
5. [Package tarball](#5-package-tarball)
6. [publish.toml — publish manifest](#6-publishtoml--publish-manifest)
7. [meta.toml — installed package metadata](#7-metatoml--installed-package-metadata)
8. [Installation flow](#8-installation-flow)
9. [TOFU — Trust On First Use](#9-tofu--trust-on-first-use)
10. [Protocol versioning](#10-protocol-versioning)
11. [Multiple registries and priority](#11-multiple-registries-and-priority)

---

## 1. Registry structure

A registry is identified by a base URL. Owl expects three files at that URL:

```
https://example.com/registry/
 registry.json ← metadata and public key
 index.toml ← package index
 index.toml.sig ← registry signature over index.toml
```

No server-side logic, databases, or dynamic endpoints are needed. A static
file server, a GitHub repository served via raw.githubusercontent.com,
or any CDN that serves these three files is a valid registry.

Owl stores a local copy of each registry under `~/.owl/registries/<name>/`:

```
~/.owl/registries/<name>/
 registry.json ← as downloaded
 index.toml ← as downloaded
 index.toml.sig ← as downloaded
 last_sync ← timestamp of last sync (Unix seconds)
```

---

## 2. registry.json — registry descriptor

This is the first file Owl downloads when a registry is added. It declares the
registry's name, protocol version, and public key for index verification.

### Format

```json
{
 "name": "mire-registry",
 "protocol": 1,
 "public-key": "MCowBQYDK2VwAyEA...",
 "mirrors": [],
 "packages": 138
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Registry name. Used as the directory name in `~/.owl/registries/`. Must be non-empty. |
| `protocol` | integer | yes | Protocol version. Must be `1` for this specification. Owl refuses registries with `protocol > 1`. |
| `public-key` | string | yes | Base64-encoded Ed25519 public key. Used to verify `index.toml.sig`. |
| `mirrors` | array | no | List of mirror URLs for the same registry. Not yet used by Owl. |
| `packages` | integer | no | Approximate package count. Informational only. |
| `url` | string | no | Base URL for fetching `index.toml`. If absent, the URL used to add the registry is used. |

---

## 3. index.toml — package index

A TOML file listing every available package version. Each package version is a
`[[package]]` entry. Older versions remain in the index to guarantee reproducible
builds — a lockfile pins exact versions regardless of new releases.

### Format

```toml
[[package]]
name = "kioto-strings"
version = "1.2.0"
description = "String utilities for Mire"
author = "evelyn"
author-key = "ed25519:MCowBQYDK2VwAyEA..."
tarball = "https://example.com/packages/kioto-strings-1.2.0.tar.zst"
sha256 = "a3f9b5c2d1e0..."
signature = "MCowBQYDK2VwAyEA..."
compiler = ">=0.15.0"
abi = 1
language = ">=0.15.0"
published = "2025-06-01"

[[package]]
name = "kioto-math"
version = "0.4.1"
description = "Math utilities for Mire"
author = "evelyn"
author-key = "ed25519:MCowBQYDK2VwAyEA..."
tarball = "https://example.com/packages/kioto-math-0.4.1.tar.zst"
sha256 = "d4e5f6a7b8c9..."
signature = "MCowBQYDK2VwAyEA..."
compiler = ">=0.15.0"
abi = 1
language = ">=0.15.0"
published = "2025-06-01"
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Package name. Must match `[project].name` in the package's `owl.toml`. |
| `version` | string | yes | Semantic version. Owl normalises `"1.2"` to `"1.2.0"`. |
| `description` | string | no | Short description of the package. |
| `author` | string | no | Author name or handle. |
| `author-key` | string | yes | Base64-encoded Ed25519 public key of the package author. Used to verify `signature`. Prefix `ed25519:` is optional. |
| `tarball` | string | yes | URL of the package tarball. Can be relative to the registry base URL. |
| `sha256` | string | yes | Hex-encoded SHA-256 hash of the tarball. Verified before extraction. |
| `signature` | string | yes | Base64-encoded Ed25519 signature of the tarball, created with the author's private key. Verified against `author-key`. |
| `compiler` | string | no | Minimum compiler version required (e.g. `">=0.15.0"`, `"^0.15.0"`, or exact). |
| `abi` | integer | yes | ABI version number. Currently always `1`. |
| `language` | string | no | Minimum language version required. |
| `published` | string | no | ISO 8601 date (`"2025-06-01"`) or datetime (`"2025-06-01T00:00:00Z"`). |

### Index signature

The file `index.toml.sig` at the registry root contains an Ed25519 signature
over the raw bytes of `index.toml`, created with the registry's private key
(the counterpart of `public-key` in `registry.json`). Owl verifies this
signature after every sync. An invalid signature means the registry is
compromised or the index was tampered with during download.

---

## 4. Signature scheme

Owl uses Ed25519 for all cryptographic signatures. Keys are base64-encoded.

### Key generation

```bash
# Generate a private key
openssl genpkey -algorithm ed25519 -out id_ed25519

# Extract the public key
openssl pkey -in id_ed25519 -pubout -out id_ed25519.pub

# Base64-encode the public key (strip PEM headers)
openssl pkey -in id_ed25519.pub -pubin -outform DER | base64 -w0
```

### Signing a file

```bash
# Sign a file with the private key
openssl pkeyutl -sign -inkey id_ed25519 -rawin -in <file> | base64 -w0
```

### Verifying a signature

```bash
# Verify a file against a public key and signature
echo "<base64-signature>" | base64 -d | \
 openssl pkeyutl -verify -pubin -inkey id_ed25519.pub -rawin -in <file>
```

### Two signatures, two purposes

| Signature | Signer | What it signs | Purpose |
|-----------|--------|---------------|---------|
| `index.toml.sig` | Registry owner | `index.toml` (the index) | Proves the index is authentic. A compromised registry cannot forge author signatures. |
| `signature` in `[[package]]` | Package author | The tarball | Proves authorship. A compromised registry cannot publish packages under someone else's name. |

These are independent. An author can prove ownership of their packages without
trusting the registry operator.

---

## 5. Package tarball

A package is distributed as a `.tar.zst` archive (tar compressed with zstd).

### Archive contents

```
kioto-strings-1.2.0.tar.zst
 owl.toml ← project manifest
 code/ ← source code
 tests/ ← test files (optional)
 docs/ ← documentation (optional)
 README.md ← readme (optional)
```

The archive is created from the project root. The top-level directory structure
mirrors the source project. No nested parent directory is added — extracting
creates `owl.toml`, `code/`, `tests/`, etc. directly in the current directory.

### Naming convention

```
<name>-<version>.tar.zst
```

Example: `kioto-strings-1.2.0.tar.zst`

### SHA-256

Every tarball has a SHA-256 checksum listed in `index.toml`. Owl verifies this
hash before extracting. If the hash does not match, Owl deletes the downloaded
file and reports an error. No partial files are left on disk.

---

## 6. publish.toml — publish manifest

Generated by `owl -e` (export). This file is a ready-to-submit entry for a
registry's `index.toml`.

### Format

```toml
# Generated by owl -e — verify before submitting to registry

[package]
name = "mylib"
version = "1.0.0"
archive = "mylib-1.0.0.tar.zst"
sha256 = "abc123..."
public-key = "MCowBQYDK2VwAyEA..."
signature = "base64signature..."
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | From `owl.toml [project].name`. |
| `version` | string | yes | From `owl.toml [project].version`. |
| `archive` | string | yes | Tarball filename. |
| `sha256` | string | yes | Hex-encoded SHA-256 of the tarball. |
| `public-key` | string | no | Author's Ed25519 public key. Absent in `--dry-run` mode. |
| `signature` | string | no | Ed25519 signature of the tarball. Absent in `--dry-run` mode. |

The archive, signature file (`.sig`), and public key file (`.pub`) are all
emitted alongside `publish.toml` during export.

---

## 7. meta.toml — installed package metadata

Written to `~/.owl/lib/<name>/<version>/meta.toml` after installation. Records
what was installed and which compiler/ABI it targets.

### Format

```toml
[package]
name = "mylib"
version = "1.2.3"
compiler = "mire"
abi = 1
language = "mire v0.1.0"
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Package name. |
| `version` | string | yes | Installed version. |
| `compiler` | string | yes | Compiler command used to build. |
| `abi` | integer | yes | ABI version of the installed package. |
| `language` | string | yes | Language version string. |

Owl reads `meta.toml` during `owl check` to verify ABI compatibility between
dependencies and the current compiler.

---

## 8. Installation flow

When a user runs `owl -S <name>`, Owl follows these steps:

```
 1. Search registries in priority order
 2. Resolve version (best match for constraint)
 3. Download tarball from the URL in index.toml
 4. Verify SHA-256 of the downloaded tarball
 → mismatch: delete tarball, error
 5. Verify Ed25519 signature of the tarball
 → key unknown: TOFU prompt (see §9)
 → key revoked: error, abort
 → signature invalid: error, abort
 6. Extract tarball to ~/.owl/lib/<name>/<version>/
 7. Set extracted directory to read-only
 8. Write meta.toml with version, compiler, abi, language
 9. Update owl.lock with exact name, version, sha256, registry
 (owl.lock is never modified by sync — only by install/uninstall)
 10. Add dependency to owl.toml if not already declared
```

### Error handling

- **Download fails**: network error, abort. No files written.
- **SHA-256 mismatch**: file corrupted during download or registry compromised.
 Delete the tarball, error.
- **Signature invalid**: tarball does not match the author's key. The author
 key or the tarball may be compromised. Error, abort.
- **Key revoked**: the author key was explicitly revoked by the user.
 Error, abort.
- **ABI mismatch**: the package was compiled for a different ABI version.
 Owl can auto-recompile if source is available, otherwise error.

---

## 9. TOFU — Trust On First Use

Owl uses Trust On First Use (TOFU) for author public keys. The first time a
new author key is encountered, Owl prompts the user to confirm trust.

### Key storage

```
~/.owl/keys/
 trusted.toml ← keys the user has accepted
 revoked.toml ← keys the user has explicitly revoked
```

### Trust flow

 1. **First encounter**: Owl shows the key fingerprint (SHA-256 of the
 base64-encoded public key) and asks for confirmation:
 ```
 unknown author key: evelyn
 fingerprint: a3f9b5c2d1e0...
 trust this key? [y/N]
 ```
 2. **Accepted**: The key is added to `trusted.toml`. Future packages from
 the same author are accepted silently.
 3. **Rejected**: Installation aborts. The key is not stored.
 4. **Already trusted**: No prompt. Package installs normally.
 5. **Revoked**: The key is in `revoked.toml`. Owl refuses any package signed
 with that key. Un-revocation requires manual editing.

### Trust model

- Trust is per-author-key, not per-package.
- Trusting an author means trusting all current and future packages signed
 by that key.
- Registry operators and package authors are separate trust domains.
 The registry key verifies the index. Author keys verify individual packages.
- Revocation is local to each Owl installation. There is no global PKI.

---

## 10. Protocol versioning

The `protocol` field in `registry.json` governs the registry format.

- **Protocol 1**: This specification.
- **Future protocols**: When Owl encounters a `protocol` value greater than
 what it supports, it refuses the registry with a clear error:

 ```
 error: registry 'example-registry' uses protocol v2
 this version of Owl only supports protocol v1
 → update Owl to add this registry
 ```

This allows the protocol to evolve without breaking older Owl versions.
A registry can also serve multiple protocols from the same URL by having
separate `registry.json` files (e.g., `registry-v1.json`, `registry-v2.json`),
but that is outside this specification.

### Backward compatibility

- Registries running protocol v1 will continue to work with future Owl
 versions that support protocol v1 (even if they also support v2).
- Owl never modifies `index.toml` or `registry.json`. It only reads them.
- All files use standard, well-documented formats (JSON, TOML, base64).

---

## 11. Multiple registries and priority

Owl can have multiple registries active at the same time. Registries are
queried in priority order (lower number = higher priority).

```
 1 mire-registry (official) synced 2h ago 138 packages
 2 company (private) synced 1h ago 42 packages
```

### Priority rules

- Registries with higher priority (lower number) are searched first.
- A package in a lower-priority registry never overrides a package of the
 same name in a higher-priority registry.
- The user can change priority with `owl reg priority <name> <n>`.

### Registry states

- **Enabled**: Active, included in sync and search.
- **Disabled**: Present on disk but skipped during sync and search.
 Signaled by the presence of a `.disabled` file in the registry directory.
- **Removed**: Deleted from disk entirely.

### Sync

`owl -Sy` iterates all enabled registries, downloads the latest `index.toml`
and `index.toml.sig`, verifies the signature, and updates `last_sync`.

---

## Appendix A: File format reference

| File | Location | Format |
|------|----------|--------|
| `registry.json` | `<registry-url>/registry.json` | JSON |
| `index.toml` | `<registry-url>/index.toml` | TOML |
| `index.toml.sig` | `<registry-url>/index.toml.sig` | Raw Ed25519 signature, base64-encoded |
| `publish.toml` | `<project>/publish.toml` | TOML |
| `meta.toml` | `~/.owl/lib/<name>/<version>/meta.toml` | TOML |
| `owl.lock` | `<project>/owl.lock` | TOML |
| `owl.toml` | `<project>/owl.toml` | TOML |
| `trusted.toml` | `~/.owl/keys/trusted.toml` | TOML |
| `revoked.toml` | `~/.owl/keys/revoked.toml` | TOML |
| `last_sync` | `~/.owl/registries/<name>/last_sync` | Unix timestamp (text) |
| `.disabled` | `~/.owl/registries/<name>/.disabled` | Empty file (presence = disabled) |

## Appendix B: Creating a minimal registry

To create a working registry, you need:

1. An Ed25519 keypair (for signing the index).
2. A `registry.json` file with `name`, `protocol: 1`, and `public-key`.
3. An `index.toml` with at least one `[[package]]` entry.
4. An `index.toml.sig` — the Ed25519 signature of `index.toml`.

Host these three files at any URL. That's it.

```bash
# 1. Generate a registry key
openssl genpkey -algorithm ed25519 -out registry-key
openssl pkey -in registry-key -pubout -out registry-key.pub
PUBKEY=$(openssl pkey -in registry-key.pub -pubin -outform DER | base64 -w0)

# 2. Create registry.json
cat > registry.json << EOF
{
 "name": "my-registry",
 "protocol": 1,
 "public-key": "$PUBKEY"
}
EOF

# 3. Create index.toml
cat > index.toml << EOF
[[package]]
name = "hello"
version = "0.1.0"
author = "me"
author-key = "$PUBKEY"
tarball = "https://example.com/hello-0.1.0.tar.zst"
sha256 = "0000000000000000000000000000000000000000000000000000000000000000"
signature = "placeholder"
abi = 1
EOF

# 4. Sign the index
openssl pkeyutl -sign -inkey registry-key -rawin -in index.toml | base64 -w0 > index.toml.sig

# 5. Upload registry.json, index.toml, index.toml.sig to your server
```
