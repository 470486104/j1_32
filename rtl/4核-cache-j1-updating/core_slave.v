`include "define.v"
module core_slave
#(
	parameter is_master = 0,
	parameter num = 1
)
(
	input clk, 
	input rst,
    
    input  wire						c_l2_data_page_wr	,
    input  wire [127:0]				c_l2_data_page_dout	,
    input  wire 					c_l2_data_wr_ack	,
    output wire 					c_l2_data_valid		,
    output wire 					c_l2_data_rd_wr		,
    output wire [13:0]				c_l2_data_addr		,
    output wire [31:0]				c_l2_data_din		,
    input  wire 					c_data_dirty		,
    input  wire [13:0]				c_data_dirty_addr	,
    
    input  wire						c_l2_inst_page_wr	,
    input  wire [127:0]				c_l2_inst_page_dout	,
    output wire 					c_l2_inst_valid	    ,
    output wire 					c_l2_inst_rd_wr	    ,
    output wire [13:0]				c_l2_inst_addr		,
    input  wire 					c_inst_dirty		,
    input  wire [13:0]				c_inst_dirty_addr	,
    
    input  wire	[`UartDataWidth]	cpu_uart_dat_i		,
	// output wire	[`CpuNumWidth]		cpu_uart_num		,
	output wire	[`UartDataWidth]	cpu_uart_dat_o		,
	output wire						cpu_uart_rd_o		,
	output wire						cpu_uart_wr_o		,
	output wire						cpu_uart_adr_o		,
    
    input  wire						cpu_start			,
	input  wire	[`PcWidth]			cpu_start_adr		,
	output wire						cpu_end
);
	wire data_valid,data_rd_wr;
    wire[13:0] data_addr;
    wire[31:0] data_din;
    wire[31:0] data_dout;
    wire data_miss,data_wr_wait;
    
    wire inst_valid,inst_rd_wr;
    wire[13:0] inst_addr;
    wire[31:0] inst_dout;
    wire inst_miss;

    wb_j1_cpu_slave 
    #(.is_master(is_master), .num(num))
    c_s(
    	.clk(clk),
        .rst(rst),
        
        .cache_data_miss	(data_miss			),
    	.cache_data_wr_wait (data_wr_wait		),
    	.cache_data_dout	(data_dout			),
    	.cache_data_valid	(data_valid			),
    	.cache_data_rd_wr	(data_rd_wr			),
    	.cache_data_addr	(data_addr			),
    	.cache_data_din	    (data_din			),
        
    	.cache_inst_miss	(inst_miss			),
    	.cache_inst_dout	(inst_dout			),
    	.cache_inst_valid	(inst_valid			),
    	.cache_inst_rd_wr	(inst_rd_wr			),
    	.cache_inst_addr	(inst_addr			),
        
        .cpu_uart_dat_i		(cpu_uart_dat_i	),
		// .cpu_uart_num		(cpu_uart_num		),
		.cpu_uart_dat_o		(cpu_uart_dat_o	),
		.cpu_uart_rd_o		(cpu_uart_rd_o		),
		.cpu_uart_wr_o		(cpu_uart_wr_o		),
		.cpu_uart_adr_o		(cpu_uart_adr_o	),
                        	
		.cpu_start			(cpu_start			),
		.cpu_start_adr		(cpu_start_adr		),
		.cpu_end			(cpu_end			)
    );
    
    cache_l1 data_cache(
    	.clk(clk),
        .rst(rst),
        
    	.valid				(data_valid			),
        .rd_wr				(data_rd_wr			),
        .addr				(data_addr			),
        .din				(data_din			),	
        .dout				(data_dout			),
        .miss				(data_miss			),
        .wr_wait			(data_wr_wait		),	
                        	
        .c_l2_page_wr		(c_l2_data_page_wr	),
        .c_l2_page_dout		(c_l2_data_page_dout),
        .c_l2_wr_ack		(c_l2_data_wr_ack	),	
        .c_l2_valid			(c_l2_data_valid	),
        .c_l2_rd_wr			(c_l2_data_rd_wr	),
        .c_l2_addr			(c_l2_data_addr		),
        .c_l2_din			(c_l2_data_din		),
                        	
        .c_dirty			(c_data_dirty		),	
        .c_dirty_addr		(c_data_dirty_addr	)
    );
    cache_l1 inst_cache(
    	.clk(clk),
        .rst(rst),
        
    	.valid				(inst_valid			),
        .rd_wr				(inst_rd_wr			),
        .addr				(inst_addr			),
        .dout				(inst_dout			),
        .miss				(inst_miss			),
                        	
        .c_l2_page_wr		(c_l2_inst_page_wr	),
        .c_l2_page_dout		(c_l2_inst_page_dout	),
        .c_l2_valid			(c_l2_inst_valid	),
        .c_l2_rd_wr			(c_l2_inst_rd_wr	),
        .c_l2_addr			(c_l2_inst_addr		),
                        	
        .c_dirty			(c_inst_dirty		),	
        .c_dirty_addr		(c_inst_dirty_addr	)
    );
endmodule