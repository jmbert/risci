`include "core/rfile.sv"
`include "core/rlocks.sv"

`define VLEN 64
`define DLEN 64

`define ILEN 32

`define XLEN 64
`define XWDT 6
`define XN 64
`define IMMLEN 16

`define U_FORMAT		3'b000
`define R_FORMAT 		3'b001
`define I_FORMAT 		3'b010
`define S_FORMAT 		3'b011
`define B_FORMAT		3'b100

`define NOP_MAJOR 		5'b00000

`define LOAD_MAJOR 		5'b00001
`define INT_A_MAJOR 		5'b00010

`define LOAD_IMMEDIATE_MAJOR 	5'b00001

`define STORE_MAJOR 		5'b00001

`define BRANCH_MAJOR		5'b00001

`define PARALLELACCESS 3

module risci_core (
	output [`VLEN-1:0] iaddr,
	input [`ILEN-1:0] iin,

	output [`VLEN-1:0] daddr,
	input [`DLEN-1:0] din,
	output [`DLEN-1:0] dout,
	output [1:0] dlen,
	output we,
	output re,


	input rst,
	input hlt,

	input clk
);
	reg [`VLEN-1:0] addr;
	reg [`VLEN-1:0] pc;

	reg m_re;
	reg m_we;

	reg [`DLEN-1:0] datain;
	reg [`DLEN-1:0] dataout;
	reg [1:0] datalen;

	assign dlen = datalen;
	assign dout = dataout;
	assign daddr = addr;
	assign iaddr = pc;
	assign re = m_re;
	assign we = m_we;

	always @(din) begin
		datain <= din;
	end


	reg [`XWDT-1:0] rreads[`PARALLELACCESS-1:0];
	reg [`XLEN-1:0] routs[`PARALLELACCESS-1:0];
	reg [`XWDT-1:0] rwrites[`PARALLELACCESS-1:0];
	reg [`XLEN-1:0] rins[`PARALLELACCESS-1:0];
	reg r_we;
	reg [1:0] rwsizes[`PARALLELACCESS-1:0];
	reg [2:0] rwposs[`PARALLELACCESS-1:0];

	rfile xregs (
		.rreads(rreads),
		.routs(routs),
		.rwrites(rwrites),
		.rins(rins),
		.we(r_we),
		.rwsizes(rwsizes),
		.rwposs(rwposs),
		.clk(clk)
	);


	reg [`XWDT-1:0] rset, rclear;
	reg [`XN-1:0] rlocks_stored;

	rlocks locks (
		.rset(rset),
		.rclear(rclear),
		.rlocks(rlocks_stored),

		.clk(clk)
	);

	/* Instruction Pipeline
	 *
	 * Each stage runs once every clock cycle in order, backwards from the writeback stage
	 * Each stage has a set of registers that describes the instruction it is working on
	 * After running, the stage forwards it's results to the next stage. This is why they are run backwards.
	*/


	reg [`ILEN-1:0] i_fetch, i_decode, i_execute, i_memaccess, i_writeback;
	reg fetch_stalled, decode_stalled, execute_stalled, memaccess_stalled, writeback_stalled;

	reg [`VLEN-1:0] ma_addr; /* Address to access, computed during execute */
	reg [`DLEN-1:0] e_result, ma_data, wb_data; /* Data for ma stage */

	/* Instruction Pipeline
	 *
	 */

	always @(posedge clk ) begin
		$strobe("FETCH: %x", i_fetch);
		$strobe("DECODE: %x", i_decode);
		$strobe("EXECUTE: %x", i_execute);
		$strobe("MEMACCESS: %x", i_memaccess);
		$strobe("WRITEBACK: %x", i_writeback);
	end

	always @(posedge clk) begin
		if (!fetch_stalled) begin // Fetch is receiving new values
			i_fetch <= iin;
		end

		if (!decode_stalled) begin // Decode is receiving new values
			if (!fetch_stalled) begin // Fetch is sending new values
				i_decode <= i_fetch;
			end else begin	// Fetch is stalled, load a NOP
				i_decode <= 0;
			end
		end

		if (!execute_stalled) begin // Execute is receiving new values
			if (!decode_stalled) begin // Decode is sending new values
				i_execute <= i_decode;
			end else begin	// Decode is stalled, load a NOP
				i_execute <= 0;
			end
		end

		if (!memaccess_stalled) begin 
			if (!execute_stalled) begin 
				i_memaccess <= i_execute;
				ma_data <= e_result;
			end else begin	
				i_memaccess <= 0;
			end
		end

		if (!writeback_stalled) begin 
			if (!memaccess_stalled) begin 
				i_writeback <= i_memaccess;
				wb_data <= ma_data;
			end else begin	// 
				i_writeback <= 0;
			end
		end
	end

	// Fetch
	always @(posedge clk) begin
		pc <= pc + 4;
	end

	// Decode
	always_comb begin
		decode_stalled = 0;
		fetch_stalled = 0;

		case (i_decode[2:0]) // Decoding varies by format
			`R_FORMAT: begin
				if (!rlocks_stored[i_decode[19:14]] && !rlocks_stored[i_decode[25:20]] && !rlocks_stored[i_decode[13:8]]) begin
					rreads[0] = i_decode[19:14]; // RS1
					rreads[1] = i_decode[25:20]; // RS2
					rset = i_decode[13:8];  // RD	
				end else begin
					decode_stalled = 1;
					fetch_stalled = 1;
				end
			end 
			`I_FORMAT: begin
				rset = i_decode[13:8];  // RD
			end
			`S_FORMAT: begin
				rset = 0;
				if (!rlocks_stored[i_decode[19:14]] && !rlocks_stored[i_decode[25:20]] && !rlocks_stored[i_decode[13:8]]) begin
					rreads[0] = i_decode[19:14]; // RS1
					rreads[1] = i_decode[25:20]; // RS2
					rreads[2] = i_decode[13:8]; // RS3
				end else begin
					decode_stalled = 1;
					fetch_stalled = 1;
				end
			end
			default: begin end // TODO - INVI Exception here
		endcase
	end

	// Execute
	always_comb begin
		case (i_execute[2:0]) // Vary by format
			`R_FORMAT: begin
				case (i_execute[7:3])
					`LOAD_MAJOR: begin
						ma_addr = routs[0] + (routs[1] * (1 << (i_execute[27:26])));
					end 
					`INT_A_MAJOR: begin
						e_result = routs[0] + routs[1];
					end
					default: begin end // TODO - INVI Exception here
				endcase
			end
			`I_FORMAT: begin
				case (i_execute[7:3])
					`LOAD_IMMEDIATE_MAJOR: begin
					end
					default: begin end // TODO - INVI Exception here
				endcase
			end 
			`S_FORMAT: begin
				case (i_execute[7:3])
					`STORE_MAJOR: begin
						ma_addr = routs[0] + (routs[1] * (1 << (i_execute[27:26])));
						e_result = routs[2];
					end 
					default: begin end // TODO - INVI Exception here
				endcase
			end
			default: begin end // TODO - INVI Exception here
		endcase
	end


	// Memory Access
	always_comb begin
		case (i_memaccess[2:0]) // Vary by format
			`R_FORMAT: begin
				case (i_memaccess[7:3])
					`LOAD_MAJOR: begin
						addr = ma_addr;
						m_re = 1;
					end 
					`INT_A_MAJOR: begin
						
					end
					default: begin end // TODO - INVI Exception here
				endcase
			end
			`I_FORMAT: begin
				case (i_memaccess[7:3])
					`LOAD_IMMEDIATE_MAJOR: begin end 
					default: begin end // TODO - INVI Exception here
				endcase
			end 
			`S_FORMAT: begin
				case (i_memaccess[7:3])
					`STORE_MAJOR: begin
						addr = ma_addr;
						dataout = ma_data;
						datalen = i_memaccess[27:26];
						m_we = 1;
					end 
					default: begin end // TODO - INVI Exception here
				endcase
			end
			default: begin end // TODO - INVI Exception here
		endcase
	end



	// Register Writeback
	always_comb begin
		r_we = 0;
		case (i_writeback[2:0]) // Vary by format
			`R_FORMAT: begin
				case (i_writeback[7:3])
					`LOAD_MAJOR: begin
						rwrites[0] = i_writeback[13:8]; 

						rins[0] = datain;

						rwposs[0] = i_writeback[30:28];
						rwsizes[0] = i_writeback[27:26];
						r_we = 1;
						
						rclear = i_writeback[13:8];
					end 
					`INT_A_MAJOR: begin
						rwrites[0] = i_writeback[13:8]; 

						rins[0] = wb_data;

						rwposs[0] = i_writeback[30:28];
						rwsizes[0] = i_writeback[27:26];
						r_we = 1;
						
						rclear = i_writeback[13:8];
					end
					default: begin end // TODO - INVI Exception here
				endcase
			end
			`I_FORMAT: begin
				case (i_writeback[7:3])
					`LOAD_IMMEDIATE_MAJOR: begin
						rwrites[0] = i_writeback[13:8]; 
						rins[0] = {48'b0, {i_writeback[31:16]}};
						rwposs[0] = {1'b0, i_writeback[15:14]};
						rwsizes[0] = 'b01; // 16 bits
						r_we = 1;

						rclear = i_writeback[13:8]; // Unlock RD
					end 
					default: begin end // TODO - INVI Exception here
				endcase
			end 
			`S_FORMAT: begin
				case (i_writeback[7:3])
					`STORE_MAJOR: begin
					end
					default: begin end // TODO - INVI Exception here
				endcase
			end
			default: begin end // TODO - INVI Exception here
		endcase
	end

endmodule

