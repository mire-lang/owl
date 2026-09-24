# Owl Changelog

## [1.1.2] - 2026-09-20

### Added
- **Lockfile checksum-of-change cache**: `owl checkup` now computes SHA-256 of `owl.toml` and compares it to the stored `manifest-sha256` in `owl.lock`. When checksums match, full lockfile validation is skipped (fast path).
- **Interactive lockfile update prompt**: When `owl.toml` has changed since the last lockfile generation, `owl checkup` prompts `Update lockfile now? (y/N)` with options to regenerate, keep existing, or install locked versions.
- **Fresh project auto-generation**: New projects created with `owl new` now automatically generate a V3 lockfile on first `owl checkup`/`build`/`run` without blocking.

### Changed
- **GitHub registry fallback removed**: The `registry add` command no longer attempts to download from `github.com`/`raw.githubusercontent.com` URLs. Users must configure a proper custom registry.
- **Permissions tightened**: `~/.owl/libs/` directories now use `500` (read+execute for owner) instead of world-readable.

### Fixed
- **Lockfile validation on fresh projects**: Previously `owl checkup` would fail with "owl.lock not found" on new projects. Now it auto-generates a V3 lockfile and proceeds.
- **Tilde expansion in dependencies**: `[dependencies]` paths with `~/.owl/libs/...` are now properly expanded via `util::expand_home()`.

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
- Project new → lockfile V3 automatically generated on first `build`/`run`
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
