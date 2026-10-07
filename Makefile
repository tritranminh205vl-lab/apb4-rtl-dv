.PHONY: basic verilator uvm-questa lint clean
VERILATOR ?= verilator

basic:
	bash scripts/run_basic.sh

verilator:
	bash scripts/run_verilator.sh

uvm-questa:
	bash scripts/run_uvm_questa.sh

lint:
	$(VERILATOR) --lint-only -Wall --timing --top-module apb4_system_top \
		rtl/apb4_master.sv rtl/apb4_addr_decoder.sv rtl/apb4_resp_mux.sv \
		rtl/apb4_reg_slave.sv rtl/apb4_system_top.sv

clean:
	rm -rf build work transcript vsim.wlf *.vcd *.ucdb

.PHONY: mutations
mutations:
	python3 scripts/check_mutations.py
