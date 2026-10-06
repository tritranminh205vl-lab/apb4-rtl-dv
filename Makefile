.PHONY: basic uvm-questa lint clean

basic:
	./scripts/run_basic.sh

uvm-questa:
	./scripts/run_uvm_questa.sh

lint:
	verilator --lint-only -Wall --timing --top-module apb4_system_top \
		rtl/apb4_master.sv rtl/apb4_addr_decoder.sv rtl/apb4_resp_mux.sv \
		rtl/apb4_reg_slave.sv rtl/apb4_system_top.sv

clean:
	rm -rf build work transcript vsim.wlf *.vcd *.ucdb
