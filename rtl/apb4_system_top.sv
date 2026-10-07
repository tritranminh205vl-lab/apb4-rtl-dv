`timescale 1ns/1ps

module apb4_system_top #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH/8,
    parameter int SLAVE_WINDOW_BYTES = 4096,
    parameter int REG_COUNT = 4,
    parameter int WAIT_S0 = 0,
    parameter int WAIT_S1 = 1,
    parameter int WAIT_S2 = 2,
    parameter int WAIT_S3 = 3
) (
    input  logic                  PCLK,
    input  logic                  PRESETn,

    input  logic                  req_valid,
    output logic                  req_ready,
    input  logic [ADDR_WIDTH-1:0] req_addr,
    input  logic                  req_write,
    input  logic [DATA_WIDTH-1:0] req_wdata,
    input  logic [STRB_WIDTH-1:0] req_strb,
    input  logic [2:0]            req_prot,

    output logic                  rsp_valid,
    output logic [DATA_WIDTH-1:0] rsp_rdata,
    output logic                  rsp_err
);

    localparam int NUM_SLAVES = 4;

    localparam logic [ADDR_WIDTH-1:0] S0_BASE = 32'h0000_0000;
    localparam logic [ADDR_WIDTH-1:0] S1_BASE = ADDR_WIDTH'(1 * SLAVE_WINDOW_BYTES);
    localparam logic [ADDR_WIDTH-1:0] S2_BASE = ADDR_WIDTH'(2 * SLAVE_WINDOW_BYTES);
    localparam logic [ADDR_WIDTH-1:0] S3_BASE = ADDR_WIDTH'(3 * SLAVE_WINDOW_BYTES);

    // Shared APB bus. These names are intentionally visible for passive DV.
    logic [ADDR_WIDTH-1:0] paddr;
    logic                  penable;
    logic                  pwrite;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [STRB_WIDTH-1:0] pstrb;
    logic [2:0]            pprot;
    logic                  master_select;
    logic [NUM_SLAVES-1:0] psel;

    logic                  pready;
    logic [DATA_WIDTH-1:0] prdata;
    logic                  pslverr;

    logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0] prdata_s;
    logic [NUM_SLAVES-1:0]                 pready_s;
    logic [NUM_SLAVES-1:0]                 pslverr_s;

    apb4_master #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .STRB_WIDTH (STRB_WIDTH)
    ) u_master (
        .PCLK, .PRESETn,
        .req_valid, .req_ready, .req_addr, .req_write,
        .req_wdata, .req_strb, .req_prot,
        .rsp_valid, .rsp_rdata, .rsp_err,
        .PADDR(paddr), .PENABLE(penable), .PWRITE(pwrite),
        .PWDATA(pwdata), .PSTRB(pstrb), .PPROT(pprot),
        .master_select,
        .PREADY(pready), .PRDATA(prdata), .PSLVERR(pslverr)
    );

    apb4_addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_SLAVES(NUM_SLAVES),
        .BASE_ADDR(S0_BASE),
        .SLAVE_WINDOW_BYTES(SLAVE_WINDOW_BYTES)
    ) u_decoder (
        .PADDR(paddr),
        .master_select(master_select),
        .PSEL(psel)
    );

    apb4_reg_slave #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH),
        .REG_COUNT(REG_COUNT), .WAIT_CYCLES(WAIT_S0), .BASE_ADDR(S0_BASE)
    ) u_s0 (
        .PCLK, .PRESETn, .PADDR(paddr), .PSEL(psel[0]), .PENABLE(penable),
        .PWRITE(pwrite), .PWDATA(pwdata), .PSTRB(pstrb), .PPROT(pprot),
        .PREADY(pready_s[0]), .PRDATA(prdata_s[0]), .PSLVERR(pslverr_s[0])
    );

    apb4_reg_slave #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH),
        .REG_COUNT(REG_COUNT), .WAIT_CYCLES(WAIT_S1), .BASE_ADDR(S1_BASE)
    ) u_s1 (
        .PCLK, .PRESETn, .PADDR(paddr), .PSEL(psel[1]), .PENABLE(penable),
        .PWRITE(pwrite), .PWDATA(pwdata), .PSTRB(pstrb), .PPROT(pprot),
        .PREADY(pready_s[1]), .PRDATA(prdata_s[1]), .PSLVERR(pslverr_s[1])
    );

    apb4_reg_slave #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH),
        .REG_COUNT(REG_COUNT), .WAIT_CYCLES(WAIT_S2), .BASE_ADDR(S2_BASE)
    ) u_s2 (
        .PCLK, .PRESETn, .PADDR(paddr), .PSEL(psel[2]), .PENABLE(penable),
        .PWRITE(pwrite), .PWDATA(pwdata), .PSTRB(pstrb), .PPROT(pprot),
        .PREADY(pready_s[2]), .PRDATA(prdata_s[2]), .PSLVERR(pslverr_s[2])
    );

    apb4_reg_slave #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH),
        .REG_COUNT(REG_COUNT), .WAIT_CYCLES(WAIT_S3), .BASE_ADDR(S3_BASE)
    ) u_s3 (
        .PCLK, .PRESETn, .PADDR(paddr), .PSEL(psel[3]), .PENABLE(penable),
        .PWRITE(pwrite), .PWDATA(pwdata), .PSTRB(pstrb), .PPROT(pprot),
        .PREADY(pready_s[3]), .PRDATA(prdata_s[3]), .PSLVERR(pslverr_s[3])
    );

    apb4_resp_mux #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_SLAVES(NUM_SLAVES)
    ) u_rsp_mux (
        .master_select(master_select), .PENABLE(penable),
        .PSEL(psel),
        .PRDATA_S(prdata_s),
        .PREADY_S(pready_s),
        .PSLVERR_S(pslverr_s),
        .PRDATA(prdata),
        .PREADY(pready),
        .PSLVERR(pslverr)
    );

endmodule
