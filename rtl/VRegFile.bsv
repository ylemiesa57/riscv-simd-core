package VRegFile;

import Types::*;
import Vector::*;

interface VRegFileIfc;
  method Vector#(4, Word) read1(Bit#(3) idx);
  method Vector#(4, Word) read2(Bit#(3) idx);
  method Action write(Bit#(3) idx, Vector#(4, Word) data);
endinterface

(* synthesize *)
module mkVRegFile(VRegFileIfc);
  Vector#(8, Vector#(4, Reg#(Word))) regs <- replicateM(replicateM(mkReg(0)));

  method Vector#(4, Word) read1(Bit#(3) idx);
    Vector#(4, Word) out = newVector;
    for (Integer i = 0; i < 4; i = i + 1) begin
      out[i] = regs[idx][i];
    end
    return out;
  endmethod

  method Vector#(4, Word) read2(Bit#(3) idx);
    Vector#(4, Word) out = newVector;
    for (Integer i = 0; i < 4; i = i + 1) begin
      out[i] = regs[idx][i];
    end
    return out;
  endmethod

  method Action write(Bit#(3) idx, Vector#(4, Word) data);
    for (Integer i = 0; i < 4; i = i + 1) begin
      regs[idx][i] <= data[i];
    end
  endmethod
endmodule

endpackage
