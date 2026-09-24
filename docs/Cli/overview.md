# Cli - Command Reference v1.1.0

## Owl v1.1.0 Release Notes

The v1.1.0 release introduces several key improvements:

- **Lockfile V3 automatic generation** - No more manual lockfile management
- **Configuration system `[cfg]`** - New `[lock]` and `update@lock` fields in owl.toml
- **Dependency checksums** - SHA-512 verification for installed packages
- **Exports verification** - Module export validation from lockfile
- **Documentation reorganization** - All docs moved to owl/docs/ following Mire Documentation Standard

## owl new

Create a new Owl project.

```bash
owl new <Name>
```

- Creates directory `<Name>/` with structure:
  - `<Name>/code/main.mire` - main entry point
  - `<Name>/owl.toml` - project configuration v1.1.0 format
  - `<Name>/bin/` - output directory
  - `<Name>/docs/` - documentation directory
- Does NOT create `tests/` directory by default
- Use `--init-tests` flag to add tests directory and smoke.mire
- New projects include `[cfg]` section with `lock = 1`, `update@lock = "Build"` by default

## owl build

Build a Mire project.

```bash
owl build -B <file> [--release] [--debug] [-O <n>]
```

- `-B <file>` - Build the specified file
- `--release` - Release build profile
- `--debug` - Debug build profile
- `-O <n>` - Optimization level (0-3)

## owl run

Run a Mire project.

```bash
owl run -R <file> [-- <args>]
```

- `-R <file>` - Run the specified file
- `-- <args>` - Pass arguments to the program

## owl test

Run tests for a project.

```bash
owl test -T <file> [--log] [--verbose] [--no-run]
```

- `-T <file>` - Test file or directory
- `--log` - Show test logging
- `--verbose` - Show per-test results
- `--no-run` - Compile only, skip execution

## owl --version

Show version information.

```bash
owl --version
```

Output: `Owl v1.1.0 / Mire / Avenys v4.0.0`
