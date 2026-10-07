class apb4_base_test extends uvm_test;
    `uvm_component_utils(apb4_base_test)
    apb4_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb4_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        apb4_smoke_seq seq;
        phase.raise_objection(this);
        seq = apb4_smoke_seq::type_id::create("seq");
        seq.start(env.seqr);
        repeat (2) @(env.up_mon.vif.mon_cb);
        phase.drop_objection(this);
    endtask
endclass

class apb4_regression_test extends apb4_base_test;
    `uvm_component_utils(apb4_regression_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        apb4_smoke_seq  smoke;
        apb4_strb_seq   strb;
        apb4_error_seq  err;
        apb4_random_seq rnd;

        phase.raise_objection(this);

        smoke = apb4_smoke_seq::type_id::create("smoke");
        strb  = apb4_strb_seq ::type_id::create("strb");
        err   = apb4_error_seq::type_id::create("err");
        rnd   = apb4_random_seq::type_id::create("rnd");
        rnd.count = 1000;

        smoke.start(env.seqr);
        strb.start(env.seqr);
        err.start(env.seqr);
        rnd.start(env.seqr);

        repeat (2) @(env.up_mon.vif.mon_cb);
        phase.drop_objection(this);
    endtask
endclass
