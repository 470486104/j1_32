`include "define.v"
`timescale 1ns / 1ps
module j1_top(
	input  		clk_in	,
	input  		rx		,
	output 		tx
);

	wire clk;
	wire rst;
	
	wire [`UartDataWidth]	uart_dout;
	wire					uart_rd	 ;
	wire					uart_wr	 ;
	wire					uart_addr;
	wire [`UartDataWidth]	uart_din ;
	
	// 时钟
	clock50 ck(.clk_in(clk_in), .clk_50(clk));
	
	// j1 多核cpu
	cpu_top cpu(
		.clk(clk),
		.rst(rst),
		
		.uart_dout(uart_dout),
	    .uart_rd  (uart_rd	), 
	    .uart_wr  (uart_wr	), 
	    .uart_addr(uart_addr),
	    .uart_din (uart_din )
	);

	// uart
	miniuart2 uart(
		.clk	  (clk),
		.rst      (rst),
		.rx		  (rx),
		.tx		  (tx),
		
		.io_rd	  (uart_rd),
		.io_wr	  (uart_wr),
		.io_addr  (uart_addr),
		.io_din   (uart_din),
		.io_dout  (uart_dout)
	);
	

	// 复位信号
	reg[4-1:0] count = 4'b1111;
	always @(posedge clk)
	begin
		if(count > 1'b0)
			count <= count - 1'b1;
	end
	assign rst = count > 0 ? 1'b1 : 1'b0 ;
	
endmodule