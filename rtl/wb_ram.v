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
	output wire [`DataWidth] 	dat_o		,
	
	input  wire 				inst_cyc_i	,
	input  wire 				inst_stb_i	,
	input  wire	[`PcWidth]		inst_pc		,
	output reg	[`DataWidth]	inst_o		,
	output reg					inst_ack_o	,
	
	input  wire [`PcWidth]		cpu0_pc_i	,
	output reg  [`DataWidth]	cpu0_inst_o	,
	
	input  wire [`PcWidth]		cpu1_pc_i	,
	output reg  [`DataWidth]	cpu1_inst_o	,
	
	input  wire [`PcWidth]		cpu2_pc_i	,
	output reg  [`DataWidth]	cpu2_inst_o	
);


	reg [`DataWidth] ram[`RamSize]; 
	// initial $readmemh(`ForthFile, ram);
	
	reg [`DataWidth] rom0[`RomSize]; 
	initial $readmemh(`ForthFile, rom0);
	
	reg [`DataWidth] rom1[`RomSize]; 
	initial $readmemh(`ForthFile, rom1);

	reg data_o_flag;
	wire data_vaild, inst_vaild;
	assign data_vaild = cyc_i & stb_i;
	assign inst_vaild = inst_cyc_i & inst_stb_i;
	
	reg [`DataWidth] rom0_data, ram_data;
	assign dat_o = data_o_flag ? rom0_data : ram_data;
	
	reg[`DataWidth] addr_ram, addr_rom;
	reg[`PcWidth] pc;
	always @(*)
	begin
		if(rst)
		begin
			addr_ram = 0;
			addr_rom = 0;
			pc = 0;
		end 
		else
		begin
			if(data_vaild && adr_i < 16'h1000)
			begin
				addr_ram = 0;
				addr_rom = adr_i[11:0];
			end else if(data_vaild && adr_i >= 16'h1000)
			begin
				addr_ram = adr_i - 16'h1000;
				addr_rom = 0;
			end 
				
			if(inst_vaild)
				pc = inst_pc < 16'h1000 ? inst_pc : inst_pc-16'h1000;
			else
				pc = 0;
		end 
	end 
	
	always @(posedge clk)
	begin
		if(data_vaild)
			if(we_i)
				ram[addr_ram] <= dat_i;
			else
				// ram_data <= ram[addr_ram] === 32'hxxxxxxxx ? 32'b0 : ram[addr_ram]; // 仿真
				ram_data <= ram[addr_ram]; // 综合
		if(inst_vaild)
			inst_o <= ram[pc];

	end
	
	
	always @(posedge clk)
	begin
		cpu0_inst_o <= rom0[cpu0_pc_i[11:0]];
		
		if(data_vaild)
			// rom0_data <= rom0[addr_rom] === 32'hxxxxxxxx ? 32'b0 : rom0[addr_rom];  // 仿真
			rom0_data <= rom0[addr_rom]; // 综合
	end
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			ack_o <= 0;
			inst_ack_o <= 0;
			data_o_flag <= 0;
		end	else
		begin
			if(data_vaild && adr_i < 16'h1000)
			begin
				ack_o <= 1;
				data_o_flag <= 1;
			end else if(data_vaild && adr_i >= 16'h1000)
			begin
				ack_o <= 1;
				data_o_flag <= 0;
			end else
			begin
				ack_o <= 0;
				data_o_flag <= 0;
			end 
			
			if(inst_vaild)
				inst_ack_o <= 1;
			else
				inst_ack_o <= 0;
		end 

	end 
	
	always @(posedge clk)
	begin
		cpu1_inst_o <= rom1[cpu1_pc_i[11:0]];
		cpu2_inst_o <= rom1[cpu2_pc_i[11:0]];
	end
	
	
endmodule