# Owl v1.6.2

Package and project manager for the [Mire](https://github.com/mire-lang) (Avenys) language.
Written in Mire, compiled by Avenys.

Owl provides project scaffolding, compilation orchestration, static analysis,
test execution, package management, and build profiling.

**Always use `owl` CLI. Never use `mire` CLI directly except for compiler development.**

## Quick Start

```bash
owl new myproject
cd myproject
owl run
```

## Installation and CI

The reproducible source installer builds Avenys first and then compiles Owl
with that exact compiler. At runtime Owl invokes the compiler with argv-safe
process execution; it does not use a shell to build projects.

```bash
./scripts/install.sh --check
./scripts/install.sh --yes --prefix "$HOME/.local"
```

The installer supports apt, dnf, pacman, apk and zypper. It provisions Rust /
Cargo, Clang, LLVM 22/LLD, pkg-config, libarchive, OpenSSL, libsodium, zlib and zstd. On an
older distribution whose glibc cannot run a prebuilt binary, use this source
installer rather than replacing system libraries.

Owl packages are created and extracted through `libarchive` linked with zstd;
the runtime does not require the `tar` or `zstd` executables. The corresponding
development package (`libarchive-dev`, `libarchive-devel`, or the distribution
equivalent) is checked by the installer.

Avenys 4.0.0 currently requires LLVM 22. The installer rejects older
`llvm-config` versions so a CI image fails with an actionable toolchain error
instead of a later `llvm-sys` linker failure.

## Uninstallation

To completely remove Owl, the Mire compiler, libraries, and configuration:

```bash
# Interactive uninstall (prompts for confirmation)
curl -fsSL https://raw.githubusercontent.com/mire-lang/Avenys-rust/main/install/uninstall.sh | sh

# Force uninstall everything without prompts
curl -fsSL https://raw.githubusercontent.com/mire-lang/Avenys-rust/main/install/uninstall.sh | sh -s -- --force

# Dry run to see what would be removed
curl -fsSL https://raw.githubusercontent.com/mire-lang/Avenys-rust/main/install/uninstall.sh | sh -s -- --dry-run
```

## Commands

### Build

| Short | Command | Description |
|-------|---------|-------------|
| `-B` | `build [file] [-d|--debug|-r|--release] [-O <n>]` | Compile project to binary |
| `-R` | `run [file] [-d|--debug|-r|--release] [-O <n>] [-- <args>]` | Compile and execute |
| `-T` | `test [file] [--release|-r] [--debug|-d] [--opt-level|-O <n>] [--jobs|-j <n>] [--no-run] [--verbose|-v] [--log] [--no-warn] [--no-categorize] [--cache|--cache-dir|--lib-dir|-L <path>] [--config <file>] [--target <triple>] [--runtime <tier>]` | Run test suite |
| `-K` | `check` | Validate dependencies (path, version, integrity) |
| `-D` | `debug [file] [--tokens|-t] [--ast|-p] [--ir] [--run|-r]` | Compiler introspection |
| `-Q` | `info [--json]` | Project and environment information |

### Project

| Short | Command | Description |
|-------|---------|-------------|
| `-N` | `new <Name>` | Scaffold a new project |
| `-C` | `clean [--bin] [--cache] [--all\|-A] [--global]` | Remove build artifacts and cache |
| | `checkup [--fix <field>...]` | Project diagnostics and repair |
| | `profile [--json]` | Build metrics |

### Packages

| Short | Command | Description |
|-------|---------|-------------|
| `-L` | `load <name> [ver]` | Add dependency to owl.toml |
| `-L` | `reg add <url>` | Add a package registry |
| `-G` | `reg list` | List registries |
| `-G` | `reg sync` | Sync registries |
| `-G` | `reg remove <name>` | Remove registry |
| `-S` | `install <name> [ver]` | Download and install package |
| `-S` | `install --lock` | Install all packages from owl.lock |
| `-S` | `install -l` | List packages from all registries |
| | `install --prune` | Install and prune unused dependencies |
| | `deps --prune` | Remove unused dependencies from owl.toml |
| `-e` | `export [--check\|--dry-run]` | Package and sign |
| | `gc` | Garbage collect orphaned packages |
| | `upgrade [--yes]` | Self-update owl from source |

### Global

| Flag | Description |
|------|-------------|
| `-V`, `-v`, `--version` | Show version |
| `-h`, `--help` | Show help |

## Testing

```bash
owl test              # the whole suite
owl test -j 8         # parallel
owl test --release    # opt-level 3, binaries land in <output>/release/
owl test --no-run     # compile only
```

Flags are forwarded to `mire test`; see `--help` for the full list.

**Testing ignores the artifact.** `owl test` always builds an executable, whatever
`[build] artifact` says, because a test needs an entry point to run from and a
package's published form is no business of its test suite. This is enforced on
both sides: owl does not forward a library artifact, and the compiler normalizes
one away if it is configured that way anyway. A manifest declaring
`runtime = "none"` is likewise lifted to `minimal` for the test build, since a
test needs the runtime to run on. An explicit `--runtime` is left alone.

Before this, every library package in the tree — `kioto`, `mire`, `sdl`, `sqlite`
and `blu` — got a shared object instead of a test executable, and each test file
was reported `ok` having run no assertion. See
[docs/changelog.md](docs/changelog.md) under 1.2.4.

> One caveat that is *not* fixed: a file with several `@[test]` functions reports
> all of them as failed when any one fails. The count is deliberately
> conservative, so a red suite is never understated — but `Failed: 11` does not
> mean eleven broken tests.

## Build Profiles and Optimization

`owl build`, `owl run` and `owl test` all accept `--release`/`-r`, `--debug`/`-d`,
and `-O <n>`/`--opt-level <n>`. `--release` implies `opt-level = 3`, `--debug`
implies `opt-level = 0`. The values default to those in `[build]` of `owl.toml`.

```bash
owl build --release    # profile=release, opt-level=3
owl run -d             # profile=debug, opt-level=0
owl test -r -O2        # release profile, opt-level 2
owl build -O s         # optimize for size
```

## `owl load` — Add a dependency

`owl load <name> [version]` adds a package to `[dependencies]` in `owl.toml`.
Without a version it uses a local path `~/.owl/libs/<name>`; with a version it
declares a versioned registry dependency. Run `owl install` afterward to resolve
and install.

```bash
owl load kioto           # path dep: ~/.owl/libs/kioto
owl load json 1.2.0      # versioned dep
owl install              # resolve and install
```

## Version History

### v1.6.2 - 2026-11-10
**Added**
- **`--lib-dir <path>`** on `owl build`, `owl run` and `owl test`, repeatable, for extra package directories.
- **`owl test`** builds and runs the project's test sources and reports failures with file and line.
- **Lockfile V3** records each dependency as `name@version:src|binary|auto`.
- **`sandbox`, `os`, `deps_db` and `pkgbuild` modules**, and temporary directories moved from `/tmp` to `~/.owl/tmp/`.

**Project Template & Config Changes**
- **Project directory renamed**: `code/` → `src/` (matches standard conventions)
- **Output directory hardcoded**: Binary output always goes to `bin/` (removed `[paths].output` from `owl.toml`)
- **New entry point config**: Added support for `[project].input` as alternative to `[project].entry` (input takes precedence)
- **CLI file override preserved**: `owl run src/main.mire` still works and overrides config

**Fixed**
- **Version reporting** — `owl -v` now reports the build version (`1.6.2`); another project's `owl.toml` is trusted only when `[project] name == "owl"`.
- **Fallback constant** — the hardcoded fallback was still `1.2.4`; it now matches the release.

### v1.3.0 - 2026-10-21
**Added**
- **`owl load <name> [version]`** — adds a dependency to `[dependencies]` in `owl.toml`. Without a version it uses a local path `~/.owl/libs/<name>`; with a version it declares a versioned registry dependency. Follow with `owl install` to resolve.

**Fixed**
- **CLI flag validation rejected valid flags** — `args::allowed_flags()` for `build`, `run`, and `test` did not declare flags that `build::compile()` and `build::test_config()` already handle. Every flag the compiler understands is now declared.
- **Version inconsistency** — README said `v1.3.0`, `owl.toml` said `1.4.0`, and the fallback constant said `1.2.4`. All now report `v1.3.0`, read from `[project] version` in `owl.toml`.
- **`owl info` hardcoded `mire`** — `info::run()` invoked `mire --version` directly instead of `util::compiler_cmd()`, ignoring `[build] compiler` and `MIRE_COMPILER`. Now resolves through `compiler_cmd()`.
- **`owl new` template mismatch** — scaffolded `src/main.mr` with `pub fn main: () :i64`, but the codebase uses `code/main.mire` with `pub fn main: ()`. Template now matches codebase conventions.

**Documentation**
- `docs/Cli/overview.md` rewritten for v1.3.0 with complete flag listings.
- `README.md` command table updated: `build`, `run`, `test` now list all flags the compiler accepts; added `owl load` and Build Profiles sections.

## `owl new` template

`owl new <name>` scaffolds:

```
<name>/
  owl.toml
  bin/
  src/
    main.mire
```

The manifest uses `entry = "src/main.mire"`, `sources = "src"`, and the entry
is `pub fn main: ()` (no return type). Build with `owl build`, run with `owl run`.

The entry point can be configured via `[project].entry` or `[project].input` in `owl.toml`:
```toml
[project]
entry = "src/main.mire"
input = "src/alt.mire"  # takes precedence over entry when set
```


```bash
# Full diagnostic (all checks)
owl checkup

# Specific checks
owl checkup --cache       # validate build cache integrity
owl checkup --deps        # validate dependencies can be loaded
owl checkup --loads       # validate load statements resolve

# Repair (skips diagnostics when --fix with fields specified)
owl checkup --fix loads        # scan sources, inject missing deps from load statements
owl checkup --fix deps         # resolve dep paths from ~/.owl/libs
owl checkup --fix cache        # clean build cache
owl checkup --fix name entry   # regenerate owl.toml fields

# Example: fix missing dependencies from load statements
owl checkup --fix loads
```

### checkup Behavior

- **Without `--fix`**: runs all selected diagnostics, reports all issues
- **With `--fix <fields>`**: **skips diagnostics**, runs only the requested fix
  - `--fix loads` → scans source files for `load` statements, injects missing deps
  - `--fix deps` → resolves dep paths from `~/.owl/libs/`
  - `--fix cache` → clears `bin/.cache`
  - `--fix <field>` → regenerates `owl.toml` fields

---

## Module Loading — Important Rules

### External packages (from `[dependencies]`)

```mire
# In code/main.mire
load kioto              # makes kioto namespace available
load blu::parse         # specific submodule from blu
load sdl::sdl3          # submodule from sdl

# External package calls are direct; local module calls use `use!`.
pub fn main: () {
    set text = kioto::strings::concat("a" "b")
    set style = blu::parse::load_file("style.css")
    set window = sdl::sdl3::create_window("title" 800 600)
}
```

### Redundant Load Anti-pattern

```mire
# WRONG — redundant
load blu
load blu::parse
load blu::widget

# CORRECT — load blu once, it exposes everything
load blu

pub fn main: () {
    use! blu::parse::load_file("style.css")
    use! blu::widget::arena::create()
}
```

**Why:** `load blu` imports the entire `blu` package namespace. Submodules like `blu::parse`, `blu::widget` are accessible as `blu::parse::...` and `blu::widget::...`. Loading them again is redundant.

### Local modules (within project)

```mire
# In code/main.mire
load! code/lib/utils    # local module from code/lib/utils/mod.mire

# Usage requires use!
pub fn main: () {
    use! utils::helper()
}
```

### Key Loading Rules

| Rule | Description |
|------|-------------|
| `load X` | External package from `[dependencies]`. **Must be in owl.toml**. |
| `load! X` | Local module (`code/...`). Path relative to `sources` dir. |
| `use! mod::fn()` | **Mandatory** for ALL cross-module calls. |
| `load X::Y` | Submodule of external package. |
| `load! X::Y` | NOT valid — local modules loaded as single unit. |

---

## Build profiles

```bash
owl build --release -O3   # Release mode, max optimization
owl run -r -Os            # Release, size optimization
owl check                 # Validate dependencies
```

## Project structure

```
myproject/
  owl.toml          # Project manifest
  code/main.mire    # Entry point
  tests/            # Test files
  bin/
    debug/          # Debug binaries
    release/        # Release binaries
    .cache/         # Build cache
```

## owl.toml

```toml
[project]
name = "myproject"
version = "0.1.0"
description = ""
entry = "code/main.mire"

[build]
compiler = "mire"
profile = "debug"
opt-level = 0
artifact = "bin"
runtime = "minimal"
target = "x86_64-unknown-linux-gnu"
panic = "abort"
incremental = true
debug-info = true

[paths]
source = "code"
test = "tests"
bin = "bin/debug"
cache = "bin/.cache"
generated = "bin/generated"

[dependencies]
kioto = { path = "~/.owl/libs/kioto", version = "2.4.9" }

[cfg]
publisher = "publish.toml"
registry = "mor"
libs = "~/.owl/libs"
cache = "~/.owl/cache"
```

**Critical:** All external packages MUST be in `[dependencies]` for `load` to work.

## Lockfile

Owl generates `owl.lock` automatically when you build or install. The lockfile
pins exact versions and paths for reproducible installs.

```bash
owl install           # Resolve owl.toml and update/install owl.lock
owl install --lock   # Install all packages from owl.lock
```

Every dependency declared in `[dependencies]` gets a `[[package]]` entry,
**including local `path` dependencies** (they are recorded with
`registry = "local"` and their declared path). A dependency that is missing
from the lockfile makes it out of sync with `owl.toml`, which re-triggers
resolution — so if a project re-resolves on every command, a dep is most
likely not being written to the lock.

```toml
[[package]]
name     = "kioto"
version  = "2.4.9"
path     = "~/.owl/libs/kioto"
registry = "local"
```

Entries are written column-aligned to width 8 (`name␣␣␣␣␣=`, `version␣␣=`,
`path␣␣␣␣␣=`, `registry␣=`); the lockfile reader matches on that exact
alignment, so hand-edited entries must keep it.

Only `[c] sources` may list C files (`.c`). A `.mire` module listed there is
passed to the C compiler and fails the build.

## Documentation

- [Changelog](docs/changelog.md) — release history
- [Technical notes](docs/technical.md) — architecture overview

## License

GNU General Public License v3.0
