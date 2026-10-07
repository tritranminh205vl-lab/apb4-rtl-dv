`timescale 1ns/1ps

module apb4_resp_mux #(
    parameter int DATA_WIDTH = 32,
    parameter int NUM_SLAVES = 4
) (
    input  logic                                  master_select,
    input  logic                                  PENABLE,
    input  logic [NUM_SLAVES-1:0]                  PSEL,
    input  logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0]  PRDATA_S,
    input  logic [NUM_SLAVES-1:0]                  PREADY_S,
    input  logic [NUM_SLAVES-1:0]                  PSLVERR_S,

    output logic [DATA_WIDTH-1:0]                   PRDATA,
    output logic                                    PREADY,
    output logic                                    PSLVERR
);

    integer i;

    always_comb begin
        // Safe idle defaults. These outputs are only sampled by the master
        // in ACCESS. Address decode guarantees one-hot PSEL for mapped traffic.
        PRDATA  = '0;
        PREADY  = 1'b1;
        // Internal default responder: an active decode miss completes with error.
        PSLVERR = master_select && PENABLE && (PSEL == '0);

        for (i = 0; i < NUM_SLAVES; i = i + 1) begin
            if (PSEL[i]) begin
                PRDATA  = PRDATA_S[i];
                PREADY  = PREADY_S[i];
                PSLVERR = PSLVERR_S[i];
            end
        end
    end

endmodule
