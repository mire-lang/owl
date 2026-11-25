# Owl/Avenys Protocol Codec

The protocol is defined by Avenys' tracked `protocol/owl_avenys.proto`. Owl implements
the version-one protobuf payload codec in `wire.mire` and `messages.mire`.
Transport framing is separate from message payload encoding so the same
messages can use private FIFOs during bootstrap and Unix-domain sockets later.

The initial synchronous build exchange contains `CompileReq` and
`CompileResp`. It uses protobuf wire types 0 and 2, nested messages, repeated
fields, and a varint length prefix. Frames are limited to 64 MiB; a zero-length
frame closes the session. Unknown fields with supported wire types are
skipped. Unsupported wire types, malformed lengths, invalid UTF-8 in strings,
unknown protocol versions, and unknown response statuses are rejected by the
message decoders.

The files in `golden/` are canonical protobuf payloads without frame prefixes.
The Rust Avenys codec keeps matching versioned fixtures. Tests check that Owl
encodes these exact bytes and decodes them into typed request and response
values. Keep field numbers stable and update the schema, both codecs, both
fixture sets, and their tests together whenever a new protocol version is
introduced.

Run the focused Mire test from the Owl repository root with the current Avenys
compiler and the pinned Kioto library set:

```sh
mire test tests/protocol_wire.mire -j 1 --release --lib-dir "$MIRE_LIB_DIR"
```

The direct interoperability gate exchanges actual raw request and response
payloads in both directions: Rust writes its encoded bytes, Owl decodes them
and writes its own encoded bytes, and Rust then decodes those outputs into the
expected typed messages. Run it from the Owl repository root:

```sh
MIRE_BIN=/path/to/branch-built/mire \
MIRE_LIB_DIR=/path/to/pinned/mire-libraries \
    scripts/verify-protocol-cross-decode.sh
```

The script creates a temporary exchange directory under `tests/` so Owl's
project-root filesystem sandbox can access it, then removes that directory on
exit. The cross-decode gate passes on the current Avenys/Owl branches. The
schema passed syntax validation with `protoc 36.1`.
`.github/workflows/protocol.yml` runs the same two-way cross-decode test for
protocol pull requests and supports an explicit Avenys ref for manual checks.

The repository-owned schema is `Avenys/protocol/owl_avenys.proto` in the
workspace. The validator also checks that the optional workspace mirror has
the same compiled descriptor. Run from the Avenys repository root:

```sh
./scripts/validate-protocol-schema.sh /tmp/owl_avenys_schema.pb
```

The Avenys CI and release-validation jobs install `protobuf-compiler` for this
check. End-user installers intentionally do not install it: the codecs have
no protobuf runtime dependency.
