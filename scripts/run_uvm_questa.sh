#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/questa
cd build/questa
rm -rf work transcript vsim.wlf
vlib work
vlog -sv +cover=bcesft \
  +incdir+../../tb/uvm \
  ../../rtl/apb4_master.sv ../../rtl/apb4_addr_decoder.sv \
  ../../rtl/apb4_resp_mux.sv ../../rtl/apb4_reg_slave.sv ../../rtl/apb4_system_top.sv \
  ../../tb/uvm/apb4_req_if.sv ../../tb/uvm/apb4_bus_if.sv \
  ../../tb/uvm/apb4_uvm_pkg.sv ../../tb/sva/apb4_protocol_sva.sv ../../tb/uvm/tb_top.sv
for mode in normal reset; do
  args=()
  if [[ "$mode" == reset ]]; then args+=(+RESET_DURING_WAIT); fi
  vsim -c -coverage -onfinish stop tb_top \
    -sv_seed "${SEED:-1}" +UVM_TESTNAME=apb4_regression_test +UVM_VERBOSITY=UVM_MEDIUM \
    "${args[@]}" -l "${mode}.log" \
    -do "onerror {quit -code 1}; onbreak {quit -code 1}; run -all; coverage save ${mode}.ucdb; coverage report -details; quit -code 0"
  # UVM_ERROR does not necessarily change the simulator's process exit code.
  if ! grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0([[:space:]]|$)' "${mode}.log" || \
     ! grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0([[:space:]]|$)' "${mode}.log" || \
     grep -Eq '\*\* (Error|Fatal):' "${mode}.log"; then
    echo "UVM/SVA regression failed or summary missing: ${mode}.log" >&2
    exit 1
  fi
done
