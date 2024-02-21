


module rlocks #(
	XWDT = 6,
	XN = 64
) (
	input [XWDT-1:0] rset,
	input [XWDT-1:0] rclear,
	output [XN-1:0] rlocks,

	input clk
);


	reg [5:0] rlocks_counted [XN-1:0] ;

	reg [XN-1:0] rlocks_stored;
	assign rlocks = rlocks_stored;

	always_ff @( posedge clk ) begin
		if (rclear != 0 && rlocks_counted[rclear] != 0) begin
			rlocks_counted[rclear] <= rlocks_counted[rclear] - 1;
			$strobe("Unlocking %x to level %x", rclear, rlocks_counted[rclear]);
		end
		if (rset != 0) begin
			rlocks_counted[rset] <= rlocks_counted[rset] + 1;
			$strobe("Locking %x to level %x", rset, rlocks_counted[rset]);
		end

		$strobe("LOCKS: %b", rlocks_stored);
	end

	generate
		genvar i;
		for (i = 0; i < XN ; i = i + 1) begin
			always_ff @(rlocks_counted[i]) begin
				rlocks_stored[i] = rlocks_counted[i] != 0;
			end
		end
	endgenerate

endmodule
