package Core;

import Types::*;
import RegFile::*;
import VRegFile::*;
import Decode::*;
import Vector::*;

interface CoreIfc;
  method Action tick;
  method Action loadInstr(Addr addr, Word instr);
  method Action loadData(Addr addr, Word data);
  method Word readData(Addr addr);
  method Action loadVec(Bit#(3) idx, Vector#(4, Word) data);
endinterface

function Bool uses_rs2(Bit#(7) opcode);
  return (opcode == 7'h33) || (opcode == 7'h23) || (opcode == 7'h63) || (opcode == 7'h0b);
endfunction

(* synthesize *)
module mkCore(CoreIfc);
  Reg#(Addr) pc <- mkReg(0);
  RegFileIfc rf <- mkRegFile;
  VRegFileIfc vrf <- mkVRegFile;

  // Simple memories for scaffold
  Vector#(1024, Reg#(Word)) imem <- replicateM(mkReg(0));
  Vector#(1024, Reg#(Word)) dmem <- replicateM(mkReg(0));

  Reg#(IFID) ifid <- mkReg(?);
  Reg#(IDEX) idex <- mkReg(?);
  Reg#(EXMEM) exmem <- mkReg(?);
  Reg#(MEMWB) memwb <- mkReg(?);

  method Action loadInstr(Addr addr, Word instr);
    imem[addr[11:2]] <= instr;
  endmethod

  method Action loadData(Addr addr, Word data);
    dmem[addr[11:2]] <= data;
  endmethod

  method Word readData(Addr addr);
    return dmem[addr[11:2]].read;
  endmethod

  method Action loadVec(Bit#(3) idx, Vector#(4, Word) data);
    vrf.write(idx, data);
  endmethod

  method Action tick;
    // --- EX stage: forwarding + execute ---
    Word fwdA = idex.rs1;
    Word fwdB = idex.rs2;

    if (exmem.regWrite && (exmem.rd != 0) && !exmem.memToReg) begin
      if (exmem.rd == idex.rs1Idx) fwdA = exmem.aluResult;
      if (exmem.rd == idex.rs2Idx) fwdB = exmem.aluResult;
    end
    if (memwb.regWrite && (memwb.rd != 0)) begin
      Word wb = memwb.memToReg ? memwb.memData : memwb.aluResult;
      if (memwb.rd == idex.rs1Idx) fwdA = wb;
      if (memwb.rd == idex.rs2Idx) fwdB = wb;
    end

    Word alu = 0;
    Bool takeBranch = False;
    Addr branchTarget = idex.pc + idex.imm;

    if (idex.isVdot) begin
      Vector#(4, Word) v1 = vrf.read(idex.rs1Idx[2:0]);
      Vector#(4, Word) v2 = vrf.read(idex.rs2Idx[2:0]);
      Word acc = 0;
      for (Integer i = 0; i < 4; i = i + 1) begin
        acc = acc + (v1[i] * v2[i]);
      end
      alu = acc;
    end else begin
      if (idex.opcode == 7'h33) begin
        if (idex.funct7 == 7'h20) alu = fwdA - fwdB; // sub
        else alu = fwdA + fwdB; // add
      end else if (idex.opcode == 7'h13) begin
        alu = fwdA + idex.imm; // addi
      end else if (idex.opcode == 7'h03 || idex.opcode == 7'h23) begin
        alu = fwdA + idex.imm; // address calc
      end else if (idex.jal) begin
        alu = idex.pc + 4;
      end
    end

    if (idex.branch) begin
      takeBranch = (fwdA == fwdB);
    end
    if (idex.jal) begin
      takeBranch = True;
    end

    // --- Hazard detection (load-use) ---
    Bit#(5) if_rs1 = get_rs1(ifid.instr);
    Bit#(5) if_rs2 = get_rs2(ifid.instr);
    Bit#(7) if_op = get_opcode(ifid.instr);
    Bool hazard = idex.memRead && (idex.rd != 0) &&
                  ((idex.rd == if_rs1) || (uses_rs2(if_op) && (idex.rd == if_rs2)));

    // --- PC update ---
    Addr next_pc = pc + 4;
    if (takeBranch) next_pc = branchTarget;
    if (hazard) next_pc = pc;
    pc <= next_pc;

    // --- IF stage ---
    if (!hazard) begin
      let instr = imem[pc[11:2]].read;
      if (takeBranch) begin
        ifid <= IFID { instr: 0, pc: 0, rs1Idx: 0, rs2Idx: 0 };
      end else begin
        ifid <= IFID { instr: instr, pc: pc, rs1Idx: get_rs1(instr), rs2Idx: get_rs2(instr) };
      end
    end

    // --- ID stage ---
    if (hazard || takeBranch) begin
      idex <= IDEX {
        instr: 0,
        pc: 0,
        rs1Idx: 0,
        rs2Idx: 0,
        rs1: 0,
        rs2: 0,
        rd: 0,
        funct3: 0,
        funct7: 0,
        opcode: 0,
        imm: 0,
        memRead: False,
        memWrite: False,
        regWrite: False,
        memToReg: False,
        branch: False,
        jal: False,
        isVdot: False
      };
    end else begin
      let op = get_opcode(ifid.instr);
      let f3 = get_funct3(ifid.instr);
      let f7 = get_funct7(ifid.instr);
      Word imm = 0;
      if (op == 7'h13 || op == 7'h03) imm = imm_i(ifid.instr);
      else if (op == 7'h23) imm = imm_s(ifid.instr);
      else if (op == 7'h63) imm = imm_b(ifid.instr);
      else if (op == 7'h6f) imm = imm_j(ifid.instr);

      Bool memRead = (op == 7'h03);
      Bool memWrite = (op == 7'h23);
      Bool regWrite = (op == 7'h33) || (op == 7'h13) || (op == 7'h03) || (op == 7'h6f);
      Bool memToReg = (op == 7'h03);
      Bool branch = (op == 7'h63);
      Bool jal = (op == 7'h6f);
      Bool isVdot = (op == 7'h0b) && (f3 == 0) && (f7 == 7'h01);
      if (isVdot) regWrite = True;

      let rs1 = rf.read1(ifid.rs1Idx);
      let rs2 = rf.read2(ifid.rs2Idx);

      idex <= IDEX {
        instr: ifid.instr,
        pc: ifid.pc,
        rs1Idx: ifid.rs1Idx,
        rs2Idx: ifid.rs2Idx,
        rs1: rs1,
        rs2: rs2,
        rd: get_rd(ifid.instr),
        funct3: f3,
        funct7: f7,
        opcode: op,
        imm: imm,
        memRead: memRead,
        memWrite: memWrite,
        regWrite: regWrite,
        memToReg: memToReg,
        branch: branch,
        jal: jal,
        isVdot: isVdot
      };
    end

    // --- EX/MEM pipeline ---
    exmem <= EXMEM {
      instr: idex.instr,
      pc: idex.pc,
      aluResult: alu,
      rs2Val: fwdB,
      rd: idex.rd,
      memRead: idex.memRead,
      memWrite: idex.memWrite,
      regWrite: idex.regWrite,
      memToReg: idex.memToReg,
      branch: idex.branch || idex.jal,
      branchTaken: takeBranch,
      branchTarget: branchTarget
    };

    // --- MEM ---
    if (exmem.memWrite) begin
      dmem[exmem.aluResult[11:2]] <= exmem.rs2Val;
    end
    Word memData = dmem[exmem.aluResult[11:2]].read;

    memwb <= MEMWB {
      instr: exmem.instr,
      pc: exmem.pc,
      memData: memData,
      aluResult: exmem.aluResult,
      rd: exmem.rd,
      regWrite: exmem.regWrite,
      memToReg: exmem.memToReg
    };

    // --- WB ---
    if (memwb.regWrite) begin
      Word wbData = memwb.memToReg ? memwb.memData : memwb.aluResult;
      rf.write(memwb.rd, wbData);
    end
  endmethod
endmodule

endpackage
