`timescale 1ns/1ps

module apb4_reg_slave #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH/8,
    parameter int REG_COUNT  = 4,
    parameter int WAIT_CYCLES = 0,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR = '0
) (
    input  logic                  PCLK,
    input  logic                  PRESETn,

    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic                  PWRITE,
    input  logic [DATA_WIDTH-1:0] PWDATA,
    input  logic [STRB_WIDTH-1:0] PSTRB,
    input  logic [2:0]            PPROT,

    output logic                  PREADY,
    output logic [DATA_WIDTH-1:0] PRDATA,
    output logic                  PSLVERR
);

    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;
    localparam int WAIT_CNT_W = (WAIT_CYCLES < 1) ? 1 : $clog2(WAIT_CYCLES + 1);

    logic [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];
    logic [WAIT_CNT_W-1:0] wait_count;

    logic [ADDR_WIDTH-1:0] offset;
    logic                  aligned;
    logic                  in_range;
    logic                  addr_valid;
    integer                reg_index;
    integer                b;
    integer                r;

    always_comb begin
        offset     = PADDR - BASE_ADDR;
        aligned    = ((offset & (BYTES_PER_WORD - 1)) == 0);
        in_range   = (PADDR >= BASE_ADDR) && (offset < (REG_COUNT * BYTES_PER_WORD));
        addr_valid = aligned && in_range;
        reg_index  = offset / BYTES_PER_WORD;
    end

    always_comb begin
        // PREADY may be HIGH outside a transfer. It is sampled only in ACCESS.
        if (PSEL && PENABLE) begin
            PREADY = (wait_count >= WAIT_CYCLES);
        end else begin
            PREADY = 1'b1;
        end
    end

    always_comb begin
        PRDATA = '0;
        if (addr_valid) begin
            PRDATA = regs[reg_index];
        end
    end

    // In this project, an invalid/misaligned address inside a selected 4-KiB
    // window returns PSLVERR on the final ACCESS cycle.
    always_comb begin
        PSLVERR = PSEL && PENABLE && PREADY && !addr_valid;
    end

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            wait_count <= '0;
            for (r = 0; r < REG_COUNT; r = r + 1) begin
                regs[r] <= '0;
            end
        end else begin
            if (!PSEL || !PENABLE) begin
                wait_count <= '0;
            end else if (!PREADY) begin
                wait_count <= wait_count + 1'b1;
            end else begin
                wait_count <= '0;
            end

            // Register updates occur only on a completed, valid APB write.
            if (PSEL && PENABLE && PREADY && PWRITE && addr_valid) begin
                for (b = 0; b < STRB_WIDTH; b = b + 1) begin
                    if (PSTRB[b]) begin
                        regs[reg_index][8*b +: 8] <= PWDATA[8*b +: 8];
                    end
                end
            end
        end
    end

    // PPROT is accepted as part of the APB4 interface but this simple
    // register-bank peripheral does not implement protection policy.
    logic unused_pprot;
    always_comb unused_pprot = ^PPROT;

endmodule
