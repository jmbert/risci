

module ram #(
	ALEN=64,
	DLEN=64,
	DLEN2=32,
	SIZE=1024
) (
	input [ALEN-1:0] addr1,
	input [ALEN-1:0] addr2,
	output [DLEN-1:0] out1,
	output [DLEN2-1:0] out2,

	input [DLEN-1:0] in,

	input [1:0] len,
	input we,
	input re,

	input clk
);
	reg [7:0] mem[SIZE-1:0];
	wire [9:0] addrreal1 = addr1[9:0];
	wire [9:0] addrreal2 = addr2[9:0];

	initial begin
		int fileID = $fopen("image.bin", "rb");
		$fread(mem, fileID);

	end

	always_comb begin
		out2[7:0] = mem[addrreal2];
		out2[15:8] = mem[addrreal2+1];
		out2[23:16] = mem[addrreal2+2];
		out2[31:24] = mem[addrreal2+3];
	end

	always_latch begin
		if (re) begin
			out1[7:0] = mem[addrreal1];
			out1[15:8] = mem[addrreal1+1];
			out1[23:16] = mem[addrreal1+2];
			out1[31:24] = mem[addrreal1+3];
			out1[39:32] = mem[addrreal1+4];
			out1[47:40] = mem[addrreal1+5];
			out1[55:48] = mem[addrreal1+6];
			out1[63:56] = mem[addrreal1+7];
			$strobe("READ: %x => %x", addrreal1, out1);
		end
	end

	always_latch begin
		if (we) begin
			mem[addrreal1] = in[63:56];
			if (len > 'b00) begin
				mem[addrreal1+1] = in[55:48];
				if (len > 'b01) begin
					mem[addrreal1+2] = in[47:40];
					mem[addrreal1+3] = in[39:32];
					if (len > 'b10) begin
						mem[addrreal1+4] = in[31:24];
						mem[addrreal1+5] = in[23:16];
						mem[addrreal1+6] = in[15:8];
						mem[addrreal1+7] = in[7:0];
					end
				end
			end
			$strobe("WRITE: %x => %x", in, addrreal1);
		end
	end
endmodule
