`include "define.v"
module cpu_top(
	input clk		,
	input rst		,
	// input wire[1:0] key2		,
	
	input  wire [`UartDataWidth]	uart_dout,
	input  wire [`UartDataWidth]	uart_dout1,
	output wire						uart_rd	 ,
	output wire						uart_wr	 ,
	output wire	[1:0]				uart_addr,
	output wire [`UartDataWidth]	uart_din 
);

	wire [`DataWidth]	wb_dat_i		;
	wire 				wb_dat_ack		;
	wire [`PcWidth]		wb_dat_adr		;
	wire [`DataWidth]	wb_dat_o		;
	wire 				wb_dat_we 		;
	wire 				wb_dat_stb		;
	wire 				wb_dat_cyc		;
	
	wire 				wb_inst_cyc		;
	wire 				wb_inst_stb		;
	wire [`PcWidth]		wb_inst_pc		;
	wire [`DataWidth]	wb_inst_o		;
	wire 				wb_inst_ack		;
	
	wire [`CpuSelWidth] core_state      ;

	wire [`CpuNumWidth]	cpu_uart_num	;
	wire 				cpu0_control	;
	wire [`CpuNumWidth]	start_cpu_num   ;
	wire [`PcWidth]		cpu_start_adr   ;
	
	// wire [`CpuNumWidth]		cpu0_num		;
	wire [`DataWidth]		cpu0_dat_i 		;
	wire 					cpu0_ack_i 		;
	wire [`PcWidth]			cpu0_adr_o 		;
	wire [`DataWidth]		cpu0_dat_o 		;
	wire 					cpu0_we_o  		;
	wire 					cpu0_cyc_o 		;
	wire [`DataWidth]		cpu0_inst_i		;
	wire					cpu0_inst_ack_i	;
	wire					cpu0_inst_cyc_o	;
	wire [`PcWidth]			cpu0_inst_pc_o	;	
	wire [`UartDataWidth]	cpu0_uart_dat_o	;
	wire					cpu0_uart_rd_o	;
	wire					cpu0_uart_wr_o	;
	wire 					cpu0_uart_adr_o	;
	wire [`UartDataWidth]	cpu0_uart_dat_i	;
	
	wire					cpu1_end		;
	wire					cpu1_start		;
	wire [`PcWidth]			cpu1_start_adr	;
	// wire [`CpuNumWidth]		cpu1_num		;
	wire [`DataWidth]		cpu1_dat_i 		;
	wire 					cpu1_ack_i 		;
	wire [`PcWidth]			cpu1_adr_o 		;
	wire [`DataWidth]		cpu1_dat_o 		;
	wire 					cpu1_we_o  		;
	wire 					cpu1_cyc_o 		;
	wire [`DataWidth]		cpu1_inst_i		;
	wire					cpu1_inst_ack_i	;
	wire					cpu1_inst_cyc_o	;
	wire [`PcWidth]			cpu1_inst_pc_o	;	
	wire [`UartDataWidth]	cpu1_uart_dat_o	;
	wire					cpu1_uart_rd_o	;
	wire					cpu1_uart_wr_o	;
	wire 					cpu1_uart_adr_o	;
	wire [`UartDataWidth]	cpu1_uart_dat_i	;
	
	wire					cpu2_end		;
	wire					cpu2_start		;
	wire [`PcWidth]			cpu2_start_adr	;
	// wire [`CpuNumWidth]		cpu2_num		;
	wire [`DataWidth]		cpu2_dat_i 		;
	wire 					cpu2_ack_i 		;
	wire [`PcWidth]			cpu2_adr_o 		;
	wire [`DataWidth]		cpu2_dat_o 		;
	wire 					cpu2_we_o  		;
	wire 					cpu2_cyc_o 		;
	wire [`DataWidth]		cpu2_inst_i		;
	wire					cpu2_inst_ack_i	;
	wire					cpu2_inst_cyc_o	;
	wire [`PcWidth]			cpu2_inst_pc_o	;	
	wire [`UartDataWidth]	cpu2_uart_dat_o	;
	wire					cpu2_uart_rd_o	;
	wire					cpu2_uart_wr_o	;
	wire 					cpu2_uart_adr_o	;
	wire [`UartDataWidth]	cpu2_uart_dat_i	;
	
	wire [`PcWidth]		cpu0_pc	   ;
	wire [`DataWidth]	cpu0_inst  ;
	
	wire [`PcWidth]		cpu1_pc    ;
	wire [`DataWidth]	cpu1_inst  ;
	
	wire [`PcWidth]		cpu2_pc    ;
	wire [`DataWidth]	cpu2_inst  ;
	
	
	wb_ram ram(
		.clk	(clk),
		.rst	(rst),
		
		.dat_i  (wb_dat_i		),
		.cyc_i  (wb_dat_cyc		),
		.stb_i  (wb_dat_stb		),
		.adr_i  (wb_dat_adr		),
		.we_i   (wb_dat_we		),
		.ack_o  (wb_dat_ack		),
		.dat_o  (wb_dat_o		),
		
		.inst_cyc_i	(wb_inst_cyc),
		.inst_stb_i	(wb_inst_stb),
		.inst_pc	(wb_inst_pc	),	
		.inst_o		(wb_inst_o	),
		.inst_ack_o	(wb_inst_ack),
		
		.cpu0_pc_i		(cpu0_pc	),
		.cpu0_inst_o 	(cpu0_inst  ),
		                 
		.cpu1_pc_i		(cpu1_pc    ),
		.cpu1_inst_o 	(cpu1_inst  ),
		                 
		.cpu2_pc_i		(cpu2_pc    ),
		.cpu2_inst_o 	(cpu2_inst  )
	); 
	
	uart_control uart_io(
		.clk	(clk),
		.rst	(rst),
		
		.uart_dout		(uart_dout		),
		.uart_dout1		(uart_dout1		),
	    .uart_rd		(uart_rd		),
	    .uart_wr		(uart_wr		),
	    .uart_addr		(uart_addr		),
	    .uart_din		(uart_din		),
		
	    .cpu_uart_num   (cpu_uart_num   ),
		
	    // .cpu0_num		(cpu0_num		),
	    .cpu0_uart_dat_o(cpu0_uart_dat_o),
	    .cpu0_uart_rd_o	(cpu0_uart_rd_o	),
	    .cpu0_uart_wr_o	(cpu0_uart_wr_o	),
	    .cpu0_uart_adr_o(cpu0_uart_adr_o),
	    .cpu0_uart_dat_i(cpu0_uart_dat_i),
		
		// .cpu1_num		(cpu1_num		),
	    .cpu1_uart_dat_o(cpu1_uart_dat_o),
	    .cpu1_uart_rd_o	(cpu1_uart_rd_o	),
	    .cpu1_uart_wr_o	(cpu1_uart_wr_o	),
	    .cpu1_uart_adr_o(cpu1_uart_adr_o),
	    .cpu1_uart_dat_i(cpu1_uart_dat_i),
		
		// .cpu2_num		(cpu2_num		),
	    .cpu2_uart_dat_o(cpu2_uart_dat_o),
	    .cpu2_uart_rd_o	(cpu2_uart_rd_o	),
	    .cpu2_uart_wr_o	(cpu2_uart_wr_o	),
	    .cpu2_uart_adr_o(cpu2_uart_adr_o),
	    .cpu2_uart_dat_i(cpu2_uart_dat_i)
	); 
	
	wb_arbiter arbiter(
		.clk		(clk),
		.rst		(rst),
		
		.wb_ack	    (wb_dat_ack		),
		.wb_dat_o   (wb_dat_o		),
		.wb_cyc	    (wb_dat_cyc		),
		.wb_dat_i   (wb_dat_i		),
		.wb_adr	    (wb_dat_adr		),
		.wb_we 	    (wb_dat_we		),
		.wb_stb	    (wb_dat_stb		),
		
		.wb_inst_o	(wb_inst_o	),
		.wb_inst_ack(wb_inst_ack),	
		.wb_inst_cyc(wb_inst_cyc),	
		.wb_inst_stb(wb_inst_stb),	
		.wb_inst_pc	(wb_inst_pc	),
		
		// .cpu0_num   (cpu0_num   ),
		.cpu0_adr_o (cpu0_adr_o ),
		.cpu0_dat_o (cpu0_dat_o ),
		.cpu0_we_o  (cpu0_we_o  ),
		.cpu0_cyc_o (cpu0_cyc_o ),
		.cpu0_dat_i (cpu0_dat_i ),
		.cpu0_ack_i (cpu0_ack_i ),
		
		.cpu0_inst_cyc_o(cpu0_inst_cyc_o),	
		.cpu0_inst_pc_o	(cpu0_inst_pc_o	),
		.cpu0_inst_i	(cpu0_inst_i	),	
		.cpu0_inst_ack_i(cpu0_inst_ack_i),	
		
		// .cpu1_num   (cpu1_num   ),
		.cpu1_adr_o (cpu1_adr_o ),
		.cpu1_dat_o (cpu1_dat_o ),
		.cpu1_we_o  (cpu1_we_o  ),
		.cpu1_cyc_o (cpu1_cyc_o ),
		.cpu1_dat_i (cpu1_dat_i ),
		.cpu1_ack_i (cpu1_ack_i ),
		
		.cpu1_inst_cyc_o(cpu1_inst_cyc_o),	
		.cpu1_inst_pc_o	(cpu1_inst_pc_o	),
		.cpu1_inst_i	(cpu1_inst_i	),	
		.cpu1_inst_ack_i(cpu1_inst_ack_i),	
		
		// .cpu2_num   (cpu2_num   ),
		.cpu2_adr_o (cpu2_adr_o ),
		.cpu2_dat_o (cpu2_dat_o ),
		.cpu2_we_o  (cpu2_we_o  ),
		.cpu2_cyc_o (cpu2_cyc_o ),
		.cpu2_dat_i (cpu2_dat_i ),
		.cpu2_ack_i (cpu2_ack_i ),
		
		.cpu2_inst_cyc_o(cpu2_inst_cyc_o),	
		.cpu2_inst_pc_o	(cpu2_inst_pc_o	),
		.cpu2_inst_i	(cpu2_inst_i	),	
		.cpu2_inst_ack_i(cpu2_inst_ack_i),
		
		.cpu0_inst	(cpu0_inst	),
		.cpu0_pc	(cpu0_pc	),		
		             
		.cpu1_inst	(cpu1_inst	),
		.cpu1_pc	(cpu1_pc	),		
	                 
		.cpu2_inst	(cpu2_inst	),
		.cpu2_pc	(cpu2_pc	)		
	);
	
	core_control core_sel(
		.clk		(clk),
		.rst		(rst),
		
		.cpu0_control	(cpu0_control	),
		.start_cpu_num  (start_cpu_num  ), 
		.cpu_start_adr  (cpu_start_adr  ), 
		.cpu1_end		(cpu1_end		),
		.cpu2_end		(cpu2_end		),
		.cpu1_start		(cpu1_start		),
		.cpu1_start_adr	(cpu1_start_adr	),
		.cpu2_start		(cpu2_start		),
		.cpu2_start_adr	(cpu2_start_adr	),
		.core_state     (core_state     )
	);
	
	
	wb_j1_cpu_master 
		#(.is_master(1), .num(0))
	cpu0(
		.clk	(clk)		,
		.rst	(rst)		,
		// .key2	(key2)		,
		
		.dat_i	(cpu0_dat_i ),
		.ack_i	(cpu0_ack_i ),
		// .cpu_num(cpu0_num	),
		.adr_o	(cpu0_adr_o ),
		.dat_o	(cpu0_dat_o ),
		.we_o	(cpu0_we_o  ),
		.cyc_o	(cpu0_cyc_o ),
		
		.inst_i		(cpu0_inst_i	),
		.inst_ack_i	(cpu0_inst_ack_i),
		.inst_cyc_o	(cpu0_inst_cyc_o),
		.inst_pc_o	(cpu0_inst_pc_o	),
		
		.cpu_uart_dat_i	(cpu0_uart_dat_i),
		.cpu_uart_num	(cpu_uart_num	),
		.cpu_uart_dat_o	(cpu0_uart_dat_o),
		.cpu_uart_rd_o	(cpu0_uart_rd_o	),
		.cpu_uart_wr_o	(cpu0_uart_wr_o	),
		.cpu_uart_adr_o	(cpu0_uart_adr_o),
		
		.core_state		(core_state		),
		.cpu0_control	(cpu0_control	),
		.start_cpu_num  (start_cpu_num	), 
		.cpu_start_adr  (cpu_start_adr	) 
	); 
	
	wb_j1_cpu_slave 
		#(.is_master(0), .num(1))
	cpu1(
		.clk	(clk)		,
		.rst	(rst)		,
		.dat_i	(cpu1_dat_i ),
		.ack_i	(cpu1_ack_i ),
		// .cpu_num(cpu1_num	),
		.adr_o	(cpu1_adr_o ),
		.dat_o	(cpu1_dat_o ),
		.we_o	(cpu1_we_o  ),
		.cyc_o	(cpu1_cyc_o ),
		
		.inst_i		(cpu1_inst_i	),
		.inst_ack_i	(cpu1_inst_ack_i),
		.inst_cyc_o	(cpu1_inst_cyc_o),
		.inst_pc_o	(cpu1_inst_pc_o	),	
		
		.cpu_uart_dat_i	(cpu1_uart_dat_i),
		.cpu_uart_dat_o	(cpu1_uart_dat_o),
		.cpu_uart_rd_o	(cpu1_uart_rd_o	),
		.cpu_uart_wr_o	(cpu1_uart_wr_o	),
		.cpu_uart_adr_o	(cpu1_uart_adr_o),
		
		.cpu_start		(cpu1_start		),
		.cpu_start_adr	(cpu1_start_adr	),
		.cpu_end        (cpu1_end		)
	); 
	
	wb_j1_cpu_slave 
		#(.is_master(0), .num(2))
	cpu2(
		.clk	(clk)		,
		.rst	(rst)		,
		.dat_i	(cpu2_dat_i ),
		.ack_i	(cpu2_ack_i ),
		// .cpu_num(cpu2_num	),
		.adr_o	(cpu2_adr_o ),
		.dat_o	(cpu2_dat_o ),
		.we_o	(cpu2_we_o  ),
		.cyc_o	(cpu2_cyc_o ),
		
		.inst_i		(cpu2_inst_i	),
		.inst_ack_i	(cpu2_inst_ack_i),
		.inst_cyc_o	(cpu2_inst_cyc_o),
		.inst_pc_o	(cpu2_inst_pc_o	),
		
		.cpu_uart_dat_i	(cpu2_uart_dat_i),
		.cpu_uart_dat_o	(cpu2_uart_dat_o),
		.cpu_uart_rd_o	(cpu2_uart_rd_o	),
		.cpu_uart_wr_o	(cpu2_uart_wr_o	),
		.cpu_uart_adr_o	(cpu2_uart_adr_o),
		
		.cpu_start		(cpu2_start		),
		.cpu_start_adr	(cpu2_start_adr	),
		.cpu_end        (cpu2_end		)
	);  
endmodule