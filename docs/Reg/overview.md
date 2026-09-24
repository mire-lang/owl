# Reg - Registry Management v1.1.0

## Owl v1.1.0 Release Notes

### Registry Configuration

Owl uses registries to find and install packages. Registry configuration is stored in `owl.toml`.

### Registry Format

```toml
[registries]
my_registry = "https://example.com/registry"
```

### Common Operations v1.1.0

#### Add a Registry

```bash
owl reg add <url>
```

#### List Registries

```bash
owl reg list
```

#### Remove a Registry

```bash
owl reg remove <name>
```

#### Synchronize a Registry

```bash
owl reg sync
```

or

```bash
owl reg sync_one <path>
```

### Registry Validation v1.1.0

Owl validates registries by checking:
- Package index format
- Public key availability
- Version compatibility
- Dependency exports

### Registry Security v1.1.0

- Public key verification for package signing
- Version range validation
- Export compatibility checks
- Path traversal prevention
