class apb4_env extends uvm_env;
    `uvm_component_utils(apb4_env)

    apb4_sequencer        seqr;
    apb4_driver           drv;
    apb4_upstream_monitor up_mon;
    apb4_bus_monitor      bus_mon;
    apb4_scoreboard       scb;
    apb4_coverage         cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr    = apb4_sequencer       ::type_id::create("seqr", this);
        drv     = apb4_driver          ::type_id::create("drv", this);
        up_mon  = apb4_upstream_monitor::type_id::create("up_mon", this);
        bus_mon = apb4_bus_monitor     ::type_id::create("bus_mon", this);
        scb     = apb4_scoreboard      ::type_id::create("scb", this);
        cov     = apb4_coverage        ::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        up_mon.ap.connect(scb.imp);
        bus_mon.ap.connect(cov.analysis_export);
    endfunction
endclass
