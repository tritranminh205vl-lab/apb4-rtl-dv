# Requirement-to-Verification Traceability

| Requirement | RTL implementation | Verification |
|---|---|---|
| One master/requester | `rtl/apb4_master.sv` | smoke/random + SVA |
| Address decoder creates one-hot select | `rtl/apb4_addr_decoder.sv` | one-hot monitor + SVA |
| Four 4-KiB address windows | decoder/top | all-slave directed tests |
| Shared address/control/write bus | `rtl/apb4_system_top.sv` | passive APB monitor |
| Response mux returns selected slave response | `rtl/apb4_resp_mux.sv` | reads across all slaves |
| APB SETUP/ACCESS sequencing | master FSM | `ap_setup_to_access` |
| Wait states through PREADY | slave wait counter | exact wait checker + stability assertion + four latency bins |
| PSTRB byte enables | slave byte-write loop | directed strobe sequence + scoreboard |
| PSLVERR | slave invalid-offset response | error sequence + scoreboard |
| Reset | all state/register blocks | reset and mid-transfer-reset tests |
| Back-to-back transfers | master completion boundary logic | basic TB back-to-back test + SVA |

| Decode miss | internal default responder in mux | basic/UVM unmapped read/write |
| Zero strobe / every mask | byte-write loop | 16-mask directed tests with readback |
| Parameterized window | bases derived in top | `tb_apb4_parameters.sv` |
| Four-state response | monitor transaction `logic` fields | X checks + unknown-data mutation |
| Checker detects bad RTL | temporary mutations | `make mutations` |
| Reset synchronization | driver/monitors/scoreboard | Questa normal/reset runs; execution pending |

See `VALIDATION.md` for measured results and limitations. A test-plan row or a
checker in source code is not by itself evidence that the test passed.
