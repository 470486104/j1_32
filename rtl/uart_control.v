`include "define.v"
module uart_control(
	input clk,
	input rst,
	
	input  wire [`UartDataWidth]	uart_dout		,
	output wire						uart_rd			,
	output wire						uart_wr			,
	output wire						uart_addr		,
	output wire [`UartDataWidth]	uart_din		,
	
	input  wire [`CpuNumWidth]		cpu_uart_num	,
	
	input  wire [`CpuNumWidth]		cpu0_num		,
	input  wire [`UartDataWidth]	cpu0_uart_dat_o	,
	input  wire						cpu0_uart_rd_o	,
	input  wire						cpu0_uart_wr_o	,
	input  wire						cpu0_uart_adr_o	,
	output wire [`UartDataWidth]	cpu0_uart_dat_i	,
	
	input  wire [`CpuNumWidth]		cpu1_num		,
	input  wire [`UartDataWidth]	cpu1_uart_dat_o	,
	input  wire						cpu1_uart_rd_o	,
	input  wire						cpu1_uart_wr_o	,
	input  wire						cpu1_uart_adr_o	,
	output wire [`UartDataWidth]	cpu1_uart_dat_i	,
	
	input  wire [`CpuNumWidth]		cpu2_num		,
	input  wire [`UartDataWidth]	cpu2_uart_dat_o	,
	input  wire						cpu2_uart_rd_o	,
	input  wire						cpu2_uart_wr_o	,
	input  wire						cpu2_uart_adr_o	,
	output wire [`UartDataWidth]	cpu2_uart_dat_i	

);




	(* KEEP="TRUE" *)reg cpu_sel[`CpuSelWidth];
	always @(posedge clk)
	begin
		case(cpu_uart_num)
			2'b00 : begin cpu_sel[0] <= 1; cpu_sel[1] <= 0; cpu_sel[2] <= 0; end
			2'b01 : begin cpu_sel[0] <= 0; cpu_sel[1] <= 1; cpu_sel[2] <= 0; end
			2'b10 : begin cpu_sel[0] <= 0; cpu_sel[1] <= 0; cpu_sel[2] <= 1; end
			default : begin cpu_sel[0] <= 0; cpu_sel[1] <= 0; cpu_sel[2] <= 0; end
		endcase
	end  
	
	assign uart_rd	=	(cpu0_uart_rd_o & cpu_sel[0]) | 
						(cpu1_uart_rd_o & cpu_sel[1]) | 
						(cpu2_uart_rd_o & cpu_sel[2]);
						
	assign uart_wr	=	(cpu0_uart_wr_o & cpu_sel[0]) | 
						(cpu1_uart_wr_o & cpu_sel[1]) | 
						(cpu2_uart_wr_o & cpu_sel[2]);
						
	assign uart_addr =	(cpu0_uart_adr_o & cpu_sel[0]) | 
						(cpu1_uart_adr_o & cpu_sel[1]) | 
						(cpu2_uart_adr_o & cpu_sel[2]);
						
	assign uart_din  =	(cpu0_uart_dat_o & {`UartDataLengh{cpu_sel[0]}}) | 
						(cpu1_uart_dat_o & {`UartDataLengh{cpu_sel[1]}}) | 
						(cpu2_uart_dat_o & {`UartDataLengh{cpu_sel[2]}});

	
	assign cpu0_uart_dat_i = uart_dout & {`UartDataLengh{cpu_sel[0]}};
	assign cpu1_uart_dat_i = uart_dout & {`UartDataLengh{cpu_sel[1]}};
	assign cpu2_uart_dat_i = uart_dout & {`UartDataLengh{cpu_sel[2]}};
	
endmodule