
TOPMOD?=risci
TOPFILE?=risci.sv
CXX=gcc

VERILATOR?=verilator
NPROC=$(shell nproc)
VFLAGS= --compiler $(CXX) --assert --top $(TOPMOD) -j $(NPROC)


binary:
	$(VERILATOR) --binary $(TOPFILE) $(VFLAGS)
cc:
	$(VERILATOR) --cc $(TOPFILE) $(VFLAGS)