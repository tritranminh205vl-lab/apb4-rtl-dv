`timescale 1ns/1ps

interface apb4_bus_if(input logic PCLK);
    logic          PRESETn;
    logic [31:0]   PADDR;
    logic [3:0]    PSEL;
    logic          PENABLE;
    logic          PWRITE;
    logic [31:0]   PWDATA;
    logic [3:0]    PSTRB;
    logic [2:0]    PPROT;
    logic          PREADY;
    logic [31:0]   PRDATA;
    logic          PSLVERR;

    clocking mon_cb @(posedge PCLK);
        default input #1step;
        input PRESETn, PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB,
              PPROT, PREADY, PRDATA, PSLVERR;
    endclocking
endinterface
