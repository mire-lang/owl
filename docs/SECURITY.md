# OWL Security Audit — Shell Call Inventory

## Overview

OWL invokes subprocesses via argv-safe mechanisms only:
- `proc::run::output(cmd, args)` — **argv-based** (no shell). Safe from injection.
- `proc::run::output_cwd(cmd, args, cwd, merge_err)` — argv-based with working directory and optional stderr merge.
- `proc::run::read_line()` — reads the controlling terminal directly (no subprocess).

`proc::run::shell` has been **fully removed** (avenys 3.24.26 / kioto 2.4.6). The `PAL_ALLOW_LEGACY_SHELL` build flag defaults to `0`, compiling out the last shell surface (`pal_proc_system`, `pal_proc_capture*`, `rt_proc_capture_output`) from the C runtime.

## Audit Results

### All shell calls converted to argv — 0 remaining injection surface

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
| `code/upgrade/mod.mire` | `cd /tmp/.owl-upgrade && mire build ...` | `proc::run::output_cwd("mire" ["build" "code/main.mire" "--release"] tmp_dir true)` | hardcoded tmp path, argv-based |
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
| `code/install/mod.mire` | `cp bin_path/* owl_home/bin` | `ls -1` + per-file `cp` loop (argv) | glob expansion replaced with explicit argv |
| `code/install/mod.mire` | `chmod +x` | argv equivalent | developer-controlled binary name |
| `code/crypto/mod.mire` | `mktemp -d` | `proc::run::output("mktemp" args)` | prefix is owl-controlled |
| `code/crypto/mod.mire` | `sha256sum` (×2) | `util::sha256sum_hex()` | local files |
| `code/crypto/mod.mire` | `printf ... \| base64 -d` (pubkey/sig) | Write to file → `proc::run::output("base64" ["-d" "-i" ...])` | **critical fix** — pubkey_b64 is network-sourced |
| `code/crypto/mod.mire` | `openssl pkey -inform DER ...` | `proc::run::output("openssl" args)` | local tmp paths |
| `code/crypto/mod.mire` | `openssl pkeyutl -verify` (×2) | `proc::run::output("openssl" args)` | local paths |
| `code/crypto/mod.mire` | `base64 -w0 sig_file` | `proc::run::output("base64" ["-w0" sig_file])` | local file |
| `code/profile/mod.mire` | `stat --format=%s ...` | `proc::run::output("stat" args)` | developer-controlled path from owl.toml |
| `code/registry/mod.mire` | `read ans < /dev/tty` (×2) | `proc::run::read_line()` | interactive terminal input — no subprocess |

### Key fixes in this session

1. **Network URL injection in `install` and `lockfile` modules**: `curl` commands with URLs derived from registry index files (network-sourced) were interpolated into shell strings. Converted to `proc::run::output("curl", args)`.
2. **Pubkey injection in `registry` and `crypto` modules**: `printf '%s' "<pubkey>" | sha256sum` and `printf '%s' "<pubkey>" | base64 -d` with network-sourced pubkey data were converted to file-based argv operations.
3. **`grep | sed` pipeline injection in `lockfile` and `install`**: Package names from lockfiles (network-sourced) were interpolated into `grep ... | sed` shell commands. Converted to argv grep + strings-based parsing.
4. **`git clone` injection in `upgrade`**: The `--url` flag value was interpolated into a `git clone` shell command. Converted to argv.
5. **`cp` glob injection in `install`**: `cp bin_path/* owl_home/bin` used shell glob expansion. Converted to `ls -1` + per-file `cp` loop.
6. **TTY prompt injection in `registry`**: `read ans < /dev/tty` spawned a shell subprocess. Converted to `proc::run::read_line()`.
7. **`cd && mire build` in `upgrade`**: Shell `cd` + `&&` idiom replaced with `proc::run::output_cwd` which sets the working directory directly.

## Phase E: Strict Mode

Not yet implemented. The `[security].mode = "strict"` flag in `owl.toml` will:
- Reject any `proc::run::shell` call at runtime (E0021) — now moot since `shell` no longer exists
- Require all subprocess invocations to use `proc::run::output` with argv vectors
- Be enforced by the `trust Tier` system (shell calls require `TrustTier::Shell` which is only granted in open mode)

## WAL Cache Note

The parallel WAL cache corruption (`owl test` with a shared `bin/.cache` truncating same-millisecond
WAL files) was fixed in avenys 3.24.25 (WAL filenames now include pid+seq and are created with
`O_EXCL`; owners clean up only their own files; a `create_dir` init lock serializes cold-cache
setup). Parallel `owl test` is safe with a shared `bin/.cache` — the old
`rm -rf bin/.cache && owl test -j 1` workaround is no longer required.