`timescale 1ns/1ps
// Independent smoke test for a non-default decoder window and slave bases.
module tb_apb4_parameters;
    logic PCLK = 0;
    always #5 PCLK = ~PCLK;
    logic PRESETn = 0;
    logic req_valid = 0, req_ready, req_write = 0;
    logic [31:0] req_addr = 0, req_wdata = 0;
    logic [3:0] req_strb = 0;
    logic [2:0] req_prot = 0;
    logic rsp_valid, rsp_err;
    logic [31:0] rsp_rdata;
    apb4_system_top #(.SLAVE_WINDOW_BYTES(2048)) dut (.*);
    task automatic transfer(input logic [31:0] addr, input bit wr,
                            input logic [31:0] data, input bit expected_err);
        @(negedge PCLK);
        req_valid = 1; req_addr = addr; req_write = wr;
        req_wdata = data; req_strb = wr ? 4'hf : 4'h0;
        do @(posedge PCLK); while (!req_ready);
        @(negedge PCLK); req_valid = 0;
        do @(posedge PCLK); while (!rsp_valid);
        if (rsp_err !== expected_err) $fatal(1,"Parameter-map error mismatch at %h",addr);
        if (!wr && !expected_err && rsp_rdata !== data)
            $fatal(1,"Parameter-map data mismatch at %h got=%h expected=%h",addr,rsp_rdata,data);
    endtask
    initial begin
        repeat (3) @(negedge PCLK);
        PRESETn = 1;
        for (int s=0; s<4; s++) transfer(s*2048,1,32'hABCD0000+s,0);
        for (int s=0; s<4; s++) transfer(s*2048,0,32'hABCD0000+s,0);
        transfer(32'h2000,0,0,1);
        $display("APB4 PARAMETER SMOKE PASS - window=2048");
        $finish;
    end
    initial begin #10000; $fatal(1,"Parameter smoke timeout"); end
endmodule
