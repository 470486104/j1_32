`include "define.v"
module cpu_top(
	input clk		,
	input rst		,
	
	input  wire [`UartDataWidth]	uart_dout	,
	input  wire [`UartDataWidth]	uart_dout1	,
	output wire						uart_rd	 	,
	output wire						uart_wr	 	,
	output wire	[1:0]				uart_addr	,
	output wire [`UartDataWidth]	uart_din
);
	
    wire					core_inst_page_wr		[0:3];
    wire[127:0]				core_inst_page_din		[0:3];
    wire					core_inst_c_dirty		[0:3];
    wire[13:0]				core_inst_c_dirty_addr	[0:3];
    wire 					core_inst_valid			[0:3];
    wire					core_inst_rd_wr			[0:3];
    wire[13:0]				core_inst_addr			[0:3];
	
    wire					core_data_page_wr		[0:3];
    wire[127:0]				core_data_page_din		[0:3];
    wire					core_data_wr_ack		[0:3];
    wire					core_data_c_dirty		[0:3];
    wire[13:0]				core_data_c_dirty_addr	[0:3];
    wire 					core_data_valid			[0:3];
    wire					core_data_rd_wr			[0:3];
    wire[13:0]				core_data_addr			[0:3];
    wire[31:0]				core_data_dout			[0:3];
    
	wire [`CpuSelWidth] 	core_state      ;
    
	wire [`CpuNumWidth]		cpu_uart_num	;
	wire 					cpu0_control	;
	wire [`CpuNumWidth]		start_cpu_num   ;
	// wire [`PcWidth]			cpu_start_adr   ;
	
    wire					cpu_end			[1:3];
	wire					cpu_start		[1:3];
	wire [`PcWidth]			cpu_start_adr	[0:3];
    
    wire [`UartDataWidth]	cpu_uart_dat_o  [0:3];
    wire					cpu_uart_rd_o	[0:3];
    wire 					cpu_uart_wr_o	[0:3];
    wire					cpu_uart_adr_o  [0:3];
    wire [`UartDataWidth]	cpu_uart_dat_i  [0:3];
	
    wire		mem_rd_wr1	;
    wire		mem_valid1	;
    wire[13:0]	mem_addr1 	;
    wire[127:0]	mem_din1 	;
    reg[127:0]	mem_dout1	;
    reg			mem_ack1	;
    
    wire		mem_rd_wr2	;
    wire		mem_valid2	;
    wire[13:0]	mem_addr2 	;
    wire[127:0]	mem_din2 	;
    reg[127:0]	mem_dout2	;
    reg			mem_ack2	;
    
    reg[127:0] mem[0:3071];
    initial $readmemh("E:/j1_32_128.hex", mem);
    
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
	    .cpu0_uart_dat_o(cpu_uart_dat_o[0]	),
	    .cpu0_uart_rd_o	(cpu_uart_rd_o[0]	),
	    .cpu0_uart_wr_o	(cpu_uart_wr_o[0]	),
	    .cpu0_uart_adr_o(cpu_uart_adr_o[0]	),
	    .cpu0_uart_dat_i(cpu_uart_dat_i[0]	),
		
		// .cpu1_num		(cpu1_num		),
	    .cpu1_uart_dat_o(cpu_uart_dat_o[1]	),
	    .cpu1_uart_rd_o	(cpu_uart_rd_o[1]	),
	    .cpu1_uart_wr_o	(cpu_uart_wr_o[1]	),
	    .cpu1_uart_adr_o(cpu_uart_adr_o[1]	),
	    .cpu1_uart_dat_i(cpu_uart_dat_i[1]	),
		
		// .cpu2_num		(cpu2_num		),
	    .cpu2_uart_dat_o(cpu_uart_dat_o[2]	),
	    .cpu2_uart_rd_o	(cpu_uart_rd_o[2]	),
	    .cpu2_uart_wr_o	(cpu_uart_wr_o[2]	),
	    .cpu2_uart_adr_o(cpu_uart_adr_o[2]	),
	    .cpu2_uart_dat_i(cpu_uart_dat_i[2]	),
        
        .cpu3_uart_dat_o(cpu_uart_dat_o[3]	),
	    .cpu3_uart_rd_o	(cpu_uart_rd_o[3]	),
	    .cpu3_uart_wr_o	(cpu_uart_wr_o[3]	),
	    .cpu3_uart_adr_o(cpu_uart_adr_o[3]	),
	    .cpu3_uart_dat_i(cpu_uart_dat_i[3]	)
	); 
	
	core_control core_sel(
		.clk		(clk),
		.rst		(rst),
		
		.cpu0_control	(cpu0_control		),
		.start_cpu_num  (start_cpu_num  	), 
		.cpu_start_adr  (cpu_start_adr[0]  	), 
        
		.cpu1_end		(cpu_end[1]			),
		.cpu2_end		(cpu_end[2]			),
		.cpu3_end		(cpu_end[3]			),
        
		.cpu1_start		(cpu_start[1]		),
		.cpu1_start_adr	(cpu_start_adr[1]	),
        
		.cpu2_start		(cpu_start[2]		),
		.cpu2_start_adr	(cpu_start_adr[2]	),
        
        .cpu3_start		(cpu_start[3]		),
		.cpu3_start_adr	(cpu_start_adr[3]	),
        
		.core_state     (core_state     )
	);
	
	
	core_master 
		#(.is_master(1), .num(0))
	core0(
		.clk	(clk)		,
		.rst	(rst)		,
		
		.c_l2_data_page_wr	(core_data_page_wr[0]	),
        .c_l2_data_page_dout(core_data_page_din[0]	),	
        .c_l2_data_wr_ack	(core_data_wr_ack[0]	),
        .c_l2_data_valid	(core_data_valid[0]		),	
        .c_l2_data_rd_wr	(core_data_rd_wr[0]		),	
        .c_l2_data_addr		(core_data_addr[0]		),
        .c_l2_data_din		(core_data_dout[0]		),
        .c_data_dirty		(core_data_c_dirty[0]	),
        .c_data_dirty_addr	(core_data_c_dirty_addr[0]),

        .c_l2_inst_page_wr	(core_inst_page_wr[0]	),
        .c_l2_inst_page_dout(core_inst_page_din[0]	),
        .c_l2_inst_valid	(core_inst_valid[0]		),    
        .c_l2_inst_rd_wr	(core_inst_rd_wr[0]		),    
        .c_l2_inst_addr		(core_inst_addr[0]		),
        .c_inst_dirty		(core_inst_c_dirty[0]	),
        .c_inst_dirty_addr	(core_inst_c_dirty_addr[0]),

		.cpu_uart_dat_i	(cpu_uart_dat_i[0]	),
		.cpu_uart_num	(cpu_uart_num		),
		.cpu_uart_dat_o	(cpu_uart_dat_o[0]	),
		.cpu_uart_rd_o	(cpu_uart_rd_o[0]	),
		.cpu_uart_wr_o	(cpu_uart_wr_o[0]	),
		.cpu_uart_adr_o	(cpu_uart_adr_o[0]	),
		
		.core_state		(core_state		),
		.cpu0_control	(cpu0_control	),
		.start_cpu_num  (start_cpu_num	), 
		.cpu_start_adr  (cpu_start_adr[0]) 
	); 
	
	core_slave 
		#(.is_master(0), .num(1))
	core1(
		.clk	(clk)		,
		.rst	(rst)		,
        
		.c_l2_data_page_wr	(core_data_page_wr[1]	),
        .c_l2_data_page_dout(core_data_page_din[1]	),	
        .c_l2_data_wr_ack	(core_data_wr_ack[1]	),
        .c_l2_data_valid	(core_data_valid[1]		),	
        .c_l2_data_rd_wr	(core_data_rd_wr[1]		),	
        .c_l2_data_addr		(core_data_addr[1]		),
        .c_l2_data_din		(core_data_dout[1]		),
        .c_data_dirty		(core_data_c_dirty[1]	),
        .c_data_dirty_addr	(core_data_c_dirty_addr[1]),

        .c_l2_inst_page_wr	(core_inst_page_wr[1]	),
        .c_l2_inst_page_dout(core_inst_page_din[1]	),
        .c_l2_inst_valid	(core_inst_valid[1]		),    
        .c_l2_inst_rd_wr	(core_inst_rd_wr[1]		),    
        .c_l2_inst_addr		(core_inst_addr[1]		),
        .c_inst_dirty		(core_inst_c_dirty[1]	),
        .c_inst_dirty_addr	(core_inst_c_dirty_addr[1]),	
		
		.cpu_uart_dat_i	(cpu_uart_dat_i[1]	),
		.cpu_uart_dat_o	(cpu_uart_dat_o[1]	),
		.cpu_uart_rd_o	(cpu_uart_rd_o[1]	),
		.cpu_uart_wr_o	(cpu_uart_wr_o[1]	),
		.cpu_uart_adr_o	(cpu_uart_adr_o[1]	),
		
		.cpu_start		(cpu_start[1]		),
		.cpu_start_adr	(cpu_start_adr[1]	),
		.cpu_end        (cpu_end[1]			)
	); 
	
	core_slave 
		#(.is_master(0), .num(2))
	core2(
		.clk	(clk)		,
		.rst	(rst)		,
		
        .c_l2_data_page_wr	(core_data_page_wr[2]	),
        .c_l2_data_page_dout(core_data_page_din[2]	),	
        .c_l2_data_wr_ack	(core_data_wr_ack[2]	),
        .c_l2_data_valid	(core_data_valid[2]		),	
        .c_l2_data_rd_wr	(core_data_rd_wr[2]		),	
        .c_l2_data_addr		(core_data_addr[2]		),
        .c_l2_data_din		(core_data_dout[2]		),
        .c_data_dirty		(core_data_c_dirty[2]	),
        .c_data_dirty_addr	(core_data_c_dirty_addr[2]),

        .c_l2_inst_page_wr	(core_inst_page_wr[2]	),
        .c_l2_inst_page_dout(core_inst_page_din[2]	),
        .c_l2_inst_valid	(core_inst_valid[2]		),    
        .c_l2_inst_rd_wr	(core_inst_rd_wr[2]		),    
        .c_l2_inst_addr		(core_inst_addr[2]		),
        .c_inst_dirty		(core_inst_c_dirty[2]	),
        .c_inst_dirty_addr	(core_inst_c_dirty_addr[2]),
		
		.cpu_uart_dat_i	(cpu_uart_dat_i[2]	),
		.cpu_uart_dat_o	(cpu_uart_dat_o[2]	),
		.cpu_uart_rd_o	(cpu_uart_rd_o[2]	),
		.cpu_uart_wr_o	(cpu_uart_wr_o[2]	),
		.cpu_uart_adr_o	(cpu_uart_adr_o[2]	),
		
		.cpu_start		(cpu_start[2]		),
		.cpu_start_adr	(cpu_start_adr[2]	),
		.cpu_end        (cpu_end[2]			)
	);  
    
    core_slave 
		#(.is_master(0), .num(3))
	core3(
		.clk	(clk)		,
		.rst	(rst)		,
		
        .c_l2_data_page_wr	(core_data_page_wr[3]	),
        .c_l2_data_page_dout(core_data_page_din[3]	),	
        .c_l2_data_wr_ack	(core_data_wr_ack[3]	),
        .c_l2_data_valid	(core_data_valid[3]		),	
        .c_l2_data_rd_wr	(core_data_rd_wr[3]		),	
        .c_l2_data_addr		(core_data_addr[3]		),
        .c_l2_data_din		(core_data_dout[3]		),
        .c_data_dirty		(core_data_c_dirty[3]	),
        .c_data_dirty_addr	(core_data_c_dirty_addr[3]),

        .c_l2_inst_page_wr	(core_inst_page_wr[3]	),
        .c_l2_inst_page_dout(core_inst_page_din[3]	),
        .c_l2_inst_valid	(core_inst_valid[3]		),    
        .c_l2_inst_rd_wr	(core_inst_rd_wr[3]		),    
        .c_l2_inst_addr		(core_inst_addr[3]		),
        .c_inst_dirty		(core_inst_c_dirty[3]	),
        .c_inst_dirty_addr	(core_inst_c_dirty_addr[3]),
		
		.cpu_uart_dat_i	(cpu_uart_dat_i[3]	),
		.cpu_uart_dat_o	(cpu_uart_dat_o[3]	),
		.cpu_uart_rd_o	(cpu_uart_rd_o[3]	),
		.cpu_uart_wr_o	(cpu_uart_wr_o[3]	),
		.cpu_uart_adr_o	(cpu_uart_adr_o[3]	),
		
		.cpu_start		(cpu_start[3]		),
		.cpu_start_adr	(cpu_start_adr[3]	),
		.cpu_end        (cpu_end[3]			)
	); 
    
     cache_l2 l2(
    	.clk(clk),
        .rst(rst),
        
    	.core0_inst_valid		(core_inst_valid[0]			),
        .core0_inst_rd_wr		(core_inst_rd_wr[0]			),
        .core0_inst_addr		(core_inst_addr[0]			),
        .core0_inst_page_wr		(core_inst_page_wr[0]		),
        .core0_inst_page_din	(core_inst_page_din[0]		),
        .core0_inst_c_dirty		(core_inst_c_dirty[0]		),
        .core0_inst_c_dirty_addr(core_inst_c_dirty_addr[0]	),
        .core0_data_valid		(core_data_valid[0]			),
        .core0_data_rd_wr		(core_data_rd_wr[0]			),
        .core0_data_addr		(core_data_addr[0]			),
        .core0_data_dout		(core_data_dout[0]			),
        .core0_data_page_wr		(core_data_page_wr[0]		),
        .core0_data_page_din	(core_data_page_din[0]		),
        .core0_data_wr_ack		(core_data_wr_ack[0]		),
        .core0_data_c_dirty		(core_data_c_dirty[0]		),
        .core0_data_c_dirty_addr(core_data_c_dirty_addr[0]	),
        
        .core1_inst_valid		(core_inst_valid[1]			),
        .core1_inst_rd_wr		(core_inst_rd_wr[1]			),
        .core1_inst_addr		(core_inst_addr[1]			),	
        .core1_inst_page_wr		(core_inst_page_wr[1]		),
        .core1_inst_page_din	(core_inst_page_din[1]		),	
        .core1_inst_c_dirty		(core_inst_c_dirty[1]		),
        .core1_inst_c_dirty_addr(core_inst_c_dirty_addr[1]	),	
        .core1_data_valid		(core_data_valid[1]			),
        .core1_data_rd_wr		(core_data_rd_wr[1]			),
        .core1_data_addr		(core_data_addr[1]			),	
        .core1_data_dout		(core_data_dout[1]			),	
        .core1_data_page_wr		(core_data_page_wr[1]		),
        .core1_data_page_din	(core_data_page_din[1]		),	
        .core1_data_wr_ack		(core_data_wr_ack[1]		),
        .core1_data_c_dirty		(core_data_c_dirty[1]		),
        .core1_data_c_dirty_addr(core_data_c_dirty_addr[1]	),	
        
        .core2_inst_valid		(core_inst_valid[2]			),
        .core2_inst_rd_wr		(core_inst_rd_wr[2]			),
        .core2_inst_addr		(core_inst_addr[2]			),	
        .core2_inst_page_wr		(core_inst_page_wr[2]		),
        .core2_inst_page_din	(core_inst_page_din[2]		),	
        .core2_inst_c_dirty		(core_inst_c_dirty[2]		),
        .core2_inst_c_dirty_addr(core_inst_c_dirty_addr[2]	),	
        .core2_data_valid		(core_data_valid[2]			),
        .core2_data_rd_wr		(core_data_rd_wr[2]			),
        .core2_data_addr		(core_data_addr[2]			),	
        .core2_data_dout		(core_data_dout[2]			),	
        .core2_data_page_wr		(core_data_page_wr[2]		),
        .core2_data_page_din	(core_data_page_din[2]		),	
        .core2_data_wr_ack		(core_data_wr_ack[2]		),
        .core2_data_c_dirty		(core_data_c_dirty[2]		),
        .core2_data_c_dirty_addr(core_data_c_dirty_addr[2]	),	
                                
        .core3_inst_valid		(core_inst_valid[3]			),
        .core3_inst_rd_wr		(core_inst_rd_wr[3]			),
        .core3_inst_addr		(core_inst_addr[3]			),	
        .core3_inst_page_wr		(core_inst_page_wr[3]		),
        .core3_inst_page_din	(core_inst_page_din[3]		),	
        .core3_inst_c_dirty		(core_inst_c_dirty[3]		),
        .core3_inst_c_dirty_addr(core_inst_c_dirty_addr[3]	),	
        .core3_data_valid		(core_data_valid[3]			),
        .core3_data_rd_wr		(core_data_rd_wr[3]			),
        .core3_data_addr		(core_data_addr[3]			),
        .core3_data_dout		(core_data_dout[3]			),	
        .core3_data_page_wr		(core_data_page_wr[3]		),
        .core3_data_page_din	(core_data_page_din[3]		),	
        .core3_data_wr_ack		(core_data_wr_ack[3]		),
        .core3_data_c_dirty		(core_data_c_dirty[3]		),
        .core3_data_c_dirty_addr(core_data_c_dirty_addr[3]	),	
        
        .mem_rd_wr1				(mem_rd_wr1				),	
        .mem_valid1				(mem_valid1				),	
        .mem_addr1 				(mem_addr1 				),
        .mem_din1 				(mem_din1 				),
        .mem_dout1				(mem_dout1				),
        .mem_ack1				(mem_ack1				),
        
        .mem_rd_wr2				(mem_rd_wr2				),	
        .mem_valid2				(mem_valid2				),	
        .mem_addr2 				(mem_addr2 				),
        .mem_din2 				(mem_din2 				),
        .mem_dout2				(mem_dout2				),
        .mem_ack2				(mem_ack2				)
    );
    
    
    reg[4:0] count;
    reg port1,port2;
    always @(posedge clk)
    begin
    	if(rst)
        	count <= 0;
        else if(|count)
        	count <= count + 1;
        else if(mem_valid1 || mem_valid2)
        	count <= 1;
    end
    always @(posedge clk)
    begin
    	if(count == 5'h10)
    	begin
        	if(mem_valid1)
    			if(mem_rd_wr1)
            		mem[mem_addr1[13:2]] <= mem_din1;
            	else 
            		mem_dout1 <= mem[mem_addr1[13:2]];
    	end 
    end
    always @(posedge clk)
    begin
    	if(count == 5'h10)
    	begin
        	if(mem_valid2)            
            	if(mem_rd_wr2)
            		mem[mem_addr2[13:2]] <= mem_din2;
            	else 
            		mem_dout2 <= mem[mem_addr2[13:2]];
    	end 
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    	begin
    		mem_ack1 <= 0;
            mem_ack2 <= 0;
            port1 <= 0;
            port2 <= 0;
    	end else if(count == 5'h10)
    	begin
    		mem_ack1 <= mem_valid1;
            mem_ack2 <= mem_valid2;
            port1 <= mem_valid1;
            port2 <= mem_valid2;
    	end else if(count >= 5'h11)
        begin
        	if(port1)
            	if(mem_valid1)
        			mem_ack1 <= 1;
                else
                begin
                	mem_ack1 <= 0;
                    port1 <= 0;
                end 
            if(port2)
            	if(mem_valid2)
            		mem_ack2 <= 1;
                else
                begin
                	mem_ack2 <= 0;
                    port2 <= 0;
                end 
        end 
    end
endmodule