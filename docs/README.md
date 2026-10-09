# Owl Documentation v1.1.0

This is the documentation for Owl v1.1.0+, the package and project manager for the Mire language.

## Overview

Owl manages Mire projects, dependencies, and packages. It provides commands for:
- Creating new projects (`owl new`)
- Building and running projects (`owl build`, `owl run`)
- Testing projects (`owl test`)
- Managing dependencies and registries
- Self-update and garbage collection

## Project configuration

See the full [`owl.toml` configuration reference](Configuration/owl-toml.md)
for every project-manifest section Owl currently reads, defaults, limitations,
and examples. The `[cfg]` lock options are legacy settings; the reference
describes their current limits and the preferred `owl.lock` workflow.

## Quick Start

```bash
owl new my-project        # Create src/main.mr, bin/, and owl.toml
cd my-project
owl build                 # Build the configured entry
owl run                   # Build and run the configured entry
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
