# APB4 UVM normal + SVA result — 2026-10-16

## Result

**PASS for the supplied normal UVM run.** The scoreboard checked 1,167 completed transactions, the functional covergroup reported 100.00%, and no UVM errors/fatals or assertion failures were reported.

| Item | Observed result |
| --- | --- |
| Platform | EDA Playground |
| Simulator | QuestaSim-64 2025.2 |
| UVM library | UVM 1.2 |
| Run header timestamp | 2026-10-16 08:40:05 UTC / 15:40:05 Vietnam time |
| Top module | `tb_top` |
| Test | `apb4_regression_test` |
| Scoreboard | 1,167 completed transactions checked |
| Functional covergroup coverage | 100.00% |
| UVM warnings / errors / fatals | 0 / 0 / 0 |
| SVA | `work.apb4_protocol_sva(fast)` loaded; no failures reported |
| Finish time | 75,525 ns |
| Tool errors / warnings | 0 / 3 |
| Reset-during-wait UVM mode | Not enabled in the recorded command |

## Provenance and scope

This report records the complete console log supplied by the project owner after running EDA Playground. It is not a newly executed CI run or an independently reproduced simulation.

The prepared browser files were based on commit `549ed2185c679231d2d7f986e918a134843710e6`. RTL was concatenated in file-list order, and the UVM interfaces, package components, SVA checker, and top were bundled into one testbench. After an initial NOCOMP failure, the browser top was instructed to use `run_test("apb4_regression_test")` instead of `run_test()`; this successful log confirms that the named test ran. The actual browser source snapshot, playground URL, and random seed were not supplied, so this result cannot be independently pinned to exact executed source bytes.

This is **part 2: normal UVM + SVA**. The recorded command does not contain `+RESET_DURING_WAIT`. Part 3 was recorded subsequently: see the [passing UVM reset-mode report](questa_uvm_reset_2026-10-16.md). The earlier basic testbench did exercise its own reset scenario; that is separate evidence.

## Testbench scope and coverage meaning

The prepared regression runs smoke, byte-strobe, error, and random sequences, including 1,000 random transactions. Its scoreboard models the 16 registers and byte writes, checks address decoding and expected wait counts, and compares APB/upstream requests and responses.

The 100.00% value is the existing functional covergroup's reported instance coverage. That model covers slave/decode-miss selection, reads/writes, all 16 write-strobe masks for successful writes, wait counts, response errors, legal slave/wait pairs, and the defined crosses. It is **not** code coverage or assertion coverage and does not prove exhaustive APB compliance.

## Recorded command

```sh
qrun -batch -access=rw+/. -uvmhome uvm-1.2 '-timescale' '1ns/1ns' -mfcu design.sv testbench.sv '-voptargs=+acc=npr' -do " run -all; exit"
```

## Selected console excerpts

These are selected excerpts from the supplied full log.

```text
# Loading work.tb_top(fast)
# Loading work.apb4_system_top(fast)
# Loading work.apb4_protocol_sva(fast)
# UVM_INFO @ 0: reporter [RNTST] Running test apb4_regression_test...
# UVM_INFO testbench.sv(488) @ 75525000: uvm_test_top.env.cov [COV] Functional coverage = 100.00%
# UVM_INFO testbench.sv(445) @ 75525000: uvm_test_top.env.scb [SCB] Scoreboard checked 1167 completed transactions
# --- UVM Report Summary ---
# ** Report counts by severity
# UVM_INFO :    7
# UVM_WARNING :    0
# UVM_ERROR :    0
# UVM_FATAL :    0
# ** Report counts by id
# [COV]     1
# [Questa UVM]     2
# [RNTST]     1
# [SCB]     1
# [TEST_DONE]     1
# [UVM/RELNOTES]     1
# ** Note: $finish    : /usr/share/questa/questasim/verilog_src/uvm-1.2/src/base/uvm_root.svh(517)
#    Time: 75525 ns  Iteration: 70  Instance: /tb_top
# Errors: 0, Warnings: 0
*** Summary *********************************************
    qrun: Errors:   0, Warnings:   0
    vlog: Errors:   0, Warnings:   1
    vopt: Errors:   0, Warnings:   2
    vsim: Errors:   0, Warnings:   0
  Totals: Errors:   0, Warnings:   3
Done
```

## Warnings

- `vlog-13314` and `vopt-13314`, at `design.sv(180)`: port `PRDATA_S` defaults to variable rather than wire kind under `-svinputport=relaxed`.
- `vopt-10587`: `+acc` disables some optimizations; the simulator recommends `-access/-debug` for visibility.

These are tool warnings, separate from the zero UVM warning count. They did not prevent this run from finishing. No intentional assertion-failure control run or per-property coverage report was supplied.

See also the [basic + SVA result](questa_sva_2026-10-16.md).
