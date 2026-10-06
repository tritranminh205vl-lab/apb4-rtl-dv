class apb4_sequencer extends uvm_sequencer #(apb4_txn);
    `uvm_component_utils(apb4_sequencer)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
