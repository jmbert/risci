`include "core/risci_core.sv"
`include "soc/ram.sv"
`include "mmu/mmu.sv"

module risci ();
	reg clk;


  	initial begin
  	  clk = 0;
  	  forever begin 
		#5 clk = 1;
	  	$strobe("\n\nPOSEDGE @ %0t", $time());
		#5 clk = 0;
	  	$strobe("NEGEDGE @ %0t\n\n", $time());
	  end 
  	end

	mmu mmu1 (
		.iin(),
		.iaddr(core.iaddr),
		.din_back(ram1.out1),
		.iin_back(ram1.out2),
		.paddr(),
		.iaddr_ram(),
		.re_ram(),
		.we_ram(),
		.dout_ram(),
		.dlen_ram(),
		.din(),
		.dlen(core.dlen),
		.re(core.re),
		.we(core.we),
		.daddr(core.daddr),
		.dout(core.dout)
	);

	ram ram1 (
		.addr1(mmu1.paddr),
		.addr2(mmu1.iaddr_ram),
		.re(mmu1.re_ram),
		.we(mmu1.we_ram),
		.in(mmu1.dout_ram),
		.len(mmu1.dlen_ram),
		.out1(),
		.out2(),

		.clk(clk)
	);


	risci_core core (
		.clk (clk),

		.iaddr(),
		.iin (mmu1.iin),

		.daddr(),
		.din (mmu1.din),
		.dout(),

		.dlen(),
		.re(),
		.we(),


		.hlt (0),
		.rst (0)
	);
	
endmodule
