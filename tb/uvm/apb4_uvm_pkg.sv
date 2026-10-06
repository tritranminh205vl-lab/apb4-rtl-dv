`timescale 1ns/1ps

package apb4_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "apb4_txn.sv"
    `include "apb4_sequencer.sv"
    `include "apb4_driver.sv"
    `include "apb4_upstream_monitor.sv"
    `include "apb4_bus_monitor.sv"
    `include "apb4_scoreboard.sv"
    `include "apb4_coverage.sv"
    `include "apb4_env.sv"
    `include "apb4_sequences.sv"
    `include "apb4_tests.sv"
endpackage
