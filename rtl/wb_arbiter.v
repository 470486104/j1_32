`include "define.v"
module wb_arbiter(
	input clk		,
	input rst		,
	
	input  wire					wb_ack			,
	input  wire [`DataWidth]	wb_dat_o		,
	output wire 				wb_cyc			,
	output wire [`DataWidth]	wb_dat_i		,
	output wire [`DataWidth]	wb_adr			,
	output wire 				wb_we 			,
	output wire 				wb_stb			,
												
	input  wire [`DataWidth]	wb_inst_o		,
	input  wire					wb_inst_ack		,
	output wire 				wb_inst_cyc		,
	output wire 				wb_inst_stb		,
	output wire [`PcWidth]		wb_inst_pc		,
												
	input  wire [`CpuNumWidth]	cpu0_num  		,
	input  wire [`DataWidth]	cpu0_adr_o		,
	input  wire [`DataWidth]	cpu0_dat_o		,
	input  wire 				cpu0_we_o 		,
	input  wire 				cpu0_cyc_o		,
	output wire [`DataWidth]	cpu0_dat_i		,
	output wire 				cpu0_ack_i		,
	
	input  wire					cpu0_inst_cyc_o	,
	input  wire [`PcWidth]		cpu0_inst_pc_o	,
	output wire [`DataWidth]	cpu0_inst_i		,
	output wire					cpu0_inst_ack_i	,
	
	input  wire [`CpuNumWidth]	cpu1_num  		,
	input  wire [`DataWidth]	cpu1_adr_o		,
	input  wire [`DataWidth]	cpu1_dat_o		,
	input  wire 				cpu1_we_o 		,
	input  wire 				cpu1_cyc_o		,
	output wire [`DataWidth]	cpu1_dat_i		,
	output wire 				cpu1_ack_i		,
												
	input  wire					cpu1_inst_cyc_o	,
	input  wire [`PcWidth]		cpu1_inst_pc_o	,
	output wire [`DataWidth]	cpu1_inst_i		,
	output wire					cpu1_inst_ack_i	,												
												
	input  wire [`CpuNumWidth]	cpu2_num  		,
	input  wire [`DataWidth]	cpu2_adr_o		,
	input  wire [`DataWidth]	cpu2_dat_o		,
	input  wire 				cpu2_we_o 		,
	input  wire 				cpu2_cyc_o		,
	output wire [`DataWidth]	cpu2_dat_i		,
	output wire 				cpu2_ack_i		,
	
	input  wire					cpu2_inst_cyc_o	,
	input  wire [`PcWidth]		cpu2_inst_pc_o	,
	output wire [`DataWidth]	cpu2_inst_i		,
	output wire					cpu2_inst_ack_i	,
	
	input  wire [`DataWidth]	cpu0_inst		,
	output wire [`PcWidth]		cpu0_pc			,
	
	input  wire [`DataWidth]	cpu1_inst		,
	output wire [`PcWidth]		cpu1_pc			,
	
	input  wire [`DataWidth]	cpu2_inst		,
	output wire [`PcWidth]		cpu2_pc			
);

	
	reg[3:0] cpu_data_list;
	reg[`CpuNumWidth] sel_data, new_cpu_data;
	
	reg[3:0] cpu_inst_list;
	reg[`CpuNumWidth] sel_inst, new_cpu_inst;
	
	always @(*)
	begin
		if(rst)
			cpu_inst_list = 0;
		else 
		begin 
			if(cpu0_inst_cyc_o)
				cpu_inst_list = cpu_inst_list | 4'b0001;
			else
				cpu_inst_list = cpu_inst_list & 4'b0110;
				
			if(cpu1_inst_cyc_o)
				cpu_inst_list = cpu_inst_list | 4'b0010;
			else
				cpu_inst_list = cpu_inst_list & 4'b0101;
				
			if(cpu2_inst_cyc_o)
				cpu_inst_list = cpu_inst_list | 4'b0100;
			else
				cpu_inst_list = cpu_inst_list & 4'b0011;
		end
	end
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			sel_inst <= 0;
			new_cpu_inst <= 3;
		end else if(wb_inst_stb)
		begin
			if(wb_inst_ack)
				new_cpu_inst <= 3;
				
			if(!cpu_inst_list[sel_inst])
				sel_inst <= sel_inst + 1;
		end else 
		begin
			if(cpu_inst_list != 4'b0000)
			begin
				if(cpu_inst_list[sel_inst])
					new_cpu_inst <= sel_inst;
				sel_inst <= sel_inst + 1;
			end 
		end 
	end 
	
	always @(*)
	begin
		if(rst)
			cpu_data_list = 0;
		else 
		begin 
			if(cpu0_cyc_o)
				cpu_data_list = cpu_data_list | 4'b0001;
			else
				cpu_data_list = cpu_data_list & 4'b0110;
				
			if(cpu1_cyc_o)
				cpu_data_list = cpu_data_list | 4'b0010;
			else
				cpu_data_list = cpu_data_list & 4'b0101;
				
			if(cpu2_cyc_o)
				cpu_data_list = cpu_data_list | 4'b0100;
			else
				cpu_data_list = cpu_data_list & 4'b0011;
		end
	end
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			sel_data <= 0;
			new_cpu_data <= 3;
		end else if(wb_stb)
		begin
			if(wb_ack)
				new_cpu_data <= 3;
				
			if(!cpu_data_list[sel_data])
				sel_data <= sel_data + 1;
		end else 
		begin
			if(cpu_data_list != 4'b0000)
			begin
				if(cpu_data_list[sel_data])
					new_cpu_data <= sel_data;
				sel_data <= sel_data + 1;
			end 
		end 
	end 
	
	

	(* KEEP="TRUE" *)reg cpu_sel_data[`CpuSelWidth];
	(* KEEP="TRUE" *)reg cpu_sel_inst[`CpuSelWidth];
	
	always @(new_cpu_data)
	begin
		case(new_cpu_data)
			2'b00 : begin cpu_sel_data[1] = 0;	cpu_sel_data[2] = 0;	cpu_sel_data[0] = 1; end
			2'b01 : begin cpu_sel_data[0] = 0;	cpu_sel_data[2] = 0;	cpu_sel_data[1] = 1;	end
			2'b10 : begin cpu_sel_data[0] = 0;	cpu_sel_data[1] = 0;	cpu_sel_data[2] = 1;	end
			default : begin	cpu_sel_data[0] = 0;		cpu_sel_data[1] = 0;	cpu_sel_data[2] = 0;	end
		endcase
	end 
	
	always @(new_cpu_inst)
	begin
		case(new_cpu_inst)
			2'b00 : begin cpu_sel_inst[1] = 0;	cpu_sel_inst[2] = 0;	cpu_sel_inst[0] = 1; end
			2'b01 : begin cpu_sel_inst[0] = 0;	cpu_sel_inst[2] = 0;	cpu_sel_inst[1] = 1;	end
			2'b10 : begin cpu_sel_inst[0] = 0;	cpu_sel_inst[1] = 0;	cpu_sel_inst[2] = 1;	end
			default : begin	cpu_sel_inst[0] = 0;		cpu_sel_inst[1] = 0;	cpu_sel_inst[2] = 0;	end
		endcase
	end 
	
	assign wb_cyc	=	(cpu0_cyc_o & cpu_sel_data[0]) |
						(cpu1_cyc_o & cpu_sel_data[1]) |
						(cpu2_cyc_o & cpu_sel_data[2]);
						
	assign wb_dat_i =	(cpu0_dat_o & {`DataWordLength{cpu_sel_data[0]}}) |
						(cpu1_dat_o & {`DataWordLength{cpu_sel_data[1]}}) |
						(cpu2_dat_o & {`DataWordLength{cpu_sel_data[2]}});
						
	assign wb_adr	=	(cpu0_adr_o & {`DataWordLength{cpu_sel_data[0]}}) |
						(cpu1_adr_o & {`DataWordLength{cpu_sel_data[1]}}) |
						(cpu2_adr_o & {`DataWordLength{cpu_sel_data[2]}});
						
	assign wb_we 	=	(cpu0_we_o & cpu_sel_data[0]) |
						(cpu1_we_o & cpu_sel_data[1]) |
						(cpu2_we_o & cpu_sel_data[2]);
						
	assign wb_stb	=	(cpu_sel_data[0]) |
						(cpu_sel_data[1]) |
						(cpu_sel_data[2]);
	
	assign cpu0_dat_i = wb_dat_o & {`DataWordLength{cpu_sel_data[0]}};
	assign cpu1_dat_i = wb_dat_o & {`DataWordLength{cpu_sel_data[1]}};
	assign cpu2_dat_i = wb_dat_o & {`DataWordLength{cpu_sel_data[2]}};
	
	assign cpu0_ack_i = wb_ack & cpu_sel_data[0];
	assign cpu1_ack_i = wb_ack & cpu_sel_data[1];
	assign cpu2_ack_i = wb_ack & cpu_sel_data[2];
	
	assign wb_inst_cyc =	(cpu0_inst_cyc_o & cpu_sel_inst[0]) |
							(cpu1_inst_cyc_o & cpu_sel_inst[1]) |
							(cpu2_inst_cyc_o & cpu_sel_inst[2]);
	
	assign wb_inst_pc =		(cpu0_inst_pc_o & {`DataWordLength{cpu_sel_inst[0]}}) |
							(cpu1_inst_pc_o & {`DataWordLength{cpu_sel_inst[1]}}) |
							(cpu2_inst_pc_o & {`DataWordLength{cpu_sel_inst[2]}});
	
	assign wb_inst_stb = 	(cpu_sel_inst[0]) |
							(cpu_sel_inst[1]) |
							(cpu_sel_inst[2]);
	
	assign cpu0_inst_i = cpu_sel_inst[0] ? wb_inst_o : cpu0_inst;
	assign cpu1_inst_i = cpu_sel_inst[1] ? wb_inst_o : cpu1_inst;
	assign cpu2_inst_i = cpu_sel_inst[2] ? wb_inst_o : cpu2_inst;
	
	assign cpu0_pc = cpu0_inst_pc_o;
	assign cpu1_pc = cpu1_inst_pc_o;
	assign cpu2_pc = cpu2_inst_pc_o;
	
	assign cpu0_inst_ack_i = wb_inst_ack & cpu_sel_inst[0];
	assign cpu1_inst_ack_i = wb_inst_ack & cpu_sel_inst[1];
	assign cpu2_inst_ack_i = wb_inst_ack & cpu_sel_inst[2];
endmodule