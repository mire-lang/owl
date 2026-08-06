# Owl Technical Notes

## Architecture (v0.31.0)

### CLI core
- Entrypoint: `code/main.mire` (slim dispatcher)
- Codebase modularized into 18 sub-packages under `code/`:
  `util`, `crypto`, `trust`, `registry`, `build`, `check`, `info`, `ui`,
  `args`, `deps`, `export`, `gc`, `install`, `lockfile`, `profile`, `semver`, `tree`, `upgrade`
- All internal modules imported via `load!` (local) with `use!` calls
- `load!` modules use path prefixes (`/code/util`, `/code/crypto`, etc.)
- Supports both long commands and pacman-style short flags (`-B`, `-T`, `-S`, etc.)

### Command dispatch
- `main()` reads `env_args()[1]` as the command
- `-V`, `-h`, `-N`/`new` handled first (no args copy needed)
- Remaining commands use `a1..a15` args copy chain for ownership
- Pacman subflags (`-Ss`, `-Qi`, etc.) handled in fallback block
  after all named commands

### Build/Run pipeline
- `compile_pipeline()` resolves file, profile, and optimization flags
- Builds command string: `mire <build|run> <file> --debug|--release -O <n>`
- Delegates to `proc::run()` which maps to `pal_proc_run` C function
- Returns compiler stdout to user

### Test runner
- `find_mire_files("tests")` -- recursive `.mire` discovery, skips `lib/`
- Each file compiled with `mire build <file> --debug -O0`
- Binary extracted from `bin/debug/<stem>` where stem = last path component
- Executed via `proc::run("./" + bin_path)`
- Pass/fail counted; `lib/` directories excluded from discovery

### TOML parser
- `toml_get(file, section, key)` -- reads a single key from a TOML section
- `toml_keys(file, section)` -- lists all keys in a TOML section
- Handles `[section]` headers, `key = "value"` pairs, `# comments`
- Strips quotes from values automatically

### Package management
- `~/.owl/` directory structure:
  - `libs/<name>/` -- installed packages (tarballs extracted here)
  - `registries/<name>/` -- synced registry data (index.toml, index.toml.sig)
  - `cache/tarballs/` -- downloaded tarballs (cleaned by `owl gc`)
- `owl load <name>` -- adds dependency to owl.toml [dependencies]
- `owl load -Lu <url>` -- adds a package registry
- `owl load -Ls` -- syncs registries via HTTP (curl)
- `owl install <name>` -- downloads and installs from registries
- `owl install --lock` -- installs all packages from owl.lock
- `owl export` -- packages and signs for registry publication

### Lockfile
- `owl.lock` auto-generated on build/install
- Contains `[[package]]` entries with: name, version, path, registry, abi, compiler, language
- `owl install --lock` reads lockfile and installs missing packages
- Registry resolution: scans configured registries when no explicit registry field

### Module resolution
- Internal modules: `load!` with path prefixes (`/code/util`, `/code/crypto`)
- External packages: `load kioto` (from `owl.toml [dependencies]`)
- `use!` mandatory for all calls into `load!`-imported modules
- `--lib-dir` flag enables custom library search path

### Built-in functions used
Owl relies on compiler built-ins (not kioto imports):
- `proc::run` -- execute command, capture stdout
- `dasu` -- print to stdout
- `fs_exists`, `fs_is_dir`, `fs_read`, `fs_write`, `fs_drop`, `fs_list`,
  `fs_mkdir`, `fs_rmdir`, `fs_copy`, `fs_move`
- `strings::split`, `strings::trim`, `strings::startswith`, `strings::endswith`,
  `strings::substr`, `strings::replace`, `strings::index`, `strings::join`
- `lists::get`, `lists::push`, `len`
- `env_args`, `env_get`
- `rt_vec_get_str`, `rt_vec_len`, `rt_i64_to_string`, `rt_string_to_i64`

### Cache management
- `owl clean --cache` clears `.cache/`
- `owl clean --bin` removes `bin/`
- `owl clean --all` removes both plus `deps/` and `_test_harness.mire`

### Current scope (v0.31.0)
- Project management: `new`, `run`, `build`, `test`, `clean`, `info`, `check`, `checkup`, `profile`, `tree`
- `checkup` validates all owl.toml fields, dependency count, and lockfile integrity
- Package management: `load`, `install`, `install --lock`, `export`, `gc`, `upgrade`
- Registry management: `load -Lu`, `load -Ls`, `load -Ll`, `load -Lr`
- Dependency pruning: `deps --prune`, `install --prune`
- Pacman-style short flags for all primary commands
- Registry sync via HTTP (curl-based, no git required)

## Audit hardening (0.31.0)

- **`util::expand_home(path)`** — expands a leading `~` to `$HOME`. Wired into
  `cmd_check`, `cmd_checkup` deps check, `checkup --fix deps`, and
  `lockfile_validate`; TOML `~/.owl/...` paths are otherwise unresolvable.
- **`util::record_build()`** — appends to `~/.owl/cache/build_status.toml`
  after a successful compile (gated on `proc::run::last_exit() == 0`), feeding
  `owl profile`'s build count. Subprocess success is judged ONLY by
  `last_exit()`, never by string-matching tool output (that was the
  `owl export` "tar + zstd required" bug).
- **`gc` is safe by construction:** dry-run default (`--yes` to delete), skips
  flat working copies (`libs/<pkg>/` with a top-level `meta.toml`/`owl.toml`,
  e.g. kioto), prunes only versioned `libs/<pkg>/<ver>/`. `rm -rf` does not
  follow symlinks, but the old layout assumption made it delete flat libs and
  the `mire` symlink target anyway — hence the hard versioned-layout check.
- **`deps --prune` never removes `mire`** (the compiler stdlib has no
  ``load ` `` reference by construction); other deps are pruned only when no
  source contains ``load <dep> ``.
- **`run -- args...`** — `compile_pipeline` parses the `--` separator and
  forwards trailing args to `proc::run::spawn(bin run_args)`.
- **PAL channel contract honored:** `pal_proc_create` with `{0,0}` channel args
  means "no pipes, inherit parent fd"; child stdout is no longer swallowed
  (this was a PAL implementation bug, not a cache issue).
