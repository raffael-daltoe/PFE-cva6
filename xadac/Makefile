VERILATOR  = verilator
CXX        = g++
CXXFLAGS   = -Wall -O3
LDFLAGS    = -lverilated -lverilated_vcd_c

BUILD_DIR = ./build

AXI_DIR   = ../vendor/pulp-platform/axi
BHV_DIR   = ./bhv
RTL_DIR   = ./rtl

TOP = xadac_verilator

SV_INC = \
	$(AXI_DIR)/include

SV_SRC = \
	$(AXI_DIR)/src/axi_pkg.sv \
	$(AXI_DIR)/src/axi_intf.sv \
	$(RTL_DIR)/xadac_pkg.sv \
	$(RTL_DIR)/xadac_if.sv \
	$(RTL_DIR)/xadac_skid.sv \
	$(RTL_DIR)/xadac_vrf_phy.sv \
	$(RTL_DIR)/xadac_if_skid.sv \
	$(RTL_DIR)/xadac_mux.sv \
	$(RTL_DIR)/xadac_sink.sv \
	$(RTL_DIR)/xadac_vactv.sv \
	$(RTL_DIR)/xadac_vbias.sv \
	$(RTL_DIR)/xadac_vclobber.sv \
	$(RTL_DIR)/xadac_vload.sv \
	$(RTL_DIR)/xadac_vmacc.sv \
	$(RTL_DIR)/xadac_vrf.sv \
	$(RTL_DIR)/xadac.sv \
	$(RTL_DIR)/xadac_verilator.sv

C_INC = \
	$(BHV_DIR)

C_SRC = \
	$(BHV_DIR)/main.cpp

CFLAGS = \
	$(foreach dir, $(C_INC), -I../$(dir))

VFLAGS = \
	--exe --cc \
	--Wno-fatal \
	-Mdir $(BUILD_DIR) \
	-CFLAGS "$(CFLAGS)" \
	$(foreach dir, $(SV_INC), -I$(dir)) \
	--top $(TOP) \
	--trace

$(shell mkdir -p $(BUILD_DIR))

verilate: $(SRC)
	$(VERILATOR) $(SV_SRC) $(VFLAGS)

compile: $(SRC)
	$(VERILATOR) $(SV_SRC) $(C_SRC) $(VFLAGS) --build

run: compile
	$(BUILD_DIR)/V$(TOP)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: verilate compile run clean
