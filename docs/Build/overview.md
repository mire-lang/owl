# Build - Build System Guide v1.1.0

## Owl v1.1.0 Release Notes

### Build Profiles

Owl supports different build profiles configurable via `owl.toml [build]` section:

- `profile = "debug"` - Debug mode, no optimization, slower compile
- `profile = "release"` - Release mode, optimized for performance
- `-O <n>` - Optimization level (0, 1, 2, 3) via command line

### Build Commands v1.1.0

#### owl build

```bash
owl build -B <file> [--release] [--debug] [-O <n>] [--no-analysis-cache]
```

- `-B <file>` - Build target file (required)
- `--release` - Release build profile
- `--debug` - Debug build profile (overrides --release if both specified)
- `-O <n>` - Optimization level 0-3
- `--no-analysis-cache` - Skip analysis cache, force full recompile

#### owl run

```bash
owl run -R <file> [-- <args>]
```

- `-R <file>` - Run target file (required)
- `-- <args>` - Pass command-line arguments to the program

### Clean Build v1.1.0

To force a clean build (delete analysis cache first):

```bash
owl clean --cache
owl build -B code/main.mire --release
```

### Build Cache v1.1.0

Owl uses an analysis cache (`bin/.cache`) to speed up incremental builds.
- Cache is automatically invalidated when source files change
- Use `owl clean --cache` to manually clear
- For parallel test safety, cache is now WAL-based (see Lockfile docs)

### Build Output v1.1.0

- Debug: `bin/debug/main`
- Release: `bin/release/main`
- Both respect the `[paths] output` setting in `owl.toml`

### Lockfile v1.1.0 Integration

- First `owl build` auto-generates V3 lockfile
- `[cfg]` section in owl.toml controls lock behavior
- `lock = 1` enables verification, `lock = 0` disables it
- `update@lock` mode determines when lockfile updates
