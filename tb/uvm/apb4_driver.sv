class apb4_driver extends uvm_driver #(apb4_txn);
    `uvm_component_utils(apb4_driver)

    virtual apb4_req_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb4_req_if)::get(this, "", "req_vif", vif))
            `uvm_fatal("NOVIF", "apb4_driver: req_vif not configured")
    endfunction

    task run_phase(uvm_phase phase);
        apb4_txn tr;

        vif.drv_cb.req_valid <= 1'b0;
        vif.drv_cb.req_addr  <= '0;
        vif.drv_cb.req_write <= 1'b0;
        vif.drv_cb.req_wdata <= '0;
        vif.drv_cb.req_strb  <= '0;
        vif.drv_cb.req_prot  <= '0;

        wait (vif.PRESETn === 1'b1);

        forever begin
            seq_item_port.get_next_item(tr);
            begin
                bit completed;
                do begin
                    completed = 0;
                    wait (vif.PRESETn === 1'b1);
                    fork : transfer_or_reset
                        begin drive_one(tr); completed = 1; end
                        begin @(negedge vif.PRESETn); end
                    join_any
                    disable transfer_or_reset;
                    if (!completed) begin
                        @(vif.drv_cb);
                        vif.drv_cb.req_valid <= 1'b0;
                    end
                end while (!completed);
            end
            seq_item_port.item_done();
        end
    endtask

    task drive_one(apb4_txn tr);
        // Present and hold the request until the upstream handshake completes.
        @(vif.drv_cb);
        vif.drv_cb.req_valid <= 1'b1;
        vif.drv_cb.req_addr  <= tr.addr;
        vif.drv_cb.req_write <= tr.write;
        vif.drv_cb.req_wdata <= tr.wdata;
        vif.drv_cb.req_strb  <= tr.strb;
        vif.drv_cb.req_prot  <= tr.prot;

        do @(vif.drv_cb); while (!vif.drv_cb.req_ready);
        vif.drv_cb.req_valid <= 1'b0;

        // This project's upstream side allows one outstanding request from
        // the UVM driver. The RTL itself supports boundary back-to-back traffic,
        // which is additionally exercised in tb/basic.
        do @(vif.drv_cb); while (!vif.drv_cb.rsp_valid);
        tr.rdata = vif.drv_cb.rsp_rdata;
        tr.err   = vif.drv_cb.rsp_err;
    endtask
endclass
