# Architecture

## Pipeline (5-stage)
1. IF: fetch instruction from instruction memory
2. ID: decode and read registers
3. EX: ALU + branch + SIMD dot (custom)
4. MEM: data memory access
5. WB: writeback to register file

## Notes
- The Bluespec RTL is a readable scaffold.
- Hazard handling is not yet implemented.
- The ISS is the reference for functional behavior.
