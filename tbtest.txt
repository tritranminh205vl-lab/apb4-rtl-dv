`timescale 1ns/1ps

module tb_apb4_system;
    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;
    localparam int STRB_WIDTH = 4;

    logic                  PCLK;
    logic                  PRESETn;
    logic                  req_valid;
    logic                  req_ready;
    logic [ADDR_WIDTH-1:0] req_addr;
    logic                  req_write;
    logic [DATA_WIDTH-1:0] req_wdata;
    logic [STRB_WIDTH-1:0] req_strb;
    logic [2:0]            req_prot;
    logic                  rsp_valid;
    logic [DATA_WIDTH-1:0] rsp_rdata;
    logic                  rsp_err;

    logic [31:0] model [0:3][0:3];
    integer errors;
    integer checks;
    integer i, j;

    apb4_system_top #(
        .WAIT_S0(0),
        .WAIT_S1(1),
        .WAIT_S2(2),
        .WAIT_S3(3)
    ) dut (
        .PCLK, .PRESETn,
        .req_valid, .req_ready, .req_addr, .req_write,
        .req_wdata, .req_strb, .req_prot,
        .rsp_valid, .rsp_rdata, .rsp_err
    );

    initial PCLK = 1'b0;
    always #5 PCLK = ~PCLK;
  initial begin
    $dumpfile("apb4.vcd");
    $dumpvars(0, tb_apb4_system);
end

    function automatic int slave_of(input logic [31:0] addr);
        if (addr < 32'h0000_1000)      slave_of = 0;
        else if (addr < 32'h0000_2000) slave_of = 1;
        else if (addr < 32'h0000_3000) slave_of = 2;
        else if (addr < 32'h0000_4000) slave_of = 3;
        else                            slave_of = -1;
    endfunction

    function automatic int reg_of(input logic [31:0] addr, input int slave);
        logic [31:0] base;
        logic [31:0] off;
        begin
            case (slave)
                0: base = 32'h0000_0000;
                1: base = 32'h0000_1000;
                2: base = 32'h0000_2000;
                3: base = 32'h0000_3000;
                default: base = 32'hffff_ffff;
            endcase
            off = addr - base;
            if ((slave >= 0) && (off < 16) && (off[1:0] == 2'b00))
                reg_of = off >> 2;
            else
                reg_of = -1;
        end
    endfunction

    function automatic logic [31:0] merge_bytes(
        input logic [31:0] old_data,
        input logic [31:0] new_data,
        input logic [3:0]  strb
    );
        logic [31:0] tmp;
        integer k;
        begin
            tmp = old_data;
            for (k = 0; k < 4; k = k + 1)
                if (strb[k]) tmp[8*k +: 8] = new_data[8*k +: 8];
            merge_bytes = tmp;
        end
    endfunction

    task automatic clear_model;
        integer s, r;
        begin
            for (s = 0; s < 4; s = s + 1)
                for (r = 0; r < 4; r = r + 1)
                    model[s][r] = '0;
        end
    endtask

    task automatic reset_dut;
        begin
            req_valid = 1'b0;
            req_addr  = '0;
            req_write = 1'b0;
            req_wdata = '0;
            req_strb  = '0;
            req_prot  = '0;
            PRESETn   = 1'b0;
            repeat (3) @(posedge PCLK);
            @(negedge PCLK);
            PRESETn = 1'b1;
            repeat (2) @(posedge PCLK);
            clear_model();
        end
    endtask

    task automatic upstream_xfer(
        input  logic [31:0] addr,
        input  logic        write,
        input  logic [31:0] wdata,
        input  logic [3:0]  strb,
        input  logic [2:0]  prot,
        output logic [31:0] rdata,
        output logic        err
    );
        begin
            @(negedge PCLK);
            req_valid = 1'b1;
            req_addr  = addr;
            req_write = write;
            req_wdata = wdata;
            req_strb  = strb;
            req_prot  = prot;

            do @(posedge PCLK); while (!req_ready);

            @(negedge PCLK);
            req_valid = 1'b0;

            do @(posedge PCLK); while (!rsp_valid);
            rdata = rsp_rdata;
            err   = rsp_err;
        end
    endtask

    task automatic checked_xfer(
        input logic [31:0] addr,
        input logic        write,
        input logic [31:0] wdata,
        input logic [3:0]  strb,
        input logic [2:0]  prot
    );
        logic [31:0] rdata;
        logic err;
        logic expected_err;
        logic [31:0] expected_rdata;
        int s, r;
        begin
            s = slave_of(addr);
            r = reg_of(addr, s);
            expected_err   = (s < 0) || (r < 0);
            expected_rdata = (!expected_err && !write) ? model[s][r] : '0;

            upstream_xfer(addr, write, wdata, strb, prot, rdata, err);
            checks = checks + 1;

            if (err !== expected_err) begin
                $error("ERR mismatch addr=%08h write=%0d got=%0b exp=%0b", addr, write, err, expected_err);
                errors = errors + 1;
            end

            if (!expected_err && write) begin
                model[s][r] = merge_bytes(model[s][r], wdata, strb);
            end

            if (!expected_err && !write) begin
                if (rdata !== expected_rdata) begin
                    $error("READ mismatch addr=%08h got=%08h exp=%08h", addr, rdata, expected_rdata);
                    errors = errors + 1;
                end
            end
        end
    endtask

    // Exercises acceptance of a second request on the same edge that the first
    // ACCESS phase completes. The bus must still return to SETUP (PENABLE=0)
    // for the second transfer.
    task automatic back_to_back_writes;
        logic [31:0] rdata_dummy;
        logic err_first, err_second;
        begin
            // First write request.
            @(negedge PCLK);
            req_valid = 1'b1;
            req_addr  = 32'h0000_0004;
            req_write = 1'b1;
            req_wdata = 32'h1111_2222;
            req_strb  = 4'hF;
            req_prot  = 3'b000;
            do @(posedge PCLK); while (!req_ready);

            // Keep req_valid asserted, but change payload only after the first
            // request has been accepted. It will be held until req_ready rises
            // again at the current transfer completion boundary.
            @(negedge PCLK);
            req_addr  = 32'h0000_0008;
            req_wdata = 32'h3333_4444;
            do @(posedge PCLK); while (!req_ready);

           // At this point transfer 1 has completed and transfer 2 has
// been accepted on the same completion boundary.
//
// rsp_valid currently belongs to transfer 1.

@(negedge PCLK);

req_valid = 1'b0;

// Capture response of transfer 1.
if (!rsp_valid) begin
    $error("Missing response for first back-to-back transfer");
    errors = errors + 1;
end

err_first = rsp_err;


// Wait until response pulse of transfer 1 disappears.
while (rsp_valid)
    @(negedge PCLK);


// Now wait for response belonging to transfer 2.
while (!rsp_valid)
    @(negedge PCLK);

err_second  = rsp_err;
rdata_dummy = rsp_rdata;


// Wait until transfer-2 response is completely consumed.
// This prevents the following read from seeing stale rsp_valid.
while (rsp_valid)
    @(negedge PCLK);
            if (err_first || err_second) begin
                $error("Unexpected error in back-to-back valid writes");
                errors = errors + 1;
            end

            model[0][1] = 32'h1111_2222;
            model[0][2] = 32'h3333_4444;
            checked_xfer(32'h0000_0004, 1'b0, '0, 4'h0, 3'b000);
            checked_xfer(32'h0000_0008, 1'b0, '0, 4'h0, 3'b000);
        end
    endtask

    // ----------------------------
    // Lightweight protocol monitor
    // ----------------------------
    logic prev_wait;
    logic prev_setup;
    logic prev_complete;
    logic [31:0] prev_paddr;
    logic        prev_pwrite;
    logic [31:0] prev_pwdata;
    logic [3:0]  prev_pstrb;
    logic [2:0]  prev_pprot;
    logic [3:0]  prev_psel;

    function automatic bit onehot0_4(input logic [3:0] v);
        onehot0_4 = (v == 0) || ((v & (v - 1'b1)) == 0);
    endfunction

    always @(posedge PCLK) begin
        #1;
        if (!PRESETn) begin
            prev_wait     = 1'b0;
            prev_setup    = 1'b0;
            prev_complete = 1'b0;
            prev_paddr    = '0;
            prev_pwrite   = 1'b0;
            prev_pwdata   = '0;
            prev_pstrb    = '0;
            prev_pprot    = '0;
            prev_psel     = '0;
        end else begin
            if (!onehot0_4(dut.psel)) begin
                $error("Protocol: PSEL is not one-hot/zero: %b", dut.psel);
                errors = errors + 1;
            end

            if (dut.penable && (dut.psel == 0)) begin
                $error("Protocol: PENABLE asserted without any selected slave");
                errors = errors + 1;
            end

            if ((dut.psel != 0) && !dut.pwrite && (dut.pstrb != 0)) begin
                $error("Protocol: PSTRB must be zero for project read transfers");
                errors = errors + 1;
            end

            if (dut.pslverr && !((dut.psel != 0) && dut.penable && dut.pready)) begin
                $error("Protocol: PSLVERR observed outside completed ACCESS");
                errors = errors + 1;
            end

            if (prev_setup) begin
                if (!(dut.penable && (dut.psel != 0))) begin
                    $error("Protocol: SETUP was not followed by ACCESS");
                    errors = errors + 1;
                end
                if ({dut.paddr,dut.pwrite,dut.pwdata,dut.pstrb,dut.pprot,dut.psel} !==
                    {prev_paddr,prev_pwrite,prev_pwdata,prev_pstrb,prev_pprot,prev_psel}) begin
                    $error("Protocol: control/data changed between SETUP and ACCESS");
                    errors = errors + 1;
                end
            end

            if (prev_wait) begin
                if (!(dut.penable && (dut.psel != 0))) begin
                    $error("Protocol: ACCESS dropped while PREADY was LOW");
                    errors = errors + 1;
                end
                if ({dut.paddr,dut.pwrite,dut.pwdata,dut.pstrb,dut.pprot,dut.psel} !==
                    {prev_paddr,prev_pwrite,prev_pwdata,prev_pstrb,prev_pprot,prev_psel}) begin
                    $error("Protocol: bus changed during wait-state extension");
                    errors = errors + 1;
                end
            end

            if (prev_complete && dut.penable) begin
                $error("Protocol: PENABLE must be LOW in the cycle after completion");
                errors = errors + 1;
            end

            prev_setup    = ((dut.psel != 0) && !dut.penable);
            prev_wait     = ((dut.psel != 0) && dut.penable && !dut.pready);
            prev_complete = ((dut.psel != 0) && dut.penable && dut.pready);
            prev_paddr    = dut.paddr;
            prev_pwrite   = dut.pwrite;
            prev_pwdata   = dut.pwdata;
            prev_pstrb    = dut.pstrb;
            prev_pprot    = dut.pprot;
            prev_psel     = dut.psel;
        end
    end

    task automatic mid_transfer_reset_test;
        begin
            $display("[TEST] reset during wait-state transfer");
            @(negedge PCLK);
            req_valid = 1'b1;
            req_addr  = 32'h0000_3000;
            req_write = 1'b1;
            req_wdata = 32'hDEAD_BEEF;
            req_strb  = 4'hF;
            req_prot  = 3'b000;
            do @(posedge PCLK); while (!req_ready);
            @(negedge PCLK);
            req_valid = 1'b0;

            // Wait until slave 3 is in ACCESS and stretching the transfer.
            wait (dut.penable && dut.psel[3] && !dut.pready);
            @(negedge PCLK);
            PRESETn = 1'b0;
            repeat (2) @(posedge PCLK);
            @(negedge PCLK);
            PRESETn = 1'b1;
            clear_model();
            repeat (2) @(posedge PCLK);

            if (dut.penable || (dut.psel != 0)) begin
                $error("Reset did not return APB controller to IDLE");
                errors = errors + 1;
            end

            // Verify that the peripheral register banks were reset.
            checked_xfer(32'h0000_0000, 1'b0, '0, 4'h0, 3'b000);
            checked_xfer(32'h0000_1000, 1'b0, '0, 4'h0, 3'b000);
            checked_xfer(32'h0000_2000, 1'b0, '0, 4'h0, 3'b000);
            checked_xfer(32'h0000_3000, 1'b0, '0, 4'h0, 3'b000);
        end
    endtask

    initial begin
        logic [31:0] addr;
        logic [31:0] data;
        logic [3:0]  strb;
        int s;
        int r;
        int n;

        errors = 0;
        checks = 0;
        clear_model();
        reset_dut();

        $display("[TEST] full-word read/write on all four slaves");
        for (s = 0; s < 4; s = s + 1) begin
            for (r = 0; r < 4; r = r + 1) begin
                addr = (s * 32'h1000) + (r * 4);
                data = 32'hA500_0000 ^ (s << 12) ^ r;
                checked_xfer(addr, 1'b1, data, 4'hF, 3'b000);
                checked_xfer(addr, 1'b0, '0, 4'h0, 3'b000);
            end
        end

        $display("[TEST] PSTRB byte-write behavior");
        checked_xfer(32'h0000_0000, 1'b1, 32'h1122_3344, 4'b1111, 3'b000);
        checked_xfer(32'h0000_0000, 1'b1, 32'hAAAA_BBBB, 4'b0011, 3'b000);
        checked_xfer(32'h0000_0000, 1'b1, 32'hCCCC_DDDD, 4'b1100, 3'b000);
        checked_xfer(32'h0000_0000, 1'b0, '0, 4'h0, 3'b000);

        $display("[TEST] error response on invalid local offsets / alignment");
        checked_xfer(32'h0000_0100, 1'b0, '0, 4'h0, 3'b000);
        checked_xfer(32'h0000_1002, 1'b1, 32'h1234_5678, 4'hF, 3'b000);
        checked_xfer(32'h0000_2FFC, 1'b0, '0, 4'h0, 3'b000);

        $display("[TEST] back-to-back request boundary");
        back_to_back_writes();

        $display("[TEST] constrained-random regression (250 transfers)");
        for (n = 0; n < 250; n = n + 1) begin
            s = $urandom_range(0, 3);
            if ($urandom_range(0, 9) < 8) begin
                // 80% legal register accesses.
                r = $urandom_range(0, 3);
                addr = (s * 32'h1000) + (r * 4);
            end else begin
                // 20% invalid but still within a mapped 4-KiB slave window.
                addr = (s * 32'h1000) + 32'h100 + (4 * $urandom_range(0, 15));
            end
            data = $urandom;
            strb = $urandom_range(1, 15);
            checked_xfer(addr, $urandom_range(0, 1), data, strb, $urandom_range(0, 7));
        end

        mid_transfer_reset_test();

        repeat (5) @(posedge PCLK);
        if (errors == 0) begin
            $display("\n============================================");
            $display(" APB4 BASIC REGRESSION PASS - checks=%0d", checks);
            $display("============================================\n");
            $finish;
        end else begin
            $fatal(1, "APB4 BASIC REGRESSION FAIL - errors=%0d checks=%0d", errors, checks);
        end
    end

    initial begin
        // Global timeout protects CI from deadlock.
        #2_000_000;
        $fatal(1, "Simulation timeout");
    end

endmodule
