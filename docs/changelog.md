## [1.2.3] - 2026-09-26

### Fixed
- **Path dependencies were never written to the lockfile** — `dep_resolver::resolve()` skipped
  every dep that was absent from the registry index (`version == ""` → `continue`), so a project
  whose deps are all `path = ...` got a lock with zero `[[package]]` entries. `lockfile::in_sync()`
  compares locked packages against declared deps, so the lock was permanently out of sync and
  **every** command re-resolved dependencies and exited without doing any work. Local/path deps
  are now recorded with `registry = "local"`, their declared path, and their pinned version when
  `owl.toml` declares one (new `dep_resolver::declared_dep_field()` helper, deliberately local to
  avoid a `deps` ↔ `dep_resolver` load cycle).
- **Lockfile entry alignment** — `lockfile::packages()` and `get_field()` match column-aligned
  keys (`name␣␣␣␣␣=`, `version␣␣=`, `path␣␣␣␣␣=`, `registry␣=`), but `dep_resolver` wrote
  single-space keys — so the writer produced locks its own reader could not parse, and its
  "already locked?" search key never matched. Writers and search keys now use the aligned format.
- **`[c] sources` accepted a `.mire` file** — `owl.toml` listed `code/_externs/mod.mire` as a C
  source, which the C compiler then tried to build, failing every `owl test` target with
  `Could not publish C object ... No such file or directory`. It is a Mire module and is compiled
  by the Mire compiler; removed from `[c] sources`.
- **Undefined identifier in `lockfile::generate()`** — a typo (`nl_c` for `nl3`) referenced an
  undeclared name, which reached LLVM as `@nl_c` and aborted `opt` with
  `use of undefined value '@nl_c'`.
- **Undefined identifier in `new`** — the final confirmation messages interpolated an undeclared
  `name`; now `vec::get::str(args 0)`.

### Changed
- **Ownership (MSS) fixes across 15 modules** — `dep_resolver` now copies loop-invariant
  `:str` values (`strings::copy`) before reuse, `util::mkdir_p` takes `&str`, and the vector
  externs were replaced by the public `mire::vec` API (`vec::len`, `vec::get::str`) with explicit
  `load mire::vec` per consuming module. Each module that calls `proc::` now declares
  `load kioto::proc` itself: reachable-import selection does not inherit another module's loads.

## [1.2.2] - 2026-09-26

### Changed
- **Dependency bump** — kioto updated to 2.5.2 (adds `compat-v2` and `minimal-runtime` feature flags, compatibility shim).
- **Feature flag support** — owl now forwards `[features]` from kioto when building.

## [1.2.1] - 2026-09-26

### Added
- **P0 Infrastructure: cfg/cache/libs/bin separation** — New `util` path helpers for `~/.owl/{cfg,cache,libs,keys}` layout; versioned libs with `Name@ver` directories and active symlinks (`Name -> Name@ver`); `owl.cfg` get/set/list for standard config keys; canonical lockfile copy to `cache/resolution/<sha>/lock.toml`; `checkup --fix lock` restores from cache.
- **`owl new` minimal template** — Creates only `owl.toml`, `bin/`, and `src/main.mire` with v1.2.0 format.
- **CLI flag validation** — `args::allowed_flags()` and `args::validate()` provide tree-style error messages for unknown flags per subcommand.
- **Project `[c]` forwarding** — `owl build`/`run`/`test` now forward `[c] sources`, `[c] include`, `[c] libs`, `[c] cflags` from `owl.toml` to the compiler. `[c] include` directories emitted as `-I` cflags.
- **Test runner integration** — `check::run_tests()` generates test config and invokes compiler's `test` command with proper flags and lib-dir.

### Changed
- **Dependency commands** — `deps clean` removes unused deps and regenerates lockfile; `deps load` scans sources for `load` statements and injects missing deps; `deps deps` prints dependency tree.
- **`proc::run::output` → `proc::run_output`** — Updated test suite to use new kioto API.
- **`testlib` path** — Changed from local `./testlib` to `~/.owl/libs/testlib` for consistency.
- **Lockfile generation** — Writes main `owl.lock`; cache write deferred to avoid ownership issues.

### Fixed
- **`write_mire_config` debug output** — Added debug file writes to trace config generation.
- **Archive bridge** — Only adds `native/archive.c` if not already declared in `owl.toml`; does not add `archive` to libs (source compiled directly).
- **Lockfile restore** — Reads cached lock file content before writing to avoid ownership issues.

### Known Limitations (Stubs)
- **`install package/clone`** — Minimal stubs due to compiler ownership analysis issues; full implementation pending compiler fix.
- **`checkup --fix deps` / `lockfile.ensure`** — Stubbed for same reason.
- **`clean`, `load`, `install`, `deps` commands** — Stubbed in main dispatch.

# Owl Changelog

## [1.1.2] - 2026-09-22

### Fixed
- **Main entry point restored**: `code/main.mire` now has a proper `pub fn main: ()` with full command dispatch (build, run, test, check, info, checkup, profile, new, clean, load, install, export, reg, deps, gc, upgrade, help, version)
- **proc module integration fixed**: `code/util/mod.mire` now declares PAL proc externs directly (`pal_proc_create`, `pal_proc_wait`, `pal_proc_kill`, `pal_proc_close`, `rt_build_argv`, `rt_free_argv`, `rt_vec_len`, `rt_proc_capture_argv`, `rt_proc_capture_argv2`, `rt_proc_last_exit`, `rt_read_tty`) instead of depending on `kioto::proc` which could not be loaded due to Mire's module resolution limitations
- **Build configuration updated**: Uses manual `mire-config.toml` for native archive linking (`native/archive.c`, `archive` lib)
- **Command modules updated**: All modules (build, check, crypto, export, info, install, lockfile, profile, registry, upgrade) now call PAL/rt_* functions directly instead of `proc::run_*`

### Changed
- **owl.toml version 1.1.2**: Updated dependency paths to `~/.owl/libs/mire` and `~/.owl/libs/kioto`
- **Kioto proc module flattened**: `kioto::proc` now exports all functions at top level (`run_create`, `run_spawn`, `run_output`, `run_output_cwd`, `run_last_exit`, `run_read_line`, `wait`, `kill`, `close`, `stream`) for direct loading

## [1.1.1] - 2026-09-18

### Fixed
- **Project `[c]` forwarded to the compiler**: `owl build`/`owl run`/`owl test`
  now forward a project's native C configuration (`[c] sources`, `[c] include`,
  `[c] libs`, `[c] cflags`) into the normalized Mire config. Previously the
  generated config hardcoded empty `sources`/`libs` (only the archive bridge),
  so projects that ship their own `rt_*`/PAL helpers in C (e.g. token's
  FreeType/SVG runtime) built but failed to link.
- **New `[c]` utilities**: `toml_get_array`/`toml_array_literal` read `[c]`
  arrays from `owl.toml`; `[c] include` directories are emitted as
  `-I<dir>` `cflags` (Avenys' normalized config contract has no `include` key).

## [1.1.0] - 2026-09-16

### Lockfile V3 Automatic Generation
- `owl ensure` now returns `true` immediately if no `owl.lock` exists
- Project new → lockfile V3 automatically generated on first `owl checkup`/`build`/`run`
- Lockfile format: `manifest-sha512`, `[[package]]` entries with name/version/path/registry/compiler/language
- V1 and V2 still readable and editable via `owl.toml [owl@lock] version`

### Configuration System `[cfg]`
- New `[cfg]` section in `owl.toml` with `lock` and `update@lock` fields
- `lock = 1` enables lockfile verification, `lock = 0` disables it
- `update@lock` modes: `Build` (always on build), `Changes` (only on owl.toml/load changes), `None` (never auto-update)
- Default: `lock = 1`, `update@lock = "Build"` for new projects
- `owl cfg` command family for managing configuration (planned for 1.2.0)

### Dependency Checksums V3
- `dependency_checksum(pkg_name installed_version)`: Verifies SHA-512 checksums
- Checks `~/.owl/cache/lockfile_checksums` for stored checksums
- Auto-generates and stores missing checksums
- Validates kioto@x.x.x checksums against installed version

### Exports Verification V3
- `exports_verified(pkg_name)`: Validates exported modules from lockfile
- Checks installed package's meta.toml for exports field
- Issues warnings for mismatches or missing format

### Heavy logic delegated to Kioto
- `code/crypto` is now a thin layer: SHA-256/SHA-512 and Ed25519
  verification call `kioto::crypto` directly (no `openssl`, no temp files, no
  shell). `owl::crypto::verify::ed25519` uses
  `kioto::crypto::sign::ed25519::public::verify_b64`, with new `sigfile` and
  `pemfile` variants backed by `verify_file` / `raw_b64_from_pem`.
- Lockfile checksums use `kioto::crypto::hash` and
  `kioto::crypto::encode::base64` instead of reimplementing them in Owl.
- Registry signature verification and base64 decoding are handled by Kioto's
  binary-safe file helpers, removing the last `openssl base64 -d`/`pkeyutl`
  subprocess paths from Owl.

### Documentation Reorganization
- Docs moved to `owl/docs/` following Mire Documentation Standard
- Each topic has its own subdirectory: `Cli/`, `Lockfile/`, `Reg/`, `Security/`
- `README.md` indexes all documentation for easy navigation
- All documents follow: one level-one heading, no emojis, no decorative HTML

### Breaking Changes (migrated from 1.0.x)
- `proc::run::shell()` removed (was shell violation, use `proc::run::output("cmd", args)`)
- `owl ensure` no longer a standalone command (policy now in build/run/test)
- Lockfile V3 is default; V1/V2 legacy mode only
- `[tool.owl.auto-deps]` removed from `owl new` template

### Compatible Changes
- Old lockfiles (V1, V2) automatically upgraded to V3 on first read
- All existing `owl.toml` configurations continue to work
- Backward compatible with projects created with owl < v1.1.0
- `owl --version` shows real-time: `Owl v1.1.0 / Mire / Avenys v4.0.0`

## [1.0.1] - 2026-08-24
### Transition entry (moved to historical)
- Marks transition from unstructured changelog to formal semantic versioning
- All subsequent entries follow [1.1.0] format
