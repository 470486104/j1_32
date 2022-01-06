module cache_l2(
	input clk		,
	input rst		,	
    
    input wire 				core0_inst_valid		,
    input wire				core0_inst_rd_wr		,
    input wire[13:0]		core0_inst_addr			,
    output reg				core0_inst_page_wr		,
    output reg[127:0]		core0_inst_page_din		,
    output wire				core0_inst_c_dirty		,
    output wire[13:0]		core0_inst_c_dirty_addr	,
    input wire 				core0_data_valid		,
    input wire				core0_data_rd_wr		,
    input wire[13:0]		core0_data_addr			,
    input wire[31:0]		core0_data_dout			,
    output reg				core0_data_page_wr		,
    output reg[127:0]		core0_data_page_din		,
    output reg				core0_data_wr_ack		,
    output wire				core0_data_c_dirty		,
    output wire[13:0]		core0_data_c_dirty_addr	,
    
    input wire 				core1_inst_valid		,
    input wire				core1_inst_rd_wr		,
    input wire[13:0]		core1_inst_addr			,
    output reg				core1_inst_page_wr		,
    output reg[127:0]		core1_inst_page_din		,
    output wire				core1_inst_c_dirty		,
    output wire[13:0]		core1_inst_c_dirty_addr	,
    input wire 				core1_data_valid		,
    input wire				core1_data_rd_wr		,
    input wire[13:0]		core1_data_addr			,
    input wire[31:0]		core1_data_dout			,
    output reg				core1_data_page_wr		,
    output reg[127:0]		core1_data_page_din		,
    output reg				core1_data_wr_ack		,
    output wire				core1_data_c_dirty		,
    output wire[13:0]		core1_data_c_dirty_addr	,
    
    input wire 				core2_inst_valid		,
    input wire				core2_inst_rd_wr		,
    input wire[13:0]		core2_inst_addr			,
    output reg				core2_inst_page_wr		,
    output reg[127:0]		core2_inst_page_din		,
    output wire				core2_inst_c_dirty		,
    output wire[13:0]		core2_inst_c_dirty_addr	,
    input wire 				core2_data_valid		,
    input wire				core2_data_rd_wr		,
    input wire[13:0]		core2_data_addr			,
    input wire[31:0]		core2_data_dout			,
    output reg				core2_data_page_wr		,
    output reg[127:0]		core2_data_page_din		,
    output reg				core2_data_wr_ack		,
    output wire				core2_data_c_dirty		,
    output wire[13:0]		core2_data_c_dirty_addr	,
    
    input wire 				core3_inst_valid		,
    input wire				core3_inst_rd_wr		,
    input wire[13:0]		core3_inst_addr			,
    output reg				core3_inst_page_wr		,
    output reg[127:0]		core3_inst_page_din		,
    output wire				core3_inst_c_dirty		,
    output wire[13:0]		core3_inst_c_dirty_addr	,
    input wire 				core3_data_valid		,
    input wire				core3_data_rd_wr		,
    input wire[13:0]		core3_data_addr			,
    input wire[31:0]		core3_data_dout			,
    output reg				core3_data_page_wr		,
    output reg[127:0]		core3_data_page_din		,
    output reg				core3_data_wr_ack		,
    output wire				core3_data_c_dirty		,
    output wire[13:0]		core3_data_c_dirty_addr	,
    
	// RAM
    output reg 				mem_rd_wr1				,
    output reg				mem_valid1				,
    output wire[13:0]		mem_addr1 				,
    output reg[127:0]		mem_din1 				,
    input wire[127:0]		mem_dout1				,
    input wire				mem_ack1				,
    
    output reg 				mem_rd_wr2				,
    output reg				mem_valid2				,
    output wire[13:0]		mem_addr2 				,
    output reg[127:0]		mem_din2 				,
    input wire[127:0]		mem_dout2				,
    input wire				mem_ack2					
);
	// cache 2级
	reg[3:0] read_write_cycle_count;
    
    reg[31:0] c_mem0[0:511];
    reg[31:0] c_mem1[0:511];
    reg[31:0] c_mem2[0:511];
    reg[31:0] c_mem3[0:511];
    reg[2:0] tag[0:511];
    reg c_tag_rd1,c_tag_rd2;
    reg[0:511] valid,dirty;
    reg[2:0] c_tag1,c_tag2;
    reg c_valid1,c_valid2,c_dirty1,c_dirty2;
    
    reg[3:0] data_miss,inst_miss;
    
    reg[1:0] sel_data,old_sel_data,sel_inst,old_sel_inst;
    reg end_sel_data,end_sel_inst;
    wire[3:0] data_list,inst_list;
    assign data_list = {core3_data_valid,core2_data_valid,core1_data_valid,core0_data_valid};
    assign inst_list = {core3_inst_valid,core2_inst_valid,core1_inst_valid,core0_inst_valid};
    
    reg m_valid1,m_valid2;
    reg m_rd_wr1,m_rd_wr2;
    reg m0_rd_wr1,m0_rd_wr2;
    reg m1_rd_wr1,m1_rd_wr2;
    reg m2_rd_wr1,m2_rd_wr2;
    reg m3_rd_wr1,m3_rd_wr2;
    reg[31:0] dout10,dout11,dout12,dout13;
    reg[31:0] dout20,dout21,dout22,dout23;
    wire[127:0] m_dout1 = {dout13,dout12,dout11,dout10};
    wire[127:0] m_dout2 = {dout23,dout22,dout21,dout20};
    reg[31:0] m_din1_single;
    reg[127:0] m_din1,m_din2;
    reg[13:0] m_addr1,m_addr2;
    reg m_allow_port1,m_allow_port2;
    
    reg swap_out1,swap_out2;
    
    reg[3:0] data_c_dirty;
    reg[13:0] data_c_dirty_addr;
    
    reg core_wr1;
    reg[127:0] mem_dout_reg1;
    
    
    // 读写周期
    always @(posedge clk)
    begin
    	if(rst)
    		read_write_cycle_count <= 0;
        else if(read_write_cycle_count == 4'ha)
        	read_write_cycle_count <= 0;
        else if(!(|read_write_cycle_count) && (|data_list && !mem_valid1 || |inst_list && !mem_valid2 || mem_ack1 || mem_ack2))
        	read_write_cycle_count <= 1;
        else if(|read_write_cycle_count)
        	read_write_cycle_count <= read_write_cycle_count + 1;
    end
    
    // cache_l2读写仲裁 数据端口
    always @(posedge clk)
    begin
    	if(rst)
    		sel_data <= 3;
        else if(|data_list && read_write_cycle_count == 1 && !mem_valid1)
        	case(old_sel_data)
				2'b00 : if(data_list[1]) sel_data<= 1; else if(data_list[2]) sel_data<= 2; else if(data_list[3]) sel_data<= 3; else if(data_list[0]) sel_data<= 0;
				2'b01 : if(data_list[2]) sel_data<= 2; else if(data_list[3]) sel_data<= 3; else if(data_list[0]) sel_data<= 0; else if(data_list[1]) sel_data<= 1;
				2'b10 : if(data_list[3]) sel_data<= 3; else if(data_list[0]) sel_data<= 0; else if(data_list[1]) sel_data<= 1; else if(data_list[2]) sel_data<= 2;
				default : if(data_list[0]) sel_data<= 0; else if(data_list[1]) sel_data<= 1; else if(data_list[2]) sel_data<= 2; else if(data_list[3]) sel_data<= 3;
			endcase
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		old_sel_data <= 3;
        else
        	old_sel_data <= sel_data;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		m_allow_port1 <= 0;
        else if(|data_list && read_write_cycle_count == 1 && !mem_valid1) // cache存储器端口1能被1级cache访问
        	m_allow_port1 <= 1;
        else if(read_write_cycle_count == 4'ha)
        	m_allow_port1 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		c_tag_rd1 <= 0;
        else if(|data_list && read_write_cycle_count == 2 && !mem_valid1) // 当1级cache有读写需求时，开启cache标识和状态的读使能
        	c_tag_rd1 <= 1;
        else if(read_write_cycle_count == 3)
    	    c_tag_rd1 <= 0;
    end
    
    // cache_l2数据端口  信号处理 
    always @(posedge clk)
    begin
    	if(rst)
        begin
    		m_addr1 <= 0;
        end else
        begin
        	if(read_write_cycle_count == 2 && m_allow_port1) // 数据端口的地址更新
        		case(sel_data)
        			2'b00 : m_addr1 <= core0_data_addr;
        			2'b01 : m_addr1 <= core1_data_addr;
        			2'b10 : m_addr1 <= core2_data_addr;
        			2'b11 : m_addr1 <= core3_data_addr;
        		endcase
        end 
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		m_din1_single <= 0;
        else if(read_write_cycle_count == 3 && m_allow_port1) // 接收来自1级cache的数据
        		case(sel_data)
        			2'b00 : m_din1_single <= core0_data_dout;
        			2'b01 : m_din1_single <= core1_data_dout;
        			2'b10 : m_din1_single <= core2_data_dout;
        			2'b11 : m_din1_single <= core3_data_dout;
        		endcase
        // else if(read_write_cycle_count == 4'ha)
        	// m_din1_single <= 0;
    end
	
    always @(*)
    begin
    	if(rst)
        	core_wr1 = 0;
        else if(mem_valid1 && mem_ack1) 
        	case(sel_data)
        		2'b00 : core_wr1 = core0_data_valid && core0_data_rd_wr; // 从内存送来数据时，是否有来自一级cache的写数据
        		2'b01 : core_wr1 = core1_data_valid && core1_data_rd_wr;
        		2'b10 : core_wr1 = core2_data_valid && core2_data_rd_wr;
        		2'b11 : core_wr1 = core3_data_valid && core3_data_rd_wr;
        	endcase
        else
        	core_wr1 = 0;
    end
    
    always @(*)
    begin
    	if(rst)
        	mem_dout_reg1 = 0;
        else if(mem_valid1 && mem_ack1 && read_write_cycle_count == 4 && core_wr1) // 有来自一级cache的写数据则更新从内存送来数据
        	case(m_addr1[1:0])
        		2'b00 : mem_dout_reg1 = {mem_dout1[127:32],m_din1_single};
        		2'b01 : mem_dout_reg1 = {mem_dout1[127:64],m_din1_single,mem_dout1[31:0]};
        		2'b10 : mem_dout_reg1 = {mem_dout1[127:96],m_din1_single,mem_dout1[63:0]};
        		2'b11 : mem_dout_reg1 = {m_din1_single,mem_dout1[95:0]};
        	endcase
        else
        	mem_dout_reg1 = mem_dout1;
    end
    
    // 更新端口1 的写入数据
    always @(posedge clk)
    begin
    	if(rst)
    		m_din1 <= 0;
        else if(mem_valid1 && mem_ack1 && read_write_cycle_count == 4) 
        		m_din1 <= mem_dout_reg1;
        else if(read_write_cycle_count == 4 && m_allow_port1)
        	case(m_addr1[1:0])
        		2'b00 : m_din1[31:0]	<= m_din1_single;
        		2'b01 : m_din1[63:32]	<= m_din1_single;
        		2'b10 : m_din1[95:64]	<= m_din1_single;
        		2'b11 : m_din1[127:96]	<= m_din1_single;
        	endcase
        else if(read_write_cycle_count == 4'ha)
        	m_din1 <= 0;
    end
    
   	// cache 读写使能
    always @(posedge clk)
    begin
    	if(rst)
    		m_valid1 <= 0;
    	else if((m_allow_port1 && c_valid1 || mem_valid1 && mem_ack1) && read_write_cycle_count == 4) // 有来自内存的数据或1级cache读写需求时，开启cache存储器的1端口
        	m_valid1 <= 1;
        else
        	m_valid1 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		m_rd_wr1 <= 0;
    	else if(read_write_cycle_count == 4)
        begin
        	if(mem_valid1 && !mem_rd_wr1 && mem_ack1) // 数据来自内存时 为写使能  0读 1写
            	m_rd_wr1 <= 1;
            else if(m_allow_port1 && c_valid1) // 数据来自1级cache时 为当前仲裁的1级cache的读写需求
            	if(c_tag1 == m_addr1[13:11])
        			case(sel_data)
        				2'b00 : m_rd_wr1 <= core0_data_rd_wr;
        				2'b01 : m_rd_wr1 <= core1_data_rd_wr;
        				2'b10 : m_rd_wr1 <= core2_data_rd_wr;
        				2'b11 : m_rd_wr1 <= core3_data_rd_wr;
        			endcase
                // else if(c_tag1 != m_addr1[13:11] && c_dirty1)
                	// m_rd_wr1 <= 0;
        end else
        	m_rd_wr1 <= 0;
    end
    
    
    
    always @(posedge clk)
    begin
    	if(rst)
    		swap_out1 <= 0;
        else if(read_write_cycle_count == 6 && m_allow_port1 && c_dirty1 && c_valid1) 
        begin
        	if(c_tag1 != m_addr1[13:11]) // cache未命中 且当前cache页为脏时 页面换出
        		swap_out1 <= 1;
        end else if(mem_valid1 && !mem_rd_wr1 && mem_ack1)
            	swap_out1 <= 0;
    end
    
    assign mem_addr1 = mem_valid1 && mem_rd_wr1 ? {c_tag1,m_addr1[10:0]} : m_addr1; // 需要将数据写入到内存时，为换出页地址；不需要写入到内存时为当前仲裁地址
    always @(posedge clk)
    begin
    	if(rst)
        begin
            mem_valid1 <= 0;
    		mem_rd_wr1 <= 0;
            mem_din1 <= 0;
        end else if(read_write_cycle_count == 6 && m_allow_port1)
        begin
            if(c_dirty1 && c_valid1 && c_tag1 != m_addr1[13:11]) // 数据未命中且脏，需要被换出到内存
            begin
            	mem_valid1 <= 1;
                mem_rd_wr1 <= 1; // 0读 1写
            	mem_din1 <= m_dout1;
            end else if((!c_dirty1 && c_valid1 && c_tag1 != m_addr1[13:11]) || !c_valid1) // 数据未命中且不脏或者数据无效，从内存读数据
            begin
            	mem_valid1 <= 1;
                mem_rd_wr1 <= 0;
            	mem_din1 <= 0;
            end 
        end else if(mem_ack1 && read_write_cycle_count == 4'h6) // 收到来自内存的数据 重置使能信号
        begin
        	mem_valid1 <= 0;
        	mem_rd_wr1 <= 0;
            mem_din1 <= 0;
        end else if(!mem_valid1 && mem_ack1 && read_write_cycle_count == 4'h7)
        begin
        	mem_valid1 <= swap_out1; // cache未命中 且当前cache页为脏时 页面换出后 需要将数据从内存中读出
        	mem_rd_wr1 <= 0;
            mem_din1 <= 0;
        end
    end
    
    // 写入1级数据缓存 信号处理 
    always @(posedge clk)
    begin
    	if(rst)
    	begin
    		core0_data_page_wr <= 0;
    		core1_data_page_wr <= 0;
    		core2_data_page_wr <= 0;
    		core3_data_page_wr <= 0;
            
            core0_data_page_din <= 0;
            core1_data_page_din <= 0;
            core2_data_page_din <= 0;
            core3_data_page_din <= 0;
    	end else if(mem_ack1 && mem_valid1 && !mem_rd_wr1 && read_write_cycle_count == 6) // 把从内存中读来的数据送入 1级cache
    	begin
    		case(sel_data)
    			2'b00 : begin if(core0_data_valid && !core0_data_rd_wr) begin core0_data_page_wr <= 1; core0_data_page_din <= mem_dout1; end end
    			2'b01 : begin if(core1_data_valid && !core1_data_rd_wr) begin core1_data_page_wr <= 1; core1_data_page_din <= mem_dout1; end end
    			2'b10 : begin if(core2_data_valid && !core2_data_rd_wr) begin core2_data_page_wr <= 1; core2_data_page_din <= mem_dout1; end end
    			2'b11 : begin if(core3_data_valid && !core3_data_rd_wr) begin core3_data_page_wr <= 1; core3_data_page_din <= mem_dout1; end end
    		endcase
    	end else if(read_write_cycle_count == 6 && m_allow_port1 && c_valid1 && c_tag1 == m_addr1[13:11]) // 把从cache中读来的数据送入 1级cache
        begin
        	case(sel_data)
    			2'b00 : if(core0_data_valid && !core0_data_rd_wr) begin core0_data_page_wr <= 1; core0_data_page_din <= m_dout1; end
    			2'b01 : if(core1_data_valid && !core1_data_rd_wr) begin core1_data_page_wr <= 1; core1_data_page_din <= m_dout1; end
    			2'b10 : if(core2_data_valid && !core2_data_rd_wr) begin core2_data_page_wr <= 1; core2_data_page_din <= m_dout1; end
    			2'b11 : if(core3_data_valid && !core3_data_rd_wr) begin core3_data_page_wr <= 1; core3_data_page_din <= m_dout1; end
    		endcase
        end else
        begin
        	core0_data_page_wr <= 0;
    		core1_data_page_wr <= 0;
    		core2_data_page_wr <= 0;
    		core3_data_page_wr <= 0;
            
            core0_data_page_din <= 0;
            core1_data_page_din <= 0;
            core2_data_page_din <= 0;
            core3_data_page_din <= 0;
        end 
    end
    
    // 写入cache_l2确认信号
    always @(posedge clk)
    begin
    	if(rst)
    	begin
    		core0_data_wr_ack <= 0;
            core1_data_wr_ack <= 0;
            core2_data_wr_ack <= 0;
            core3_data_wr_ack <= 0;
    	end else if(m_valid1 && m_rd_wr1 && read_write_cycle_count == 5)
    	begin
        	case(sel_data)
        		2'b00 : if(core0_data_valid && core0_data_rd_wr) core0_data_wr_ack <= 1; // 有数据写入到cache中时，向cache 1级发出写确认
                2'b01 : if(core1_data_valid && core1_data_rd_wr) core1_data_wr_ack <= 1;
                2'b10 : if(core2_data_valid && core2_data_rd_wr) core2_data_wr_ack <= 1;
                2'b11 : if(core3_data_valid && core3_data_rd_wr) core3_data_wr_ack <= 1;
        	endcase
    	end else
        begin
        	core0_data_wr_ack <= 0;
            core1_data_wr_ack <= 0;
            core2_data_wr_ack <= 0;
            core3_data_wr_ack <= 0;
        end 
    end
    
    // cache_l2读写仲裁 指令端口
	always @(posedge clk)
    begin
    	if(rst)
    		sel_inst <= 3;
        else if(|inst_list && read_write_cycle_count == 1 && !mem_valid2)
        	case(old_sel_inst)
				2'b00 : if(inst_list[1]) sel_inst<= 1; else if(inst_list[2]) sel_inst<= 2; else if(inst_list[3]) sel_inst<= 3; else if(inst_list[0]) sel_inst<= 0;
				2'b01 : if(inst_list[2]) sel_inst<= 2; else if(inst_list[3]) sel_inst<= 3; else if(inst_list[0]) sel_inst<= 0; else if(inst_list[1]) sel_inst<= 1;
				2'b10 : if(inst_list[3]) sel_inst<= 3; else if(inst_list[0]) sel_inst<= 0; else if(inst_list[1]) sel_inst<= 1; else if(inst_list[2]) sel_inst<= 2;
				default : if(inst_list[0]) sel_inst<= 0; else if(inst_list[1]) sel_inst<= 1; else if(inst_list[2]) sel_inst<= 2; else if(inst_list[3]) sel_inst<= 3;
			endcase
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		old_sel_inst <= 3;
        else
        	old_sel_inst <= sel_inst;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		m_allow_port2 <= 0;
        else if(|inst_list && read_write_cycle_count == 1 && !mem_valid2)
        	m_allow_port2 <= 1;
        else if(read_write_cycle_count == 4'ha)
        	m_allow_port2 <= 0;
    end
    
    // cache_l2指令端口  信号处理 
    always @(posedge clk)
    begin
    	if(rst)
    		m_addr2 <= 0;
        else
        begin
        	if(read_write_cycle_count == 2 && m_allow_port2)
            	case(sel_inst)
            		2'b00 : m_addr2 <= core0_inst_addr;
                    2'b01 : m_addr2 <= core1_inst_addr;
                    2'b10 : m_addr2 <= core2_inst_addr;
                    2'b11 : m_addr2 <= core3_inst_addr;
            	endcase
        end 
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		m_din2 <= 0;
        else if(mem_valid2 && mem_ack2 && read_write_cycle_count == 4)
        	m_din2 <= mem_dout2;
        else if(read_write_cycle_count == 4'ha)
        	m_din2 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		m_valid2 <= 0;
        else if((m_allow_port2 && c_valid2 || mem_valid2 && mem_ack2) && read_write_cycle_count == 4)
        	m_valid2 <= 1;
        else
        	m_valid2 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		m_rd_wr2 <= 0;
        else if(read_write_cycle_count == 4)
        begin
        	if(mem_valid2 && !mem_rd_wr2 && mem_ack2)
            	m_rd_wr2 <= 1;
            else if(m_allow_port2 && c_valid2)
            	if(c_tag2 == m_addr2[13:11])
                	case(sel_inst)
        				2'b00 : m_rd_wr2 <= core0_inst_rd_wr;
        				2'b01 : m_rd_wr2 <= core1_inst_rd_wr;
        				2'b10 : m_rd_wr2 <= core2_inst_rd_wr;
        				2'b11 : m_rd_wr2 <= core3_inst_rd_wr;
        			endcase
                // else if(c_tag2 != m_addr2[13:11] && c_dirty2)
                	// m_rd_wr2 <= 0;
        end else
        	m_rd_wr2 <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		c_tag_rd2 <= 0;
        else if(|inst_list && read_write_cycle_count == 2 && !mem_valid2)
        	c_tag_rd2 <= 1;
        else if(read_write_cycle_count == 3)
    	    c_tag_rd2 <= 0;
    end

	always @(posedge clk)
    begin
    	if(rst)
    		swap_out2 <= 0;
        else if(read_write_cycle_count == 6 && m_allow_port2 && c_dirty2 && c_valid2)
        begin
        	if(c_tag2 != m_addr2[13:11])
        		swap_out2 <= 1;
        end else if(mem_valid2 && !mem_rd_wr2 && mem_ack2)
            	swap_out2 <= 0;
    end
    
    assign mem_addr2 = mem_valid2 && mem_rd_wr2 ? {c_tag2,m_addr2[10:0]} : m_addr2;
    always @(posedge clk)
    begin
    	if(rst)
        begin
        	mem_valid2 <= 0;
    		mem_rd_wr2 <= 0;
            mem_din2 <= 0;
        end else if(read_write_cycle_count == 6 && m_allow_port2)
        begin
            if(c_dirty2 && c_valid2 && c_tag2 != m_addr2[13:11])
            begin
            	mem_valid2 <= 1;
                mem_rd_wr2 <= 1;
            	mem_din2 <= m_dout2;
            end else if((!c_dirty2 && c_valid2 && c_tag2 != m_addr2[13:11]) || !c_valid2)
            begin
            	mem_valid2 <= 1;
                mem_rd_wr2 <= 0;
            	mem_din2 <= 0;
            end 
        end else if(mem_valid2 && mem_ack2 && read_write_cycle_count == 4'h7)
        begin
        	mem_valid2 <= 0;
        	mem_rd_wr2 <= 0;
            mem_din2 <= 0;
        end else if(!mem_valid2 && mem_ack2 && read_write_cycle_count == 4'h8)
        begin
        	mem_valid2 <= swap_out2;
        	mem_rd_wr2 <= 0;
            mem_din2 <= 0;
        end 
    end

    
    // 写入1级指令缓存 信号处理 
    always @(posedge clk)
    begin
    	if(rst)
    	begin
    		core0_inst_page_wr <= 0;
    		core1_inst_page_wr <= 0;
    		core2_inst_page_wr <= 0;
    		core3_inst_page_wr <= 0;
            
            core0_inst_page_din <= 0;
            core1_inst_page_din <= 0;
            core2_inst_page_din <= 0;
            core3_inst_page_din <= 0;
    	end else if(mem_ack2 && mem_valid2 && !mem_rd_wr2 && read_write_cycle_count == 6)
    	begin
    		case(sel_inst)
    			2'b00 : if(core0_inst_valid && !core0_inst_rd_wr) begin core0_inst_page_wr <= 1; core0_inst_page_din <= mem_dout2; end
    			2'b01 : if(core1_inst_valid && !core1_inst_rd_wr) begin core1_inst_page_wr <= 1; core1_inst_page_din <= mem_dout2; end
    			2'b10 : if(core2_inst_valid && !core2_inst_rd_wr) begin core2_inst_page_wr <= 1; core2_inst_page_din <= mem_dout2; end
    			2'b11 : if(core3_inst_valid && !core3_inst_rd_wr) begin core3_inst_page_wr <= 1; core3_inst_page_din <= mem_dout2; end
    		endcase
    	end else if(read_write_cycle_count == 6 && m_allow_port2 && c_valid2 && c_tag2 == m_addr2[13:11])
        begin
        	case(sel_inst)
    			2'b00 : if(core0_inst_valid && !core0_inst_rd_wr) begin core0_inst_page_wr <= 1; core0_inst_page_din <= m_dout2; end
    			2'b01 : if(core1_inst_valid && !core1_inst_rd_wr) begin core1_inst_page_wr <= 1; core1_inst_page_din <= m_dout2; end
    			2'b10 : if(core2_inst_valid && !core2_inst_rd_wr) begin core2_inst_page_wr <= 1; core2_inst_page_din <= m_dout2; end
    			2'b11 : if(core3_inst_valid && !core3_inst_rd_wr) begin core3_inst_page_wr <= 1; core3_inst_page_din <= m_dout2; end
    		endcase
        end else
        begin
        	core0_inst_page_wr <= 0;
    		core1_inst_page_wr <= 0;
    		core2_inst_page_wr <= 0;
    		core3_inst_page_wr <= 0;
            
            core0_inst_page_din <= 0;
            core1_inst_page_din <= 0;
            core2_inst_page_din <= 0;
            core3_inst_page_din <= 0;
        end 
    end
    

    
    always @(posedge clk)
    begin
    	if(c_tag_rd1)
    		c_tag1 <= tag[m_addr1[10:2]];
    	else if(m_valid1 && m_rd_wr1 && mem_ack1 && mem_valid1)
        	tag[m_addr1[10:2]] <= m_addr1[13:11];
    end
    always @(posedge clk)
    begin
    	if(c_tag_rd2)
        	c_tag2 <= tag[m_addr2[10:2]];
        else if(m_valid2 && m_rd_wr2 && mem_ack2 && mem_valid2)
        	tag[m_addr2[10:2]] <= m_addr2[13:11];
    end
    
    
    always @(posedge clk)
    begin
    	if(rst)
        begin
        	c_valid1 <= 0;
            c_valid2 <= 0;
            valid <= 0;
        end else
        begin
        	if(c_tag_rd1)
        		c_valid1 <= valid[m_addr1[10:2]];
        	else if(m_valid1 && m_rd_wr1 && mem_ack1 && mem_valid1)
        		valid[m_addr1[10:2]] <= 1;
        	    
        	if(c_tag_rd2)
        		c_valid2 <= valid[m_addr2[10:2]];
        	else if(m_valid2 && m_rd_wr2 && mem_ack2 && mem_valid2)
        		valid[m_addr2[10:2]] <= 1;
        end 
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        begin
        	c_dirty1 <= 0;
        	c_dirty2 <= 0;
			dirty <= 0;
        end else
        begin
        	if(c_tag_rd1)
        		c_dirty1 <= dirty[m_addr1[10:2]];
        	else if(m_valid1 && m_rd_wr1 && core_wr1)
        		dirty[m_addr1[10:2]] <= 1;
            else if(m_valid1 && m_rd_wr1)
            	dirty[m_addr1[10:2]] <= m_allow_port1;
        	    
        	if(c_tag_rd2)
        		c_dirty2 <= dirty[m_addr2[10:2]];
        	else if(m_valid2 && m_rd_wr2)
        		dirty[m_addr2[10:2]] <= m_allow_port2;
        end 
    end
    
    always @(*)
    begin
    	if(rst)
        	m0_rd_wr1 = 0;
        else if(m_valid1 && m_rd_wr1 && (m_allow_port1 && m_addr1[1:0] == 2'b00 || mem_valid1 && mem_ack1))
        	m0_rd_wr1 = 1;
        else
        	m0_rd_wr1 = 0;
    end
    always @(*)
    begin
    	if(rst)
        	m1_rd_wr1 = 0;
        else if(m_valid1 && m_rd_wr1 && (m_allow_port1 && m_addr1[1:0] == 2'b01 || mem_valid1 && mem_ack1))
        	m1_rd_wr1 = 1;
        else
        	m1_rd_wr1 = 0;
    end
    always @(*)
    begin
    	if(rst)
        	m2_rd_wr1 = 0;
        else if(m_valid1 && m_rd_wr1 && (m_allow_port1 && m_addr1[1:0] == 2'b10 || mem_valid1 && mem_ack1))
        	m2_rd_wr1 = 1;
        else
        	m2_rd_wr1 = 0;
    end
    always @(*)
    begin
    	if(rst)
        	m3_rd_wr1 = 0;
        else if(m_valid1 && m_rd_wr1 && (m_allow_port1 && m_addr1[1:0] == 2'b11 || mem_valid1 && mem_ack1))
        	m3_rd_wr1 = 1;
        else
        	m3_rd_wr1 = 0;
    end
    
    always @(posedge clk)
    begin
    	if(m_valid1)
        	if(m0_rd_wr1)
            	c_mem0[m_addr1[10:2]] <= m_din1[31:0];
            else
            	dout10 <= c_mem0[m_addr1[10:2]];
           end
    always @(posedge clk)
    begin
    	if(m_valid2)
        	if(m_rd_wr2)
            	c_mem0[m_addr2[10:2]] <= m_din2[31:0];
            else
            	dout20 <= c_mem0[m_addr2[10:2]];
    end
    
    always @(posedge clk)
    begin
    	if(m_valid1)
        	if(m1_rd_wr1)
            	c_mem1[m_addr1[10:2]] <= m_din1[63:32];
            else
            	dout11 <= c_mem1[m_addr1[10:2]];
    end
    always @(posedge clk)
    begin
    	if(m_valid2)
        	if(m_rd_wr2)
            	c_mem1[m_addr2[10:2]] <= m_din2[63:32];
            else
            	dout21 <= c_mem1[m_addr2[10:2]];
    end
    
    always @(posedge clk)
    begin
    	if(m_valid1)
        	if(m2_rd_wr1)
            	c_mem2[m_addr1[10:2]] <= m_din1[95:64];
            else
            	dout12 <= c_mem2[m_addr1[10:2]];
    end
    always @(posedge clk)
    begin
    	if(m_valid2)
        	if(m_rd_wr2)
            	c_mem2[m_addr2[10:2]] <= m_din2[95:64];
            else
            	dout22 <= c_mem2[m_addr2[10:2]];
    end
    
    always @(posedge clk)
    begin
    	if(m_valid1)
        	if(m3_rd_wr1)
            	c_mem3[m_addr1[10:2]] <= m_din1[127:96];
            else
            	dout13 <= c_mem3[m_addr1[10:2]];
    end
    always @(posedge clk)
    begin
    	if(m_valid2)
        	if(m_rd_wr2)
            	c_mem3[m_addr2[10:2]] <= m_din2[127:96];
            else
            	dout23 <= c_mem3[m_addr2[10:2]];
    end
    

	// cache一致性
    always @(posedge clk)
    begin
    	if(rst)
    	begin
    		data_c_dirty <= 0;
            data_c_dirty_addr <= 0;
    	end if(read_write_cycle_count == 5 && m_valid1 && m_rd_wr1)
        		case(sel_data)
        			2'b00 : begin if(core0_data_valid && core0_data_rd_wr) data_c_dirty <= 4'b0001; data_c_dirty_addr <= core0_data_addr; end
        			2'b01 : begin if(core1_data_valid && core1_data_rd_wr) data_c_dirty <= 4'b0010; data_c_dirty_addr <= core1_data_addr; end
        			2'b10 : begin if(core2_data_valid && core2_data_rd_wr) data_c_dirty <= 4'b0100; data_c_dirty_addr <= core2_data_addr; end
        			2'b11 : begin if(core3_data_valid && core3_data_rd_wr) data_c_dirty <= 4'b1000; data_c_dirty_addr <= core3_data_addr; end
        		endcase
        else if(read_write_cycle_count == 6)
        begin
        	data_c_dirty <= 0;
            data_c_dirty_addr <= 0;
        end 
    end
    
    assign core0_data_c_dirty = |(data_c_dirty & 4'b1110);
    assign core1_data_c_dirty = |(data_c_dirty & 4'b1101);
    assign core2_data_c_dirty = |(data_c_dirty & 4'b1011);
    assign core3_data_c_dirty = |(data_c_dirty & 4'b0111);
    assign core0_data_c_dirty_addr = data_c_dirty_addr;
    assign core1_data_c_dirty_addr = data_c_dirty_addr;
    assign core2_data_c_dirty_addr = data_c_dirty_addr;
    assign core3_data_c_dirty_addr = data_c_dirty_addr;
    
    assign core0_inst_c_dirty = |data_c_dirty;
    assign core1_inst_c_dirty = |data_c_dirty;
    assign core2_inst_c_dirty = |data_c_dirty;
    assign core3_inst_c_dirty = |data_c_dirty;
    assign core0_inst_c_dirty_addr = data_c_dirty_addr;
    assign core1_inst_c_dirty_addr = data_c_dirty_addr;
    assign core2_inst_c_dirty_addr = data_c_dirty_addr;
    assign core3_inst_c_dirty_addr = data_c_dirty_addr;
endmodule