`timescale 1ns/1ps

module apb4_addr_decoder #(
    parameter int ADDR_WIDTH = 32,
    parameter int NUM_SLAVES = 4,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR = '0,
    parameter int SLAVE_WINDOW_BYTES = 4096
) (
    input  logic [ADDR_WIDTH-1:0]     PADDR,
    input  logic                      master_select,
    output logic [NUM_SLAVES-1:0]     PSEL
);

    integer i;
    logic [ADDR_WIDTH-1:0] low_addr;
    logic [ADDR_WIDTH-1:0] high_addr;

    always_comb begin
        PSEL = '0;
        low_addr = '0;
        high_addr = '0;

        if (master_select) begin
            for (i = 0; i < NUM_SLAVES; i = i + 1) begin
                low_addr  = BASE_ADDR + (i * SLAVE_WINDOW_BYTES);
                high_addr = BASE_ADDR + ((i + 1) * SLAVE_WINDOW_BYTES);
                if ((PADDR >= low_addr) && (PADDR < high_addr)) begin
                    PSEL[i] = 1'b1;
                end
            end
        end
    end

endmodule
