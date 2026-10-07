#!/usr/bin/env python3
"""Prove that selected regressions are detected; never alter the real RTL."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CASES = [
    ("wrong_wait", "tb/basic/tb_apb4_system.sv", ".WAIT_S1(1)", ".WAIT_S1(0)", "WAIT mismatch"),
    ("decode_miss_success", "rtl/apb4_resp_mux.sv",
     "PSLVERR = master_select && PENABLE && (PSEL == '0);", "PSLVERR = 1'b0;", "ERR mismatch"),
    ("ignore_byte_strobe", "rtl/apb4_reg_slave.sv", "if (PSTRB[b])", "if (1'b1)", "READ mismatch"),
    ("unknown_read_data", "rtl/apb4_reg_slave.sv", "PRDATA = regs[reg_index];", "PRDATA = 'x;", "Unknown response fields"),
]
for name, filename, old, new, expected in CASES:
    with tempfile.TemporaryDirectory(prefix="apb4-mutation-") as temp:
        work = Path(temp)
        for folder in ("rtl", "tb", "scripts"):
            shutil.copytree(ROOT / folder, work / folder)
        source = work / filename
        text = source.read_text()
        assert old in text, f"Mutation anchor missing: {name}"
        source.write_text(text.replace(old, new, 1))
        result = subprocess.run(["bash", "scripts/run_basic.sh"], cwd=work,
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=60, env=os.environ.copy())
        if result.returncode == 0 or expected not in result.stdout:
            print(result.stdout)
            raise SystemExit(f"FAIL: mutation {name} was not caught by {expected}")
        print(f"PASS: detected {name} ({expected})")
