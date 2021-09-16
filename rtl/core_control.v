`include "define.v"
module core_control(
	input clk		,
	input rst		,	
	
	input wire 					cpu0_control	,
	input wire [`CpuNumWidth]	start_cpu_num   ,
	input wire [`PcWidth]		cpu_start_adr   ,
	
	input wire					cpu1_end		,
	input wire					cpu2_end		,
	
	output reg					cpu1_start		,
	output reg [`PcWidth]		cpu1_start_adr	,
	output reg					cpu2_start		,
	output reg [`PcWidth]		cpu2_start_adr	,
	
	output reg[`CpuSelWidth] 	core_state
);
	
	reg cpu1_state, cpu2_state;
	
	always @(*)
	begin
		if(rst)
		begin
			cpu1_start = 0; 
			cpu1_start_adr = 0; 
			cpu2_start = 0; 
			cpu2_start_adr = 0;
		end else if(cpu0_control)
		begin
			case(start_cpu_num)
				2'b01 : begin cpu1_start_adr = cpu_start_adr; cpu1_start = 1; cpu2_start = 0; cpu2_start_adr = 0; end
				2'b10 : begin cpu1_start = 0; cpu1_start_adr = 0; cpu2_start_adr = cpu_start_adr; cpu2_start = 1; end
				default : begin cpu1_start = 0; cpu1_start_adr = 0; cpu2_start = 0; cpu2_start_adr = 0; end
			endcase
		end else
		begin
			cpu1_start = 0; 
			cpu1_start_adr = 0; 
			cpu2_start = 0; 
			cpu2_start_adr = 0;
		end 
	end
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			cpu1_state <= 0;
			cpu2_state <= 0;
		end else
		begin
			if(cpu1_start)
				cpu1_state <= 1;
			else if(cpu1_end)
				cpu1_state <= 0;
			
			if(cpu2_start)
				cpu2_state <= 1;
			else if(cpu2_end)
				cpu2_state <= 0;
		end 
	end 
	
	always @(*)
	begin
		if(rst)
			core_state = 0;
		else
		begin
			if(cpu1_state)
				core_state = core_state & 3'b100;
			else
				core_state = core_state | 3'b010;
			
			if(cpu2_state)
				core_state = core_state & 3'b010;
			else
				core_state = core_state | 3'b100;
		end 
		
	end
endmodule