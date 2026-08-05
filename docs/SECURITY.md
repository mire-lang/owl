# OWL Security Audit — Shell Call Inventory

## Overview

OWL invokes subprocesses via two mechanisms:
- `proc::run::output(cmd, args)` — **argv-based** (no shell). Safe from injection.
- `proc::run::shell(cmd)` — **shell-based**. Subject to shell injection if any argument is derived from untrusted input.

This document audits every remaining `proc::run::shell` call in the OWL codebase, classifies its risk, and explains why it is acceptable or what was done to mitigate it.

## Audit Results (as of session D)

### Converted to argv (no shell) — 0 remaining injection surface

| File | Former shell call | Now argv | Rationale |
|------|------------------|----------|-----------|
| `code/lockfile/mod.mire` | `curl ... tarball_url` | `proc::run::output("curl" args)` | tarball_url derived from registry index (network-sourced) |
| `code/lockfile/mod.mire` | `grep -c ... dep_name` | `proc::run::output("grep" args)` | dep_name from lockfile (network-sourced) |
| `code/lockfile/mod.mire` | `ls reg_dir` | `proc::run::output("ls" args)` | reg_dir is local trusted path |
| `code/registry/mod.mire` | `curl ... try_url` (×2) | `proc::run::output("curl" args)` | try_url from registry.json (network-sourced) |
| `code/registry/mod.mire` | `rm -rf tmp` | `proc::run::output("rm" args)` | tmp dir is owl-controlled |
| `code/registry/mod.mire` | `printf ... \| sha256sum` (pubkey) | Write to file → `proc::run::output("sha256sum" args)` | pubkey is network-sourced — injection risk |
| `code/registry/mod.mire` | `ls reg_dir` | `proc::run::output("ls" args)` | local trusted path |
| `code/registry/mod.mire` | `stat -c%s sig_file` | `proc::run::output("stat" args)` | sig_file is local |
| `code/registry/mod.mire` | `printf '%s' $(date +%s)` | `proc::run::output("date" ["+%s"])` + `fs::write` | local |
| `code/semver/mod.mire` | `grep -A1 ... \| grep ... \| sed ...` | `proc::run::output("grep" args)` + strings parsing | dep_name from lockfile (network-sourced) |
| `code/semver/mod.mire` | `ls reg_dir` | `proc::run::output("ls" args)` | local trusted path |
| `code/info/mod.mire` | `uname -m`, `uname -s \| tr ...` | `proc::run::output("uname" args)` + `strings::lower()` | local system info |
| `code/info/mod.mire` | `mire --version` | `proc::run::output("mire" ["--version"])` | local compiler |
| `code/info/mod.mire` | `llvm-config --version` | `proc::run::output("llvm-config" ["--version"])` | local tool |
| `code/gc/mod.mire` | `ls lib_dir`, `rm -rf ver_dir`, `rmdir pkg_dir` | argv equivalents | local filesystem paths |
| `code/export/mod.mire` | `which tar/zstd/openssl` | `proc::run::output("which" args)` | tool lookup |
| `code/export/mod.mire` | `tar --zstd -cf ...`, `tar -I zstd -cf ...` | `proc::run::output("tar" args)` | developer-controlled paths |
| `code/export/mod.mire` | `openssl genpkey/pkey` | `proc::run::output("openssl" args)` | developer-controlled paths |
| `code/export/mod.mire` | `cat pubkey \| base64 -w0` | `proc::run::output("base64" ["-w0" pub_key])` | local file |
| `code/export/mod.mire` | `openssl pkeyutl -sign` | `proc::run::output("openssl" args)` | local paths |
| `code/export/mod.mire` | `printf '%s' sig \| base64 -d > file` | Write to temp → `proc::run::output("base64" ["-d" "-i" tmp "-o" out])` | base64 data is safe (A-Za-z0-9+/=) |
| `code/export/mod.mire` | `cp pub_key pub_file` | `proc::run::output("cp" args)` | developer-controlled paths |
| `code/upgrade/mod.mire` | `rm -rf tmp_dir` | `proc::run::output("rm" args)` | hardcoded tmp path |
| `code/upgrade/mod.mire` | `git clone --depth 1 url tmp` | `proc::run::output("git" args)` | **critical fix** — url was user-provided via `--url` flag |
| `code/upgrade/mod.mire` | `ln -sfn ...` | `proc::run::output("ln" args)` | local paths |
| `code/upgrade/mod.mire` | `install -m 0755 ...` | `proc::run::output("install" args)` | local paths |
| `code/util/mod.mire` | `mkdir -p`, `rm -rf`, `chmod` | argv equivalents | local trusted paths |
| `code/util/mod.mire` | `mire --version` | `proc::run::output("mire" ["--version"])` | local compiler |
| `code/util/mod.mire` | `grep -rh ... \| sed ...` | `proc::run::output("grep" args)` + strings parsing | pattern is fixed string |
| `code/util/mod.mire` | `sha256sum file` | `util::sha256sum_hex(file)` helper | local file |
| `code/check/mod.mire` | `mire --version` | `proc::run::output("mire" ["--version"])` | local compiler |
| `code/check/mod.mire` | `find ... \| wc -l` (×4) | `proc::run::output("find" args)` + `len(split(...))` | local filesystem paths |
| `code/install/mod.mire` | `ls reg_dir`, `cat idx_path` | `proc::run::output("ls" args)` / `fs::read()` | local trusted paths |
| `code/install/mod.mire` | `grep -A10 ... \| sed` (×2) | `proc::run::output("grep" args)` + strings parsing | dep_name from lockfile (network-sourced) |
| `code/install/mod.mire` | `curl tarball_url` | `proc::run::output("curl" args)` | **critical fix** — tarball_url from registry index |
| `code/install/mod.mire` | `stat -c%s tarball` | `proc::run::output("stat" args)` | local file |
| `code/install/mod.mire` | `sha256sum tarball` | `util::sha256sum_hex(tarball)` | local file |
| `code/install/mod.mire` | `curl sig_url` | `proc::run::output("curl" args)` | **critical fix** — sig_url derived from tarball_url |
| `code/install/mod.mire` | `rm -f` (×6) | `proc::run::output("rm" args)` | local paths |
| `code/install/mod.mire` | `tar -xzf ... -C ...` | `proc::run::output("tar" args)` | local paths |
| `code/install/mod.mire` | `cp named owl_home/bin`, `chmod +x` | argv equivalents | developer-controlled binary name |
| `code/crypto/mod.mire` | `mktemp -d` | `proc::run::output("mktemp" args)` | prefix is owl-controlled |
| `code/crypto/mod.mire` | `sha256sum` (×2) | `util::sha256sum_hex()` | local files |
| `code/crypto/mod.mire` | `printf ... \| base64 -d` (pubkey/sig) | Write to file → `proc::run::output("base64" ["-d" "-i" ...])` | **critical fix** — pubkey_b64 is network-sourced |
| `code/crypto/mod.mire` | `openssl pkey -inform DER ...` | `proc::run::output("openssl" args)` | local tmp paths |
| `code/crypto/mod.mire` | `openssl pkeyutl -verify` (×2) | `proc::run::output("openssl" args)` | local paths |
| `code/crypto/mod.mire` | `base64 -w0 sig_file` | `proc::run::output("base64" ["-w0" sig_file])` | local file |
| `code/profile/mod.mire` | `stat --format=%s ...` | `proc::run::output("stat" args)` | developer-controlled path from owl.toml |

### Acceptable shell uses (documented, low risk)

| File | Call | Rationale |
|------|------|-----------|
| `code/upgrade/mod.mire` | `cd /tmp/.owl-upgrade && mire build ...` | `tmp_dir` is hardcoded (`/tmp/.owl-upgrade`), not user input. The `cd &&` shell idiom is required to set the working directory for the build. |
| `code/registry/mod.mire` | `read ans < /dev/tty` (×2) | Interactive terminal input — cannot be converted to argv. Only runs in interactive `owl registry add` / `owl registry sync` commands. |
| `code/install/mod.mire` | `cp bin_path/* owl_home/bin` | Glob expansion (`*`) is a shell feature. `bin_path` is derived from `owl.toml` (developer-controlled). |
| `code/main.mire` | `mire test <flags>` | Converted to argv in this session. |

### Key fixes in this session

1. **Network URL injection in `install` and `lockfile` modules**: `curl` commands with URLs derived from registry index files (network-sourced) were interpolated into shell strings. Converted to `proc::run::output("curl", args)`.
2. **Pubkey injection in `registry` and `crypto` modules**: `printf '%s' "<pubkey>" | sha256sum` and `printf '%s' "<pubkey>" | base64 -d` with network-sourced pubkey data were converted to file-based argv operations.
3. **`grep | sed` pipeline injection in `lockfile` and `install`**: Package names from lockfiles (network-sourced) were interpolated into `grep ... | sed` shell commands. Converted to argv grep + strings-based parsing.
4. **`git clone` injection in `upgrade`**: The `--url` flag value was interpolated into a `git clone` shell command. Converted to argv.

## Phase E: Strict Mode

Not yet implemented. The `[security].mode = "strict"` flag in `owl.toml` will:
- Reject any `proc::run::shell` call at runtime (E0021)
- Require all subprocess invocations to use `proc::run::output` with argv vectors
- Be enforced by the `trust Tier` system (shell calls require `TrustTier::Shell` which is only granted in open mode)

## WAL Cache Note

`owl test` (parallel) corrupts the WAL cache. Always use `rm -rf bin/.cache && owl test -j 1`.