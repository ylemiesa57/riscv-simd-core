# RISC-V SIMD Core (WIP)

A 5-stage pipelined RISC-V core with custom SIMD vector instructions for dot-product acceleration. This repo will host the Bluespec (BSV) RTL, a C++ instruction set simulator (ISS), and tests used to cross-verify hardware and software execution traces.

## Status
Work in progress. This is a scaffold with planned layout and documentation.

## Goals
- 5-stage pipeline with hazard handling (forwarding + stalls).
- Custom SIMD vector ops for dot-product acceleration.
- C++ ISS for trace-level parity with RTL.
- Focus on simple, auditable microarchitecture and clean test vectors.

## Planned repo layout
- `rtl/` - Bluespec RTL and supporting modules.
- `iss/` - C++ instruction set simulator.
- `tests/` - Assembly and C-based tests.
- `software/` - Build helpers, reference kernels.
- `docs/` - Microarchitecture notes and ISA extensions.
- `scripts/` - Build, lint, and regression helpers.

## License
MIT
