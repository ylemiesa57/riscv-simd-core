#!/usr/bin/env python3
import re

REGS = {f"x{i}": i for i in range(32)}
OPCODES = {
    "add": 0x33,
    "sub": 0x33,
    "addi": 0x13,
    "lw": 0x03,
    "sw": 0x23,
    "beq": 0x63,
    "jal": 0x6F,
    "vdot.vv": 0x0B,
}

FUNCT3 = {
    "add": 0x0,
    "sub": 0x0,
    "addi": 0x0,
    "lw": 0x2,
    "sw": 0x2,
    "beq": 0x0,
    "vdot.vv": 0x0,
}

FUNCT7 = {
    "add": 0x00,
    "sub": 0x20,
    "vdot.vv": 0x01,
}

LABEL = re.compile(r"^([A-Za-z_][\w]*):")


def encode_r(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_i(imm, rs1, funct3, rd, opcode):
    imm &= 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_s(imm, rs2, rs1, funct3, opcode):
    imm &= 0xFFF
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0 = imm & 0x1F
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode


def encode_b(imm, rs2, rs1, funct3, opcode):
    imm &= 0x1FFF
    return ((imm >> 12) & 0x1) << 31 | ((imm >> 5) & 0x3F) << 25 | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm >> 1) & 0xF) << 8 | ((imm >> 11) & 0x1) << 7 | opcode


def encode_j(imm, rd, opcode):
    imm &= 0x1FFFFF
    return ((imm >> 20) & 0x1) << 31 | ((imm >> 1) & 0x3FF) << 21 | ((imm >> 11) & 0x1) << 20 | ((imm >> 12) & 0xFF) << 12 | (rd << 7) | opcode


def parse_reg(tok):
    if tok not in REGS:
        raise ValueError(f"bad reg: {tok}")
    return REGS[tok]


def assemble(lines):
    pc = 0
    labels = {}
    for line in lines:
        line = line.split("#")[0].strip()
        if not line:
            continue
        m = LABEL.match(line)
        if m:
            labels[m.group(1)] = pc
            line = line[m.end():].strip()
            if not line:
                continue
        pc += 4

    pc = 0
    out = []
    for line in lines:
        line = line.split("#")[0].strip()
        if not line:
            continue
        m = LABEL.match(line)
        if m:
            line = line[m.end():].strip()
            if not line:
                continue

        toks = [t.strip() for t in re.split(r"[\s,()]+", line) if t.strip()]
        op = toks[0]
        if op in ("add", "sub"):
            rd, rs1, rs2 = map(parse_reg, toks[1:4])
            out.append(encode_r(FUNCT7[op], rs2, rs1, FUNCT3[op], rd, OPCODES[op]))
        elif op == "vdot.vv":
            rd, rs1, rs2 = map(parse_reg, toks[1:4])
            out.append(encode_r(FUNCT7[op], rs2, rs1, FUNCT3[op], rd, OPCODES[op]))
        elif op == "addi":
            rd, rs1, imm = toks[1], toks[2], int(toks[3], 0)
            out.append(encode_i(imm, parse_reg(rs1), FUNCT3[op], parse_reg(rd), OPCODES[op]))
        elif op == "lw":
            rd, imm, rs1 = toks[1], int(toks[2], 0), toks[3]
            out.append(encode_i(imm, parse_reg(rs1), FUNCT3[op], parse_reg(rd), OPCODES[op]))
        elif op == "sw":
            rs2, imm, rs1 = toks[1], int(toks[2], 0), toks[3]
            out.append(encode_s(imm, parse_reg(rs2), parse_reg(rs1), FUNCT3[op], OPCODES[op]))
        elif op == "beq":
            rs1, rs2, label = toks[1], toks[2], toks[3]
            target = labels[label]
            imm = target - pc
            out.append(encode_b(imm, parse_reg(rs2), parse_reg(rs1), FUNCT3[op], OPCODES[op]))
        elif op == "jal":
            rd, label = toks[1], toks[2]
            target = labels[label]
            imm = target - pc
            out.append(encode_j(imm, parse_reg(rd), OPCODES[op]))
        else:
            raise ValueError(f"unknown op: {op}")
        pc += 4

    return out


def main():
    import sys
    if len(sys.argv) < 3:
        print("usage: mini_asm.py input.s output.hex")
        return 1
    with open(sys.argv[1], "r") as f:
        lines = f.readlines()
    words = assemble(lines)
    with open(sys.argv[2], "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
