class apb4_scoreboard extends uvm_component;
    `uvm_component_utils(apb4_scoreboard)

    uvm_analysis_imp #(apb4_txn, apb4_scoreboard) imp;
    bit [31:0] model [0:3][0:3];
    int unsigned checked;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        int s, r;
        super.build_phase(phase);
        for (s = 0; s < 4; s++)
            for (r = 0; r < 4; r++)
                model[s][r] = '0;
        checked = 0;
    endfunction

    function int slave_of(bit [31:0] addr);
        if (addr < 32'h0000_1000)      return 0;
        else if (addr < 32'h0000_2000) return 1;
        else if (addr < 32'h0000_3000) return 2;
        else if (addr < 32'h0000_4000) return 3;
        else                            return -1;
    endfunction

    function int reg_of(bit [31:0] addr, int s);
        bit [31:0] base;
        bit [31:0] off;
        case (s)
            0: base = 32'h0000_0000;
            1: base = 32'h0000_1000;
            2: base = 32'h0000_2000;
            3: base = 32'h0000_3000;
            default: return -1;
        endcase
        off = addr - base;
        if ((off < 16) && (off[1:0] == 0)) return (off >> 2);
        return -1;
    endfunction

    function bit [31:0] merge_bytes(bit [31:0] old_d, bit [31:0] new_d, bit [3:0] strb);
        bit [31:0] x;
        x = old_d;
        for (int b = 0; b < 4; b++)
            if (strb[b]) x[8*b +: 8] = new_d[8*b +: 8];
        return x;
    endfunction

    function void write(apb4_txn t);
        int s, r;
        bit expected_err;
        bit [31:0] expected_data;

        checked++;
        s = slave_of(t.addr);
        r = reg_of(t.addr, s);
        expected_err = (s < 0) || (r < 0);

        if (t.err !== expected_err) begin
            `uvm_error("SCB", $sformatf("PSLVERR mismatch addr=%08h write=%0d got=%0b exp=%0b",
                                        t.addr, t.write, t.err, expected_err))
        end

        if (!expected_err && t.write) begin
            model[s][r] = merge_bytes(model[s][r], t.wdata, t.strb);
        end

        if (!expected_err && !t.write) begin
            expected_data = model[s][r];
            if (t.rdata !== expected_data) begin
                `uvm_error("SCB", $sformatf("Read mismatch addr=%08h got=%08h exp=%08h",
                                            t.addr, t.rdata, expected_data))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("Scoreboard checked %0d completed transactions", checked), UVM_LOW)
    endfunction
endclass
