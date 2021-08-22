`include "define.v"
module wb_arbiter(
	input clk		,
	input rst		,
	
	input  wire					wb_ack		,
	input  wire [`DataWidth]	wb_dat_o	,
	output wire 				wb_cyc		,
	output wire [`DataWidth]	wb_dat_i	,
	output wire [`DataWidth]	wb_adr		,
	output wire 				wb_we 		,
	output wire 				wb_stb		,
	
	input  wire [`CpuNumWidth]	cpu0_num  	,
	input  wire [`DataWidth]	cpu0_adr_o	,
	input  wire [`DataWidth]	cpu0_dat_o	,
	input  wire 				cpu0_we_o 	,
	input  wire 				cpu0_cyc_o	,
	output wire [`DataWidth]	cpu0_dat_i	,
	output wire 				cpu0_ack_i	,
	
	input  wire [`CpuNumWidth]	cpu1_num  	,
	input  wire [`DataWidth]	cpu1_adr_o	,
	input  wire [`DataWidth]	cpu1_dat_o	,
	input  wire 				cpu1_we_o 	,
	input  wire 				cpu1_cyc_o	,
	output wire [`DataWidth]	cpu1_dat_i	,
	output wire 				cpu1_ack_i	,
	
	input  wire [`CpuNumWidth]	cpu2_num  	,
	input  wire [`DataWidth]	cpu2_adr_o	,
	input  wire [`DataWidth]	cpu2_dat_o	,
	input  wire 				cpu2_we_o 	,
	input  wire 				cpu2_cyc_o	,
	output wire [`DataWidth]	cpu2_dat_i	,
	output wire 				cpu2_ack_i	

);

	
	
	reg[3:0] cpu_ram_list;
	reg[`CpuNumWidth] sel, new_cpu;
	
	always @(*)
	begin
		if(rst)
			cpu_ram_list = 0;
		else 
		begin 
			if(cpu0_cyc_o)
				cpu_ram_list = cpu_ram_list | 3'b0001;
			else
				cpu_ram_list = cpu_ram_list & 3'b0110;
				
			if(cpu1_cyc_o)
				cpu_ram_list = cpu_ram_list | 3'b0010;
			else
				cpu_ram_list = cpu_ram_list & 3'b0101;
				
			if(cpu2_cyc_o)
				cpu_ram_list = cpu_ram_list | 3'b0100;
			else
				cpu_ram_list = cpu_ram_list & 3'b0011;
		end
	end
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			sel <= 0;
			new_cpu <= 0;
		end else if(wb_stb)
		begin
			if(wb_ack)
				new_cpu <= 3;
				
			if(!cpu_ram_list[sel])
				sel <= sel + 1;
		end else 
		begin
			if(cpu_ram_list != 3'b000)
			begin
				if(cpu_ram_list[sel])
					new_cpu <= sel;
				sel <= sel + 1;
			end 
		end 
	end 
	
	
	// ÖÙ²ÃÆ÷
	(* KEEP="TRUE" *)reg cpu_sel[`CpuSelWidth];
	
	always @(new_cpu)
	begin
		case(new_cpu)
			2'b00 : begin cpu_sel[1] = 0;	cpu_sel[2] = 0;	cpu_sel[0] = 1; end
			2'b01 : begin cpu_sel[0] = 0;	cpu_sel[2] = 0;	cpu_sel[1] = 1;	end
			2'b10 : begin cpu_sel[0] = 0;	cpu_sel[1] = 0;	cpu_sel[2] = 1;	end
			default : begin	cpu_sel[0] = 0;		cpu_sel[1] = 0;	cpu_sel[2] = 0;	end
		endcase
	end 
	
	assign wb_cyc	=	(cpu0_cyc_o & cpu_sel[0]) |
						(cpu1_cyc_o & cpu_sel[1]) |
						(cpu2_cyc_o & cpu_sel[2]);
						
	assign wb_dat_i =	(cpu0_dat_o & {`DataWordLength{cpu_sel[0]}}) |
						(cpu1_dat_o & {`DataWordLength{cpu_sel[1]}}) |
						(cpu2_dat_o & {`DataWordLength{cpu_sel[2]}});
						
	assign wb_adr	=	(cpu0_adr_o & {`DataWordLength{cpu_sel[0]}}) |
						(cpu1_adr_o & {`DataWordLength{cpu_sel[1]}}) |
						(cpu2_adr_o & {`DataWordLength{cpu_sel[2]}});
						
	assign wb_we 	=	(cpu0_we_o & cpu_sel[0]) |
						(cpu1_we_o & cpu_sel[1]) |
						(cpu2_we_o & cpu_sel[2]);
						
	assign wb_stb	=	(cpu_sel[0]) |
						(cpu_sel[1]) |
						(cpu_sel[2]);
	
	assign cpu0_dat_i = wb_dat_o & {`DataWordLength{cpu_sel[0]}};
	assign cpu1_dat_i = wb_dat_o & {`DataWordLength{cpu_sel[1]}};
	assign cpu2_dat_i = wb_dat_o & {`DataWordLength{cpu_sel[2]}};
	
	assign cpu0_ack_i = wb_ack & cpu_sel[0];
	assign cpu1_ack_i = wb_ack & cpu_sel[1];
	assign cpu2_ack_i = wb_ack & cpu_sel[2];
	
	
endmodule