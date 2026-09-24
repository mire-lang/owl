# Owl v1.1.1

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

## Commands

### Build

| Short | Command | Description |
|-------|---------|-------------|
| `-B` | `build [file] [-d\|-r] [-O <n>]` | Compile project to binary |
| `-R` | `run [file] [-d\|-r] [-O <n>] [-- <args>]` | Compile and execute |
| `-T` | `test [file] [--verbose] [--no-run]` | Run test suite |
| `-K` | `check` | Validate dependencies (path, version, integrity) |
| `-D` | `debug [file] [--tokens\|-t] [--ast\|-p] [--ir] [--run\|-r]` | Compiler introspection |
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
| `-L` | `load <name>` | Add dependency to owl.toml |
| `-G` | `reg add <url>` | Add a package registry |
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
| `-V`, `--version` | Show version |
| `-h`, `--help` | Show help |

## checkup Command — Diagnostics & Repair

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

## Documentation

- [Changelog](docs/changelog.md) — release history
- [Technical notes](docs/technical.md) — architecture overview

## License

GNU General Public License v3.0
