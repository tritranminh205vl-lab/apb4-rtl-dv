`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import apb4_uvm_pkg::*;

    logic PCLK;
    logic PRESETn;

    apb4_req_if req_if(PCLK);
    apb4_bus_if bus_if(PCLK);

    initial PCLK = 1'b0;
    always #5 PCLK = ~PCLK;

    apb4_system_top #(
        .WAIT_S0(0), .WAIT_S1(1), .WAIT_S2(2), .WAIT_S3(3)
    ) dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .req_valid(req_if.req_valid),
        .req_ready(req_if.req_ready),
        .req_addr(req_if.req_addr),
        .req_write(req_if.req_write),
        .req_wdata(req_if.req_wdata),
        .req_strb(req_if.req_strb),
        .req_prot(req_if.req_prot),
        .rsp_valid(req_if.rsp_valid),
        .rsp_rdata(req_if.rsp_rdata),
        .rsp_err(req_if.rsp_err)
    );

    assign req_if.PRESETn = PRESETn;

    // Passive tap of the internal APB bus for monitor/coverage/assertions.
    assign bus_if.PRESETn = PRESETn;
    assign bus_if.PADDR   = dut.paddr;
    assign bus_if.PSEL    = dut.psel;
    assign bus_if.PENABLE = dut.penable;
    assign bus_if.PWRITE  = dut.pwrite;
    assign bus_if.PWDATA  = dut.pwdata;
    assign bus_if.PSTRB   = dut.pstrb;
    assign bus_if.PPROT   = dut.pprot;
    assign bus_if.PREADY  = dut.pready;
    assign bus_if.PRDATA  = dut.prdata;
    assign bus_if.PSLVERR = dut.pslverr;

    apb4_protocol_sva u_protocol_sva (
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PADDR(dut.paddr), .PSEL(dut.psel), .PENABLE(dut.penable),
        .PWRITE(dut.pwrite), .PWDATA(dut.pwdata), .PSTRB(dut.pstrb),
        .PPROT(dut.pprot), .PREADY(dut.pready), .PRDATA(dut.prdata),
        .PSLVERR(dut.pslverr)
    );

    initial begin
        PRESETn = 1'b0;
        repeat (5) @(posedge PCLK);
        @(negedge PCLK);
        PRESETn = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual apb4_req_if)::set(null, "*", "req_vif", req_if);
        uvm_config_db#(virtual apb4_bus_if)::set(null, "*", "bus_vif", bus_if);
        run_test();
    end

    initial begin
        #10_000_000;
        `uvm_fatal("TIMEOUT", "Global UVM simulation timeout")
    end
endmodule
