`timescale 1ns/1ps

module apb4_protocol_sva #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH/8,
    parameter int NUM_SLAVES = 4
) (
    input logic                  PCLK,
    input logic                  PRESETn,
    input logic [ADDR_WIDTH-1:0] PADDR,
    input logic [NUM_SLAVES-1:0] PSEL,
    input logic                  PENABLE,
    input logic                  PWRITE,
    input logic [DATA_WIDTH-1:0] PWDATA,
    input logic [STRB_WIDTH-1:0] PSTRB,
    input logic [2:0]            PPROT,
    input logic                  PREADY,
    input logic [DATA_WIDTH-1:0] PRDATA,
    input logic                  PSLVERR
);

    default clocking cb @(posedge PCLK); endclocking
    default disable iff (!PRESETn);

    // One selected peripheral at most.
    ap_psel_onehot0:
        assert property ($onehot0(PSEL));

    // This integrated project only starts ACCESS for mapped transfers.
    ap_access_has_select:
        assert property (PENABLE |-> (|PSEL));

    // SETUP is followed by ACCESS and the request fields stay stable.
    ap_setup_to_access:
        assert property ((|PSEL && !PENABLE) |=>
                         (|PSEL && PENABLE &&
                          $stable({PADDR,PWRITE,PWDATA,PSTRB,PPROT,PSEL})));

    // Wait-state extension: all requester-side fields remain stable and
    // PENABLE stays asserted until PREADY terminates the transfer.
    ap_wait_stability:
        assert property ((|PSEL && PENABLE && !PREADY) |=>
                         (|PSEL && PENABLE &&
                          $stable({PADDR,PWRITE,PWDATA,PSTRB,PPROT,PSEL})));

    // The cycle following a completed ACCESS must be either IDLE or SETUP.
    ap_completion_drops_penable:
        assert property ((|PSEL && PENABLE && PREADY) |=> !PENABLE);

    // Project policy consistent with APB4 write-strobe intent: no active
    // byte strobes on reads.
    ap_read_strb_zero:
        assert property ((|PSEL && !PWRITE) |-> (PSTRB == '0));

    // Our slaves only assert PSLVERR on a terminating ACCESS cycle.
    ap_error_only_on_completion:
        assert property (PSLVERR |-> (|PSEL && PENABLE && PREADY));

    // Useful protocol coverage points for debug/coverage reports.
    cp_read_complete:
        cover property (|PSEL && PENABLE && PREADY && !PWRITE);
    cp_write_complete:
        cover property (|PSEL && PENABLE && PREADY && PWRITE);
    cp_wait_state:
        cover property (|PSEL && PENABLE && !PREADY ##1 PREADY);
    cp_error:
        cover property (|PSEL && PENABLE && PREADY && PSLVERR);

endmodule
