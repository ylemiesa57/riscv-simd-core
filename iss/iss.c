#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MEM_WORDS 4096

static uint32_t imem[MEM_WORDS];
static uint32_t dmem[MEM_WORDS];
static uint32_t regs[32];
static int32_t vregs[8][4];

static uint32_t fetch(uint32_t pc) {
  return imem[(pc >> 2) & (MEM_WORDS - 1)];
}

static int32_t signext(uint32_t val, int bits) {
  int32_t m = 1u << (bits - 1);
  return (int32_t)((val ^ m) - m);
}

static void exec(uint32_t *pc) {
  uint32_t instr = fetch(*pc);
  uint32_t opcode = instr & 0x7f;
  uint32_t rd = (instr >> 7) & 0x1f;
  uint32_t funct3 = (instr >> 12) & 0x7;
  uint32_t rs1 = (instr >> 15) & 0x1f;
  uint32_t rs2 = (instr >> 20) & 0x1f;
  uint32_t funct7 = (instr >> 25) & 0x7f;

  uint32_t next_pc = *pc + 4;

  switch (opcode) {
    case 0x33: { // R-type
      if (funct3 == 0x0 && funct7 == 0x00) regs[rd] = regs[rs1] + regs[rs2]; // add
      else if (funct3 == 0x0 && funct7 == 0x20) regs[rd] = regs[rs1] - regs[rs2]; // sub
      break;
    }
    case 0x13: { // I-type
      int32_t imm = signext(instr >> 20, 12);
      if (funct3 == 0x0) regs[rd] = regs[rs1] + imm; // addi
      break;
    }
    case 0x03: { // loads
      int32_t imm = signext(instr >> 20, 12);
      uint32_t addr = regs[rs1] + imm;
      if (funct3 == 0x2) regs[rd] = dmem[(addr >> 2) & (MEM_WORDS - 1)]; // lw
      break;
    }
    case 0x23: { // stores
      int32_t imm = signext(((instr >> 25) << 5) | ((instr >> 7) & 0x1f), 12);
      uint32_t addr = regs[rs1] + imm;
      if (funct3 == 0x2) dmem[(addr >> 2) & (MEM_WORDS - 1)] = regs[rs2]; // sw
      break;
    }
    case 0x63: { // branches
      int32_t imm = signext(((instr >> 31) << 12) | (((instr >> 7) & 0x1) << 11) |
                            (((instr >> 25) & 0x3f) << 5) | (((instr >> 8) & 0xf) << 1), 13);
      if (funct3 == 0x0 && regs[rs1] == regs[rs2]) next_pc = *pc + imm; // beq
      break;
    }
    case 0x6f: { // jal
      int32_t imm = signext(((instr >> 31) << 20) | (((instr >> 12) & 0xff) << 12) |
                            (((instr >> 20) & 0x1) << 11) | (((instr >> 21) & 0x3ff) << 1), 21);
      regs[rd] = *pc + 4;
      next_pc = *pc + imm;
      break;
    }
    case 0x0b: { // custom-0
      if (funct3 == 0x0 && funct7 == 0x01) {
        int32_t acc = 0;
        for (int i = 0; i < 4; i++) acc += vregs[rs1 & 0x7][i] * vregs[rs2 & 0x7][i];
        regs[rd] = (uint32_t)acc;
      }
      break;
    }
    default:
      break;
  }

  regs[0] = 0;
  *pc = next_pc;
}

static void load_hex(const char *path) {
  FILE *f = fopen(path, "r");
  if (!f) {
    perror("open program");
    exit(1);
  }
  char line[128];
  uint32_t addr = 0;
  while (fgets(line, sizeof(line), f)) {
    uint32_t word = 0;
    if (sscanf(line, "%x", &word) == 1) {
      imem[addr++] = word;
    }
  }
  fclose(f);
}

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: %s program.hex\n", argv[0]);
    return 1;
  }

  memset(imem, 0, sizeof(imem));
  memset(dmem, 0, sizeof(dmem));
  memset(regs, 0, sizeof(regs));
  memset(vregs, 0, sizeof(vregs));

  // simple init for SIMD vectors
  for (int i = 0; i < 4; i++) {
    vregs[1][i] = i + 1;
    vregs[2][i] = (i + 1) * 2;
  }

  load_hex(argv[1]);

  uint32_t pc = 0;
  for (int step = 0; step < 256; step++) {
    exec(&pc);
  }

  printf("x1=%u\n", regs[1]);
  printf("x2=%u\n", regs[2]);
  printf("x3=%u\n", regs[3]);
  return 0;
}
