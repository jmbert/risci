`include "core/rfile.sv"

`define VLEN 64
`define DLEN 64

`define ILEN 32

`define XLEN 64
`define XWDT 6
`define XN 1 << `XWDT
`define IMMLEN 16

`define RESERVED_MAJOR 		'b00000000
`define LOAD_MAJOR 		'b00000001
`define LOAD_IMMEDIATE_MAJOR 	'b00000010
`define STORE_MAJOR 		'b00000011

`define PARALLELREADS 3
`define PARALLELWRITES 3

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

	assign daddr = addr;

	reg [`VLEN-1:0] pc;
	assign iaddr = pc;

	reg m_re;
	assign re = m_re;
	reg m_we;
	assign we = m_we;


	reg [`XWDT-1:0] rreads[`PARALLELREADS-1:0];
	reg [`XLEN-1:0] routs[`PARALLELREADS-1:0];
	reg [`XWDT-1:0] rwrites[`PARALLELWRITES-1:0];
	reg [`XLEN-1:0] rins[`PARALLELWRITES-1:0];
	reg r_we;
	reg [1:0] rwsizes[`PARALLELWRITES-1:0];
	reg [3:0] rwposs[`PARALLELWRITES-1:0];


	

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

	reg [7:0] e_major;
	reg [1:0] e_minor2;
	reg [5:0] e_minor6;
	reg [`XWDT-1:0] e_rd;
	reg [`XWDT-1:0] e_rs1;
	reg [`XWDT-1:0] e_rs2;
	reg [`IMMLEN-1:0] e_imm;

	reg [7:0] ma_major;
	reg [`XWDT-1:0] ma_rd;
	reg [`IMMLEN-1:0] ma_imm;
	reg [5:0] ma_minor6;
	reg [1:0] ma_minor2;
	reg [`VLEN-1:0] ma_addr;

	reg [7:0] wb_major;
	reg [`XWDT-1:0] wb_rd;
	reg [`XLEN-1:0] wb_rs1;
	reg [`XLEN-1:0] wb_rs2;
	reg [`IMMLEN-1:0] wb_imm;
	reg [5:0] wb_minor6;
	reg [1:0] wb_minor2;


	reg can_forward_e, can_forward_ma, can_forward_wb;

	always @(posedge can_forward_e) begin
		// Decode and forward to execute stage
		e_major = iin[7:0];
		e_rd = iin[13:8];
		e_rs1 = iin[19:14];
		e_rs2 = iin[25:20];
		e_minor6 = iin[31:26];
		e_minor2 = iin[15:14];
		e_imm = iin[31:16];
		
		$write("DE MAJOR: %b\n", e_major);
		$write("%x => %x\n", pc, iin);
		pc = pc + 4;
		can_forward_e = 0;
	end

	always @(posedge can_forward_ma) begin
		// Execute
		$write("E MAJOR: %b\n", e_major);
		case (e_major)
			`LOAD_MAJOR: begin
				rreads[0] = e_rs1;
				rreads[1] = e_rs2;
			end
			`LOAD_IMMEDIATE_MAJOR: begin
				
			end

			default: begin end// TODO - exception support 
		endcase

		// Forward to MA stage

		ma_major = e_major;
		ma_minor2 = e_minor2;
		ma_rd = e_rd;
		ma_imm = e_imm;

		can_forward_e = 1;
		can_forward_ma = 0;
	end

	
	always @(posedge can_forward_wb) begin
		// Memory Access
		$write("MA MAJOR: %b\n", ma_major);
		case (ma_major)
			`LOAD_MAJOR: begin
				addr = routs[0] + (routs[1] * (1 << e_minor6[1:0]));
				m_re = 1;
			end
			`LOAD_IMMEDIATE_MAJOR: begin
				addr = routs[0] + (routs[1] * (1 << e_minor6[1:0]));
				
				m_we = 1;
			end

			default: begin end// TODO - exception support 
		endcase

		// Forward to writeback stage
		wb_major = ma_major;
		wb_minor2 = ma_minor2;
		wb_rd = ma_rd;
		wb_imm = ma_imm;

		can_forward_ma = 1;
		can_forward_wb = 0;
	end

	always @(posedge clk) begin
		r_we = 0;
		// Write back
		$write("WB MAJOR: %b\n", wb_major);
		case (wb_major)
			`LOAD_MAJOR: begin
				rwrites[2] = wb_rd;
				rwsizes[2] = wb_minor6[1:0];
				rwposs[2] = wb_minor6[5:2];
				rins[2] = din;
				m_re = 0;
			end
			`STORE_MAJOR: begin
				m_we = 0;
			end
			`LOAD_IMMEDIATE_MAJOR: begin
				
				rwrites[2] = wb_rd;
				rwsizes[2] = 'b01;
				rwposs[2][1:0] = wb_minor2;
				rins[2][15:0] = wb_imm;
				r_we = 1;
				$write("%x = %x\n", wb_rd, wb_imm);
			end

			default: begin 
			end// TODO - exception support 
		endcase
		can_forward_wb = 1;
	end
	
endmodule
