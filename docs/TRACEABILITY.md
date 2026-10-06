# Requirement-to-Verification Traceability

| Requirement | RTL implementation | Verification |
|---|---|---|
| One master/requester | `rtl/apb4_master.sv` | smoke/random + SVA |
| Address decoder creates one-hot select | `rtl/apb4_addr_decoder.sv` | one-hot monitor + SVA |
| Four 4-KiB address windows | decoder/top | all-slave directed tests |
| Shared address/control/write bus | `rtl/apb4_system_top.sv` | passive APB monitor |
| Response mux returns selected slave response | `rtl/apb4_resp_mux.sv` | reads across all slaves |
| APB SETUP/ACCESS sequencing | master FSM | `ap_setup_to_access` |
| Wait states through PREADY | slave wait counter | wait coverage + stability assertion |
| PSTRB byte enables | slave byte-write loop | directed strobe sequence + scoreboard |
| PSLVERR | slave invalid-offset response | error sequence + scoreboard |
| Reset | all state/register blocks | reset and mid-transfer-reset tests |
| Back-to-back transfers | master completion boundary logic | basic TB back-to-back test + SVA |
