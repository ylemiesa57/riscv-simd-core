# ISA Notes

## Base ISA
- RV32I subset
- Supported in ISS: `add`, `sub`, `addi`, `lw`, `sw`, `beq`, `jal`

## Custom SIMD extension
### vdot.vv
- Mnemonic: `vdot.vv rd, rs1, rs2`
- Semantics: `rd <- sum_{i=0..3} v[rs1][i] * v[rs2][i]`
- Vector registers: v0..v7, each 4x32-bit

### Encoding (custom-0)
```
31        25 24   20 19   15 14  12 11    7 6      0
funct7       rs2    rs1    funct3   rd    opcode
0000001      rs2    rs1     000     rd    0001011
```

- `opcode` = `0b0001011` (custom-0)
- `funct3` = `0b000`
- `funct7` = `0b0000001`

This keeps the custom op in the standard custom-0 space while leaving room for future vector ops.
