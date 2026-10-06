class apb4_base_seq extends uvm_sequence #(apb4_txn);
    `uvm_object_utils(apb4_base_seq)
    function new(string name = "apb4_base_seq"); super.new(name); endfunction

    task automatic send(bit [31:0] addr, bit write, bit [31:0] data, bit [3:0] strb, bit [2:0] prot = 0);
        apb4_txn tr;
        tr = apb4_txn::type_id::create("tr");
        start_item(tr);
        tr.addr  = addr;
        tr.write = write;
        tr.wdata = data;
        tr.strb  = write ? strb : 4'b0000;
        tr.prot  = prot;
        finish_item(tr);
    endtask
endclass

class apb4_smoke_seq extends apb4_base_seq;
    `uvm_object_utils(apb4_smoke_seq)
    function new(string name = "apb4_smoke_seq"); super.new(name); endfunction

    task body();
        for (int s = 0; s < 4; s++) begin
            for (int r = 0; r < 4; r++) begin
                bit [31:0] a = s*32'h1000 + r*4;
                send(a, 1, 32'hCAFE_0000 ^ (s << 8) ^ r, 4'hF);
                send(a, 0, '0, 4'h0);
            end
        end
    endtask
endclass

class apb4_strb_seq extends apb4_base_seq;
    `uvm_object_utils(apb4_strb_seq)
    function new(string name = "apb4_strb_seq"); super.new(name); endfunction

    task body();
        send(32'h0000_0000, 1, 32'h1122_3344, 4'b1111);
        send(32'h0000_0000, 1, 32'hAAAA_BBBB, 4'b0001);
        send(32'h0000_0000, 1, 32'hCCCC_DDDD, 4'b0010);
        send(32'h0000_0000, 1, 32'h1234_5678, 4'b1100);
        send(32'h0000_0000, 0, '0, 4'h0);
    endtask
endclass

class apb4_error_seq extends apb4_base_seq;
    `uvm_object_utils(apb4_error_seq)
    function new(string name = "apb4_error_seq"); super.new(name); endfunction

    task body();
        // Inside mapped slave windows but outside the implemented register bank.
        send(32'h0000_0100, 0, '0, 4'h0);
        send(32'h0000_1100, 1, 32'hDEAD_BEEF, 4'hF);
        send(32'h0000_2100, 0, '0, 4'h0);
        send(32'h0000_3100, 1, 32'h1234_5678, 4'hF);
    endtask
endclass

class apb4_random_seq extends apb4_base_seq;
    `uvm_object_utils(apb4_random_seq)
    rand int unsigned count = 500;
    function new(string name = "apb4_random_seq"); super.new(name); endfunction

    task body();
        int s, r;
        bit [31:0] a, d;
        bit wr;
        bit [3:0] st;
        bit [2:0] pr;

        repeat (count) begin
            s  = $urandom_range(0, 3);
            wr = $urandom_range(0, 1);
            d  = $urandom;
            st = $urandom_range(1, 15);
            pr = $urandom_range(0, 7);

            if ($urandom_range(0, 9) < 8) begin
                r = $urandom_range(0, 3);
                a = s*32'h1000 + r*4;
            end else begin
                a = s*32'h1000 + 32'h100 + 4*$urandom_range(0, 31);
            end
            send(a, wr, d, st, pr);
        end
    endtask
endclass
