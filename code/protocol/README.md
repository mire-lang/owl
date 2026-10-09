# Owl/Avenys Protocol Codec

The protocol is defined by the workspace-level `protocol/owl_avenys.proto`. Owl implements
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

The protocol milestone is not complete until an automated cross-decode gate
feeds actual Owl-encoded request and response payloads through the Rust codec,
and Rust-encoded payloads through Owl's typed decoders. The golden checks
provide a stable byte contract but do not replace that gate.
