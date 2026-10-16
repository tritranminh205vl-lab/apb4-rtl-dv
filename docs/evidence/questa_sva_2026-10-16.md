# APB4 basic + SVA result — 2026-10-16

## Result

**PASS for the supplied run:** the basic self-checking regression completed with 453 checks, the protocol SVA module loaded, and no reported simulation or assertion errors.

| Item | Result |
| --- | --- |
| Platform | EDA Playground |
| Simulator | QuestaSim-64 2025.2, Linux x86-64 |
| Top module | `tb_apb4_system` |
| SVA module loaded | `work.apb4_protocol_sva(fast)` |
| Testbench seed | 1 |
| Checks | 453 |
| Random traffic | 250 transfers |
| Reset during wait-state transfer | Scenario executed |
| Finish time | 25,435 ns |
| Tool errors | 0 |
| Tool warnings | 3: vlog 1, vopt 2, vsim 0 |
| Result message | `APB4 BASIC REGRESSION PASS - checks=453` |

## Provenance and scope

The project owner supplied the EDA Playground console output. This report records that result; it is not a new CI execution or an independently reproduced simulation.

The browser bundles prepared for this run were derived from repository commit `549ed2185c679231d2d7f986e918a134843710e6`: RTL was concatenated in `rtl/files.f` order, and the basic testbench was combined with `apb4_protocol_sva.sv` and an `ENABLE_SVA` definition. No RTL or checker behavior was changed by packaging. The actual browser source snapshot and playground URL were not supplied with the result, so the executed source cannot be independently matched to that commit.

This is the **basic + SVA** regression. It does not establish a UVM pass; the normal and reset-during-transfer UVM runs remain pending.

## Scenarios reported

- Full-word reads/writes on all four slaves.
- Byte-write behavior and all 16 PSTRB masks with immediate readback.
- Decode misses.
- Error responses for invalid local offsets and alignment.
- Back-to-back request boundary.
- 250 random transfers.
- Reset during a wait-state transfer.

## Selected console excerpts

These are selected excerpts from the owner-supplied output.

```text
# Loading work.tb_apb4_system(fast)
# Loading work.apb4_system_top(fast)
# Loading work.apb4_master(fast)
# Loading work.apb4_addr_decoder(fast)
# Loading work.apb4_reg_slave(fast)
# Loading work.apb4_reg_slave(fast__1)
# Loading work.apb4_reg_slave(fast__2)
# Loading work.apb4_reg_slave(fast__3)
# Loading work.apb4_resp_mux(fast)
# Loading work.apb4_protocol_sva(fast)
#
# run -all
# [CONFIG] seed=1
# [TEST] full-word read/write on all four slaves
# [TEST] PSTRB byte-write behavior
# [TEST] all 16 write-strobe patterns with immediate readback
# [TEST] decode misses
# [TEST] error response on invalid local offsets / alignment
# [TEST] back-to-back request boundary
# [TEST] constrained-random regression (250 transfers)
# [TEST] reset during wait-state transfer
#
# ============================================
#  APB4 BASIC REGRESSION PASS - checks=453
# ============================================
#
# ** Note: $finish    : testbench.sv(562)
#    Time: 25435 ns  Iteration: 1  Instance: /tb_apb4_system
# End time: 04:32:25 on Oct 16,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
End time: 04:32:25 on Oct 16,2026, Elapsed time: 0:00:02
*** Summary *********************************************
    qrun: Errors:   0, Warnings:   0
    vlog: Errors:   0, Warnings:   1
    vopt: Errors:   0, Warnings:   2
    vsim: Errors:   0, Warnings:   0
  Totals: Errors:   0, Warnings:   3
Done
```

## Limits

- The excerpt omits the text of the three compile/optimization warnings; their causes have not been assessed.
- No assertion coverage, functional coverage percentage, or code coverage report was supplied. This report makes no claim of coverage closure.
- The SVA module was loaded and no assertion failures were reported. A deliberate failing-assertion control run was not supplied.
- This seed/configuration passing does not prove exhaustive APB compliance.
- The simulator's displayed wall-clock timezone is not identified in the supplied excerpt; no UTC conversion is inferred.
