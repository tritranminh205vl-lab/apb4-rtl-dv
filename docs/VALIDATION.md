# Validation record — 2026-10-07

This repair was based on commit `ccd85e4daa3c989c1a36968fe4e9583a0e330e3a`.
The previous GitHub run failed before simulation because the Makefile executed
non-executable scripts. The scripts are now invoked with bash.

## Executed checks

| Check | Result |
|---|---|
| RTL lint, `--lint-only -Wall`, top `apb4_system_top` | PASS, no warnings |
| Icarus Verilog 12.0, main regression, seeds 1 / 17 / 2026 | PASS, 453 checked transfers per seed |
| Non-default slave window (2048 bytes), all four banks and decode miss | PASS |
| Verilator timed regression with `--assert` and SVA instantiated | PASS, 453 checked transfers |
| Wrong S1 wait count (1 changed to 0) | Detected by `WAIT mismatch` |
| Decode miss incorrectly reports success | Detected by `ERR mismatch` |
| Byte strobes ignored | Detected by `READ mismatch` |
| Unknown read data injected (Icarus four-state simulation) | Detected by `Unknown response fields` |
| UVM sources + Accellera uvm-core, slang 12 semantic compilation | 0 errors; 1 warning in external UVM library |

The local Verilator wheel was distributed as 5.48.0 and reports 5.49 at runtime.
GitHub Actions installs its Ubuntu-packaged versions and publishes its own logs.
Icarus notes that it ignores `unique case` simulation qualities; explicit protocol
checks and the separate Verilator/SVA run are retained.

## Not yet established

- Questa UVM normal/reset simulations and measured functional/code coverage.
- Exhaustive parameter verification, formal proof, synthesis/PPA or timing closure.
- All legal APB traffic permutations (for example long mixed-direction back-to-back
  streams and very short asynchronous reset pulses).

The basic/SVA tests passing must not be reported as a UVM run passing. The UVM
coverage model is structurally reachable for this fixed-latency configuration, but
100% measured coverage requires simulator evidence. A recorded random seed is
reproducible within the same simulator/version, not necessarily across simulators.

## Re-run

```bash
make lint
SEED=1 make basic
SEED=17 make basic
SEED=2026 make basic
make mutations
make verilator
make uvm-questa
```

The final command requires Questa/UVM access. It runs normal and reset scenarios,
checks the UVM summary, and writes separate log/UCDB files under `build/questa`.
Mutation tests operate exclusively on temporary copies.
