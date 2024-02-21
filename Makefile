
TOPMOD?=risci
TOPFILE?=risci.sv
CXX=gcc

VERILATOR?=verilator
NPROC=$(shell nproc)
VFLAGS= -Wall -Wno-UNDRIVEN -Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL --compiler $(CXX) --assert --top $(TOPMOD) -j $(NPROC)


binary:
	$(VERILATOR) --binary $(TOPFILE) $(VFLAGS)
cc:
	$(VERILATOR) --cc $(TOPFILE) $(VFLAGS)