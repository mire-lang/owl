# `owl.toml` project configuration

This is the reference for the project manifest read by Owl. `owl new NAME`
creates only `NAME/{src/main.mr,bin/,owl.toml}`. It deliberately does not create
tests, documentation, dependency declarations, or language-specific tooling;
the project developer chooses and maintains those.

Paths below are interpreted relative to the project directory unless stated
otherwise. Owl currently reads this file with a small, line-oriented TOML
reader, not a complete TOML implementation. Use one key per line, ordinary
quoted strings, and single-line arrays of quoted strings. Avoid multiline
arrays, escaped quotes, dotted/nested tables for the documented keys, and
duplicate keys. Dependency tables use the inline form shown below.

## Minimal working manifest

```toml
[project]
name = "sample"
version = "0.1.0"
description = ""
entry = "src/main.mr"

[build]
compiler = "mire"
profile = "debug"
opt-level = "0"
artifact = "bin"
runtime = "minimal"

[paths]
sources = "src"
tests = "tests"
output = "bin"
cache = "bin/.cache"
```

The `tests` path is configuration only: Owl does not create that directory.
Create it when you add tests. `owl build` and `owl run` use `project.entry`;
`owl test` scans the configured test directory.

## `[project]`

| Key | Meaning |
|---|---|
| `name` | Project/package name. Required by project checks and publishing. |
| `version` | Project version string. Required by project checks and publishing. |
| `description` | Human-readable summary; recommended, but not required to build. |
| `entry` | Mire source file built by default. Required by build/run/test; the generated project uses `src/main.mr`. |

## `[build]`

| Key | Meaning |
|---|---|
| `compiler` | Compiler executable. Defaults to `mire` when omitted. Owl validates compiler paths; use `mire` or an absolute executable path. |
| `profile` | Build profile label, conventionally `debug` or `release`. Required by build and test. Also determines the profile output subdirectory. |
| `opt-level` | Optimization level passed to Mire. Required by build and test; use a string such as `"0"`, `"1"`, `"2"`, `"3"`, `"s"`, or `"z"` supported by the installed compiler. |
| `artifact` | Requested artifact kind, default `bin`. The compiler validates supported values. `owl test` always requests an executable regardless of this setting. |
| `runtime` | Runtime tier forwarded to Mire; default `minimal`. Use a tier supported by the compiler in use. |
| `target` | Target triple forwarded when Owl generates a test compiler configuration. |
| `artifacts` | Optional comma-separated artifact kinds used by `owl export`; if absent, export considers shared, static, and object outputs. |

The current CLI also provides per-invocation controls such as `--release`,
`--debug`, `--opt-level`, `--runtime`, and `--target` where supported. These do
not rewrite the manifest. See `owl help` for the command-specific flag set.

## `[paths]`

| Key | Meaning |
|---|---|
| `sources` | Source root used by project checks and source/load discovery. |
| `tests` | Test source directory used by `owl test` and checkup. It may not exist until the developer adds tests. |
| `output` | Build output root. Required by build/install/checkup. Binaries are organized below this path by profile. |
| `cache` | Owl/compiler cache root. Required by build and test. |
| `source`, `test`, `bin`, `generated`, `target` | Legacy/normalized compiler-config path names encountered in existing projects. New project manifests should use `sources`, `tests`, `output`, and `cache`; these legacy keys are not interchangeable in all Owl commands. |

## `[dependencies]`

Each key is a package name. Declare either a local path or a version accepted
by the configured registry/resolver:

```toml
[dependencies]
kioto = { path = "../kioto" }
json = { version = "1.2.0" }
```

Owl resolves and installs declared packages and records the resolved state in
`owl.lock`. `owl load -L NAME` and dependency maintenance commands may edit this
section. Do not hand-edit `owl.lock` to express a dependency. The reader
currently extracts inline `path` and `version` string fields; it does not
implement the full TOML dependency-specification grammar.

## `[c]` — native C inputs

All values are single-line arrays of strings:

```toml
[c]
sources = ["native/helper.c"]
include = ["native/include"]
libs = ["m"]
cflags = ["-O2"]
```

| Key | Meaning |
|---|---|
| `sources` | C source files included in the project build. |
| `include` | Include directories forwarded as C include options. |
| `libs` | Native libraries to link. |
| `cflags` | Additional C compiler flags. |

These are optional; omit `[c]` for a Mire-only project. C compiler support and
the selected backend determine which flags and libraries are available.

## `[security]` — compiler policy

| Key | Type | Meaning |
|---|---|---|
| `mode` | string | Security mode forwarded to the compiler, when set. |
| `externs` | string array | Extern symbol patterns allowed by compiler policy. |
| `extern-libs` or `extern_libs` | string array | Native libraries allowed for extern declarations. Prefer `extern_libs`; the dashed spelling remains supported for compatibility. |
| `macros` | string array | Macro names allowed by compiler policy. |
| `allow-unsafe` | boolean | Set `true` to pass the compiler's unsafe-code allowance; otherwise unsafe remains disallowed by the generated configuration. |

Omitting these keys lets Owl apply its compiler-configuration defaults. Review
the resulting policy carefully before building untrusted code; this section is
not a sandbox for native C code or external processes.

## `[cfg]` — project package-manager settings

This section is also readable/writable with `owl cfg get/set ... --project`.
The legacy lock settings are:

| Key | Meaning |
|---|---|
| `lock` | Lockfile format/configuration version. Legacy default is `1`; current lockfile generation can migrate projects to its supported format. |
| `update@lock` | Legacy lock refresh policy. The historical default is `Build`; verify current behavior with `owl cfg list --project` and lockfile commands. |
| `publisher`, `registry`, `registry_url`, `cache`, `libs`, `deps` | Project-level registry, cache, and package-location values used by particular Owl workflows or older manifests. They are not required for a basic local build; defaults may also come from Owl's global configuration and environment. |

Because the lock policy is being migrated, prefer the normal `owl install`,
`owl update`, and `owl.lock` workflow over setting legacy lock keys in a new
project.

## `[exports]` and Owl metadata

`[exports]` maps package module names to the source files/directories exported
by a library package. It is relevant when publishing/re-exporting an Owl
package, not to a simple executable project. The quoted table `"owl@lock"`
contains Owl's lockfile-format version metadata and is maintained by Owl; do
not use it for project settings.

Dependency/package manifests may also contain `[package]` metadata. Owl's
lockfile and package checks recognize `compiler`, `language`, and `abi` there
when identifying package compatibility. These keys describe a package for
consumers; they do not configure the current project's build. Older manifests
may contain `[tool.owl.auto-deps]`; it is generated metadata rather than a
general-purpose project configuration interface.

## Adding developer-owned project structure

For example, when tests are desired, create `tests/` and add test sources, then
run `owl test`. Add `native/` only when using C, and add docs, examples, CI,
editor settings, or scripts according to the project's needs. Owl does not
assume those directories exist merely because they are conventional.

When configuration behavior differs from this reference, inspect the installed
Owl version and run `owl checkup`; the manifest reader is intentionally being
expanded and should not be mistaken for support for every feature of TOML.
