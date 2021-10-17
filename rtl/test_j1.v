`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/26 14:39:35
// Design Name: 
// Module Name: test_j1
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


module test_j1;
	localparam str_size = 29;
	
	wire rx,tx;
	reg clk_in,clk,rst;
	
    reg uart_wr,uart_rd;
    reg[1:0] uart_addr;
    reg[7:0] uart_din;
    wire[7:0] uart_dout;
    reg[31:1] i;
    reg[(str_size+1)*8-1:0] str;
    
	j1_top j1_test(.clk_in(clk_in), .rx(rx), .tx(tx));
	
    uart u_ini (
    	.clk	  (clk),
        .rst      (rst),
        .rx		  (tx),
        .tx		  (rx),
        
        .wr	      (uart_wr	),
        .rd	      (uart_rd	),
        .adr	  (uart_addr),
        .din	  (uart_din	),
        .dout     (uart_dout),
        .dout1    ()
    );
	
    initial
    begin
    	#100
    	uart_wr = 0;
        uart_rd = 0;
        uart_addr = 0;
        uart_din = 0;
        str[(str_size+1)*8-1:8] = ": w 30 0 do i . loop ;  w w";
        str[7:0] = 8'h0d;
        i = 0;
        $display("初始化完成。。");
    	forever #(100)
        begin
        	@(posedge clk);
            uart_rd <= 1; 
            uart_addr[1] <= 1;
            @(posedge clk);
            if(uart_dout[0])
           	begin
            	@(posedge clk);
                	uart_rd <= 1;
            		uart_addr[1] <= 0;
                @(posedge clk);
                	if(uart_dout != 8'h0a)
                		$write("%c",uart_dout);
           	end else if(!uart_dout[1] && ($time>80_0000))
            begin
            	@(posedge clk);
                	uart_rd <= 0;
                    uart_addr[1] <= 0;
                    if(i <= str_size)
                    begin
	                	uart_wr <= 1;
    	            	{uart_din,str} <= {str,8'b0};
                        i <= i + 1;
                    end 
            end 
            @(posedge clk);
            	uart_rd <= 0;
            	uart_addr[1] <= 0;
            	uart_wr <= 0;
        		uart_din <= 0;
        end 
    end 
    
	initial 
	begin
		clk_in=1;
		forever #(10)
			clk_in = ~clk_in;
	end

	initial 
	begin
		clk=1;
		forever #(5)
			clk = ~clk;
	end
    
    initial 
	begin
		rst=1;
		#100 rst = 0;
	end
endmodule
