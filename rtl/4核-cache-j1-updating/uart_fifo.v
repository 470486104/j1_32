`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/16 21:21:56
// Design Name: 
// Module Name: uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_fifo
#(
	parameter BAUD_RATE 	= 'd300_0000	,
	parameter CLK_FREQ 	= 'd100_000_000	
)
(
	input clk,
	input rst,
	
	input  wire			rx			,
	input  wire			wr			,
	input  wire			rd			,
	input  wire[1:0]	adr			,
	input  wire[7:0]	din			,

	output reg			tx			,
	output wire[7:0]	dout		,
	output wire[7:0]	dout1		
);

	localparam BAUD_COUNT = (CLK_FREQ / BAUD_RATE) - 1;
	localparam BAUD_COUNT_MID = (BAUD_COUNT / 2) - 1;
    localparam BAUD_WIDTH = $clog2(BAUD_COUNT+1);
	
    reg rx1,rx2,rx3;
    reg rx_en;
    reg[BAUD_WIDTH-1:0] rx_buad_count;
    reg[3:0] rx_bit_count;
    
    reg tx_en;
    reg[BAUD_WIDTH-1:0] tx_buad_count;
    reg[3:0] tx_bit_count;
    reg[7:0] tx_reg;
    
    reg	rx_data_ok;
    reg[7:0] rx_data;	
    wire[7:0] data_out;	
	
    wire fifo_rd = rd & !adr[1];
    wire tx_wr = wr & !adr[0];
	wire is_ready;
    
	assign dout = adr[1] ? {6'b0,tx_en,is_ready} : data_out;
	assign dout1 = adr[0] ? {6'b0,tx_en,is_ready} : data_out;


    fifo_mem 
   		#(.MEM_SIZE(256), .BIT_WIDTH(8))
    fifo(
    	.clk(clk),
        .rst(rst),
		
        .wr	 		(rx_data_ok	),
        .rd	 		(fifo_rd	),
        .din 		(rx_data	),
        .is_ready	(is_ready	),
        .dout		(data_out	)
    );
    
    // Rx
    always @(posedge clk)
    begin
    	if(rst)
    	begin
    		rx1 <= 1;
    		rx2 <= 1;
    		rx3 <= 1;
    	end else 
    	begin
    		rx1 <= rx;
    		rx2 <= rx1;
    		rx3 <= rx2;
    	end
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        	rx_en <= 0;
        else if(!rx2 && rx3 && !rx_en)
        	rx_en <= 1;
        else if((rx_bit_count == 'd8) && (rx_buad_count == BAUD_COUNT_MID) && rx_en)
        	rx_en <= 0;
   	end
    
    always @(posedge clk)
    begin
    	if(rst)
    		rx_buad_count <= 0;
    	else if(rx_en)
        	if(rx_buad_count == BAUD_COUNT)
            	rx_buad_count <= 0;
            else
        		rx_buad_count <= rx_buad_count + 1;
        else
        	rx_buad_count <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        	rx_bit_count <= 0;
        else if(rx_en)
        begin
        	if(rx_buad_count == BAUD_COUNT)
            	rx_bit_count <= rx_bit_count + 1;
        end else
        	rx_bit_count <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		rx_data <= 0;
        else if(rx_en)
        	if(|rx_bit_count && rx_buad_count == BAUD_COUNT_MID)
            	rx_data <= {rx3,rx_data[7:1]};
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		rx_data_ok <= 0;
        else if((rx_bit_count == 'd8) && (rx_buad_count == BAUD_COUNT_MID) && rx_en)
        	rx_data_ok <= 1;
        else
        	rx_data_ok <= 0;
    end
    
    // Tx
    always @(posedge clk)
    begin
    	if(rst)
    		tx_en <= 0;
        else if(tx_wr && !tx_en)
        	tx_en <= 1;
        else if(tx_bit_count == 9 && tx_buad_count == BAUD_COUNT && tx_en)
        	tx_en <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		tx_buad_count <= 0;
        else if(tx_en)
        	if(tx_buad_count == BAUD_COUNT)
            	tx_buad_count <= 0;
            else
            	tx_buad_count <= tx_buad_count + 1;
        else
        	tx_buad_count <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		tx_bit_count <= 0;
        else if(tx_en)
        begin
        	if(tx_buad_count == BAUD_COUNT)
            	tx_bit_count <= tx_bit_count + 1;
        end else
        	tx_bit_count <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        begin
    		tx <= 1;
            tx_reg <= 0;
        end else if(tx_wr && !tx_en)
        begin
        	tx <= 0;
        	tx_reg <= din;
        end else if(tx_en)
        begin
            if(tx_buad_count == BAUD_COUNT)
            	{tx_reg, tx} <= {1'b1, tx_reg};
        end else
        begin
        	tx <= 1;
        	tx_reg <= 0;
        end 
    end
    
endmodule
