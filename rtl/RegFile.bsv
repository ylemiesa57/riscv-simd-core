package RegFile;

import Types::*;
import Vector::*;

interface RegFileIfc;
  method Word read1(Bit#(5) addr);
  method Word read2(Bit#(5) addr);
  method Action write(Bit#(5) addr, Word data);
endinterface

(* synthesize *)
module mkRegFile(RegFileIfc);
  Vector#(32, Reg#(Word)) regs <- replicateM(mkReg(0));

  method Word read1(Bit#(5) addr);
    return (addr == 0) ? 0 : regs[addr];
  endmethod

  method Word read2(Bit#(5) addr);
    return (addr == 0) ? 0 : regs[addr];
  endmethod

  method Action write(Bit#(5) addr, Word data);
    if (addr != 0) regs[addr] <= data;
  endmethod
endmodule

endpackage
