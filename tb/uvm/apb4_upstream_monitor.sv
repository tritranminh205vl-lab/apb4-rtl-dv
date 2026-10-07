class apb4_upstream_monitor extends uvm_component;
    `uvm_component_utils(apb4_upstream_monitor)

    virtual apb4_req_if vif;
    uvm_analysis_port #(apb4_txn) ap;
    apb4_txn pending[$];
    bit in_reset;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb4_req_if)::get(this, "", "req_vif", vif))
            `uvm_fatal("NOVIF", "apb4_upstream_monitor: req_vif not configured")
    endfunction

    task run_phase(uvm_phase phase);
        apb4_txn tr;
        forever begin
            @(vif.mon_cb);

            if (!vif.mon_cb.PRESETn) begin
                pending.delete();
                if (!in_reset) begin
                    tr = apb4_txn::type_id::create("reset_event");
                    tr.is_reset = 1;
                    ap.write(tr);
                end
                in_reset = 1;
                continue;
            end

            in_reset = 0;
            if ($isunknown({vif.mon_cb.req_valid,vif.mon_cb.req_ready,vif.mon_cb.rsp_valid}))
                `uvm_error("XCTRL", "Unknown upstream handshake")
            if (vif.mon_cb.req_valid && vif.mon_cb.req_ready &&
                $isunknown({vif.mon_cb.req_addr,vif.mon_cb.req_write,vif.mon_cb.req_wdata,
                            vif.mon_cb.req_strb,vif.mon_cb.req_prot}))
                `uvm_error("XREQ", "Unknown accepted request")
            // Retire response first. This ordering correctly handles a cycle
            // where an old response and a new request acceptance coincide.
            if (vif.mon_cb.rsp_valid) begin
                if (pending.size() == 0) begin
                    `uvm_error("UPMON", "Response observed with no pending request")
                end else begin
                    tr = pending.pop_front();
                    tr.rdata = vif.mon_cb.rsp_rdata;
                    tr.err   = vif.mon_cb.rsp_err;
                    ap.write(tr);
                end
            end

            if (vif.mon_cb.req_valid && vif.mon_cb.req_ready) begin
                tr = apb4_txn::type_id::create("accepted_tr");
                tr.addr  = vif.mon_cb.req_addr;
                tr.write = vif.mon_cb.req_write;
                tr.wdata = vif.mon_cb.req_wdata;
                tr.strb  = vif.mon_cb.req_strb;
                tr.prot  = vif.mon_cb.req_prot;
                pending.push_back(tr);
            end
        end
    endtask
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (pending.size() != 0) `uvm_error("PENDING", "Unretired upstream requests at end of test")
    endfunction
endclass
