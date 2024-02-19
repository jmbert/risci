
module rfile #(
	XLEN=64,
	XWDT=6,
	XN=64,
	PARALLELREAD=3,
	PARALLELWRITE=3
) (
	input [XWDT-1:0] rreads[PARALLELREAD-1:0],
	output [XLEN-1:0] routs[PARALLELREAD-1:0],
	input [XWDT-1:0] rwrites[PARALLELWRITE-1:0],
	input [XLEN-1:0] rins[PARALLELWRITE-1:0],
	input [1:0]	rwsizes[PARALLELWRITE-1:0],
	input [3:0]	rwposs[PARALLELWRITE-1:0],

	input we,
	input clk
);
	reg [XLEN-1:0] xregs[XN-1:0];
	reg [XLEN-1:0] routs_r[PARALLELREAD-1:0];
	assign routs = routs_r;

	generate
		genvar i;
		for (i = 0; i < PARALLELREAD; i++ ) begin
			always @(posedge clk)  begin
				if (i == 0) begin
					routs_r[i] = 0;
				end else begin
					routs_r[i] = xregs[rreads[i]];
				end
			end
		end
		for (i = 0; i < PARALLELWRITE; i++ ) begin
			always @(posedge clk) begin
				if (we) begin
					$write("R: %x = %x (%x) (%x)\n", rwrites[i], rins[i], rwposs[i], rwsizes[i]);
					xregs[rwrites[i]] = (rins[i] & ((1 << (8*(rwsizes[i]) + 8)) - 1)) // Isolate wanted bits
					 		    << (rwposs[i] * (8*(rwsizes[i])+8)); // Shift into position	
					$write("R DONE: %x = %x\n", rwrites[i], xregs[rwrites[i]]);
				end
			end
		end
			
	endgenerate

	always @(posedge clk) begin
		$write("X1: %x\n", xregs[1]);
	end
endmodule