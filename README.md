# RISC-V SIMD Core

Minimal 5-stage RISC-V core in **Bluespec** with a tiny **C** ISS and a **Python** test harness. The focus is clarity and traceable correctness, not peak performance. This repo includes a custom SIMD dot-product instruction and a simple assembler for a small test subset.

## What this is
- 5-stage pipeline skeleton (IF/ID/EX/MEM/WB) in Bluespec.
- Scalar RV32I subset plus one SIMD op: 4-lane dot product.
- C-based ISS for cross-checking and test goldens.
- Python tests that assemble a tiny program and verify outputs.

## Custom SIMD instruction
A single vector dot-product op accelerates 4x32-bit integer dot products.

```
vdot.vv rd, rs1, rs2
# rd <- sum_{i=0..3} v[rs1][i] * v[rs2][i]
```

Encoding is documented in `docs/ISA.md` (custom opcode `0b0001011`).

## Repo layout
- `rtl/` — Bluespec pipeline skeleton and modules.
- `iss/` — Minimal C ISS + build script.
- `tests/` — Python tests and mini-assembler; sample asm/c.
- `docs/` — ISA notes and architecture.

## Build the ISS
```bash
cd iss
make
```

## Run tests
```bash
python -m pytest -q
```

If `gcc` is missing, tests will skip the ISS integration test.

## Status
This is a minimal, readable baseline. It is intentionally incomplete: the pipeline is a skeleton and needs functional unit completion, hazard handling, and memory integration.

## License
MIT
