export DESIGN_NICKNAME = ibex_branch
export DESIGN_NAME = ibex_core
export PLATFORM    = nangate45
export VERILOG_DEFINES += -DSYNTHESIS


export VERILOG_FILES = \
designs/src/ibex_sv/ibex_pkg.sv \
designs/src/ibex_sv/vendor/lowrisc_ip/prim/rtl/prim_assert.sv \
designs/src/ibex_sv/ibex_alu.sv \
designs/src/ibex_sv/ibex_branch_predict.sv \
designs/src/ibex_sv/ibex_branch_predict_dynamic.sv \
designs/src/ibex_sv/ibex_compressed_decoder.sv \
designs/src/ibex_sv/ibex_controller.sv \
designs/src/ibex_sv/ibex_counter.sv \
designs/src/ibex_sv/ibex_csr.sv \
designs/src/ibex_sv/ibex_decoder.sv \
designs/src/ibex_sv/ibex_dummy_instr.sv \
designs/src/ibex_sv/ibex_ex_block.sv \
designs/src/ibex_sv/ibex_fetch_fifo.sv \
designs/src/ibex_sv/ibex_icache.sv \
designs/src/ibex_sv/ibex_id_stage.sv \
designs/src/ibex_sv/ibex_if_stage.sv \
designs/src/ibex_sv/ibex_load_store_unit.sv \
designs/src/ibex_sv/ibex_multdiv_fast.sv \
designs/src/ibex_sv/ibex_multdiv_slow.sv \
designs/src/ibex_sv/ibex_pmp.sv \
designs/src/ibex_sv/ibex_prefetch_buffer.sv \
designs/src/ibex_sv/ibex_register_file_ff.sv \
designs/src/ibex_sv/ibex_wb_stage.sv \
designs/src/ibex_sv/ibex_cs_registers.sv \
designs/src/ibex_sv/ibex_core.sv \
designs/src/ibex_sv/ibex_top.sv

export VERILOG_INCLUDE_DIRS = \
    $(DESIGN_HOME)/src/ibex_sv/vendor/lowrisc_ip/prim/rtl/

export SYNTH_HDL_FRONTEND = slang

export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export CORE_UTILIZATION ?= 50
export PLACE_DENSITY_LB_ADDON = 0.20
export TNS_END_PERCENT        = 100

