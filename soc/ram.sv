

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
	    	mem[7] =  8'b0001_010; 		// LIB X2, 0x0050
		mem[6] =  8'b00_000010;
		mem[5] =  8'b01010000;
		mem[4] =  8'b00000000;

	    	mem[11] =  8'b0001_010; 	// LIB X3, 0x0001
		mem[10] =  8'b00_000011;
		mem[9] =  8'b00000001;
		mem[8] =  8'b00000000;

	    	mem[15] = 8'b0001_010; 		// LIB X1, 0x0010
		mem[14] = 8'b00_000001;
		mem[13] =  8'b00010000;
		mem[12] =  8'b00000000;

	    	mem[19] = 8'b0001_011;		// SH X1, X2, X1
		mem[18] = 8'b10_000001;
		mem[17] = 8'b0001_0000;
		mem[16] = 8'b000001_00;

	    	mem[23] = 8'b0010_001;		// ADD X1, X1, X3
		mem[22] = 8'b01_000001;
		mem[21] = 8'b0011_0000;
		mem[20] = 8'b000010_00;
/*
	    	mem[27] = 8'b0001_100;		// BEQ X2, X0, -2
		mem[26] = 8'b00_1110_10;
		mem[25] = 8'b1111_0000;
		mem[24] = 8'b11111111;*/
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
		end
	end
endmodule
