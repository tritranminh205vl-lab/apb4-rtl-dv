`timescale 1ns/1ps

module apb4_master #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH/8
) (
    input  logic                  PCLK,
    input  logic                  PRESETn,

    // Simple upstream request interface (project-specific, not part of APB4)
    input  logic                  req_valid,
    output logic                  req_ready,
    input  logic [ADDR_WIDTH-1:0] req_addr,
    input  logic                  req_write,
    input  logic [DATA_WIDTH-1:0] req_wdata,
    input  logic [STRB_WIDTH-1:0] req_strb,
    input  logic [2:0]            req_prot,

    output logic                  rsp_valid,
    output logic [DATA_WIDTH-1:0] rsp_rdata,
    output logic                  rsp_err,

    // APB4 requester/master side
    output logic [ADDR_WIDTH-1:0] PADDR,
    output logic                  PENABLE,
    output logic                  PWRITE,
    output logic [DATA_WIDTH-1:0] PWDATA,
    output logic [STRB_WIDTH-1:0] PSTRB,
    output logic [2:0]            PPROT,
    output logic                  master_select,

    input  logic                  PREADY,
    input  logic [DATA_WIDTH-1:0] PRDATA,
    input  logic                  PSLVERR
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_t;

    apb_state_t state;

    logic [ADDR_WIDTH-1:0] addr_q;
    logic                  write_q;
    logic [DATA_WIDTH-1:0] wdata_q;
    logic [STRB_WIDTH-1:0] strb_q;
    logic [2:0]            prot_q;

    // A new request can be accepted in IDLE or on the same clock edge
    // that the current APB access completes. This permits back-to-back
    // APB transfers while still inserting the mandatory SETUP phase.
    always_comb begin
        req_ready = PRESETn && ((state == IDLE) || ((state == ACCESS) && PREADY));
    end

    always_comb begin
        PADDR         = addr_q;
        PWRITE        = write_q;
        PWDATA        = wdata_q;
        PPROT         = prot_q;
        // APB4 write strobes are meaningful for writes. Keep them zero on reads.
        PSTRB         = write_q ? strb_q : '0;
        PENABLE       = (state == ACCESS);
        master_select = (state != IDLE);
    end

    task automatic latch_request;
        begin
            addr_q  <= req_addr;
            write_q <= req_write;
            wdata_q <= req_wdata;
            strb_q  <= req_strb;
            prot_q  <= req_prot;
        end
    endtask

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state     <= IDLE;
            addr_q    <= '0;
            write_q   <= 1'b0;
            wdata_q   <= '0;
            strb_q    <= '0;
            prot_q    <= '0;
            rsp_valid <= 1'b0;
            rsp_rdata <= '0;
            rsp_err   <= 1'b0;
        end else begin
            // Response is a one-cycle pulse on APB completion.
            rsp_valid <= 1'b0;

            unique case (state)
                IDLE: begin
                    if (req_valid) begin
                        latch_request();
                        state <= SETUP;
                    end
                end

                SETUP: begin
                    // APB requires one SETUP cycle with PSEL asserted and
                    // PENABLE LOW before entering ACCESS.
                    state <= ACCESS;
                end

                ACCESS: begin
                    if (PREADY) begin
                        rsp_valid <= 1'b1;
                        rsp_rdata <= PRDATA;
                        rsp_err   <= PSLVERR;

                        // Accept the next request at the completion boundary.
                        // The next cycle is SETUP, so PENABLE goes LOW.
                        if (req_valid) begin
                            latch_request();
                            state <= SETUP;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
