#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/verilator
"${VERILATOR:-verilator}" --binary --timing --assert -Wno-fatal \
  +define+ENABLE_SVA --top-module tb_apb4_system --Mdir build/verilator \
  -f rtl/files.f tb/sva/apb4_protocol_sva.sv tb/basic/tb_apb4_system.sv
build/verilator/Vtb_apb4_system +SEED="${SEED:-1}"
