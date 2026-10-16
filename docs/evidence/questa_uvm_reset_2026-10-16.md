# APB4 UVM reset-during-wait + SVA result — 2026-10-16

## Result

**PASS for the supplied run with reset-during-wait mode enabled.** The scoreboard checked 1,167 completed transactions, functional covergroup coverage reached 100.00%, and no UVM errors/fatals or assertion failures were reported.

| Item | Observed result |
| --- | --- |
| Platform | EDA Playground |
| Simulator | QuestaSim-64 2025.2 |
| UVM library | UVM 1.2 |
| Run header timestamp | 2026-10-16 08:47:02 UTC / 15:47:02 Vietnam time |
| Top / test | `tb_top` / `apb4_regression_test` |
| Mode | `+RESET_DURING_WAIT`, present in both qrun and vsim commands |
| Scoreboard | 1,167 completed transactions checked |
| Functional covergroup coverage | 100.00% |
| UVM warnings / errors / fatals | 0 / 0 / 0 |
| SVA | Protocol checker included and inlined during optimization; no assertion failures reported |
| Simulation finish time | 75,585 ns |
| Tool errors / warnings | 0 / 2 |

## Provenance and reset evidence

This report records the full console log supplied by the project owner from EDA Playground. It is not an independent rerun or a CI execution.

The prepared browser bundle originated from repository commit `549ed2185c679231d2d7f986e918a134843710e6`. The actual browser source snapshot, playground URL, and random seed were not supplied with this result, so the exact executed source bytes cannot be independently verified.

In the prepared top, `+RESET_DURING_WAIT` enables a process that waits for slave S3 in ACCESS with PREADY low, asserts PRESETn at a falling clock edge, holds reset across three falling edges, and releases it. The recorded qrun and vsim commands confirm that the option was passed. The supplied log does not print a dedicated reset-event marker or include a waveform proving the precise reset edge. A waveform or explicit reset-event log would strengthen that evidence; this result is therefore described as a passing run with reset mode enabled.

The SVA checker appears as `Inlining module apb4_protocol_sva(fast)` during optimization. Its absence as a separate simulation Loading line is consistent with that inlining, not evidence that assertions were disabled.

## Recorded command

```sh
qrun -batch -access=rw+/. -uvmhome uvm-1.2 '-timescale' '1ns/1ns' -mfcu design.sv testbench.sv '+UVM_TESTNAME=apb4_regression_test' '+UVM_VERBOSITY=UVM_MEDIUM' '+RESET_DURING_WAIT' -do " run -all; exit"
```

## Selected console excerpts

These are selected excerpts from the supplied full log.

```text
-- Inlining module apb4_protocol_sva(fast)
# vsim -batch "+UVM_TESTNAME=apb4_regression_test" "+UVM_VERBOSITY=UVM_MEDIUM" "+RESET_DURING_WAIT" -lib qrun.out/work -do " run -all; exit" -statslog qrun.out/stats_log qrun_opt -appendlog -l qrun.log
# UVM_INFO @ 0: reporter [RNTST] Running test apb4_regression_test...
# UVM_INFO testbench.sv(488) @ 75585000: uvm_test_top.env.cov [COV] Functional coverage = 100.00%
# UVM_INFO testbench.sv(445) @ 75585000: uvm_test_top.env.scb [SCB] Scoreboard checked 1167 completed transactions
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
#    Time: 75585 ns  Iteration: 70  Instance: /tb_top
# Errors: 0, Warnings: 0
*** Summary *********************************************
    qrun: Errors:   0, Warnings:   0
    vlog: Errors:   0, Warnings:   1
    vopt: Errors:   0, Warnings:   1
    vsim: Errors:   0, Warnings:   0
  Totals: Errors:   0, Warnings:   2
Done
```

## Warnings and limitations

- `vlog-13314` and `vopt-13314` at `design.sv(180)`: Questa defaults port `PRDATA_S` to variable rather than wire kind under `-svinputport=relaxed`. These warnings did not prevent simulation completion.
- The reported 100.00% applies to the existing functional covergroup only. No code coverage or assertion coverage percentage was supplied.
- No deliberate assertion-failure control run was supplied.
- A passing configured run is bounded evidence, not proof of all seeds, parameter combinations, reset timings, or exhaustive APB compliance.

## Related results

| Run | Result |
| --- | --- |
| [Basic + SVA](questa_sva_2026-10-16.md) | PASS, 453 checks, seed 1 |
| [Normal UVM + SVA](questa_uvm_normal_2026-10-16.md) | PASS, 1,167 completed transactions, functional coverage 100.00% |
| UVM reset mode + SVA (this report) | PASS, 1,167 completed transactions, functional coverage 100.00% |
