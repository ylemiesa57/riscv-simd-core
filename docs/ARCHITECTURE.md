# Architecture

## Pipeline (5-stage)
1. IF: fetch instruction from instruction memory
2. ID: decode and read registers
3. EX: ALU + branch + SIMD dot (custom)
4. MEM: data memory access
5. WB: writeback to register file

## Notes
- The Bluespec RTL is intentionally small and readable.
- Basic load-use stall and EX/MEM + MEM/WB forwarding are implemented.
- The ISS remains the reference for functional behavior.
