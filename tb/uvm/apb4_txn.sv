class apb4_txn extends uvm_sequence_item;
    rand bit [31:0] addr;
    rand bit        write;
    rand bit [31:0] wdata;
    rand bit [3:0]  strb;
    rand bit [2:0]  prot;

    bit [31:0] rdata;
    bit        err;
    int unsigned slave;
    int unsigned wait_cycles;

    constraint c_word_aligned { addr[1:0] == 2'b00; }
    constraint c_nonzero_strb { if (write) strb != 4'b0000; }

    `uvm_object_utils_begin(apb4_txn)
        `uvm_field_int(addr,        UVM_ALL_ON)
        `uvm_field_int(write,       UVM_ALL_ON)
        `uvm_field_int(wdata,       UVM_ALL_ON)
        `uvm_field_int(strb,        UVM_ALL_ON)
        `uvm_field_int(prot,        UVM_ALL_ON)
        `uvm_field_int(rdata,       UVM_ALL_ON)
        `uvm_field_int(err,         UVM_ALL_ON)
        `uvm_field_int(slave,       UVM_ALL_ON)
        `uvm_field_int(wait_cycles, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb4_txn");
        super.new(name);
    endfunction
endclass
