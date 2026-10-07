`uvm_analysis_imp_decl(_bus)
class apb4_scoreboard extends uvm_component;
    `uvm_component_utils(apb4_scoreboard)

    uvm_analysis_imp #(apb4_txn, apb4_scoreboard) imp;
    uvm_analysis_imp_bus #(apb4_txn, apb4_scoreboard) bus_imp;
    apb4_txn bus_pending[$];
    bit [31:0] model [0:3][0:3];
    int unsigned checked;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
        bus_imp = new("bus_imp", this);
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

    function void write_bus(apb4_txn t);
        int s, expected_slave, expected_wait;
        s = slave_of(t.addr);
        expected_slave = (s < 0) ? 4 : s;
        expected_wait = (s < 0) ? 0 : s;
        if (t.slave != expected_slave)
            `uvm_error("DECODE", $sformatf("addr=%h selected=%0d expected=%0d", t.addr,t.slave,expected_slave))
        if (t.wait_cycles != expected_wait)
            `uvm_error("WAIT", $sformatf("slave=%0d waits=%0d expected=%0d",s,t.wait_cycles,expected_wait))
        if ($isunknown(t.err) || (!t.write && $isunknown(t.rdata)))
            `uvm_error("XBUSRSP", "Unknown APB completion response")
        bus_pending.push_back(t);
    endfunction

    function void write(apb4_txn t);
        int s, r;
        bit expected_err;
        bit [31:0] expected_data;
        apb4_txn bus_tr;

        if (t.is_reset) begin
            foreach (model[s,r]) model[s][r] = '0;
            bus_pending.delete();
            return;
        end
        if ($isunknown(t.err) || (!t.write && $isunknown(t.rdata)))
            `uvm_error("XRSP", "Unknown upstream response")
        if (bus_pending.size() == 0) begin
            `uvm_error("MISSING_BUS", "Upstream response without bus completion")
        end else begin
            bus_tr = bus_pending.pop_front();
            if ({bus_tr.addr,bus_tr.write,bus_tr.prot,bus_tr.strb} !==
                {t.addr,t.write,t.prot,(t.write ? t.strb : 4'b0000)} ||
                (t.write && bus_tr.wdata !== t.wdata))
                `uvm_error("REQ_FORWARD", "Upstream request differs from APB request")
            if (bus_tr.err !== t.err || (!t.write && bus_tr.rdata !== t.rdata))
                `uvm_error("RSP_FORWARD", "APB response differs from upstream response")
        end

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

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (checked == 0) `uvm_error("NO_CHECKS", "No transactions checked")
        if (bus_pending.size() != 0) `uvm_error("PENDING_BUS", "Unmatched APB completions")
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("Scoreboard checked %0d completed transactions", checked), UVM_LOW)
    endfunction
endclass
