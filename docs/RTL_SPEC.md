# APB4 RTL Microarchitecture Specification

## 1. Goal

Implement a small APB4 subsystem matching the supplied top-level architecture:

- one APB requester/master controller,
- one address decoder,
- four APB peripherals,
- one response multiplexer,
- shared `PADDR/PENABLE/PWRITE/PWDATA/PSTRB/PPROT`,
- one-hot `PSEL[3:0]`,
- selected `PRDATA/PREADY/PSLVERR` returned to the master.

The upstream `req_*` / `rsp_*` interface in this repository is project-specific. It exists only to generate APB transfers and is not an ARM APB signal set.

## 2. Configuration

| Item | Value in project |
|---|---:|
| Address width | 32 bits |
| Data width | 32 bits |
| Write strobe | 4 bits |
| Number of slaves | 4 |
| Registers per slave | 4 x 32-bit |
| Slave 0 window | `0x0000_0000-0x0000_0FFF` |
| Slave 1 window | `0x0000_1000-0x0000_1FFF` |
| Slave 2 window | `0x0000_2000-0x0000_2FFF` |
| Slave 3 window | `0x0000_3000-0x0000_3FFF` |
| Implemented register offsets | `0x0, 0x4, 0x8, 0xC` |
| Wait states | S0=0, S1=1, S2=2, S3=3 |

The 4-KiB slave windows come directly from the project architecture. The smaller 4-register implementation and different wait-state counts are deliberate project choices so DV can exercise legal, error, and wait-state behavior.

## 3. APB requester/master FSM

Three bus states are used:

- `IDLE`: no APB transfer selected.
- `SETUP`: `PSELx=1`, `PENABLE=0`. Address/control/data are already valid.
- `ACCESS`: `PSELx=1`, `PENABLE=1`. The transfer completes only when `PREADY=1`.

If `PREADY=0`, the controller remains in ACCESS and holds request-side APB signals stable.

At a completed ACCESS, a new upstream request may be accepted immediately. The following cycle is still SETUP, therefore `PENABLE` returns LOW between APB transfers as required.

## 4. Address decode

The decoder is combinational. When `master_select=1`, exactly one `PSEL` bit is expected for any address in the four project windows. The implementation is one-hot and uses half-open ranges `[base, next_base)`.

## 5. APB4 write strobes

For 32-bit data, `PSTRB[3:0]` maps one bit to each byte of `PWDATA`. The peripheral updates only bytes whose strobe bit is HIGH. On reads, the master drives `PSTRB=0` as a project protocol policy.

## 6. Peripheral response

Each peripheral:

- contains four 32-bit registers,
- supports partial byte writes,
- can stretch ACCESS using `PREADY=0`,
- returns `PSLVERR=1` on the terminating cycle for an unimplemented or misaligned local address,
- resets all registers to zero on `PRESETn=0`.

`PPROT` is carried through the APB4 interface but this simple peripheral does not enforce a protection policy.

## 7. Response mux

Only the response from the one-hot selected slave is forwarded. Idle defaults are `PREADY=1`, `PRDATA=0`, `PSLVERR=0`; these values are ignored when there is no active APB transfer.

## 8. RTL coding rules used

- synthesizable `always_ff` / `always_comb`,
- active-low asynchronous reset in state/register storage,
- no delays in RTL,
- parameters for widths and wait-state configuration,
- no testbench constructs in `rtl/`,
- one function per block responsibility,
- explicit defaults in combinational logic to avoid latches.
