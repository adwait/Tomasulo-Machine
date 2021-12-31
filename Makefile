SHELL = /bin/bash

V_SRC_DIR = .

CXX_TEST_DIR = .

SIM_DIR = sim

# MEM_DIR = src/test/inputs

OUT_DIR = output

VERILATOR = verilator

VERILATOR_OPTS = \
	-Wall \
	-Wno-WIDTH \
	-Wno-UNUSED \
	-Wno-BLKSEQ \
	-Wno-UNOPTFLAT \
	-Wno-DECLFILENAME \
	--cc \
	-I$(V_SRC_DIR) \
	+1364-2001ext+v \
	-Wno-fatal \
	--Mdir sim \
	--x-assign unique \
	--trace \

VERILATOR_MAKE_OPTS = OPT_FAST="-O3"

# VCS = vcs -full64

# VCS_OPTS = -PP -notice -line +lint=all,noVCDE,noUI +v2k -timescale=1ns/10ps -quiet \
# 	+define+DEBUG -debug_pp \
# 	+incdir+$(V_SRC_DIR) -Mdirectory=$(SIM_DIR)/csrc \
# 	+vc+list -CC "-I$(VCS_HOME)/include" \

# MAX_CYCLES = 1000000

# SIMV_OPTS = -k $(OUT_DIR)/ucli.key -q

MY_DESIGN_SRCS = $(addprefix $(V_SRC_DIR)/, \
	myTomasulo.v \
)

DESIGN_SRCS = $(addprefix $(V_SRC_DIR)/, \
	cleanTomasulo.v \
)

# SIM_SRCS = $(addprefix $(V_SRC_DIR)/, \
# 	verilator_top.v \
# )

# $(addprefix $(V_TEST_DIR)/, \
# vscale_sim_top.v \
# vscale_dp_hasti_sram.v \
# )

# VCS_TOP = $(V_TEST_DIR)/vscale_hex_tb.v

VERILATOR_CPP_TB = $(CXX_TEST_DIR)/verilator_top.cpp

VERILATOR_TOP = $(V_SRC_DIR)/verilator_top.v

# HDRS = $(addprefix $(V_SRC_DIR)/, \
# vscale_ctrl_constants.vh \
# rv32_opcodes.vh \
# vscale_alu_ops.vh \
# vscale_md_constants.vh \
# vscale_hasti_constants.vh \
# vscale_csr_addr_map.vh \
# vscale_multicore_constants.vh \
# )

# TEST_VPD_FILES = $(addprefix $(OUT_DIR)/,$(addsuffix .vpd,$(RV32_TESTS)))

# VERILATOR_VCD_FILES = $(addprefix $(OUT_DIR)/,$(addsuffix .verilator.vcd,$(RV32_TESTS)))

# default: $(SIM_DIR)/simv

# run-asm-tests: $(TEST_VPD_FILES)

verilator-sim: $(SIM_DIR)/Vverilator_top

# verilator-run-asm-tests: $(VERILATOR_VCD_FILES)

# $(OUT_DIR)/%.vpd: $(MEM_DIR)/%.hex $(SIM_DIR)/simv
# 	mkdir -p output
# 	$(SIM_DIR)/simv $(SIMV_OPTS) +max-cycles=$(MAX_CYCLES) +loadmem=$< +vpdfile=$@ && [ $$PIPESTATUS -eq 0 ]

$(OUT_DIR)/%.verilator.vcd: $(MEM_DIR)/%.hex $(SIM_DIR)/Vverilator_top
	mkdir -p output
	$(SIM_DIR)/Vverilator_top +max-cycles=$(MAX_CYCLES) +loadmem=$< --vcdfile=$@ && [ $$PIPESTATUS -eq 0 ]

$(SIM_DIR)/simv: $(VCS_TOP) $(SIM_SRCS) $(DESIGN_SRCS) $(HDRS)
	mkdir -p sim
	$(VCS) $(VCS_OPTS) -o $@ $(VCS_TOP) $(SIM_SRCS) $(DESIGN_SRCS)

$(SIM_DIR)/Vverilator_top: $(VERILATOR_TOP) $(SIM_SRCS) $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(VERILATOR_TOP) $(SIM_SRCS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vverilator_top.mk Vverilator_top__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vverilator_top.mk Vverilator_top

test1: verilator-sim
	./run.sh output/test-1-out.verilator.vcd

clean:
	rm -rf $(SIM_DIR)/* $(OUT_DIR)/*

.PHONY: clean run-asm-tests verilator-run-asm-tests
