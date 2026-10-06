#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/basic

iverilog -g2012 -Wall \
  -s tb_apb4_system \
  -o build/basic/apb4_basic.vvp \
  rtl/apb4_master.sv \
  rtl/apb4_addr_decoder.sv \
  rtl/apb4_resp_mux.sv \
  rtl/apb4_reg_slave.sv \
  rtl/apb4_system_top.sv \
  tb/basic/tb_apb4_system.sv

vvp build/basic/apb4_basic.vvp
