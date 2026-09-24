# Migration - Migrating to Owl v1.1.0

## Version Transition v1.1.0

This document marks the transition from unstructured changelog entries to formal
semantic versioning. Owl v1.1.0 introduces several breaking and non-breaking changes.

### What's New in v1.1.0

#### Lockfile V3 Automatic Generation (Default)

- Lockfile format changed from simple sha256 to structured V3 format
- Automatic generation on first build/run if no lockfile exists
- `owl ensure` now returns `true` immediately (no blocking)
- Dependencies resolved from what's *used*, not declared
- Configuration via `[cfg]` section in owl.toml

#### Configuration System `[cfg]` (New in v1.1.0)

- New `[cfg]` section in `owl.toml` with `lock` and `update@lock` fields
- `lock = 1` enables lockfile verification
- `lock = 0` disables lockfile verification
- `update@lock` modes: `Build` (always), `Changes` (on config changes), `None` (never)
- Default: `lock = 1`, `update@lock = "Build"` for new projects

#### Dependency Checksums v1.1.0

- `dependency_checksum(pkg_name installed_version)`: Verifies SHA-512 checksums
- Checks `~/.owl/cache/lockfile_checksums` for stored checksums
- Auto-generates and stores missing checksums
- Validates kioto@x.x.x checksums against installed version

#### Exports Verification v1.1.0

- `exports_verified(pkg_name)`: Validates exported modules from lockfile
- Checks installed package's meta.toml for exports field
- Issues warnings for mismatches or missing format

#### Documentation Reorganization v1.1.0

- Docs moved to `owl/docs/` directory following Mire Documentation Standard
- Each topic has its own subdirectory: `Cli/`, `Lockfile/`, `Reg/`, `Security/`
- `README.md` indexes all documentation for easy navigation
- All documents follow: one level-one heading, no emojis, no decorative HTML

#### Breaking Changes v1.1.0

1. **`proc::run::shell()` removed** - Was shell violation, use `proc::run::output("cmd", args)`
2. **`owl ensure` no longer standalone command** - Policy now in build/run/test
3. **Lockfile V3 is default** - V1/V2 legacy mode only for reading/upgrading
4. **`owl new` omits `tests/` directory by default** - use `--init-tests` to opt-in
5. **`[tool.owl.auto-deps]` removed from `owl new` template** - use `[deps]` explicitly

#### Migration Checklist v1.1.0

**For Project Owners:**

1. **Lockfile**: First `owl build` will auto-generate V3 lockfile. No manual action needed.
2. **Commands**: Replace `proc::run::shell()` with `proc::run::output("cmd", args)` if using shell operations.
3. **Dependencies**: `[tool.owl.auto-deps]` section removed from new projects. Use `[deps]` explicitly.
4. **Configuration**: Review `owl.toml` - new `[cfg]` section with `lock` and `update@lock` fields.
5. **Version Pinning**: Pin to specific owl/mire/kioto versions in CI configurations.

**For Library Authors:**

1. **Exports**: Ensure `[[package]]` entries in lockfile match actual exported modules.
2. **Version Ranges**: Use semantic versioning for dependency version specifications.
3. **Signing**: Consider Ed25519 signing for packages distributed through registries.

**For CI/CD:**

1. **Lockfile Regeneration**: CI pipelines should run `owl ensure` or `owl generate` to update lockfiles.
2. **Cache Warming**: Use `owl build --no-analysis-cache` for clean builds in CI.
3. **Version Pinning**: Pin to specific owl/mire/kioto versions in CI configurations.

### What's Compatible v1.1.0

- Old lockfiles (V1, V2) are automatically upgraded to V3 on first read
- All existing `owl.toml` configurations continue to work (with `[cfg]` section added)
- Backward compatible with projects created with owl < v1.1.0
- `owl --version` shows: `Owl v1.1.0 / Mire / Avenys v4.0.0`

### Breaking Changes v1.1.0

- `proc::run::shell()` no longer available (was removed for security)
- Lockfile format V1/V2 still readable but V3 is default
- `owl new` omits `tests/` directory by default (use `--init-tests` to opt-in)
- `owl ensure` is no longer a standalone command (lockfile policy integrated into build/run/test)
- Configuration now requires `[cfg]` section in owl.toml (defaults added automatically)

## Historical Notes

- **v1.0.0**: Initial release with basic lockfile V1 format
- **v1.0.1**: Transition entry marking move to semantic versioning
- **v1.1.0**: Current version - Lockfile V3 automatic generation, `[cfg]` configuration system, dependency checksums, exports verification, comprehensive documentation reorganization
