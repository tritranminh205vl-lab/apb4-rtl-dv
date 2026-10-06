class apb4_bus_monitor extends uvm_component;
    `uvm_component_utils(apb4_bus_monitor)

    virtual apb4_bus_if vif;
    uvm_analysis_port #(apb4_txn) ap;

    apb4_txn active;
    bit       have_active;
    int unsigned waits;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb4_bus_if)::get(this, "", "bus_vif", vif))
            `uvm_fatal("NOVIF", "apb4_bus_monitor: bus_vif not configured")
    endfunction

    function int unsigned decode_slave(bit [3:0] psel);
        case (psel)
            4'b0001: return 0;
            4'b0010: return 1;
            4'b0100: return 2;
            4'b1000: return 3;
            default: return 32'hffff_ffff;
        endcase
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(vif.mon_cb);

            if (!vif.mon_cb.PRESETn) begin
                have_active = 0;
                waits = 0;
                continue;
            end

            if ((vif.mon_cb.PSEL != 0) && !vif.mon_cb.PENABLE) begin
                active = apb4_txn::type_id::create("bus_tr");
                active.addr  = vif.mon_cb.PADDR;
                active.write = vif.mon_cb.PWRITE;
                active.wdata = vif.mon_cb.PWDATA;
                active.strb  = vif.mon_cb.PSTRB;
                active.prot  = vif.mon_cb.PPROT;
                active.slave = decode_slave(vif.mon_cb.PSEL);
                waits = 0;
                have_active = 1;
            end

            if (have_active && vif.mon_cb.PENABLE && !vif.mon_cb.PREADY)
                waits++;

            if (have_active && vif.mon_cb.PENABLE && vif.mon_cb.PREADY) begin
                active.rdata       = vif.mon_cb.PRDATA;
                active.err         = vif.mon_cb.PSLVERR;
                active.wait_cycles = waits;
                ap.write(active);
                have_active = 0;
                waits = 0;
            end
        end
    endtask
endclass
