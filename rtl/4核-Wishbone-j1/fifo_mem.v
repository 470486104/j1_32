module fifo_mem
#(
	parameter BIT_WIDTH = 'd8,
    parameter MEM_SIZE = 'd256
)
(
	input clk,
	input rst,	
    
    input wire 					wr		,
    input wire 					rd		,
    input wire[BIT_WIDTH-1:0] 	din		,
    
    output wire					is_ready,
    output wire[BIT_WIDTH-1:0] 	dout
);
	localparam ADDR_WIDTH = $clog2(MEM_SIZE); 
    
	reg[BIT_WIDTH-1 : 0] mem[0:MEM_SIZE-1];
    reg[ADDR_WIDTH-1:0] head,tail,count;
    
    // assign is_full = count == MEM_SIZE;
    assign is_ready = |count;
    assign dout = (rd && |count) ? mem[head] : 0;
    
    always@(posedge clk)
    begin
    	if(rst)
        	head <= 0;
        else if(rd && |count)
        	if(head == MEM_SIZE-1)
            	head <= 0;
            else
        		head <= head + 1;
    end 
    
    always@(posedge clk)
    begin
    	if(rst)
        	tail <= 0;
        else if(wr && count != MEM_SIZE)
        	if(tail == MEM_SIZE-1)
            	tail <= 0;
            else
        		tail <= tail + 1;
    end 
    
    always@(posedge clk)
    begin
    	if(rst)
        	count <= 0;
        else if(wr & rd)
        begin
        	if(count == 0) // 同时读和写 ，且队列为0
                	count <= count + 1;
        end else
        	if(wr && count != MEM_SIZE)
            	count <= count + 1;
            else if(rd && |count)
            	count <= count - 1;
    end 
    
    always@(posedge clk)
    begin
    	if(wr && count != MEM_SIZE)
        	mem[tail] <= din;
    end 
endmodule