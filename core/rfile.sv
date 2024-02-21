
module rfile #(
	XLEN=64,
	XWDT=6,
	XN=64,
	PARALLELACCESS=3
) (
	input [XWDT-1:0] rreads[PARALLELACCESS-1:0],
	output [XLEN-1:0] routs[PARALLELACCESS-1:0],
	input [XWDT-1:0] rwrites[PARALLELACCESS-1:0],
	input [XLEN-1:0] rins[PARALLELACCESS-1:0],
	input [1:0]	rwsizes[PARALLELACCESS-1:0],
	input [2:0]	rwposs[PARALLELACCESS-1:0],

	input we,
	input clk
);
	reg [XLEN-1:0] regs[XN-1:0];
	reg [XLEN-1:0] routs_r[PARALLELACCESS-1:0];
	assign routs = routs_r;

	generate
		genvar i;
		for (i = 0; i < PARALLELACCESS; i++ ) begin
			always @(posedge clk) begin
				if (we) begin
					case (rwsizes[i])
						'b00:
							regs[rwrites[i]][rwposs[i]*8+:8] <= rins[i][7:0];
						'b01:
							regs[rwrites[i]][rwposs[i]*16+:16] <= rins[i][15:0];
						'b10:
							regs[rwrites[i]][rwposs[i]*32+:32] <= rins[i][31:0];
						'b11:
							regs[rwrites[i]] <= rins[i]; 
						default: begin end
					endcase
					$strobe("WRITE DONE: %x <= %x", rwrites[i], regs[rwrites[i]]);
				end
				routs_r[i] <= regs[rreads[i]];
				$strobe("READ DONE: %x <= %x", routs_r[i], rreads[i]);
			end
		end
			
	endgenerate
endmodule
