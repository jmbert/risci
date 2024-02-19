`include "core/risci_core.sv"
`include "soc/ram.sv"

module risci (

);
	reg clk;
	initial begin
	    clk = 0;
	    forever 
	         #5 clk = ~clk;
	end

	ram ram1 (
		.addr1(core.daddr),
		.addr2(core.iaddr),
		.re(core.re),
		.we(core.we),
		.in(core.dout),
		.len(core.dlen),
		.out1(),
		.out2(),

		.clk(clk)
	);

	risci_core core (
		.clk (clk),

		.iaddr(),
		.iin (ram1.out2),

		.daddr(),
		.din (ram1.out1),
		.dout(),

		.dlen(),
		.re(),
		.we(),


		.hlt (0),
		.rst (0)
	);
	always @(posedge clk ) begin
		$write("POSEDGE\n");
	end
	
endmodule
