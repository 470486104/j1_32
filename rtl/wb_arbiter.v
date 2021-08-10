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
	output wire  [`DataWidth]	cpu0_dat_i	,
	output wire 				cpu0_ack_i	
	
	
);

	
	
	(* KEEP="TRUE" *)reg[`CpuNumWidth] queue[0:7];
	(* KEEP="TRUE" *)reg[2:0] first, last, _last, cpu0_last;
	reg[`CpuNumWidth] new_cpu;
	reg cpu0_on,cpu0_off,cpu0_flag;
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			cpu0_off <= 0;
		end else
		begin
			if(cpu0_on)
			begin
				queue[cpu0_last] <= cpu0_num;
				cpu0_off <= 1;
			end else if(!cpu0_cyc_o)
				cpu0_off <= 0;
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
				end else
					cpu0_last = 0;
				cpu0_flag = 0;
			end else
			begin
				cpu0_flag = 1;
				cpu0_last = 0;
				cpu0_on = 0;
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
	
	// ÖÙ²ÃÆ÷
	(* KEEP="TRUE" *)reg cpu_sel[`CpuSelWidth];
	
	always @(new_cpu)
	begin
		case(new_cpu)
			2'b00 : begin cpu_sel[0] = 1'b1;	cpu_sel[1] = 0;	cpu_sel[2] = 0;	end
			2'b01 : begin cpu_sel[0] = 1'b0;	cpu_sel[1] = 1;	cpu_sel[2] = 0;	end
			2'b10 : begin cpu_sel[0] = 1'b0;	cpu_sel[1] = 0;	cpu_sel[2] = 1;	end
			default : begin	cpu_sel[0] = 0;		cpu_sel[1] = 0;	cpu_sel[2] = 0;	end
		endcase
	end 
	
	assign wb_cyc	= cpu0_cyc_o & cpu_sel[0]		 			;
	assign wb_dat_i = cpu0_dat_o & {`DataWordLength{cpu_sel[0]}};
	assign wb_adr	= cpu0_adr_o & {`DataWordLength{cpu_sel[0]}};
	assign wb_we 	= cpu0_we_o  & cpu_sel[0]		 			;
	assign wb_stb	= cpu_sel[0]		 			;
	
	assign cpu0_dat_i = wb_dat_o & {`DataWordLength{cpu_sel[0]}};
	assign cpu0_ack_i = wb_ack   & cpu_sel[0]		 			;
	
endmodule