# Security - System Security Model

## Sandbox Model

Owl operates within the PAL (Protected Abstraction Layer) sandbox with the following principles:

### File System Isolation

- All file operations are relative to the project root
- Paths are resolved with `RESOLVE_NO_SYMLINKS` to prevent symlink attacks
- `pal_root_remove` and `pal_root_open` enforce parent resolution before operations
- Absolute paths are supported but may fall back to legacy `openat` on Linux

### Process Execution

- `proc::run::output(cmd, args)` uses argv-safe invocation (no shell)
- `proc::run::shell()` is gated behind `PAL_ALLOW_LEGACY_SHELL` (default: off)
- Channel-based communication (`pal_channel_*`) replaces popen/system patterns
- Pipe management follows RAII pattern with automatic cleanup

### Network Access

- Network operations go through registered registries only
- Package installation uses verified Ed25519 signatures
- Archive extraction respects path boundaries (no parent traversal)
- Download progress is tracked but not interactive

### Configuration gating

- `PAL_ALLOW_UNSANDBOXED` (default: 1) - bypass root capabilities, for trusted code only
- `PAL_ALLOW_LEGACY_SHELL` (default: 0) - shell surface, re-enable with flag
- Registry signatures required for package installation
- Symlink policy: never follow symlinks during removal operations

### Error Handling

- All operations return clear error codes
- Failed operations do not leave partial state
- Cache corruption recovery via WAL (Write-Ahead Log)
- Fallback to safe defaults on errors (e.g., deny access on uncertainty)