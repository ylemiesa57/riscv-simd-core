package Types;

typedef Bit#(32) Word;
typedef Bit#(32) Addr;

typedef struct {
  Word instr;
  Addr pc;
  Bit#(5) rs1Idx;
  Bit#(5) rs2Idx;
} IFID deriving (Bits, FShow);

typedef struct {
  Word instr;
  Addr pc;
  Bit#(5) rs1Idx;
  Bit#(5) rs2Idx;
  Word rs1;
  Word rs2;
  Bit#(5) rd;
  Bit#(3) funct3;
  Bit#(7) funct7;
  Bit#(7) opcode;
  Word imm;
  Bool memRead;
  Bool memWrite;
  Bool regWrite;
  Bool memToReg;
  Bool branch;
  Bool jal;
  Bool isVdot;
} IDEX deriving (Bits, FShow);

typedef struct {
  Word instr;
  Addr pc;
  Word aluResult;
  Word rs2Val;
  Bit#(5) rd;
  Bool memRead;
  Bool memWrite;
  Bool regWrite;
  Bool memToReg;
  Bool branch;
  Bool branchTaken;
  Addr branchTarget;
} EXMEM deriving (Bits, FShow);

typedef struct {
  Word instr;
  Addr pc;
  Word memData;
  Word aluResult;
  Bit#(5) rd;
  Bool regWrite;
  Bool memToReg;
} MEMWB deriving (Bits, FShow);

endpackage
