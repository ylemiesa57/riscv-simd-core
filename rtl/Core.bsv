package Core;

import Types::*;
import RegFile::*;
import Decode::*;
import Vector::*;

interface CoreIfc;
  method Action tick;
  method Action loadInstr(Addr addr, Word instr);
  method Action loadData(Addr addr, Word data);
  method Word readData(Addr addr);
endinterface

(* synthesize *)
module mkCore(CoreIfc);
  Reg#(Addr) pc <- mkReg(0);
  RegFileIfc rf <- mkRegFile;

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

  method Action tick;
    // IF
    let instr = imem[pc[11:2]].read;
    ifid <= IFID { instr: instr, pc: pc };
    pc <= pc + 4;

    // ID (minimal decode, no hazards)
    let rs1 = rf.read1(get_rs1(ifid.instr));
    let rs2 = rf.read2(get_rs2(ifid.instr));
    idex <= IDEX {
      instr: ifid.instr,
      pc: ifid.pc,
      rs1: rs1,
      rs2: rs2,
      rd: get_rd(ifid.instr),
      funct3: get_funct3(ifid.instr),
      funct7: get_funct7(ifid.instr),
      opcode: get_opcode(ifid.instr)
    };

    // EX (placeholder ALU)
    Word alu = idex.rs1 + idex.rs2;
    exmem <= EXMEM {
      instr: idex.instr,
      pc: idex.pc,
      aluResult: alu,
      rs2: idex.rs2,
      rd: idex.rd,
      memRead: False,
      memWrite: False,
      regWrite: True,
      memToReg: False
    };

    // MEM
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

    // WB
    if (memwb.regWrite) begin
      Word wbData = memwb.memToReg ? memwb.memData : memwb.aluResult;
      rf.write(memwb.rd, wbData);
    end
  endmethod
endmodule

endpackage
