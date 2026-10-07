`timescale 1ns/1ps

module apb4_protocol_sva #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH/8,
    parameter int NUM_SLAVES = 4
) (
    input logic                  PCLK,
    input logic                  PRESETn,
    input logic                  master_select,
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

    // Internal default responder handles decode misses without external PSEL.
    ap_access_active:
        assert property (PENABLE |-> master_select);
    ap_decode_miss:
        assert property ((master_select && PENABLE && !(|PSEL)) |-> (PREADY && PSLVERR));
    ap_control_known:
        assert property (!$isunknown({master_select,PSEL,PENABLE}));
    ap_request_known:
        assert property (master_select |-> !$isunknown({PADDR,PWRITE,PSTRB,PPROT}));
    ap_write_known:
        assert property ((master_select && PWRITE) |-> !$isunknown(PWDATA));
    ap_ready_known:
        assert property ((master_select && PENABLE) |-> !$isunknown(PREADY));
    ap_response_known:
        assert property ((master_select && PENABLE && PREADY) |-> !$isunknown(PSLVERR));
    ap_read_known:
        assert property ((master_select && PENABLE && PREADY && !PWRITE) |-> !$isunknown(PRDATA));

    // SETUP is followed by ACCESS and the request fields stay stable.
    ap_setup_to_access:
        assert property ((master_select && !PENABLE) |=>
                         (master_select && PENABLE &&
                          $stable({PADDR,PWRITE,PWDATA,PSTRB,PPROT,PSEL})));

    // Wait-state extension: all requester-side fields remain stable and
    // PENABLE stays asserted until PREADY terminates the transfer.
    ap_wait_stability:
        assert property ((master_select && PENABLE && !PREADY) |=>
                         (master_select && PENABLE &&
                          $stable({PADDR,PWRITE,PWDATA,PSTRB,PPROT,PSEL})));

    // The cycle following a completed ACCESS must be either IDLE or SETUP.
    ap_completion_drops_penable:
        assert property ((master_select && PENABLE && PREADY) |=> !PENABLE);

    // APB requires inactive byte strobes on reads.
    ap_read_strb_zero:
        assert property ((master_select && !PWRITE) |-> (PSTRB == '0));

    // Our slaves only assert PSLVERR on a terminating ACCESS cycle.
    ap_error_only_on_completion:
        assert property (PSLVERR |-> (master_select && PENABLE && PREADY));

    // Useful protocol coverage points for debug/coverage reports.
    cp_read_complete:
        cover property (master_select && PENABLE && PREADY && !PWRITE);
    cp_write_complete:
        cover property (master_select && PENABLE && PREADY && PWRITE);
    cp_wait_state:
        cover property ($past(master_select && PENABLE && !PREADY) &&
                        master_select && PENABLE && PREADY);
    cp_error:
        cover property (master_select && PENABLE && PREADY && PSLVERR);

endmodule
