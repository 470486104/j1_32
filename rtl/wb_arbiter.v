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

	
	/* (* KEEP="TRUE" *)reg[`CpuNumWidth] queue[0:7];
	(* KEEP="TRUE" *)reg[2:0] first, last, _last;
	reg[`CpuNumWidth] new_cpu;
	
	reg cpu0_on,cpu0_off,cpu0_flag;
	reg[2:0] cpu0_last;
	
	reg cpu1_on,cpu1_off,cpu1_flag;
	reg[2:0] cpu1_last;
	
	reg cpu2_on,cpu2_off,cpu2_flag;
	reg[2:0] cpu2_last;
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			cpu0_off <= 0;
			cpu1_off <= 0;
			cpu2_off <= 0;
		end else
		begin
			if(cpu0_on)
			begin
				queue[cpu0_last] <= cpu0_num;
				cpu0_off <= 1;
			end else if(!cpu0_cyc_o)
				cpu0_off <= 0;
			
			if(cpu1_on)
			begin
				queue[cpu1_last] <= cpu1_num;
				cpu1_off <= 1;
			end else if(!cpu1_cyc_o)
				cpu1_off <= 0;
				
			if(cpu2_on)
			begin
				queue[cpu2_last] <= cpu2_num;
				cpu2_off <= 1;
			end else if(!cpu2_cyc_o)
				cpu2_off <= 0;
		end 
	end
	
	always @(*)
	begin
		if(rst)
		begin
			_last = 0;
			
			cpu0_flag = 1;
			cpu0_last = 0;
			cpu0_on = 0;
			
			cpu1_flag = 1;
			cpu1_last = 0;
			cpu1_on = 0;
			
			cpu2_flag = 1;
			cpu2_last = 0;
			cpu2_on = 0;
		end else 
		begin
			if(cpu0_cyc_o)
			begin
				if(cpu0_off)
						cpu0_on = 0;
					else
						cpu0_on = 1;
				if(cpu0_flag)
				begin
					cpu0_last = _last;
					_last = _last + 1;
				end
				// else
					// cpu0_last = 0;
				cpu0_flag = 0;
			end else
			begin
				cpu0_flag = 1;
				cpu0_last = 0;
				cpu0_on = 0;
			end 
			
			if(cpu1_cyc_o)
			begin
				if(cpu1_off)
						cpu1_on = 0;
					else
						cpu1_on = 1;
				if(cpu1_flag)
				begin
					cpu1_last = _last;
					_last = _last + 1;
				end 
				// else
					// cpu1_last = 0;
				cpu1_flag = 0;
			end else
			begin
				cpu1_flag = 1;
				cpu1_last = 0;
				cpu1_on = 0;
			end 
			
			if(cpu2_cyc_o)
			begin
				if(cpu2_off)
						cpu2_on = 0;
					else
						cpu2_on = 1;
				if(cpu2_flag)
				begin
					cpu2_last = _last;
					_last = _last + 1;
				end
				// else
					// cpu2_last = 0;
				cpu2_flag = 0;
			end else
			begin
				cpu2_flag = 1;
				cpu2_last = 0;
				cpu2_on = 0;
			end 
		end 
	end
	

	
	always @(posedge clk)
	begin
		if(rst)
		begin
			first <= 0;
			last <= 0;
			new_cpu <= 3;
		end else if(!wb_stb)
		begin
			if(first == last)
				new_cpu <= 3;
			else 
			begin
				new_cpu <= queue[first];
				first <= first + 1;
			end
			last <= _last;
		end else
		begin
			last <= _last;
			if(wb_ack)
				new_cpu <= 3;
		end 
	end 
	 */
	
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