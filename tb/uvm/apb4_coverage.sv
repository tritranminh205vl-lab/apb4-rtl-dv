class apb4_coverage extends uvm_subscriber #(apb4_txn);
    `uvm_component_utils(apb4_coverage)

    apb4_txn sample_tr;

    covergroup cg;
        option.per_instance = 1;

        cp_slave: coverpoint sample_tr.slave {
            bins s0 = {0};
            bins s1 = {1};
            bins s2 = {2};
            bins s3 = {3};
        }

        cp_rw: coverpoint sample_tr.write {
            bins read  = {0};
            bins write = {1};
        }

        cp_strb: coverpoint sample_tr.strb iff (sample_tr.write) {
            bins byte0 = {4'b0001};
            bins byte1 = {4'b0010};
            bins byte2 = {4'b0100};
            bins byte3 = {4'b1000};
            bins full  = {4'b1111};
            bins mixed = default;
        }

        cp_wait: coverpoint sample_tr.wait_cycles {
            bins zero  = {0};
            bins one   = {1};
            bins two   = {2};
            bins three = {3};
            bins many  = {[4:15]};
        }

        cp_err: coverpoint sample_tr.err {
            bins ok    = {0};
            bins error = {1};
        }

        x_slave_rw: cross cp_slave, cp_rw;
        x_rw_err:    cross cp_rw, cp_err;
        x_slave_wait: cross cp_slave, cp_wait;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void write(apb4_txn t);
        sample_tr = t;
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Functional coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)
    endfunction
endclass
