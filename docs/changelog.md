# Owl Changelog

## [0.28.0] - 2026-07-22

### Changed

- **Cache path rename `modules` → `libs`:** `util::owl_home_modules()`
 renamed to `util::owl_home_libs()` and now points at `~/.owl/libs/`
 (previously `~/.owl/modules/`). All references in `code/gc`, `code/info`,
 `code/install`, `code/dload` and the docs updated accordingly.
- **`owl deps --prune` / `owl install --prune`:** New capability to prune
 unused dependencies. Scans `code/` and `tests/` for `load <dep>` usage via
 the new `util::grep_load()`, removes orphans from `owl.toml [dependencies]`,
 and regenerates `owl.lock`. Implemented in `code/deps/mod.mire`
 (`prune_unused()`); exposed both as `owl deps --prune` (`-p`) and
 `owl install --prune`.

### Added

- `util::grep_load(dep)` — returns true if any `.mire` under `code/` or
 `tests/` contains a `load <dep>` statement.

## [0.27.0] - 2026-07-19

### Changed

- **Full migration from `load` (package) to `load!`/`use!` (local):** All 17
 internal sub-packages under `code/` now use `load!` with path prefixes
 (`/code/util`, `/code/crypto`, etc.) instead of package `load` via
 `owl.toml [dependencies]`. Every call into a `load!`-imported module is
 wrapped in `use!`. This eliminates the `owl.toml` dependency entries for
 internal modules and aligns with the `load!`/`use!` local import model.
- **`code/load/mod.mire` removed**: The `load` command module was deleted;
 its functionality is subsumed by the `load!`/`use!` migration.
- **1 return per function enforced across all sub-packages**: Every function
 in `code/*/mod.mire` now uses at most one `return` statement. Void
 functions use `if`/`else` chains (0 returns). Non-void functions use
 `set result = default :type mut` ... `if`/`else { set result = val }` ...
 `return result`.
- **Dead code removed**: `extract_versions` and `ensure_owl_home` functions
 removed from `code/util/mod.mire`.
- **Redundant alias variables removed**: 13 `set name = name` assignments
 removed from `code/main.mire`.
- **`9999` magic number documented**: The `toml_extract_val` fallback
 length now has an inline comment explaining its purpose.

### Fixed

- **`code/crypto/mod.mire` return types**: `crypto_verify_ed25519`,
 `crypto_verify_ed25519_sigfile`, and `crypto_verify_pemfile` now return
 `:bool` instead of `:str`. The caller in `code/registry/mod.mire` no
 longer compares against the string `"true"`.
- **`code/tree/mod.mire` duplicate output**: Removed duplicate print of
 child dependencies that caused each dependency to appear twice in the
 tree output.
- **`code/install/mod.mire` `:u8` type handling**: `cmd_install` and
 `cmd_install_pkg` now use `set ec = 0 :u8 mut` with explicit `:u8`
 type annotations on literal values (`set ec = 1 :u8`), fixing
 type inference errors from integer literals defaulting to `i64`.

### Test fixes

- **`tests/04_strings.mire`**: Fixed incorrect kioto API names —
 `strings.is_empty` → `strings.check.empty`, `strings.from_i64` →
 `strings.from.i64`, `strings.index_of` → `strings.index`.
- **`tests/05_lists.mire`**: Fixed `lists.index_of` → `lists.index`,
 `lists.is_empty` → `lists.check.empty`.
- **`tests/06_math.mire`**: Fixed `math.range_between` → `math.between`,
 `math.range_step` → `math.step`, `math.min_list` → `math.minlist`,
 `math.max_list` → `math.maxlist`.
- **`tests/07_stress.mire`**: Fixed `time.unix_ms` → `time.unix.ms`,
 `strings.from_i64` → `strings.from.i64`.

### Changed (revision 2026-07-20)

- **Command dispatcher flattened (no deep `else` staircase):** `code/main.mire`
 `pub fn main` previously chained all subcommands in a 16-deep `} else {`
 staircase. It now dispatches via flat early-return guard clauses
 (`if cmd == "x" || cmd == "--x" { ...; return }`). This is the "no long if
 anidation" fix. Note: the reviewer's "no early return" request was
 interpreted (per mire-lang) as *avoid deep nesting*, not a blanket ban —
 guard-clause early returns and Mire's native `?`/`use!` error propagation
 remain in use. `match` was evaluated and rejected because avenys does not
 run effectful `use!` calls inside `match` arms.
- **Command handlers borrow `args`:** `compile_pipeline`, `cmd_info`,
 `cmd_clean`, `cmd_checkup`, `cmd_check`, `cmd_load*`, `cmd_export`,
 `cmd_gc`, `cmd_tree`, `cmd_profile`, and `cmd_upgrade` now take
 `args :&vec[str]` instead of `args :vec[str]`. This removes the ownership
 move that the flat dispatcher would otherwise trigger on every branch and
 is more idiomatic (handlers only read `args`).
- **Owl-wide `use!` qualification corrected:** All cross-module calls in the 9
 `code/*/mod.mire` packages were updated to qualify calls as
 `use! module::fn(...)` per the current avenys import model, so the project
 builds cleanly on current `mire`.

### Fixed (revision 2026-07-20)

- **CI type error at `proc_exit` call site (E0005):** `cmd_install` and
 `cmd_install_pkg` return `:u8` (their natural narrow type). The dispatcher
 now performs a single short-lived `u8 -> i64` conversion
 (`set ec_i64 = ec :i64`) immediately before `proc_exit(ec_i64)`, instead of
 ascribing `:i64` to the install call. This keeps PAL exit-code types narrow
 and unblocks CI without broadening integer types across the install path.
- **Version consistency:** `owl.toml` (`0.26.1`) and `README.md` (`v0.26.2`)
 now report `0.27.0`, matching `util::owl_version()` and the changelog.

## [0.26.2] - 2026-07-18

### Changed

- **Flag passthrough to the compiler:** `owl build` / `owl run` forward any
 extra argument starting with `-` to the underlying `mire` invocation, so
 compiler-specific flags no longer need dedicated owl options.
- **`owl test` forwards all flags:** `collect_test_flags` passes through every
 `-`-prefixed argument and quotes non-flag arguments, reaching the test
 runner correctly.

### Fixed

- **Lockfile package-name parsing:** Corrected the `[[package]]` section split
 in `lockfile_package_names` (off-by-one at the section delimiter) and removed
 a duplicated consistency check. Dependency name extraction is now accurate.

## [0.26.1] - 2026-07-17

### Docs

- **Carga local de módulos (`load`) funciona vía `path`**: un paquete Mire
 local es un directorio con `owl.toml` (`[project] name`, `entry`) + `module X`
 + (opcional) `[exports]`, y se declara en el consumidor con
 `dep = { path = "ruta/relativa" }`. Es el mismo mecanismo que kioto
 (`registry="local"` → `~/.owl/lib/kioto`); la única diferencia es la
 ruta relativa al proyecto. El claim previo de que "Mire no soporta
 load local" era incorrecto — se confundió con la falta del `owl.toml`/`module`
 correcto en el directorio del paquete.
- **Bug de `vec[i64]` por asignación indexada**: documentado en
 `avenys/docs/VEC_INDEXED_ASSIGN_BUG.md`. La sintáxis nativa
 `set vec at idx = val` corrumpe vectores dinámicos; usar
 `lists::set(vec, idx, val)` (kioto) como workaround. Afecta al runtime
 de Mire, no a owl, pero se registra aquí porque las suites de
 benchmark lo disparaban.

## [0.24.1] - 2026-07-08

### Registry Protocol specification

- `REGISTRY_PROTOCOL_v1.md` — complete, self-contained spec of the v1
 registry protocol. Documents `registry.json`, `index.toml`, `publish.toml`,
 `meta.toml`, Ed25519 signature scheme, dual-signature model, install flow,
 TOFU, protocol versioning, and multi-registry priority.

## [0.24.0] - 2026-07-08

### Performance: Resolution cache

- `semver::get_cached_resolution(name, constraint)` — looks up `~/.owl/cache/resolution.toml`
- `semver::cache_resolution(name, constraint, version)` — writes to cache
- `resolve_from_registry()` checks cache first, writes on miss
- `util::toml_get_from_string(content, section, key)` — parse TOML from a string
- `util::owl_home_cache_resolution()` — path helper: `~/.owl/cache/resolution.toml`
- `util::ensure_owl_home()` now creates `~/.owl/cache/`

### Maintenance tools

- **`owl gc`** — garbage collect: scans `~/.owl/lib/`, removes orphaned versions not referenced in any `owl.lock`
- **`owl tree [--all]`** — dependency tree: flat by default, `--all` shows recursive
- **`owl profile [--json]`** — build metrics: binary size, compiler, last build, build count
- **`owl clean --global`** — cleans `~/.owl/cache/` and `~/.owl/libs/`
- `deps::get_dep_names_from(toml_file)` — get dependency names from any owl.toml
- `deps::get_dep_field_from(toml_file, dep_name, field)` — get a specific dep field from any owl.toml

### Fixed

- **Test runner symlink bug**: test discovery (`walkdir`) followed symlinks, picking up `tests/lib/mod.mire` (symlink to `testlib/mod.mire`) as a test file. That file has `module`/`load` at the top level, which are invalid inside `pub fn main: () { ... }`. Fix: `walkdir` skips symlinks. (Avenys `src/main.rs`)

### Added

- `code/gc/mod.mire` — new gc module
- `code/tree/mod.mire` — new tree module
- `code/profile/mod.mire` — new profile module

## [0.23.0] - 2026-07-08

### CLI cleanup — command consolidation

**Renames:**
- `owl -I` / `owl import` → `owl -L` / `owl load` (consistent with Mire's `load`)
- `owl -Iu <url>` → `owl load --url <url>` / `owl -Lu <url>` (read registries)
- `owl -Lu` auto-expands to `owl -L -u` (no hardcoding)

**Removed (duplicates):**
- `owl reg` / `owl registry` — removed, replaced by `owl load --url`
- `owl -I` / `owl import` — removed, replaced by `owl load`
- `owl -Iu` — removed, replaced by `owl load --url`
- `code/import/` module — removed, replaced by `code/load/`

**Added short flags:**
- `-R` → run (previously only `run`)
- `-K` → check (previously only `check`)
- `-Q` → info (previously only `info`)

**Help:**
- Redesigned: organized by categories (Build, Project, Package)
- No more "Phase X" references
- Lists all commands with short flags

**Files:**
- `code/main.mire`
- `code/load/mod.mire` (new, replaces `code/import/`)
- `code/ui/mod.mire`
- `owl.toml`

## [0.22.0] - 2026-07-08

### Publication (`owl -e`)

- `owl -e` / `owl export`: validate, package, and sign a project for publication
- `owl -e --check`: validate project (required fields, sources, tool availability)
- `owl -e --dry-run`: create archive and `publish.toml` without signing
- Generates `<pkg>-<ver>.tar.zst` archive (tar + zstd)
- Generates `<pkg>-<ver>.tar.zst.sig` Ed25519 signature
- Generates `<pkg>-<ver>.pub` public key copy
- Generates `publish.toml` with package metadata, SHA-256 checksum, public key, and signature
- Auto-generates Ed25519 keypair at `~/.owl/keys/id_ed25519` on first use

### Added

- `code/export/mod.mire` — new publication module
- `owl.toml` dependency: `export = { path = "./code/export" }`

## [0.21.0] - 2026-07-08

### ABI compatibility

- `util::abi_version()` — returns current ABI version (`"1"`)
- `util::language_version()` — returns language version from `mire --version`
- `owl install` now writes `compiler`, `abi`, `language` to `meta.toml`
- `owl check` reports ABI info (compiler, abi, language) for each dependency that has a `meta.toml`
- ABI mismatch detection framework in place

### Added

- `util::abi_version()` — new function
- `util::language_version()` — new function

## [0.20.0] - 2026-07-08

### SemVer resolution

- `code/semver/mod.mire` — new module for SemVer parsing, matching, and resolution
- `semver::parse_version(ver)` — normalizes `"1.2"` → `"1.2.0"`
- `semver::compare_versions(a, b)` — compares two semvers (-1, 0, 1)
- `semver::constraint_matches(version, constraint)` — checks `^1.2`, `~1.2.3`, `>=1.0`, `>1.0`, `<2.0`, `<=2.0`, `*`, `latest`, exact
- `semver::best_match(versions, constraint)` — finds highest matching version from space-separated list
- `semver::resolve_from_registry(name, constraint)` — queries all registries' `index.toml`, extracts versions, resolves best match
- Registry index format: `[[package]]` entries with `name` and `version` fields
- `owl install` now resolves version constraint via registries before installing
- Conflict detection framework in place

### Added

- `code/semver/mod.mire` — 173 lines
- `owl.toml` dependency: `semver = { path = "./code/semver" }`

## [0.19.0] - 2026-07-08

### Registries via `-Iu` / `--url`

- `owl -Iu <url>`: add registry from URL
- `owl -Iu list`: list registries
- `owl -Iu remove <n>`: remove registry by index
- `owl reg|registry sync`: sync all enabled registries
- `owl reg|registry enable/disable/priority`: manage registries
- `cmd_registry_iu()` handles `-Iu` flag dispatch
- `cmd_registry_sync()` + `cmd_registry_sync_one()` for sync
- `cmd_registry_remove_by_index()` for numeric removal
- `util::string_to_i64()` and `util::i64_to_string()` helpers added

### Combined short flags

- `-rvB` expands to `-r -v -B` before command dispatch
- `find_cmd_index()` helper finds first non-flag argument
- Works with all commands: `owl -rvB build`, etc.

### `owl install` (stub)

- `owl install <name> [version]`: install a package
- `owl -S <name>`: same
- Framework in place for SHA-256 and Ed25519 verification
- `code/install/mod.mire`: new install module

### Avenys CLI cleanup

- Removed `mire validate` command
- Removed `mire owl add|remove` commands
- Avenys now only has: `run`, `build`, `check`, `debug`, `test`

### Infrastructure

- **Testlib moved**: `tests/lib/mod.mire` -> `testlib/mod.mire`
 (symlink at `tests/lib` for load compatibility)
- `tests/lib/mod.mire`: now uses `strings::to_string()` from kioto
- `util::string_to_i64()` and `util::i64_to_string()` added to util

## [0.18.0] - 2026-07-07

### Lockfile

- `owl.lock` generated on first `owl build` or `owl run`
- Lockfile format: `[[package]]` entries with name, version, path, registry, abi
- `owl.lock` with no dependencies: `# Generated by owl - no dependencies`
- `owl.lock` with path dependencies: includes path and registry="local"
- Build pipeline checks lockfile existence and sync before compiling
- `owl build` / `owl run` without lockfile → generates lockfile automatically
- **Sync check**: detects when owl.toml has deps not in lockfile (count mismatch)

### `owl import` / `owl -I`

- `owl import <name>`: imports from `~/.owl/libs/<name>` cache
- `owl -I <name>`: same as `owl import`
- `owl import <name> --path <path>`: imports local path dependency
- `owl -I <name> --path <path>`: same
- Validates no duplicate entries before adding
- Creates `owl.toml.backup` before modifying owl.toml
- `owl_home_modules()` helper added to util module

### Added
- **Tool-specific tests**: 6 tests (`test_owl_new`, `test_owl_build`,
 `test_owl_run`, `test_owl_check`, `test_owl_info`, `test_owl_import`)
- **Syntax early-warning tests**: 9 tests
- **`code/lockfile/mod.mire`**: lockfile generation and sync checking
- **`code/import/mod.mire`**: import command module

### Fixed
- `toml_get`: rewritten with `strings::index_of` to avoid kioto `vec[str]`
 corruption in loops. All owl.toml fields (name, version, description, entry,
 profile, opt-level, compiler, output, cache, sources, tests) parse correctly.
 `owl build` + `owl run` now functional on fresh projects.
- `owl new` template: `opt-level` quoted, non-empty `description`, removed
 broken `#!cfg::test` directive from test template.
- **Mire 3.11.45 compatibility**: test files changed from `#!cfg::test`
 directive to `// !cfg::test` comment (Mire removed `#` syntax in v3.11.38).
 `pub fn fail` in testlib now public (private `fn` not callable from other
 functions in same module in Mire 3.11.45). `proc_run` renamed to
 `proc::run` in Avenys 3.11.44.

### Compiler (Avenys) fixes
- Type checking: `check_statement` now attaches source context to ALL errors
 from nested statements, fixing ~130 type errors that showed
 `<source location unavailable>`.

## [0.17.0] - 2026-07-04

### Changed
- **Modularized codebase**: split monolithic `code/main.mire` (988 lines) into
 8 sub-packages under `code/`:
 - `util/` — kioto wrappers (strings, lists), TOML parser, filesystem helpers
 - `crypto/` — SHA256, Ed25519 verification
 - `trust/` — trusted/revoked key management
 - `registry/` — registry add/remove/list
 - `build/` — compile pipeline, `owl new`
 - `check/` — `owl checkup`, `owl check`
 - `info/` — `owl info`, `owl clean`
 - `ui/` — banner, help text
- `load kioto` centralized in `main.mire` only; sub-packages use `util::*` wrappers
- All sub-packages listed as path dependencies in `owl.toml`
- `proc_spawn`/`proc_wait` used as bare builtins instead of `proc::spawn_shell`/`proc::wait`
- `len` builtin replaces `strings::len` where applicable

### Compiler (Avenys) fixes
- `resolve_named_call` in MIR codegen: tries all prefix splits via
 `match_indices('.').rev().find_map(...)` for correct multi-level namespace resolution
- Error position display in MIR lowering: uses `expression_location(expr)` /
 `statement_location(stmt)` instead of hardcoded (0, 0)
- `statement_prefix` in loader: returns empty when origin is from a different
 package tree, preventing incorrect prefixing of dependency symbols

## [0.16.2] - 2026-06-29

### Added
- `info --json`: machine-readable JSON output for CI/IDE integration.
 Outputs project metadata, compiler info, LLVM version, ABI, language,
 and dependency list as structured JSON.
- `json_quote(str)` helper: wraps a string in double quotes,
 replacing `json::quoted()` from kioto (see Known Issues below).

### Known Issues (Mire / Kioto / libs)
- `json::quoted()` from `kioto/ext/json` causes `free(): invalid pointer`
 crash at runtime in all tested contexts.
 → [mire-lang/libs#5](https://github.com/mire-lang/libs/issues/5)
 → Use the custom `json_quote()` helper instead.
- Mire runtime bug: `\n` character in string concatenation/comparison
 inside loops can trigger `free(): invalid pointer`.
 → [mire-lang/Avenys-rust#22](https://github.com/mire-lang/Avenys-rust/issues/22)
- Compiler error E0005 "Assignment to undefined variable" with imprecise
 source location when variables are declared inside `if` branches.
 → [mire-lang/Avenys-rust#23](https://github.com/mire-lang/Avenys-rust/issues/23)

## [0.16.1] - 2026-06-29

### Changed
- `checkup --fix` now requires explicit field arguments:
 `owl checkup --fix <field> [<field> ...]` instead of blanket-fixing all missing
 fields. The developer controls exactly which fields get default values.
- `checkup --fix` without field names shows a usage hint listing all available fields.
- Hint message updated to reference the field-specific syntax.

## [0.16.0] - 2026-06-28

### Added
- Full `owl.toml` field validation in `checkup`: all 11 fields now checked
 (`name`, `version`, `description`, `entry`, `profile`, `opt-level`,
 `compiler`, `output`, `cache`, `sources`, `tests`)
- Dependency count reporting: `checkup` counts `[dependencies]` entries
 and warns if none configured
- `checkup --fix` preserves all existing values when regenerating `owl.toml`

### Changed
- `checkup` output redesigned: shows every field with `[OK]`, `[FAIL]`, or `[WARN]`
 instead of only showing failures
- Non-existent source/test/cache directories show `[WARN]` instead of `[FAIL]`
 (the build creates them automatically)

### Fixed
- `checkup` no longer silently omits project metadata fields
- `checkup` correctly distinguishes missing fields from non-existent directories

## [0.14.0] - 2026-06-22

### Added
- Pacman-style short flags: `-B` (build), `-T` (test), `-K` (check), `-D` (debug),
 `-N` (new), `-C` (clean), `-Q` (info/query), `-S` (sync), `-R` (remove/drop),
 `-V` (version), `-h` (help)
- Subflag support: `-Si`, `-Qi`, `-Syu`, `-Cc`, `-Rs` with delegation to
 existing commands
- Help output documents both long and short command forms

### Changed
- Test runner rewritten: compiles and executes each `.mire` file independently
 instead of generating a harness via `#!cfg::test` directives
- Test discovery skips `lib/` subdirectories automatically
- `owl info` redesigned: shows live compiler version, target arch, profile
 settings from `owl.toml` build section, registered packages
- Help output redesigned with pacman-style flag reference

### Fixed
- Infinite loop in recursive file walker (`find_mire_files`) caused by
 trailing newlines in directory queue
- `owl info` hang (120s+) when `tests/` directory contained `lib/`
 subdirectory with dot-mire files
- Test runner now correctly resolves binary names from nested test paths
 (e.g., `tests/smoke.mire` -> `bin/debug/smoke`)
- `owl.toml` dependency format corrected: uses inline table syntax for
 path dependencies (`testlib = { path = "./tests/lib" }`)
- Build cache invalidation: stale binaries no longer served after source
 changes when `.cache/` directory is cleared

### Test suite
- 10/10 tests pass: primitives, control flow, functions, strings, lists,
 math, stress, bugs, smoke, verify setup
- Test runner verifies compile + execute for each file

## [0.13.2] - 2026-05-25

### Added
- `run/build` now accept `--import-mode <legacy|reachable>` and pass it through to `mire`.
- `owl test` re-enabled with a native runner that discovers `.mire` files under `tests/` and executes them through the compiler pipeline.
- Dependency preflight hardening in `build/run`: validates lock presence plus `semver` and `sha256:` checksum shape for declared dependencies.

### Changed
- Default Owl import mode is now `reachable` (configurable from `owl.toml` via `[build].import_mode`).
- Compatibility fallback: if compiler does not support `--import-mode`, Owl retries automatically without the flag.
- Run cache now keys by build signature (`source_hash + profile + opt + compiler cmd + import_mode`) to avoid stale reuse across profiles/options.
- Run fast-path now also reuses cached binaries when passing runtime args (`-- ...`).
- `owl profile` re-enabled in main pipeline (cache/check history metrics and compare/history views).
- Internal `build/run` flow unified into a shared compile pipeline to reduce duplicated parsing/runtime logic.

### Notes
- `owl profile --json` returns JSON object output again.

## [0.13.1] - 2026-05-23

### Changed
- Compiler command resolution is now config-first via `owl.toml`:
 - preferred key: `[compiler].cmd`
 - compatibility key: `[build].compiler`
 - fallback: `mire` in `PATH`
- Removed hardcoded compiler path probing from:
 - `code/main.mire`
 - `modules/tests.mire`
- Project template generated by `owl new` now includes `[compiler].cmd = "mire"`.
- Runtime/compiler banner aligned to Avenys `3.8.2`.

## [0.13.0] - 2026-05-22

### Changed
- Owl codebase migrated to namespace calls with stable `::` syntax (`strings::...`, `lists::...`, etc.).
- Internal Kioto-facing usage aligned with the new canonical module call style.
- Runtime/version banner updated for Avenys `3.8.x` compatibility.

## [0.12.0] - 2026-05-18

### Added
- Native installer scripts in `scripts/`:
 - `install.sh` (automatic mode)
 - `install-review.sh` (auditable mode with explicit confirmation)
- Installer support for precompiled binaries from GitHub Releases:
 - `owl` install by default
 - optional `mire` install via `--with-mire`
- Configurable installation parameters:
 - `--prefix`, `--bin-dir`, `--owl-version`, `--mire-version`, `--owl-repo`, `--mire-repo`

### Changed
- `README.md` now documents two installation flows:
 - one-shot quick install (`curl | bash`)
 - review-first install (download, inspect, execute)
- Added documented release-asset naming convention for Linux/macOS and x86_64/aarch64.

## [0.11.0] - 2026-05-18

### Added
- New static analysis command: `owl check` with `--all`, `--strict`, `--deny`.
- New profiling command: `owl profile` with `--json`, `--history`, `--compare`.
- New support modules:
 - `modules/diagnostics.mire`
 - `modules/profile.mire`
- `owl check` now prints ownership-oriented warning summary, including lifecycle codes `W0028`-`W0033`.
- `owl profile` now surfaces latest check totals (`warn.total`, `warn.lifecycle`, `strict_failed`) and includes check history rows for compare mode.

### Changed
- `run/build` now accept short profile flags `-r` and `-d` in addition to long flags.
- `clean` now supports selective cleanup: `--cache`, `--bin`, `--all`/`-A`.
- `info` output redesigned to diagnostics-style structured layout.
- Compiler borrow checking updated to treat function calls as non-consuming by default; explicit ownership transfer remains via `move::(...)`.

## [0.10.0] - 2026-05-18

### Changed
- Complete redesign focusing on local project management and build operations.
- Removed all external dependency management commands (`install`, `remove`, `purge`, `update`).
- Eliminated dependency modules (`deps`, `registry`, `download`, `lock`, `semver`) from distribution.
- Owl now operates entirely locally without network access or external package resolution.

### Focus
- Core functionality: `owl new`, `owl run`, `owl build`, `owl test`, `owl clean`, `owl info`
- Local cache management for compiled artifacts
- Project-based and projectless build workflows
- Profile and optimization level management

### Versioning
- Owl runtime/version banner updated to `0.10.0`.
- Compiler target alignment updated to `Avenys 2.8.x`.

## [0.9.0] - 2026-05-11

### Changed
- Full CLI refactor in `code/main.mire` with modular dependency flow (`deps`, `lock`, `tests`, `fs_ops`) and reduced duplicated legacy logic.
- Improved install/update/remove/purge stability with stricter name validation (`path traversal` guard + bounded naming rules).
- Test harness execution now supports debug-first compiler output and fallback binary paths.

### Fixed
- Multiple ownership/use-after-move failures discovered by full Owl compile pipeline in dependency and CLI paths.
- Symbol collision fixes for module global functions (duplicate `lock`, `toml`, `mkdir_p` definitions during full compile).

### Versioning
- Owl runtime/version banner updated to `0.9.0`.
- Compiler target alignment updated to `Avenys 2.8.x`.

## [0.8.0] - 2026-05-11

### Changed
- CLI surface stabilized around primary workflows (`new`, `run`, `build`, `test`, `install`, `remove`, `purge`, `update`, `clean`, `info`).
- Debug-first default behavior aligned with compiler profile changes.

### Added
- Projectless run/build flow (`.cache` + `bin`) with warning and low-friction execution.
- Initial fast-path runtime reuse by source hash.

### Stability
- First hardening pass on dependency lock/remove flows.

## [0.7.0] - 2026-05-11

### Changed
- CLI redesigned around a minimal command surface and direct UX (`owl` prints banner+help).
- `run/build` now accept explicit profile and optimization flags (`--debug`, `--release`, `-O`).
- Default execution profile aligned to debug-first workflow for faster iteration.

### Added
- Projectless execution/build flow with local `.cache` and `bin` creation.
- Fast-path run cache using source hash reuse.
- Stronger naming validation for project/dependency names.
- `purge` command for forced dependency cleanup in project context.

### Security/Stability
- Dependency install path keeps source-level warnings and lock-driven operations.
- Dependency removal now also cleans project symlink path when present.
