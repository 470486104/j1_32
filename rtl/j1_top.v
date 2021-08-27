`include "define.v"
`timescale 1ns / 1ps
module j1_top(
	input  		clk_in	,
	input		rst_in	,
	input		key2	,
	input  		rx		,
	output 		tx
);

	wire clk;
	wire rst;
	
	reg[`CpuNumWidth] u_n;
	
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
		.key2(u_n),
		
		.uart_dout(uart_dout),
	    .uart_rd  (uart_rd	), 
	    .uart_wr  (uart_wr	), 
	    .uart_addr(uart_addr),
	    .uart_din (uart_din )
	);

	// uart
	miniuart2 uart1(
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
		if(rst_in)
			count <= 4'b1111;
		else if(count > 1'b0)
			count <= count - 1'b1;
	end
	assign rst = count > 0 ? 1'b1 : 1'b0 ;
	

	// 按键消抖
	parameter DURATION = 50_000_000;                           //延时10ms	
	reg [31:0] cnt; 
	
	reg ken_enable;
	// assign ken_enable = key2; //只要任意按键被按下，相应的按键进行消抖
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			ken_enable <= 0;
		end else if(key2 & !ken_enable)
		begin
			ken_enable <= key2;
		end else if(cnt == DURATION)
			ken_enable <= 0;
	end

	always @(posedge clk)
	begin
		if(rst)
			cnt <= 16'b0;
		else if(ken_enable == 1) begin
			if(cnt == DURATION)
				cnt <= cnt;
			else 
				cnt <= cnt + 1'b1;
			end
		else
			cnt <= 16'b0;
	end

	always @(posedge clk)
	begin
		if(rst)
			u_n <= 0;
		else if(cnt == 25)
			u_n <= u_n + 1;
	end
	
endmodule