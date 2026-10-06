#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/questa
cd build/questa

rm -rf work transcript vsim.wlf apb4.ucdb
vlib work

vlog -sv \
  +incdir+../../tb/uvm \
  ../../rtl/apb4_master.sv \
  ../../rtl/apb4_addr_decoder.sv \
  ../../rtl/apb4_resp_mux.sv \
  ../../rtl/apb4_reg_slave.sv \
  ../../rtl/apb4_system_top.sv \
  ../../tb/uvm/apb4_req_if.sv \
  ../../tb/uvm/apb4_bus_if.sv \
  ../../tb/uvm/apb4_uvm_pkg.sv \
  ../../tb/sva/apb4_protocol_sva.sv \
  ../../tb/uvm/tb_top.sv

vsim -c -coverage tb_top \
  +UVM_TESTNAME=apb4_regression_test \
  +UVM_VERBOSITY=UVM_MEDIUM \
  -do "run -all; coverage save apb4.ucdb; coverage report -details; quit -f"
