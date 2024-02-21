

module mmu #(
	VLEN=64,
	PLEN=64,
	DLEN=64,
	ILEN=32
) (
	// To Core
	input [VLEN-1:0] iaddr,
	output [ILEN-1:0] iin,

	input [VLEN-1:0] daddr,
	output [DLEN-1:0] din,
	input [DLEN-1:0] dout,
	input [1:0] dlen,
	input we,
	input re,

	// To RAM

	output [PLEN-1:0] paddr,
	input [DLEN-1:0]din_back,
	output [DLEN-1:0]dout_ram,

	output [PLEN-1:0] iaddr_ram,
	input [ILEN-1:0] iin_back,

	output [1:0] dlen_ram,
	output we_ram,
	output re_ram
);

	assign re_ram = re;
	assign we_ram = we;

	// Address translation
	reg [PLEN-1:0] addr_translated;
	assign paddr = addr_translated;

	reg [PLEN-1:0] iaddr_translated;
	assign iaddr_ram = iaddr_translated;

	always begin
		// TODO - Virtual Memory here
		addr_translated = daddr;
		iaddr_translated = iaddr;
	end
	
	// Correct endianness
	
	reg [DLEN-1:0] din_back_corrected;
	assign din = din_back_corrected;

	reg [ILEN-1:0] iin_back_corrected;
	assign iin = iin_back_corrected;

	reg [DLEN-1:0] dout_corrected;
	assign dout_ram = dout_corrected;


	always begin
		// Instruction
		iin_back_corrected[7:0] = 	iin_back[31:24];
		iin_back_corrected[15:8] = 	iin_back[23:16];
		iin_back_corrected[23:16] = 	iin_back[15:8];
		iin_back_corrected[31:24] = 	iin_back[7:0];

		// Data out
		dout_corrected[7:0] = 	dout[63:56];
		dout_corrected[15:8] = 	dout[55:48];
		dout_corrected[23:16] = dout[47:40];
		dout_corrected[31:24] = dout[39:32];
		dout_corrected[39:32] = dout[31:24];
		dout_corrected[47:40] = dout[23:16];
		dout_corrected[55:48] = dout[15:8];
		dout_corrected[63:56] = dout[7:0];

		// Data in
		din_back_corrected[7:0] =	din_back[63:56];
		din_back_corrected[15:8] =	din_back[55:48];
		din_back_corrected[23:16] = 	din_back[47:40];
		din_back_corrected[31:24] = 	din_back[39:32];
		din_back_corrected[39:32] = 	din_back[31:24];
		din_back_corrected[47:40] = 	din_back[23:16];
		din_back_corrected[55:48] = 	din_back[15:8];
		din_back_corrected[63:56] = 	din_back[7:0];

	end

endmodule
