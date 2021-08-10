`include "define.v"
module cpu_top(
	input clk		,
	input rst		,
	
	input  wire [`UartDataWidth]	uart_dout,
	output wire						uart_rd	 ,
	output wire						uart_wr	 ,
	output wire						uart_addr,
	output wire [`UartDataWidth]	uart_din 
);

	wire [`DataWidth]	wb_dat_i	;
	wire 				wb_ack		;
	wire [`PcWidth]		wb_pc		;
	wire [`DataWidth]	wb_adr		;
	wire [`DataWidth]	wb_dat_o	;
	wire 				wb_we 		;
	wire 				wb_stb		;
	wire 				wb_cyc		;
	wire [`DataWidth]	wb_inst		;


	wire [`CpuNumWidth]	cpu_uart_num	;
	
	wire [`CpuNumWidth]		cpu0_num		;
	wire [`DataWidth]		cpu0_dat_i 		;
	wire 					cpu0_ack_i 		;
	wire [`DataWidth]		cpu0_inst_i		;
	wire [`DataWidth]		cpu0_adr_o 		;
	wire [`DataWidth]		cpu0_dat_o 		;
	wire 					cpu0_we_o  		;
	wire 					cpu0_cyc_o 		;
	wire [`PcWidth]			cpu0_pc_o  		;
	wire [`UartDataWidth]	cpu0_uart_dat_o	;
	wire					cpu0_uart_rd_o	;
	wire					cpu0_uart_wr_o	;
	wire 					cpu0_uart_adr_o	;
	wire [`UartDataWidth]	cpu0_uart_dat_i	;
	
	
	wb_ram ram(
		.clk	(clk),
		.rst	(rst),
		
		.dat_i  (wb_dat_i	),
		.cyc_i  (wb_cyc		),
		.stb_i  (wb_stb		),
		.adr_i  (wb_adr		),
		.we_i   (wb_we		),
		.ack_o  (wb_ack		),
		.dat_o  (wb_dat_o	),
		
		.cpu0_pc_i		(cpu0_pc_o		),
		.cpu0_inst_o 	(cpu0_inst_i	)
	); 
	
	uart_control uart_io(
		.clk	(clk),
		.rst	(rst),
		
		.uart_dout		(uart_dout		),
	    .uart_rd		(uart_rd		),
	    .uart_wr		(uart_wr		),
	    .uart_addr		(uart_addr		),
	    .uart_din		(uart_din		),
		
	    .cpu_uart_num   (cpu_uart_num   ),
	    .cpu0_num		(cpu0_num		),
	    .cpu0_uart_dat_o(cpu0_uart_dat_o),
	    .cpu0_uart_rd_o	(cpu0_uart_rd_o	),
	    .cpu0_uart_wr_o	(cpu0_uart_wr_o	),
	    .cpu0_uart_adr_o(cpu0_uart_adr_o),
	    .cpu0_uart_dat_i(cpu0_uart_dat_i)
	); 
	
	wb_arbiter arbiter(
		.clk		(clk),
		.rst		(rst),
		
		.wb_ack	    (wb_ack		),
		.wb_dat_o   (wb_dat_o	),
		.wb_cyc	    (wb_cyc		),
		.wb_dat_i   (wb_dat_i	),
		.wb_adr	    (wb_adr		),
		.wb_we 	    (wb_we		),
		.wb_stb	    (wb_stb		),
		
		.cpu0_num   (cpu0_num   ),
		.cpu0_adr_o (cpu0_adr_o ),
		.cpu0_dat_o (cpu0_dat_o ),
		.cpu0_we_o  (cpu0_we_o  ),
		.cpu0_cyc_o (cpu0_cyc_o ),
		.cpu0_dat_i (cpu0_dat_i ),
		.cpu0_ack_i (cpu0_ack_i )
	);
	
	wb_j1_cpu cpu0(
		.clk	(clk)		,
		.rst	(rst)		,
		.dat_i	(cpu0_dat_i ),
		.ack_i	(cpu0_ack_i ),
		.inst_i	(cpu0_inst_i),
		.cpu_num(cpu0_num	),
		.adr_o	(cpu0_adr_o ),
		.dat_o	(cpu0_dat_o ),
		.we_o	(cpu0_we_o  ),
		.cyc_o	(cpu0_cyc_o ),
		.pc_o	(cpu0_pc_o  ),
		
		.cpu_uart_dat_i	(cpu0_uart_dat_i),
		.cpu_uart_num	(cpu_uart_num	),
		.cpu_uart_dat_o	(cpu0_uart_dat_o),
		.cpu_uart_rd_o	(cpu0_uart_rd_o	),
		.cpu_uart_wr_o	(cpu0_uart_wr_o	),
		.cpu_uart_adr_o	(cpu0_uart_adr_o)
	); 
	
endmodule