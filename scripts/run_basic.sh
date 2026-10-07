#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/basic

"${IVERILOG:-iverilog}" -g2012 -Wall \
  -s tb_apb4_system \
  -o build/basic/apb4_basic.vvp \
  rtl/apb4_master.sv \
  rtl/apb4_addr_decoder.sv \
  rtl/apb4_resp_mux.sv \
  rtl/apb4_reg_slave.sv \
  rtl/apb4_system_top.sv \
  tb/basic/tb_apb4_system.sv

"${VVP:-vvp}" build/basic/apb4_basic.vvp +SEED="${SEED:-1}"

"${IVERILOG:-iverilog}" -g2012 -Wall -s tb_apb4_parameters \
  -o build/basic/apb4_parameters.vvp -f rtl/files.f tb/basic/tb_apb4_parameters.sv
"${VVP:-vvp}" build/basic/apb4_parameters.vvp
