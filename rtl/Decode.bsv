package Decode;

import Types::*;

function Bit#(7) get_opcode(Word instr) = instr[6:0];
function Bit#(3) get_funct3(Word instr) = instr[14:12];
function Bit#(7) get_funct7(Word instr) = instr[31:25];
function Bit#(5) get_rs1(Word instr) = instr[19:15];
function Bit#(5) get_rs2(Word instr) = instr[24:20];
function Bit#(5) get_rd(Word instr) = instr[11:7];

function Word imm_i(Word instr);
  return signExtend(instr[31:20]);
endfunction

function Word imm_s(Word instr);
  return signExtend({instr[31:25], instr[11:7]});
endfunction

function Word imm_b(Word instr);
  return signExtend({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});
endfunction

function Word imm_j(Word instr);
  return signExtend({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});
endfunction

endpackage
