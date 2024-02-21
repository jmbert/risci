


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

	always_ff @( posedge clk ) begin
		if (rclear != 0) begin
			rlocks_stored[rclear] <= 0;
		end
		if (rset != 0) begin
			rlocks_stored[rset] <= 1;
		end

		$strobe("LOCKS: %b", rlocks_stored);
	end

endmodule
