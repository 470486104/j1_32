`include "define.v"
module wb_arbiter(
	input clk		,
	input rst		,
	
	input  wire					wb_ack			,
	input  wire [`DataWidth]	wb_dat_o		,
	output wire 				wb_cyc			,
	output wire [`DataWidth]	wb_dat_i		,
	output wire [`PcWidth]		wb_adr			,
	output wire 				wb_we 			,
	output wire 				wb_stb			,
												
	input  wire [`DataWidth]	wb_inst_o		,
	input  wire					wb_inst_ack		,
	output wire 				wb_inst_cyc		,
	output wire 				wb_inst_stb		,
	output wire [`PcWidth]		wb_inst_pc		,
												
	// input  wire [`CpuNumWidth]	cpu0_num  		,
	input  wire [`PcWidth]		cpu0_adr_o		,
	input  wire [`DataWidth]	cpu0_dat_o		,
	input  wire 				cpu0_we_o 		,
	input  wire 				cpu0_cyc_o		,
	output wire [`DataWidth]	cpu0_dat_i		,
	output wire 				cpu0_ack_i		,
	
	input  wire					cpu0_inst_cyc_o	,
	input  wire [`PcWidth]		cpu0_inst_pc_o	,
	output wire [`DataWidth]	cpu0_inst_i		,
	output wire					cpu0_inst_ack_i	,
	
	// input  wire [`CpuNumWidth]	cpu1_num  		,
	input  wire [`PcWidth]		cpu1_adr_o		,
	input  wire [`DataWidth]	cpu1_dat_o		,
	input  wire 				cpu1_we_o 		,
	input  wire 				cpu1_cyc_o		,
	output wire [`DataWidth]	cpu1_dat_i		,
	output wire 				cpu1_ack_i		,
												
	input  wire					cpu1_inst_cyc_o	,
	input  wire [`PcWidth]		cpu1_inst_pc_o	,
	output wire [`DataWidth]	cpu1_inst_i		,
	output wire					cpu1_inst_ack_i	,												
												
	// input  wire [`CpuNumWidth]	cpu2_num  		,
	input  wire [`PcWidth]		cpu2_adr_o		,
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

	
	wire[3:0] cpu_data_list = {1'b0, cpu2_cyc_o, cpu1_cyc_o, cpu0_cyc_o};
	reg[`CpuNumWidth] sel_data, old_cpu_data;
	wire sel_data_flag;
	
	wire[3:0] cpu_inst_list = {1'b0, cpu2_inst_cyc_o, cpu1_inst_cyc_o, cpu0_inst_cyc_o};
	reg[`CpuNumWidth] sel_inst, old_cpu_inst;
	wire sel_inst_flag;
	
	// 指令线仲裁
	assign sel_inst_flag = (|cpu_inst_list) & !wb_inst_stb;
	
	always @(posedge clk)
	begin
		if(rst)
			sel_inst <= 3;
		else if(sel_inst_flag)
			case(old_cpu_inst)
				2'b00 : if(cpu_inst_list[1]) sel_inst <= 1; else if(cpu_inst_list[2]) sel_inst <= 2; else if(cpu_inst_list[0]) sel_inst <= 0; else sel_inst <= 3;
				2'b01 : if(cpu_inst_list[2]) sel_inst <= 2; else if(cpu_inst_list[0]) sel_inst <= 0; else if(cpu_inst_list[1]) sel_inst <= 1; else sel_inst <= 3;
				default : if(cpu_inst_list[0]) sel_inst <= 0; else if(cpu_inst_list[1]) sel_inst <= 1; else if(cpu_inst_list[2]) sel_inst <= 2; else sel_inst <= 3;
			endcase
		else if(wb_inst_ack)
			sel_inst <= 3;
	end
	
	always @(*)
	begin
		if(rst)
			old_cpu_inst = 3;
		else if(sel_inst != 3)
			old_cpu_inst = sel_inst ;
	end
	
	// 数据线仲裁
	assign sel_data_flag = (|cpu_data_list) & !wb_stb;
	
	always @(posedge clk)
	begin
		if(rst)
			sel_data <= 3;
		else if(sel_data_flag)
			case(old_cpu_data)
				2'b00 : if(cpu_data_list[1]) sel_data <= 1; else if(cpu_data_list[2]) sel_data <= 2; else if(cpu_data_list[0]) sel_data <= 0; else sel_data <= 3;
				2'b01 : if(cpu_data_list[2]) sel_data <= 2; else if(cpu_data_list[0]) sel_data <= 0; else if(cpu_data_list[1]) sel_data <= 1; else sel_data <= 3;
				default : if(cpu_data_list[0]) sel_data <= 0; else if(cpu_data_list[1]) sel_data <= 1; else if(cpu_data_list[2]) sel_data <= 2; else sel_data <= 3;
			endcase
		else if(wb_ack)
			sel_data <= 3;
	end
	
	always @(*)
	begin
		if(rst)
			old_cpu_data = 3;
		else if(sel_data != 3)
			old_cpu_data = sel_data ;
	end
	
	
	reg cpu_sel_data[`CpuSelWidth];
	reg cpu_sel_inst[`CpuSelWidth];
	
	always @(*)
	begin
		case(sel_data)
			2'b00 : begin cpu_sel_data[1] = 0;	cpu_sel_data[2] = 0;	cpu_sel_data[0] = 1;	end
			2'b01 : begin cpu_sel_data[0] = 0;	cpu_sel_data[2] = 0;	cpu_sel_data[1] = 1;	end
			2'b10 : begin cpu_sel_data[0] = 0;	cpu_sel_data[1] = 0;	cpu_sel_data[2] = 1;	end
			default : begin	cpu_sel_data[0] = 0;	cpu_sel_data[1] = 0;	cpu_sel_data[2] = 0;	end
		endcase
	end 
	
	always @(*)
	begin
		case(sel_inst)
			2'b00 : begin cpu_sel_inst[1] = 0;	cpu_sel_inst[2] = 0;	cpu_sel_inst[0] = 1;	end
			2'b01 : begin cpu_sel_inst[0] = 0;	cpu_sel_inst[2] = 0;	cpu_sel_inst[1] = 1;	end
			2'b10 : begin cpu_sel_inst[0] = 0;	cpu_sel_inst[1] = 0;	cpu_sel_inst[2] = 1;	end
			default : begin	cpu_sel_inst[0] = 0;	cpu_sel_inst[1] = 0;	cpu_sel_inst[2] = 0;	end
		endcase
	end 
	
 	assign wb_cyc	=	(cpu0_cyc_o & cpu_sel_data[0]) |
						(cpu1_cyc_o & cpu_sel_data[1]) |
						(cpu2_cyc_o & cpu_sel_data[2]);
						
	assign wb_dat_i =	(cpu0_dat_o & {`DataWordLength{cpu_sel_data[0]}}) |
						(cpu1_dat_o & {`DataWordLength{cpu_sel_data[1]}}) |
						(cpu2_dat_o & {`DataWordLength{cpu_sel_data[2]}});
						
	assign wb_adr	=	(cpu0_adr_o & {`PcWordLength{cpu_sel_data[0]}}) |
						(cpu1_adr_o & {`PcWordLength{cpu_sel_data[1]}}) |
						(cpu2_adr_o & {`PcWordLength{cpu_sel_data[2]}});
						
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
	
	assign wb_inst_pc =		(cpu0_inst_pc_o & {`PcWordLength{cpu_sel_inst[0]}}) |
							(cpu1_inst_pc_o & {`PcWordLength{cpu_sel_inst[1]}}) |
							(cpu2_inst_pc_o & {`PcWordLength{cpu_sel_inst[2]}});
	
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