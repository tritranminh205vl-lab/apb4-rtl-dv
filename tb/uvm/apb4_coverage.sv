class apb4_coverage extends uvm_subscriber #(apb4_txn);
    `uvm_component_utils(apb4_coverage)
    apb4_txn sample_tr;
    covergroup cg;
        option.per_instance = 1;
        cp_slave: coverpoint sample_tr.slave {
            bins peripherals[] = {[0:3]};
            bins decode_miss = {4};
        }
        cp_rw: coverpoint sample_tr.write {
            bins read = {0}; bins write = {1};
        }
        cp_strb: coverpoint sample_tr.strb iff (sample_tr.write && !sample_tr.err) {
            bins masks[] = {[0:15]};
        }
        cp_wait: coverpoint sample_tr.wait_cycles iff (sample_tr.slave < 4) {
            bins cycles[] = {[0:3]};
        }
        cp_err: coverpoint sample_tr.err {
            bins ok = {0}; bins error = {1};
        }
        // Exactly the four legal fixed-latency combinations. The scoreboard
        // rejects every other pair; coverage is not used as a correctness check.
        cp_slave_wait: coverpoint (sample_tr.slave*16 + sample_tr.wait_cycles)
                                  iff (sample_tr.slave < 4) {
            bins s0_w0 = {0}; bins s1_w1 = {17};
            bins s2_w2 = {34}; bins s3_w3 = {51};
        }
        x_slave_rw: cross cp_slave, cp_rw;
        x_rw_err: cross cp_rw, cp_err;
    endgroup
    function new(string name, uvm_component parent);
        super.new(name, parent); cg = new();
    endfunction
    function void write(apb4_txn t);
        sample_tr = t; cg.sample();
    endfunction
    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Functional coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)
    endfunction
endclass
