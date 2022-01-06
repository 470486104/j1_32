module cache_l1(
	input 	clk		,
	input 	rst		,	
    
    input wire 				valid			,
    input wire	 			rd_wr			,
    input wire[13:0]		addr			,
    input wire[31:0]		din				,
    output wire[31:0]		dout			,
    output reg				miss			,
    output wire				wr_wait			,
    
    input wire				c_l2_page_wr	,
    input wire[127:0]		c_l2_page_dout	,
    input wire				c_l2_wr_ack		,
    output reg				c_l2_valid		,
    output reg				c_l2_rd_wr		,
    output wire[13:0]		c_l2_addr		,
    output wire[31:0]		c_l2_din		,
    
    input wire				c_dirty			,
    input wire[13:0]		c_dirty_addr	
    
);
	parameter WAY = 'd4;
	parameter GROUP = 'd8;
	parameter PAGE_SIZE = 'd128;
    parameter WORD_SIZE = 'd32;
    parameter ADDR_WIDTH = 'd14;
    
    localparam WAY_WIDTH = $clog2(WAY);
    localparam WORD_NUM = PAGE_SIZE / WORD_SIZE;
    localparam PAGE_WIDTH = $clog2(WORD_NUM);
    localparam GROUP_WIDTH = $clog2(GROUP);
    localparam TAG_WIDTH = ADDR_WIDTH - GROUP_WIDTH - PAGE_WIDTH;
    //         TGA           |         group             |  page inter
    // TAG_ADDR~GROUP_ADDR+1 | GROUP_ADDR~PAGE_IN_ADDR+1 | PAGE_IN_ADDR~0
    localparam PAGE_IN_ADDR = PAGE_WIDTH - 1;
    localparam GROUP_ADDR = GROUP_WIDTH + PAGE_WIDTH - 1;
    localparam TAG_ADDR = ADDR_WIDTH - 1;
    
    integer i;
    
    wire[TAG_WIDTH-1:0] addr_tag = addr[TAG_ADDR:GROUP_ADDR+1];
    wire[GROUP_WIDTH-1:0] addr_group = addr[GROUP_ADDR:PAGE_IN_ADDR+1];
    wire[PAGE_WIDTH-1:0] addr_page_in = addr[PAGE_IN_ADDR:0];
    
    assign wr_wait = c_l2_valid && c_l2_rd_wr;
    
    assign c_l2_addr = addr;
    assign c_l2_din = din;
    
    reg[WORD_SIZE-1:0] c_mem0[0:WAY*GROUP-1];
    reg[WORD_SIZE-1:0] c_mem1[0:WAY*GROUP-1];
    reg[WORD_SIZE-1:0] c_mem2[0:WAY*GROUP-1];
    reg[WORD_SIZE-1:0] c_mem3[0:WAY*GROUP-1];
    reg[WORD_SIZE-1:0] dout0,dout1,dout2,dout3;
    // assign dout = (dout0 & {32{mem_valid0[0]}}) | (dout1 & {32{mem_valid0[1]}}) | (dout2 & {32{mem_valid0[2]}}) | (dout3 & {32{mem_valid0[3]}});
    assign dout = dout0|dout1|dout2|dout3;
    
    reg[TAG_WIDTH-1:0] tag[0:GROUP-1][0:WAY-1];
    reg[WAY-1:0] valid_bit[0:GROUP-1];
    reg[PAGE_WIDTH*WAY-1:0] lru_term[0:GROUP-1];
    
    wire[WAY-1:0] hit[0:GROUP-1];
    
    reg[WORD_NUM-1:0] mem_valid0;
    reg[PAGE_WIDTH+GROUP_WIDTH-1:0] mem_addr0;
    reg[PAGE_WIDTH-1:0] replace_num;
    wire[PAGE_WIDTH+GROUP_WIDTH-1:0] mem_addr1 = {addr_group,replace_num};
    
    reg valid_bit_flag;
    reg[PAGE_WIDTH-1:0] valid_bit_num;
    
    genvar gv_j;
    generate
        for(gv_j = 0 ; gv_j < GROUP ; gv_j = gv_j + 1)
        begin : hit_tag
        	assign hit[gv_j][0] = tag[gv_j][0] == addr_tag && valid_bit[gv_j][0];
        	assign hit[gv_j][1] = tag[gv_j][1] == addr_tag && valid_bit[gv_j][1];
        	assign hit[gv_j][2] = tag[gv_j][2] == addr_tag && valid_bit[gv_j][2];
        	assign hit[gv_j][3] = tag[gv_j][3] == addr_tag && valid_bit[gv_j][3];
        end 
    endgenerate
    
    
    always @(*)
    begin
    	if(rst)
        	mem_valid0 = 0;
        else if(valid)
        	case(addr_group)
        		3'b000 : 
                	if(|hit[0])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		3'b001 : 
                	if(|hit[1])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		3'b010 : 
                	if(|hit[2])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		3'b011 : 
                	if(|hit[3])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		3'b100 : 
                	if(|hit[4])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		3'b101 : 
                	if(|hit[5])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		3'b110 : 
                	if(|hit[6])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		3'b111 : 
                	if(|hit[7])
                        case(addr_page_in)
                        	2'b00 : mem_valid0 = 4'b0001;
                        	2'b01 : mem_valid0 = 4'b0010;
                        	2'b10 : mem_valid0 = 4'b0100;
                        	2'b11 : mem_valid0 = 4'b1000;
                        	default : mem_valid0 = 0;
                        endcase
                	else
                    	mem_valid0 = 0;
        		default : mem_valid0 = 0;
        	endcase
       	else
        	mem_valid0 = 0;
    end
	
    always @(*)
    begin
    	if(rst)
        	mem_addr0 = 0;
        else if(valid)
        	case(addr_group)
        		3'b000 : 
                	case(hit[0])
                		4'b0001 : mem_addr0 = {3'b000,2'b00};
                		4'b0010 : mem_addr0 = {3'b000,2'b01};
                		4'b0100 : mem_addr0 = {3'b000,2'b10};
                		4'b1000 : mem_addr0 = {3'b000,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		3'b001 : 
                	case(hit[1])
                		4'b0001 : mem_addr0 = {3'b001,2'b00};
                		4'b0010 : mem_addr0 = {3'b001,2'b01};
                		4'b0100 : mem_addr0 = {3'b001,2'b10};
                		4'b1000 : mem_addr0 = {3'b001,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		3'b010 : 
                	case(hit[2])
                		4'b0001 : mem_addr0 = {3'b010,2'b00};
                		4'b0010 : mem_addr0 = {3'b010,2'b01};
                		4'b0100 : mem_addr0 = {3'b010,2'b10};
                		4'b1000 : mem_addr0 = {3'b010,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		3'b011 : 
                	case(hit[3])
                		4'b0001 : mem_addr0 = {3'b011,2'b00};
                		4'b0010 : mem_addr0 = {3'b011,2'b01};
                		4'b0100 : mem_addr0 = {3'b011,2'b10};
                		4'b1000 : mem_addr0 = {3'b011,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		3'b100 : 
                	case(hit[4])
                		4'b0001 : mem_addr0 = {3'b100,2'b00};
                		4'b0010 : mem_addr0 = {3'b100,2'b01};
                		4'b0100 : mem_addr0 = {3'b100,2'b10};
                		4'b1000 : mem_addr0 = {3'b100,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		3'b101 : 
                	case(hit[5])
                		4'b0001 : mem_addr0 = {3'b101,2'b00};
                		4'b0010 : mem_addr0 = {3'b101,2'b01};
                		4'b0100 : mem_addr0 = {3'b101,2'b10};
                		4'b1000 : mem_addr0 = {3'b101,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		3'b110 :
					case(hit[6])
                		4'b0001 : mem_addr0 = {3'b110,2'b00};
                		4'b0010 : mem_addr0 = {3'b110,2'b01};
                		4'b0100 : mem_addr0 = {3'b110,2'b10};
                		4'b1000 : mem_addr0 = {3'b110,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		3'b111 : 
                	case(hit[7])
                		4'b0001 : mem_addr0 = {3'b111,2'b00};
                		4'b0010 : mem_addr0 = {3'b111,2'b01};
                		4'b0100 : mem_addr0 = {3'b111,2'b10};
                		4'b1000 : mem_addr0 = {3'b111,2'b11};
                		default : mem_addr0 = 0;
                	endcase
        		default : mem_addr0 = 0;
        	endcase
       	else
        	mem_addr0 = 0;
    end
    
    always @(*)
    begin
    	if(rst)
        	replace_num = 0;
        else if(miss)
        	case(addr_group)
        		3'b000 : 
                	if(&valid_bit[0])
                    	replace_num = lru_term[0][7:6];
                    else
                    	casez(valid_bit[0])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		3'b001 : 
                	if(&valid_bit[1])
                    	replace_num = lru_term[1][7:6];
                    else
                    	casez(valid_bit[1])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		3'b010 : 
                	if(&valid_bit[2])
                    	replace_num = lru_term[2][7:6];
                    else
                    	casez(valid_bit[2])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		3'b011 : 
                	if(&valid_bit[3])
                    	replace_num = lru_term[3][7:6];
                    else
                    	casez(valid_bit[3])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		3'b100 : 
                	if(&valid_bit[4])
                    	replace_num = lru_term[4][7:6];
                    else
                    	casez(valid_bit[4])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		3'b101 : 
                	if(&valid_bit[5])
                    	replace_num = lru_term[5][7:6];
                    else
                    	casez(valid_bit[5])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		3'b110 : 
                	if(&valid_bit[6])
                    	replace_num = lru_term[6][7:6];
                    else
                    	casez(valid_bit[6])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		3'b111 : 
                	if(&valid_bit[7])
                    	replace_num = lru_term[7][7:6];
                    else
                    	casez(valid_bit[7])
        					4'b???0 : replace_num = 2'b00;
       						4'b??0? : replace_num = 2'b01;
       						4'b?0?? : replace_num = 2'b10;
       						4'b0??? : replace_num = 2'b11;
                            default : replace_num = 0;
        				endcase
        		default : replace_num = 0;
        	endcase
    end
    
    always @(posedge clk)
    begin
    	if(mem_valid0[0])
        	if(rd_wr)
            	c_mem0[mem_addr0] <= din;
            else
            	dout0 <= c_mem0[mem_addr0];
        else
        	dout0 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(mem_valid0[1])
        	if(rd_wr)
            	c_mem1[mem_addr0] <= din;
            else
            	dout1 <= c_mem1[mem_addr0];
        else
        	dout1 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(mem_valid0[2])
        	if(rd_wr)
            	c_mem2[mem_addr0] <= din;
            else
            	dout2 <= c_mem2[mem_addr0];
        else
        	dout2 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(mem_valid0[3])
        	if(rd_wr)
            	c_mem3[mem_addr0] <= din;
            else
            	dout3 <= c_mem3[mem_addr0];
        else
        	dout3 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(c_l2_page_wr)
            c_mem0[mem_addr1] <= c_l2_page_dout[31:0];
    end
	
    always @(posedge clk)
    begin
    	if(c_l2_page_wr)
            c_mem1[mem_addr1] <= c_l2_page_dout[63:32];
    end
    
    always @(posedge clk)
    begin
    	if(c_l2_page_wr)
        	c_mem2[mem_addr1] <= c_l2_page_dout[95:64];
    end
    
    always @(posedge clk)
    begin
    	if(c_l2_page_wr)
        	c_mem3[mem_addr1] <= c_l2_page_dout[127:96];
    end
    
    always @(posedge clk)
    begin
    	if(c_l2_page_wr)
            tag[addr_group][replace_num] <= addr_tag;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        begin
        	valid_bit[0] <= 0;
        	valid_bit[1] <= 0;
        	valid_bit[2] <= 0;
        	valid_bit[3] <= 0;
        	valid_bit[4] <= 0;
        	valid_bit[5] <= 0;
        	valid_bit[6] <= 0;
        	valid_bit[7] <= 0;
        end else
        begin
    		if(c_l2_page_wr)
        	    valid_bit[addr_group][replace_num] <= 1'b1;
        	if(valid_bit_flag)
        	    valid_bit[c_dirty_addr[GROUP_ADDR:PAGE_IN_ADDR+1]][valid_bit_num] <= 1'b0;
        end 
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        	miss <= 0;
        else if(valid)
        	case(addr_group)
        		3'b000 : miss <= !(|(hit[0]));
        		3'b001 : miss <= !(|(hit[1]));
        		3'b010 : miss <= !(|(hit[2]));
        		3'b011 : miss <= !(|(hit[3]));
        		3'b100 : miss <= !(|(hit[4]));
        		3'b101 : miss <= !(|(hit[5]));
        		3'b110 : miss <= !(|(hit[6]));
        		3'b111 : miss <= !(|(hit[7]));
        	endcase
        else
        	miss <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        begin
        	c_l2_valid <= 0;
            c_l2_rd_wr <= 0;
        end else if(c_l2_wr_ack)
        begin
        	c_l2_valid <= 0;
            c_l2_rd_wr <= 0;
        end else if(valid)
        	case(addr_group)
        		3'b000 : begin c_l2_valid <= |(hit[0]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[0]); end
        		3'b001 : begin c_l2_valid <= |(hit[1]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[1]); end
        		3'b010 : begin c_l2_valid <= |(hit[2]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[2]); end
        		3'b011 : begin c_l2_valid <= |(hit[3]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[3]); end
        		3'b100 : begin c_l2_valid <= |(hit[4]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[4]); end
        		3'b101 : begin c_l2_valid <= |(hit[5]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[5]); end
        		3'b110 : begin c_l2_valid <= |(hit[6]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[6]); end
        		3'b111 : begin c_l2_valid <= |(hit[7]) ? rd_wr : 1'b1; c_l2_rd_wr <= |(hit[7]); end
        	endcase
    end

    always @(*)
    begin
    	if(rst)
        	valid_bit_flag = 0;
        else if(c_dirty)
        	case(c_dirty_addr[GROUP_ADDR:PAGE_IN_ADDR+1])
        		3'b000 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][3];
        		3'b001 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][3];
        		3'b010 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][3];
                3'b011 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][3];
                3'b100 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][3];
                3'b101 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][3];
                3'b110 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][3];
                3'b111 : valid_bit_flag = c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[7][0] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[7][1] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[7][2] | c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[7][3];
        		default : valid_bit_flag = 0;
        	endcase
        else
        	valid_bit_flag = 0;
    end
	
    always @(*)
    begin
    	if(rst)
        	valid_bit_num = 0;
        else if(c_dirty)
        	case(c_dirty_addr[GROUP_ADDR:PAGE_IN_ADDR+1])
        		3'b000 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
        		3'b001 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[1][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
        		3'b010 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[2][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
                3'b011 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[3][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
                3'b100 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[4][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
                3'b101 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[5][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
                3'b110 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[6][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
                3'b111 : 
                	case({c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][3],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][2],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][1],c_dirty_addr[TAG_ADDR:GROUP_ADDR+1] == tag[0][0]})
                		4'b0001 : valid_bit_num = 2'b00;
                		4'b0010 : valid_bit_num = 2'b01;
                		4'b0100 : valid_bit_num = 2'b10;
                		4'b1000 : valid_bit_num = 2'b11;
                		default : valid_bit_num = 2'b00;
                	endcase
        		default : valid_bit_num = 0;
        	endcase
        else
        	valid_bit_num = 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        begin
        	lru_term[0] <= 8'h1b;
        	lru_term[1] <= 8'h1b;
        	lru_term[2] <= 8'h1b;
        	lru_term[3] <= 8'h1b;
        	lru_term[4] <= 8'h1b;
        	lru_term[5] <= 8'h1b;
        	lru_term[6] <= 8'h1b;
        	lru_term[7] <= 8'h1b;
        end else if(valid)
        	case(addr_group)
        		3'b000 : 
                		case(hit[0])
        					4'b0001 :
                            		casez(lru_term[0])
                            			8'b????_??00 : lru_term[0] <= {lru_term[0][7:2],2'b00};
                            			8'b????_00?? : lru_term[0] <= {lru_term[0][7:4],lru_term[0][1:0],2'b00};
                            			8'b??00_???? : lru_term[0] <= {lru_term[0][7:6],lru_term[0][3:0],2'b00};
                            			8'b00??_???? : lru_term[0] <= {lru_term[0][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[0])
                            			8'b????_??01 : lru_term[0] <= {lru_term[0][7:2],2'b01};
                            			8'b????_01?? : lru_term[0] <= {lru_term[0][7:4],lru_term[0][1:0],2'b01};
                            			8'b??01_???? : lru_term[0] <= {lru_term[0][7:6],lru_term[0][3:0],2'b01};
                            			8'b01??_???? : lru_term[0] <= {lru_term[0][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[0])
                            			8'b????_??10 : lru_term[0] <= {lru_term[0][7:2],2'b10};
                            			8'b????_10?? : lru_term[0] <= {lru_term[0][7:4],lru_term[0][1:0],2'b10};
                            			8'b??10_???? : lru_term[0] <= {lru_term[0][7:6],lru_term[0][3:0],2'b10};
                            			8'b10??_???? : lru_term[0] <= {lru_term[0][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[0])
                            			8'b????_??11 : lru_term[0] <= {lru_term[0][7:2],2'b11};
                            			8'b????_11?? : lru_term[0] <= {lru_term[0][7:4],lru_term[0][1:0],2'b11};
                            			8'b??11_???? : lru_term[0] <= {lru_term[0][7:6],lru_term[0][3:0],2'b11};
                            			8'b11??_???? : lru_term[0] <= {lru_term[0][5:0],2'b11};
                            		endcase
        				endcase
        		3'b001 : 
                		case(hit[1])
        					4'b0001 :
                            		casez(lru_term[1])
                            			8'b????_??00 : lru_term[1] <= {lru_term[1][7:2],2'b00};
                            			8'b????_00?? : lru_term[1] <= {lru_term[1][7:4],lru_term[1][1:0],2'b00};
                            			8'b??00_???? : lru_term[1] <= {lru_term[1][7:6],lru_term[1][3:0],2'b00};
                            			8'b00??_???? : lru_term[1] <= {lru_term[1][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[1])
                            			8'b????_??01 : lru_term[1] <= {lru_term[1][7:2],2'b01};
                            			8'b????_01?? : lru_term[1] <= {lru_term[1][7:4],lru_term[1][1:0],2'b01};
                            			8'b??01_???? : lru_term[1] <= {lru_term[1][7:6],lru_term[1][3:0],2'b01};
                            			8'b01??_???? : lru_term[1] <= {lru_term[1][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[1])
                            			8'b????_??10 : lru_term[1] <= {lru_term[1][7:2],2'b10};
                            			8'b????_10?? : lru_term[1] <= {lru_term[1][7:4],lru_term[1][1:0],2'b10};
                            			8'b??10_???? : lru_term[1] <= {lru_term[1][7:6],lru_term[1][3:0],2'b10};
                            			8'b10??_???? : lru_term[1] <= {lru_term[1][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[1])
                            			8'b????_??11 : lru_term[1] <= {lru_term[1][7:2],2'b11};
                            			8'b????_11?? : lru_term[1] <= {lru_term[1][7:4],lru_term[1][1:0],2'b11};
                            			8'b??11_???? : lru_term[1] <= {lru_term[1][7:6],lru_term[1][3:0],2'b11};
                            			8'b11??_???? : lru_term[1] <= {lru_term[1][5:0],2'b11};
                            		endcase
        				endcase
        		3'b010 : 
                		case(hit[2])
        					4'b0001 :
                            		casez(lru_term[2])
                            			8'b????_??00 : lru_term[2] <= {lru_term[2][7:2],2'b00};
                            			8'b????_00?? : lru_term[2] <= {lru_term[2][7:4],lru_term[2][1:0],2'b00};
                            			8'b??00_???? : lru_term[2] <= {lru_term[2][7:6],lru_term[2][3:0],2'b00};
                            			8'b00??_???? : lru_term[2] <= {lru_term[2][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[2])
                            			8'b????_??01 : lru_term[2] <= {lru_term[2][7:2],2'b01};
                            			8'b????_01?? : lru_term[2] <= {lru_term[2][7:4],lru_term[2][1:0],2'b01};
                            			8'b??01_???? : lru_term[2] <= {lru_term[2][7:6],lru_term[2][3:0],2'b01};
                            			8'b01??_???? : lru_term[2] <= {lru_term[2][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[2])
                            			8'b????_??10 : lru_term[2] <= {lru_term[2][7:2],2'b10};
                            			8'b????_10?? : lru_term[2] <= {lru_term[2][7:4],lru_term[2][1:0],2'b10};
                            			8'b??10_???? : lru_term[2] <= {lru_term[2][7:6],lru_term[2][3:0],2'b10};
                            			8'b10??_???? : lru_term[2] <= {lru_term[2][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[2])
                            			8'b????_??11 : lru_term[2] <= {lru_term[2][7:2],2'b11};
                            			8'b????_11?? : lru_term[2] <= {lru_term[2][7:4],lru_term[2][1:0],2'b11};
                            			8'b??11_???? : lru_term[2] <= {lru_term[2][7:6],lru_term[2][3:0],2'b11};
                            			8'b11??_???? : lru_term[2] <= {lru_term[2][5:0],2'b11};
                            		endcase
        				endcase
        		3'b011 : 
                		case(hit[3])
        					4'b0001 :
                            		casez(lru_term[3])
                            			8'b????_??00 : lru_term[3] <= {lru_term[3][7:2],2'b00};
                            			8'b????_00?? : lru_term[3] <= {lru_term[3][7:4],lru_term[3][1:0],2'b00};
                            			8'b??00_???? : lru_term[3] <= {lru_term[3][7:6],lru_term[3][3:0],2'b00};
                            			8'b00??_???? : lru_term[3] <= {lru_term[3][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[3])
                            			8'b????_??01 : lru_term[3] <= {lru_term[3][7:2],2'b01};
                            			8'b????_01?? : lru_term[3] <= {lru_term[3][7:4],lru_term[3][1:0],2'b01};
                            			8'b??01_???? : lru_term[3] <= {lru_term[3][7:6],lru_term[3][3:0],2'b01};
                            			8'b01??_???? : lru_term[3] <= {lru_term[3][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[3])
                            			8'b????_??10 : lru_term[3] <= {lru_term[3][7:2],2'b10};
                            			8'b????_10?? : lru_term[3] <= {lru_term[3][7:4],lru_term[3][1:0],2'b10};
                            			8'b??10_???? : lru_term[3] <= {lru_term[3][7:6],lru_term[3][3:0],2'b10};
                            			8'b10??_???? : lru_term[3] <= {lru_term[3][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[3])
                            			8'b????_??11 : lru_term[3] <= {lru_term[3][7:2],2'b11};
                            			8'b????_11?? : lru_term[3] <= {lru_term[3][7:4],lru_term[3][1:0],2'b11};
                            			8'b??11_???? : lru_term[3] <= {lru_term[3][7:6],lru_term[3][3:0],2'b11};
                            			8'b11??_???? : lru_term[3] <= {lru_term[3][5:0],2'b11};
                            		endcase
        				endcase
        		3'b100 : 
                		case(hit[4])
        					4'b0001 :
                            		casez(lru_term[4])
                            			8'b????_??00 : lru_term[4] <= {lru_term[4][7:2],2'b00};
                            			8'b????_00?? : lru_term[4] <= {lru_term[4][7:4],lru_term[4][1:0],2'b00};
                            			8'b??00_???? : lru_term[4] <= {lru_term[4][7:6],lru_term[4][3:0],2'b00};
                            			8'b00??_???? : lru_term[4] <= {lru_term[4][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[4])
                            			8'b????_??01 : lru_term[4] <= {lru_term[4][7:2],2'b01};
                            			8'b????_01?? : lru_term[4] <= {lru_term[4][7:4],lru_term[4][1:0],2'b01};
                            			8'b??01_???? : lru_term[4] <= {lru_term[4][7:6],lru_term[4][3:0],2'b01};
                            			8'b01??_???? : lru_term[4] <= {lru_term[4][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[4])
                            			8'b????_??10 : lru_term[4] <= {lru_term[4][7:2],2'b10};
                            			8'b????_10?? : lru_term[4] <= {lru_term[4][7:4],lru_term[4][1:0],2'b10};
                            			8'b??10_???? : lru_term[4] <= {lru_term[4][7:6],lru_term[4][3:0],2'b10};
                            			8'b10??_???? : lru_term[4] <= {lru_term[4][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[4])
                            			8'b????_??11 : lru_term[4] <= {lru_term[4][7:2],2'b11};
                            			8'b????_11?? : lru_term[4] <= {lru_term[4][7:4],lru_term[4][1:0],2'b11};
                            			8'b??11_???? : lru_term[4] <= {lru_term[4][7:6],lru_term[4][3:0],2'b11};
                            			8'b11??_???? : lru_term[4] <= {lru_term[4][5:0],2'b11};
                            		endcase
        				endcase
        		3'b101 : 
                		case(hit[5])
        					4'b0001 :
                            		casez(lru_term[5])
                            			8'b????_??00 : lru_term[5] <= {lru_term[5][7:2],2'b00};
                            			8'b????_00?? : lru_term[5] <= {lru_term[5][7:4],lru_term[5][1:0],2'b00};
                            			8'b??00_???? : lru_term[5] <= {lru_term[5][7:6],lru_term[5][3:0],2'b00};
                            			8'b00??_???? : lru_term[5] <= {lru_term[5][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[5])
                            			8'b????_??01 : lru_term[5] <= {lru_term[5][7:2],2'b01};
                            			8'b????_01?? : lru_term[5] <= {lru_term[5][7:4],lru_term[5][1:0],2'b01};
                            			8'b??01_???? : lru_term[5] <= {lru_term[5][7:6],lru_term[5][3:0],2'b01};
                            			8'b01??_???? : lru_term[5] <= {lru_term[5][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[5])
                            			8'b????_??10 : lru_term[5] <= {lru_term[5][7:2],2'b10};
                            			8'b????_10?? : lru_term[5] <= {lru_term[5][7:4],lru_term[5][1:0],2'b10};
                            			8'b??10_???? : lru_term[5] <= {lru_term[5][7:6],lru_term[5][3:0],2'b10};
                            			8'b10??_???? : lru_term[5] <= {lru_term[5][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[5])
                            			8'b????_??11 : lru_term[5] <= {lru_term[5][7:2],2'b11};
                            			8'b????_11?? : lru_term[5] <= {lru_term[5][7:4],lru_term[5][1:0],2'b11};
                            			8'b??11_???? : lru_term[5] <= {lru_term[5][7:6],lru_term[5][3:0],2'b11};
                            			8'b11??_???? : lru_term[5] <= {lru_term[5][5:0],2'b11};
                            		endcase
        				endcase
        		3'b110 : 
                		case(hit[6])
        					4'b0001 :
                            		casez(lru_term[6])
                            			8'b????_??00 : lru_term[6] <= {lru_term[6][7:2],2'b00};
                            			8'b????_00?? : lru_term[6] <= {lru_term[6][7:4],lru_term[6][1:0],2'b00};
                            			8'b??00_???? : lru_term[6] <= {lru_term[6][7:6],lru_term[6][3:0],2'b00};
                            			8'b00??_???? : lru_term[6] <= {lru_term[6][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[6])
                            			8'b????_??01 : lru_term[6] <= {lru_term[6][7:2],2'b01};
                            			8'b????_01?? : lru_term[6] <= {lru_term[6][7:4],lru_term[6][1:0],2'b01};
                            			8'b??01_???? : lru_term[6] <= {lru_term[6][7:6],lru_term[6][3:0],2'b01};
                            			8'b01??_???? : lru_term[6] <= {lru_term[6][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[6])
                            			8'b????_??10 : lru_term[6] <= {lru_term[6][7:2],2'b10};
                            			8'b????_10?? : lru_term[6] <= {lru_term[6][7:4],lru_term[6][1:0],2'b10};
                            			8'b??10_???? : lru_term[6] <= {lru_term[6][7:6],lru_term[6][3:0],2'b10};
                            			8'b10??_???? : lru_term[6] <= {lru_term[6][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[6])
                            			8'b????_??11 : lru_term[6] <= {lru_term[6][7:2],2'b11};
                            			8'b????_11?? : lru_term[6] <= {lru_term[6][7:4],lru_term[6][1:0],2'b11};
                            			8'b??11_???? : lru_term[6] <= {lru_term[6][7:6],lru_term[6][3:0],2'b11};
                            			8'b11??_???? : lru_term[6] <= {lru_term[6][5:0],2'b11};
                            		endcase
        				endcase
        		3'b111 : 
                		case(hit[7])
        					4'b0001 :
                            		casez(lru_term[7])
                            			8'b????_??00 : lru_term[7] <= {lru_term[7][7:2],2'b00};
                            			8'b????_00?? : lru_term[7] <= {lru_term[7][7:4],lru_term[7][1:0],2'b00};
                            			8'b??00_???? : lru_term[7] <= {lru_term[7][7:6],lru_term[7][3:0],2'b00};
                            			8'b00??_???? : lru_term[7] <= {lru_term[7][5:0],2'b00};
                            		endcase
        					4'b0010 : 
                            		casez(lru_term[7])
                            			8'b????_??01 : lru_term[7] <= {lru_term[7][7:2],2'b01};
                            			8'b????_01?? : lru_term[7] <= {lru_term[7][7:4],lru_term[7][1:0],2'b01};
                            			8'b??01_???? : lru_term[7] <= {lru_term[7][7:6],lru_term[7][3:0],2'b01};
                            			8'b01??_???? : lru_term[7] <= {lru_term[7][5:0],2'b01};
                            		endcase
        					4'b0100 : 
                            		casez(lru_term[7])
                            			8'b????_??10 : lru_term[7] <= {lru_term[7][7:2],2'b10};
                            			8'b????_10?? : lru_term[7] <= {lru_term[7][7:4],lru_term[7][1:0],2'b10};
                            			8'b??10_???? : lru_term[7] <= {lru_term[7][7:6],lru_term[7][3:0],2'b10};
                            			8'b10??_???? : lru_term[7] <= {lru_term[7][5:0],2'b10};
                            		endcase
        					4'b1000 : 
                            		casez(lru_term[7])
                            			8'b????_??11 : lru_term[7] <= {lru_term[7][7:2],2'b11};
                            			8'b????_11?? : lru_term[7] <= {lru_term[7][7:4],lru_term[7][1:0],2'b11};
                            			8'b??11_???? : lru_term[7] <= {lru_term[7][7:6],lru_term[7][3:0],2'b11};
                            			8'b11??_???? : lru_term[7] <= {lru_term[7][5:0],2'b11};
                            		endcase
        				endcase
        	endcase
    end
    
    
endmodule