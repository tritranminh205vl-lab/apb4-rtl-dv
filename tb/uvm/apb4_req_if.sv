`timescale 1ns/1ps

interface apb4_req_if(input logic PCLK);
    logic                  PRESETn;
    logic                  req_valid;
    logic                  req_ready;
    logic [31:0]           req_addr;
    logic                  req_write;
    logic [31:0]           req_wdata;
    logic [3:0]            req_strb;
    logic [2:0]            req_prot;
    logic                  rsp_valid;
    logic [31:0]           rsp_rdata;
    logic                  rsp_err;

    clocking drv_cb @(posedge PCLK);
        default input #1step output #1step;
        input  PRESETn, req_ready, rsp_valid, rsp_rdata, rsp_err;
        output req_valid, req_addr, req_write, req_wdata, req_strb, req_prot;
    endclocking

    clocking mon_cb @(posedge PCLK);
        default input #1step;
        input PRESETn, req_valid, req_ready, req_addr, req_write,
              req_wdata, req_strb, req_prot, rsp_valid, rsp_rdata, rsp_err;
    endclocking
endinterface
