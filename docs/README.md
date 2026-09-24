# Owl Documentation v1.1.0

This is the documentation for Owl v1.1.0+, the package and project manager for the Mire language.

## Overview

Owl manages Mire projects, dependencies, and packages. It provides commands for:
- Creating new projects (`owl new`)
- Building and running projects (`owl build`, `owl run`)
- Testing projects (`owl test`)
- Managing dependencies and registries
- Self-update and garbage collection

## Configuration `[cfg]` Section

The `[cfg]` section in `owl.toml` controls lockfile behavior. It is **edited manually** in `owl.toml`:

```toml
[project]
name = "myproject"
version = "1.0.0"

[build]
compiler = "mire"

[lock]  # These fields are part of [cfg] section
lock = 1
update@lock = "Build"

[paths]
sources = "code"

[dependencies]
mire = { path = "~/.owl/libs/mire" }
```

### Available Configuration Options:

- **`lock = 1`** (default): Enable lockfile verification. Lockfile V3 is checked on build/run.
- **`lock = 0`**: Disable lockfile verification. Lockfile is generated but not validated.
- **`update@lock = "Build"`** (default): Update lockfile on every compilation.
- **`update@lock = "Changes"`**: Update lockfile only when `owl.toml` or `load` statements change.
- **`update@lock = "Never"`**: Never update lockfile automatically.

### How to Edit

Simply open `owl.toml` in a text editor and modify the `[cfg]` section fields. No commands are required.

### Default Behavior (New Projects)

When you create a new project with `owl new`:
1. `owl.toml` is created without `[cfg]` section initially
2. On first `owl build`, lockfile V3 is generated automatically
3. To configure lockfile behavior, add `[cfg]` section to `owl.toml`:
   - `lock = 1` enables verification
   - `update@lock = "Build"` updates on each build
   - etc.

## Quick Start

```bash
owl new miproyecto        # Create project (lockfile auto-generates on first build)
owl build -B code/main.mire  # Generates lockfile V3 automatically
owl run -R code/main.mire  # Runs project using lockfile
owl --version             # Show version
```
README: no emojis or decorative formatting.
README: follows Mire Documentation Standard (MIRE-DOC-STANDARD.md).
README: all files in owl/docs/ are indexed here for easy navigation.
README: see individual directories for detailed documentation.
README: no personal symbols except compiler-generated error messages.
README: configuration `[cfg]` section edited manually in owl.toml.
README: lockfile V3 generated automatically on first build.
</READMEEOF