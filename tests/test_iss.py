import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASM = ROOT / "tests" / "asm" / "demo.s"
HEX = ROOT / "tests" / "asm" / "demo.hex"
ASM_TOOL = ROOT / "tests" / "asm" / "mini_asm.py"
ISS_DIR = ROOT / "iss"
ISS_BIN = ISS_DIR / "iss"


def has_gcc():
    return shutil.which("gcc") is not None


def test_demo_program_runs():
    if not has_gcc():
        import pytest
        pytest.skip("gcc not available")

    # assemble
    subprocess.check_call(["python", str(ASM_TOOL), str(ASM), str(HEX)])

    # build ISS
    subprocess.check_call(["make"], cwd=str(ISS_DIR))

    # run
    out = subprocess.check_output([str(ISS_BIN), str(HEX)]).decode("utf-8")
    lines = {k: int(v) for k, v in (line.split("=") for line in out.strip().splitlines())}

    # v1=[1,2,3,4], v2=[2,4,6,8] => dot = 60
    # then x3 = dot + x1 + x2 = 60 + 10 + 20 = 90
    assert lines["x1"] == 10
    assert lines["x2"] == 20
    assert lines["x3"] == 90
