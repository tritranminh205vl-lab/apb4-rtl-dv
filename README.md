# APB4 RTL -> DV Project

A portfolio-style APB4 subsystem developed from the supplied architecture: one APB master/requester, address decoder, four peripherals and a response mux.

## Architecture

```text
upstream req/rsp
      |
      v
+-------------+    shared PADDR/PWRITE/PENABLE/PWDATA/PSTRB/PPROT
| APB4 Master |---------------------------------------------------+
+-------------+                                                   |
      | PADDR + master_select                                     |
      v                                                           v
+----------------+       PSEL[3:0]                 +-------------------------+
| Address Decoder|-------------------------------->| S0 S1 S2 S3 peripherals|
+----------------+                                 +-------------------------+
                                                          |
                                          PRDATA/PREADY/PSLVERR
                                                          v
                                                 +----------------+
                                                 | Response MUX   |
                                                 +----------------+
                                                          |
                                                          +----> master
```

## Address map

| Peripheral | Window | Implemented registers | Wait states |
|---|---|---|---:|
| S0 | `0x0000_0000-0x0000_0FFF` | `+0x0,+0x4,+0x8,+0xC` | 0 |
| S1 | `0x0000_1000-0x0000_1FFF` | `+0x0,+0x4,+0x8,+0xC` | 1 |
| S2 | `0x0000_2000-0x0000_2FFF` | `+0x0,+0x4,+0x8,+0xC` | 2 |
| S3 | `0x0000_3000-0x0000_3FFF` | `+0x0,+0x4,+0x8,+0xC` | 3 |

## Repository structure

```text
apb4_rtl_dv_project/
├── rtl/
│   ├── apb4_master.sv
│   ├── apb4_addr_decoder.sv
│   ├── apb4_resp_mux.sv
│   ├── apb4_reg_slave.sv
│   ├── apb4_system_top.sv
│   └── files.f
├── tb/
│   ├── basic/tb_apb4_system.sv
│   ├── sva/apb4_protocol_sva.sv
│   └── uvm/
│       ├── apb4_req_if.sv
│       ├── apb4_bus_if.sv
│       ├── apb4_txn.sv
│       ├── apb4_sequencer.sv
│       ├── apb4_driver.sv
│       ├── apb4_upstream_monitor.sv
│       ├── apb4_bus_monitor.sv
│       ├── apb4_scoreboard.sv
│       ├── apb4_coverage.sv
│       ├── apb4_env.sv
│       ├── apb4_sequences.sv
│       ├── apb4_tests.sv
│       ├── apb4_uvm_pkg.sv
│       └── tb_top.sv
├── docs/
│   ├── RTL_SPEC.md
│   ├── DV_PLAN.md
│   └── TRACEABILITY.md
├── scripts/
│   ├── run_basic.sh
│   └── run_uvm_questa.sh
├── .github/workflows/rtl-regression.yml
├── .gitignore
├── Makefile
└── README.md
```

## Verification strategy

There are two verification levels:

1. `tb/basic`: self-checking SystemVerilog regression intended for easy local/CI use.
2. `tb/uvm`: UVM architecture for an industry-style DV portfolio, with independent monitors, scoreboard, coverage and SVA.

The scoreboard owns a reference model of all 16 registers and performs byte-wise `PSTRB` prediction. The passive APB monitor measures wait states independently of the driver. See `docs/DV_PLAN.md` for the full test plan.

## Run the basic regression

Requirements: Icarus Verilog with SystemVerilog support.

```bash
make basic
```

Expected end-of-run message:

```text
APB4 BASIC REGRESSION PASS
```

## Run the UVM regression with Questa

Use a simulator installation that includes UVM support:

```bash
make uvm-questa
```

Default UVM test:

```text
apb4_regression_test
```

The run enables simulator coverage and saves `build/questa/apb4.ucdb`.

## Lint RTL

With Verilator installed:

```bash
make lint
```

## Waveform checklist

For every normal transfer confirm:

```text
cycle N:   PSEL=1, PENABLE=0                    SETUP
cycle N+1: PSEL=1, PENABLE=1, PREADY=0/1        ACCESS
...
final:     PSEL=1, PENABLE=1, PREADY=1          completion
next:      PENABLE=0                             IDLE or next SETUP
```

During `PREADY=0`, verify that `PADDR`, `PWRITE`, `PWDATA`, `PSTRB`, `PPROT`, and `PSEL` do not change.

## How to put this project on GitHub

### 1. Create a local Git repository

Open Git Bash or a terminal in the project folder:

```bash
cd apb4_rtl_dv_project
git init
git branch -M main
git status
```

### 2. Make the first commit

```bash
git add .
git commit -m "Initial APB4 RTL and DV project"
```

### 3. Create an empty GitHub repository

On GitHub, create a new repository, for example:

```text
apb4-rtl-dv
```

Do **not** add another README or `.gitignore` if you want the first push to stay simple, because this project already contains them.

### 4. Connect local Git to GitHub

Replace `YOUR_USERNAME`:

```bash
git remote add origin https://github.com/YOUR_USERNAME/apb4-rtl-dv.git
git remote -v
git push -u origin main
```

If you use SSH instead:

```bash
git remote add origin git@github.com:YOUR_USERNAME/apb4-rtl-dv.git
git push -u origin main
```

### 5. Recommended branch workflow after the first push

Do feature work on a branch:

```bash
git checkout -b feature/add-apb-coverage
# edit files
git add .
git commit -m "Add APB functional coverage"
git push -u origin feature/add-apb-coverage
```

Then open a Pull Request into `main`. This demonstrates a more professional development flow than committing every change directly to `main`.

### 6. Check GitHub Actions

The included workflow runs the basic RTL regression on every push and pull request. A green Actions badge/run is useful evidence that the repository is reproducible.

## Suggested commit history for a portfolio

Instead of one giant commit, a clean learning/portfolio history can look like:

```text
feat(rtl): add APB master FSM
feat(rtl): add address decoder and response mux
feat(rtl): add register peripheral with PSTRB and wait states
test(tb): add self-checking APB regression
test(sva): add APB protocol assertions
test(uvm): add driver monitors scoreboard and coverage
ci: run basic regression in GitHub Actions
docs: add RTL spec DV plan and traceability
```

## Scope / limitations

- The repository implements an educational APB4 subsystem, not an AXI-to-APB or AHB-to-APB production bridge.
- The upstream `req_*` interface is custom and should not be presented as part of the APB specification.
- The four peripherals are small register banks used to create meaningful DV scenarios.
- Unmapped addresses outside `0x0000_0000-0x0000_3FFF` are not generated by the included tests. A production interconnect should define an explicit default/error-slave policy for decode misses.

## Interview talking points

Be ready to explain:

- why APB needs SETUP then ACCESS,
- what changes when `PREADY=0`,
- why `PENABLE` must drop between completed transfers,
- how `PSTRB` enables byte writes,
- when `PSLVERR` is meaningful,
- why the monitor, not the driver, feeds the scoreboard,
- difference between code coverage, functional coverage, and assertions,
- how the address decoder guarantees one-hot `PSEL`,
- what a scoreboard reference model predicts,
- why reset-during-transfer is a useful corner case.
