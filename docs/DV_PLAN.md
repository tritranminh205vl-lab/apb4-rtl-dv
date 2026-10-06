# APB4 Design Verification Plan

## 1. Verification objective

Demonstrate that the integrated requester/decoder/peripheral/response-mux subsystem:

1. obeys the APB SETUP/ACCESS sequencing,
2. decodes addresses one-hot,
3. transfers read/write data correctly,
4. honors `PSTRB`,
5. handles `PREADY` wait states without changing request signals,
6. propagates `PSLVERR`,
7. handles back-to-back transfers,
8. resets cleanly,
9. has no scoreboard mismatches in constrained-random traffic.

## 2. Layered testbench architecture

### Basic self-checking testbench

`tb/basic/tb_apb4_system.sv` is deliberately dependency-light. It contains:

- upstream stimulus tasks,
- a software register reference model,
- automatic expected-error prediction,
- byte-strobe merge logic,
- protocol monitor checks,
- directed tests,
- 250-transfer randomized regression,
- reset-during-wait-state test,
- timeout and PASS/FAIL exit behavior.

This is the CI testbench used by GitHub Actions.

### UVM testbench

`tb/uvm/` mirrors an industrial DV structure:

- **sequence item**: transaction abstraction,
- **sequencer**: sequence arbitration,
- **driver**: converts transactions to the project upstream handshake,
- **upstream monitor**: independently reconstructs accepted requests and responses,
- **APB passive monitor**: reconstructs SETUP/ACCESS transfers and wait counts,
- **scoreboard**: predicts register state and compares data/error results,
- **coverage subscriber**: functional coverage for slave/RW/strobe/wait/error crosses,
- **SVA checker**: temporal protocol assertions,
- **tests/sequences**: smoke, strobe, error and random regression.

The driver is intentionally not the scoreboard source. The monitor is the observation point, which avoids making the checker trust the same component that generated the stimulus.

## 3. Test matrix

| ID | Test | Main expected result |
|---|---|---|
| T01 | Reset | Master returns IDLE; registers read as zero |
| T02 | Write/read each register in S0 | Data matches; no error |
| T03 | Write/read each register in S1 | Data matches with 1 wait cycle |
| T04 | Write/read each register in S2 | Data matches with 2 wait cycles |
| T05 | Write/read each register in S3 | Data matches with 3 wait cycles |
| T06 | Partial byte writes | Only strobed bytes change |
| T07 | Read transfers | `PSTRB==0` project policy |
| T08 | Invalid local offset | `PSLVERR==1` on completion |
| T09 | Back-to-back transfers | second transfer enters SETUP; no illegal continuous PENABLE |
| T10 | Wait-state stability | address/control/data/select remain stable while `PREADY=0` |
| T11 | Reset during wait | transaction aborts and design returns to reset state |
| T12 | Constrained random | reference model agrees for legal/error accesses |

## 4. Assertions

`tb/sva/apb4_protocol_sva.sv` checks:

- `$onehot0(PSEL)`,
- ACCESS has a selected peripheral in this integrated design,
- SETUP -> ACCESS sequencing,
- stable request signals across SETUP and wait-state extension,
- `PENABLE` drops after completion,
- read `PSTRB` is zero,
- project slaves assert `PSLVERR` only on a terminating ACCESS cycle.

## 5. Functional coverage

Coverage points:

- all four slaves,
- read and write,
- representative `PSTRB` patterns,
- 0/1/2/3 wait-state bins,
- error and non-error completion,
- crosses: slave x RW, RW x error, slave x wait.

A real company closure target is project-dependent; for this portfolio project, target 100% planned functional bins and zero assertion/scoreboard errors. Code coverage should be reviewed for statement/branch/toggle coverage rather than accepted blindly as a single percentage.

## 6. Review checklist before calling DV complete

- No UVM_ERROR/UVM_FATAL.
- No SVA failures.
- Basic CI regression passes.
- Every test-plan row has evidence.
- Functional coverage holes are explained or closed.
- RTL lint has no unexplained warnings.
- Reset behavior and error behavior are documented.
- Waveform spot-check confirms IDLE -> SETUP -> ACCESS timing.
