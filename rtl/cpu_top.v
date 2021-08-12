`include "define.v"
module cpu_top(
	input clk		,
	input rst		,
	input wire[1:0] key2		,
	
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
	
	wire [`CpuNumWidth]		cpu1_num		;
	wire [`DataWidth]		cpu1_dat_i 		;
	wire 					cpu1_ack_i 		;
	wire [`DataWidth]		cpu1_inst_i		;
	wire [`DataWidth]		cpu1_adr_o 		;
	wire [`DataWidth]		cpu1_dat_o 		;
	wire 					cpu1_we_o  		;
	wire 					cpu1_cyc_o 		;
	wire [`PcWidth]			cpu1_pc_o  		;
	wire [`UartDataWidth]	cpu1_uart_dat_o	;
	wire					cpu1_uart_rd_o	;
	wire					cpu1_uart_wr_o	;
	wire 					cpu1_uart_adr_o	;
	wire [`UartDataWidth]	cpu1_uart_dat_i	;
	
	wire [`CpuNumWidth]		cpu2_num		;
	wire [`DataWidth]		cpu2_dat_i 		;
	wire 					cpu2_ack_i 		;
	wire [`DataWidth]		cpu2_inst_i		;
	wire [`DataWidth]		cpu2_adr_o 		;
	wire [`DataWidth]		cpu2_dat_o 		;
	wire 					cpu2_we_o  		;
	wire 					cpu2_cyc_o 		;
	wire [`PcWidth]			cpu2_pc_o  		;
	wire [`UartDataWidth]	cpu2_uart_dat_o	;
	wire					cpu2_uart_rd_o	;
	wire					cpu2_uart_wr_o	;
	wire 					cpu2_uart_adr_o	;
	wire [`UartDataWidth]	cpu2_uart_dat_i	;
	
	
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
		.cpu0_inst_o 	(cpu0_inst_i	),
		
		.cpu1_pc_i		(cpu1_pc_o		),
		.cpu1_inst_o 	(cpu1_inst_i	),
		
		.cpu2_pc_i		(cpu2_pc_o		),
		.cpu2_inst_o 	(cpu2_inst_i	)
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
	    .cpu0_uart_dat_i(cpu0_uart_dat_i),
		
		.cpu1_num		(cpu1_num		),
	    .cpu1_uart_dat_o(cpu1_uart_dat_o),
	    .cpu1_uart_rd_o	(cpu1_uart_rd_o	),
	    .cpu1_uart_wr_o	(cpu1_uart_wr_o	),
	    .cpu1_uart_adr_o(cpu1_uart_adr_o),
	    .cpu1_uart_dat_i(cpu1_uart_dat_i),
		
		.cpu2_num		(cpu2_num		),
	    .cpu2_uart_dat_o(cpu2_uart_dat_o),
	    .cpu2_uart_rd_o	(cpu2_uart_rd_o	),
	    .cpu2_uart_wr_o	(cpu2_uart_wr_o	),
	    .cpu2_uart_adr_o(cpu2_uart_adr_o),
	    .cpu2_uart_dat_i(cpu2_uart_dat_i)
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
		.cpu0_ack_i (cpu0_ack_i ),
		
		.cpu1_num   (cpu1_num   ),
		.cpu1_adr_o (cpu1_adr_o ),
		.cpu1_dat_o (cpu1_dat_o ),
		.cpu1_we_o  (cpu1_we_o  ),
		.cpu1_cyc_o (cpu1_cyc_o ),
		.cpu1_dat_i (cpu1_dat_i ),
		.cpu1_ack_i (cpu1_ack_i ),
		
		.cpu2_num   (cpu2_num   ),
		.cpu2_adr_o (cpu2_adr_o ),
		.cpu2_dat_o (cpu2_dat_o ),
		.cpu2_we_o  (cpu2_we_o  ),
		.cpu2_cyc_o (cpu2_cyc_o ),
		.cpu2_dat_i (cpu2_dat_i ),
		.cpu2_ack_i (cpu2_ack_i )
	);
	
	wb_j1_cpu 
		#(.is_master(1), .num(0))
	cpu0(
		.clk	(clk)		,
		.rst	(rst)		,
		.key2	(key2)		,
		
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
	
	wb_j1_cpu 
		#(.is_master(0), .num(1))
	cpu1(
		.clk	(clk)		,
		.rst	(rst)		,
		.dat_i	(cpu1_dat_i ),
		.ack_i	(cpu1_ack_i ),
		.inst_i	(cpu1_inst_i),
		.cpu_num(cpu1_num	),
		.adr_o	(cpu1_adr_o ),
		.dat_o	(cpu1_dat_o ),
		.we_o	(cpu1_we_o  ),
		.cyc_o	(cpu1_cyc_o ),
		.pc_o	(cpu1_pc_o  ),
		
		.cpu_uart_dat_i	(cpu1_uart_dat_i),
		.cpu_uart_dat_o	(cpu1_uart_dat_o),
		.cpu_uart_rd_o	(cpu1_uart_rd_o	),
		.cpu_uart_wr_o	(cpu1_uart_wr_o	),
		.cpu_uart_adr_o	(cpu1_uart_adr_o)
	); 
	
	wb_j1_cpu 
		#(.is_master(0), .num(2))
	cpu2(
		.clk	(clk)		,
		.rst	(rst)		,
		.dat_i	(cpu2_dat_i ),
		.ack_i	(cpu2_ack_i ),
		.inst_i	(cpu2_inst_i),
		.cpu_num(cpu2_num	),
		.adr_o	(cpu2_adr_o ),
		.dat_o	(cpu2_dat_o ),
		.we_o	(cpu2_we_o  ),
		.cyc_o	(cpu2_cyc_o ),
		.pc_o	(cpu2_pc_o  ),
		
		.cpu_uart_dat_i	(cpu2_uart_dat_i),
		.cpu_uart_dat_o	(cpu2_uart_dat_o),
		.cpu_uart_rd_o	(cpu2_uart_rd_o	),
		.cpu_uart_wr_o	(cpu2_uart_wr_o	),
		.cpu_uart_adr_o	(cpu2_uart_adr_o)
	); 
endmodule