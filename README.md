# Owl v0.29.0

Package and project manager for the [Mire](https://github.com/mire-lang) (Avenys) language.
Written in Mire, compiled by Avenys.

Owl provides project scaffolding, compilation orchestration, static analysis,
test execution, package management, and build profiling.

## Quick Start

```bash
owl new myproject
cd myproject
owl run
```

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
| | `tree [--all]` | Show dependency tree |
| | `profile [--json]` | Build metrics |

### Packages

| Short | Command | Description |
|-------|---------|-------------|
| `-L` | `load <name>` | Add dependency to owl.toml |
| `-L` | `load -Lu <url>` | Add a package registry |
| `-L` | `load -Ll` | List registries |
| `-L` | `load -Ls` | Sync registries |
| `-L` | `load -Lr <name>` | Remove registry |
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
opt-level = "0"

[paths]
sources = "code"
tests = "tests"
output = "bin"
cache = "bin/.cache"

[dependencies]
kioto = { version = "2.4.0" }
```

## Lockfile

Owl generates `owl.lock` automatically when you build or install. The lockfile
pins exact versions and paths for reproducible installs.

```bash
owl install --lock   # Install all packages from owl.lock
```

## Documentation

- [Changelog](docs/changelog.md) — release history
- [Technical notes](docs/technical.md) — architecture overview

## License

GNU General Public License v3.0
