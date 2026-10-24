# Cli - Command Reference v1.3.0

## Owl v1.3.0 Release Notes

- **CLI flag validation fixed** — `owl build -d`, `owl build --debug`, `owl build -O`, `owl build -B`, `owl run -d`, `owl run --debug`, `owl run -R`, `owl test --release`, `owl test -j` and other flags that `build::compile()`/`test_config()` already handled were rejected by `args::allowed_flags()` with `E0012: Unknown flag`. All flags the compiler supports are now declared.
- **`owl load <name> [version]` implemented** — adds a dependency to `[dependencies]` in `owl.toml`. Without a version it uses a local path `~/.owl/libs/<name>`; with a version it declares a versioned registry dependency. Follow with `owl install`.
- **Version unified** — README, `owl.toml`, and the fallback constant all report `v1.3.0`.
- **`owl info`** now resolves the compiler through `util::compiler_cmd()` (honoring `owl.toml [build] compiler` and `MIRE_COMPILER`) instead of hardcoding `mire`.
- **`owl new` template** uses `code/main.mire`, `pub fn main: ()`, and `[paths] sources = "code"`, matching the codebase convention.

## Global flags

| Flag | Description |
|------|-------------|
| `-V`, `--version` | Show version |
| `-h`, `--help` | Show help |

## Build commands

### `owl build`

```bash
owl build [-B <file>] [-d|--debug|-r|--release] [-O <n>] [--lib-dir <path>] [--no-analysis-cache]
```

- `-B <file>` — Build the specified file (same as positional argument)
- `-d`, `--debug` — Debug build profile (opt-level 0)
- `-r`, `--release` — Release build profile (opt-level 3)
- `-O <n>`, `--opt-level <n>` — Optimization level (0, 1, 2, 3, s, z)
- `--lib-dir <path>`, `-L <path>` — Extra package directory
- `--no-analysis-cache` — Force full recompile

### `owl run`

```bash
owl run [-R <file>] [-d|--debug|-r|--release] [-O <n>] [-- <args>]
```

- `-R <file>` — Run the specified file (same as positional argument)
- `-d`, `--debug` — Debug build profile
- `-r`, `--release` — Release build profile
- `-O <n>`, `--opt-level <n>` — Optimization level
- `-- <args>` — Pass arguments to the program after the `--` separator

## `owl test`

```bash
owl test [-T <file>] [--release|-r] [--debug|-d] [--opt-level|-O <n>] [--jobs|-j <n>] [--no-run] [--verbose|-v] [--log] [--no-warn] [--no-categorize] [--cache] [--cache-dir <path>] [--lib-dir|-L <path>] [--config <file>] [--target <triple>] [--runtime <tier>]
```

- `-T <file>` — Test file or directory
- `-r`, `--release` — Release profile (opt-level 3)
- `-d`, `--debug` — Debug profile (opt-level 0)
- `-O <n>`, `--opt-level <n>` — Optimization level
- `-j <n>`, `--jobs <n>` — Parallel compilation jobs
- `--no-run` — Compile only, skip execution
- `--verbose`, `-v` — Show per-test results
- `--log` — Show test logging
- `--no-warn` — Suppress warnings
- `--no-categorize` — Disable warning categorization

**Testing always builds an executable** (`artifact = "bin"`), regardless of
`[build] artifact` in `owl.toml`. A manifest declaring `runtime = "none"` is
lifted to `minimal` for the test build.

## Project commands

### `owl new <Name>`

Scaffold a new project:

```
<Name>/
  owl.toml
  bin/
  code/
    main.mire
```

### `owl clean [--bin] [--cache] [--all|-A] [--global]`

Remove build artifacts and cache.

### `owl info [--json]`

Show project and environment information.

### `owl checkup [--fix <field> ...] [--cache] [--deps] [--loads]`

Project diagnostics and repair.

### `owl profile [--json]`

Build metrics.

## Package commands

### `owl load <name> [version]`

Add a dependency to `[dependencies]` in `owl.toml`. Without a version, uses a
local path `~/.owl/libs/<name>`. With a version, declares a versioned registry
dependency. Run `owl install` afterward to resolve and install.

### `owl install <name> [ver]`

Download and install a package. `owl install --lock` installs all packages from
`owl.lock`.

### `owl reg add <url>` / `reg list` / `reg sync` / `reg remove <name>`

Manage package registries.

### `owl export [--check|--dry-run]`

Package and sign for registry publication.

### `owl deps --prune`

Remove unused dependencies from `owl.toml`.

### `owl gc`

Garbage collect orphaned packages.

### `owl upgrade [--yes]`

Self-update owl from source.