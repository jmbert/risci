


module rlocks #(
	XWDT = 6,
	XN = 64
) (
	input [XWDT-1:0] rset,
	input [XWDT-1:0] rclear,
	output [XN-1:0] rlocks,

	input clk
);

	reg [XN-1:0] rlocks_stored;
	assign rlocks = rlocks_stored;

	always_ff @( clk ) begin
		rlocks_stored[rset] <= 1;
		rlocks_stored[rclear] <= 0;
	end

endmodule
