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

`ifdef ENABLE_SVA
    apb4_protocol_sva u_sva (
        .PCLK, .PRESETn, .master_select(dut.master_select),
        .PADDR(dut.paddr), .PSEL(dut.psel), .PENABLE(dut.penable),
        .PWRITE(dut.pwrite), .PWDATA(dut.pwdata), .PSTRB(dut.pstrb),
        .PPROT(dut.pprot), .PREADY(dut.pready), .PRDATA(dut.prdata), .PSLVERR(dut.pslverr)
    );
`endif
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

            // First response is visible after the completion edge (NBA).
            @(negedge PCLK);
            req_valid = 1'b0;
            if (!rsp_valid) begin
                $error("Missing response for first back-to-back transfer");
                errors = errors + 1;
            end
            err_first = rsp_err;
            while (rsp_valid) @(negedge PCLK);
            while (!rsp_valid) @(negedge PCLK);
            err_second = rsp_err;
            rdata_dummy = rsp_rdata;
            while (rsp_valid) @(negedge PCLK);
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
    integer observed_waits;
    integer selected_slave;
    logic [3:0] expected_select;
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
        if (!PRESETn) begin
            observed_waits = 0;
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

            if (dut.master_select) begin
                selected_slave = slave_of(dut.paddr);
                expected_select = (selected_slave < 0) ? 4'b0000 : (4'b0001 << selected_slave);
                if (dut.psel !== expected_select) begin
                    $error("Decode mismatch addr=%h psel=%b expected=%b", dut.paddr, dut.psel, expected_select);
                    errors = errors + 1;
                end
                if (!dut.penable) observed_waits = 0;
                else if (!dut.pready) observed_waits = observed_waits + 1;
                else begin
                    if (observed_waits != ((selected_slave < 0) ? 0 : selected_slave)) begin
                        $error("WAIT mismatch slave=%0d got=%0d expected=%0d", selected_slave,
                               observed_waits, (selected_slave < 0) ? 0 : selected_slave);
                        errors = errors + 1;
                    end
                end
            end
            if (((^{dut.master_select,dut.psel,dut.penable,req_ready,rsp_valid}) === 1'bx)) begin
                $error("Unknown bus/handshake control"); errors = errors + 1;
            end
            if (dut.master_select && ((^{dut.paddr,dut.pwrite,dut.pstrb,dut.pprot}) === 1'bx)) begin
                $error("Unknown request fields"); errors = errors + 1;
            end
            if (dut.master_select && dut.penable && $isunknown(dut.pready)) begin
                $error("Unknown PREADY"); errors = errors + 1;
            end
            if (dut.master_select && dut.penable && dut.pready &&
                ($isunknown(dut.pslverr) || (!dut.pwrite && $isunknown(dut.prdata)))) begin
                $error("Unknown response fields"); errors = errors + 1;
            end

            if (dut.master_select && !dut.pwrite && (dut.pstrb != 0)) begin
                $error("Protocol: PSTRB must be zero for project read transfers");
                errors = errors + 1;
            end

            if (dut.pslverr && !(dut.master_select && dut.penable && dut.pready)) begin
                $error("Protocol: PSLVERR observed outside completed ACCESS");
                errors = errors + 1;
            end

            if (prev_setup) begin
                if (!(dut.penable && dut.master_select)) begin
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
                if (!(dut.penable && dut.master_select)) begin
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

            prev_setup    = (dut.master_select && !dut.penable);
            prev_wait     = (dut.master_select && dut.penable && !dut.pready);
            prev_complete = (dut.master_select && dut.penable && dut.pready);
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

            if (dut.penable || dut.master_select) begin
                $error("Reset did not return APB controller to IDLE");
                errors = errors + 1;
            end

            // Verify that the peripheral register banks were reset.
            if (rsp_valid) begin
                $error("Aborted transfer produced a response after reset"); errors = errors + 1;
            end
            for (int s = 0; s < 4; s++)
                for (int r = 0; r < 4; r++)
                    checked_xfer(s*32'h1000+r*4, 1'b0, '0, 4'h0, 3'b000);
        end
    endtask

    initial begin
        logic [31:0] addr;
        logic [31:0] data;
        logic [3:0]  strb;
        int s;
        int r;
        int n;
        integer seed, seed_state, random_discard;

        if (!$value$plusargs("SEED=%d", seed)) seed = 1;
        seed_state = seed;
        random_discard = $urandom(seed_state);
        $display("[CONFIG] seed=%0d", seed);
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

        $display("[TEST] all 16 write-strobe patterns with immediate readback");
        for (s = 0; s < 4; s++) begin
            for (n = 0; n < 16; n++) begin
                checked_xfer(s*32'h1000, 1'b1, 32'hA5C3_7E19 ^ (32'h1020_4081*n), 4'(n), 3'b000);
                checked_xfer(s*32'h1000, 1'b0, '0, 4'h0, 3'b000);
            end
        end
        $display("[TEST] decode misses");
        checked_xfer(32'h0000_4000, 1'b0, '0, 4'h0, 3'b000);
        checked_xfer(32'hFFFF_FFFC, 1'b1, 32'hDEAD_BEEF, 4'hF, 3'b000);

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
            strb = 4'($urandom_range(0, 15));
            checked_xfer(addr, $urandom_range(0, 1), data, strb, $urandom_range(0, 7));
        end

        for (s = 0; s < 4; s++)
            for (r = 0; r < 4; r++)
                checked_xfer(s*32'h1000+r*4, 1'b0, '0, 4'h0, 3'b000);
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
