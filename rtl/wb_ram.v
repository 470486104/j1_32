`include "define.v"
module wb_ram(
	input				clk		,
	input				rst		,
	
	input  wire [`DataWidth]	dat_i		,
	input  wire 				cyc_i		,
	input  wire					stb_i		,
	input  wire [`DataWidth]	adr_i		,
	input  wire					we_i		,
	output reg					ack_o		,
	output reg  [`DataWidth] 	dat_o		,
	
	input  wire [`PcWidth]		cpu0_pc_i	,
	output reg  [`DataWidth]	cpu0_inst_o	,
	
	input  wire [`PcWidth]		cpu1_pc_i	,
	output reg  [`DataWidth]	cpu1_inst_o	,
	
	input  wire [`PcWidth]		cpu2_pc_i	,
	output reg  [`DataWidth]	cpu2_inst_o	
);


	reg [`DataWidth] ram[`RamSize]; 
	initial $readmemh(`ForthFile, ram);
	
	reg [`DataWidth] rom1[`RomSize]; 
	initial $readmemh(`ForthFile, rom1);

	wire vaild;
	assign vaild = cyc_i & stb_i;

	
	always @(posedge clk)
	begin
		if(vaild)
			if(we_i)
				ram[adr_i[`DataTransAddrBit]] <= dat_i;
			else
				// dat_o <= ram[adr_i[`DataTransAddrBit]] === 32'hxxxxxxxx ? 32'b0 : ram[adr_i[`DataTransAddrBit]]; // ·ÂÕæ
				dat_o <= ram[adr_i[`DataTransAddrBit]]; // ×ÛºÏ
		cpu0_inst_o <= ram[cpu0_pc_i];
	end
	
	always @(posedge clk)
	begin
		if(rst)
			ack_o <= 0;
		else if(vaild)
			ack_o <= 1;
		else
			ack_o <= 0;
	end 
	
	always @(posedge clk)
	begin
		cpu1_inst_o <= rom1[cpu1_pc_i];
		cpu2_inst_o <= rom1[cpu2_pc_i];
	end
	
	
endmodule