# ISA Notes

## Base ISA
- RV32I subset
- Supported in ISS: `add`, `sub`, `addi`, `lw`, `sw`, `beq`, `jal`

## Custom SIMD extension
### vdot.vv
- Mnemonic: `vdot.vv rd, rs1, rs2`
- Semantics: `rd <- sum_{i=0..3} v[rs1_idx][i] * v[rs2_idx][i]`
  - where `rs1_idx = (rs1_scalar_regnum & 0x7)` and `rs2_idx = (rs2_scalar_regnum & 0x7)`
- Vector registers: v0..v7 (8 total), each 4x32-bit

### Vector Register Indexing
The vector register index is extracted from the lower 3 bits of the scalar register field:
- `vdot.vv rd, x1, x2` uses vector registers v1 and v2
- `vdot.vv rd, x9, x10` also uses v1 and v2 (since 9 & 0x7 = 1, 10 & 0x7 = 2)
- Registers x0–x7 can access all 8 vector registers (v0–v7) without aliasing
- Registers x8–x31 alias to vector registers: x8→v0, x9→v1, ..., x15→v7, then x16→v0, etc.

### Encoding (custom-0)
```
31        25 24   20 19   15 14  12 11    7 6      0
funct7       rs2    rs1    funct3   rd    opcode
0000001      rs2    rs1     000     rd    0001011
```

- `opcode` = `0b0001011` (custom-0)
- `funct3` = `0b000`
- `funct7` = `0b0000001`
- `rs1`, `rs2` are scalar register number fields; only bits 2:0 used for vector index

This keeps the custom op in the standard custom-0 space while leaving room for future vector ops.
