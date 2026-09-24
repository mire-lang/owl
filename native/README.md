# Native archive bridge

`archive.c` is compiled into Owl through Avenys' normalized compiler config.
It links `libarchive` and uses its zstd filter for package creation and
extraction. Owl calls the two exported bridge functions directly through the
Mire C ABI; it does not spawn `tar` or `zstd`.

`mire-config.toml` is a standalone build fixture for validating the bridge.
Normal Owl builds generate an equivalent config in the project cache.
