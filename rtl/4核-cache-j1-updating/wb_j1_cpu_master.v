`include "define.v"
module wb_j1_cpu_master
#(
	parameter is_master = 1,
	parameter num = 0
 )
(
	input clk, 
	input rst, 
	
    input  wire						cache_data_miss	    ,
    input  wire						cache_data_wr_wait  ,
    input  wire	[`DataWidth]		cache_data_dout	    ,
    output reg						cache_data_valid	,
    output reg						cache_data_rd_wr	,
    output reg	[`PcWidth]			cache_data_addr	    ,
    output reg	[`DataWidth]		cache_data_din	    ,
    
    input  wire						cache_inst_miss	    ,
    input  wire	[`DataWidth]		cache_inst_dout	    ,
    output wire						cache_inst_valid	,
    output wire						cache_inst_rd_wr	,
    output wire	[`PcWidth]			cache_inst_addr	    ,
    
	input  wire	[`UartDataWidth]	cpu_uart_dat_i		,
	output reg	[`CpuNumWidth]		cpu_uart_num		,
	output wire	[`UartDataWidth]	cpu_uart_dat_o		,
	output wire						cpu_uart_rd_o		,
	output wire						cpu_uart_wr_o		,
	output wire						cpu_uart_adr_o		,
                                                    	
	input  wire [`CpuSelWidth]		core_state			,
	output reg						cpu0_control		,
	output reg  [`CpuNumWidth]		start_cpu_num   	,
	output reg  [`PcWidth]			cpu_start_adr   
);

	// assign cpu_num = num;
	
	wire cpu_state;	// 0访存 1执行
	// reg data_state, insn_state;	 // 0访存 1执行
	// reg is_fetch_inst;
	// assign cpu_state = data_state & insn_state;
	assign cpu_state = !cache_data_miss && !cache_data_wr_wait && !cache_inst_miss;

	reg [`DataWidth] insn,_insn;			//指令
	
	wire [`DataWidth] immediate = { 1'b0, insn[`ImmediateBit] };	
	
	reg [4:0] dsp;	// 当前栈顶指针
	reg [4:0] _dsp;	// 在当前周期的指令执行后的 栈顶指针
	reg [`DataWidth] st0; // 栈顶元素		T 
	reg [`DataWidth] _st0;	 // 在当前周期的指令执行后的 栈顶数据暂存 alu的结果最终赋值到 st0
    reg [`DataWidth] _st1;
	wire _dstkW;		 // 数据堆栈写使胍
	reg [`PcWidth] pc;
	reg [`PcWidth] _pc;
	reg [4:0] rsp; // 返回堆栈 栈顶指针
	reg [4:0] _rsp;
	wire _rstkW;		 // 返回堆栈写使能 
	reg [`DataWidth] _rstkD; //写入到返回栈数据			// RAM write enable
	
	wire [`PcWidth] pc_plus_1;
	assign pc_plus_1 = pc + 1;

	reg get_core_state, uart_turn_flag;
	reg[`CpuNumWidth] _uart_num;

	wire is_alu		= (insn[`InstTypeBit] == 3'b011);
	wire is_lit		= (insn[`IsImmediateBit]);
	wire is_jump	= (insn[`InstTypeBit] == 3'b000);
	wire is_cjump	= (insn[`InstTypeBit] == 3'b001);
	wire is_call	= (insn[`InstTypeBit] == 3'b010);
	
	wire is_from_mem = (is_alu & insn[`T_Bit]); // @
	wire is_to_mem = (is_alu & insn[`NTo_T_Bit]);	// !

	assign _dstkW = (is_lit | (is_alu & insn[`TToNBit])) & cpu_state;
	assign _rstkW = (is_call | (is_alu & insn[`TToRBit])) & cpu_state;

	wire [1:0] dd = insn[`DataStackDeltaBit];	// D stack delta	栈顶指针移动
	wire [1:0] rd = insn[`ReturnStackDeltaBit];	// R stack delta	栈顶指针移动

	// The D and R stacks
	reg [`DataWidth] dstack[0:31];
	reg [`DataWidth] rstack[0:31];
	always @(posedge clk)		//在系统时钟上升沿 如果 使能= 1 把数据写入到堆栈
	begin
		if (_dstkW)
			dstack[_dsp] = st0;	// 在执行st0<=_st0时此处st0仍是上个时钟的值并不是_st0
		if (_rstkW)
			rstack[_rsp] = _rstkD;
	end
	wire [`DataWidth] st1 = dstack[dsp];	// 次栈顶 
	wire [`DataWidth] rst0 = rstack[rsp];	// 返回堆栈 栈顶元素



reg aaa;
always @*
begin
	if(insn == 32'h60000023 && is_master == 1)
		aaa=1;
	if(insn == 32'h60000c00 && is_master == 1)
		aaa=1;
	if(is_master == 1)
		aaa=0;
        
    if(is_to_mem || is_from_mem)
    	if(st0 == 'hbe01)
        	aaa = 1;
end  

reg bbb;
always @(posedge clk)
begin
	if(is_master)
	begin
		bbb <= 1;
	end
	if(cpu_uart_rd_o && !cpu_uart_adr_o)
		bbb <= 0;
    if(pc == 13'h054a && cpu_state)  
    	bbb <= 0;
end
 


	// Compute the new value of T.
	always @(*)
	begin
		if(cpu_state)
		begin
			if(is_alu)
				case (insn[`AluTypeBit])
					4'b0000: _st0 = st0;
					4'b0001: _st0 = st1;
					4'b0010: _st0 = st0 + st1;
					4'b0011: _st0 = st0 & st1;
					4'b0100: _st0 = st0 | st1;
					4'b0101: _st0 = st0 ^ st1;
					4'b0110: _st0 = ~st0;
					4'b0111: _st0 = {`DataWordLength{(st1 == st0)}};
					4'b1000: _st0 = {`DataWordLength{($signed(st1) < $signed(st0))}};
					4'b1001: _st0 = st1 >> st0;
					4'b1010: _st0 = st0 - 1;
					4'b1011: _st0 = rst0;
					// 4'b1100: _st0 = (st0[`UartAddrBit] == 4'b1111) ? {24'b0,cpu_uart_dat_i} : &cache_data_dout === 1'bx ? 32'h0 : cache_data_dout ;
					4'b1100: _st0 = (st0[`UartAddrBit] == 4'b1111) ? {24'b0,cpu_uart_dat_i} : cache_data_dout ;
					4'b1101: _st0 = st1 << st0;
					4'b1110: _st0 = {19'b0,rsp, 3'b000, dsp};
					4'b1111: _st0 = {`DataWordLength{(st1 < st0)}};
					default: _st0 = `ZeroWord;
				endcase
			else
				_st0 = is_lit ? immediate : is_cjump ? st1 : st0;
		end else
			_st0 = st0;
	end

	
	always @(*)
	begin
		if(rst)
        	_dsp = 0;
        else if(cpu_state)
			if(is_lit)
        		_dsp = dsp + 1;
        	else if(is_alu)
        		_dsp = dsp + {dd[1], dd[1], dd[1], dd};
        	else if(is_cjump)
        		_dsp = dsp -1;
        	else
        		_dsp = dsp;
		else
			_dsp = dsp;
	end
    
    always @(*)
    begin
    	if(rst)
        	_rsp = 0;
        else if(cpu_state)
			if(is_alu)
				_rsp = rsp + {rd[1], rd[1], rd[1], rd};
			else if(is_call)
				_rsp = rsp + 1;
			else
				_rsp = rsp;
		else
			_rsp = rsp;
    end
    
	always @(*)
	begin
		if(rst)
			_rstkD = 0;
		else if(cpu_state)
			if(is_alu)
				_rstkD = st0;
			else if(is_call)
				_rstkD = {16'b0,pc_plus_1, 2'b00};
			else
				_rstkD = 0;
		else
			_rstkD = 0;
	end
	
	always @(*)
	begin
		if (rst)
		begin
			_pc = 0;
		end else if(cpu_state)
		begin
			if (is_jump | (is_cjump & (|st0 == 0)) | is_call)
				_pc = {3'b000,insn[`BranchAddrBit]};
			else if (is_alu & insn[`RToPCBit])
				_pc = {2'b00,rst0[`DataTransAddrBit]};
			else
				_pc = pc_plus_1;
		end else
			_pc = pc;
	end

	always @(posedge clk)
	begin
		if (rst) begin
			pc <= 0;
			dsp <= 0;
			st0 <= 0;
			rsp <= 0;
		end else
		begin
			dsp <= _dsp;
			pc <= _pc;
			st0 <= get_core_state ? core_state[3:1] : _st0;
			rsp <= _rsp;
		end
	end

	// 核心分配
	always @(*)
	begin
		if(rst)
		begin
			get_core_state = 0; 
			start_cpu_num = 0; 
			cpu_start_adr = 0; 
			cpu0_control = 0;
			_uart_num = 0;
			uart_turn_flag = 0;
		end else if(cpu_state & is_alu)
		begin
			case(insn[14:13])
				2'b01 : begin 
							get_core_state = 1; 
							start_cpu_num = 0; 
							cpu_start_adr = 0; 
							cpu0_control = 0; 
							_uart_num = 0; 
							uart_turn_flag = 0; 
						end
				2'b10 : begin 
							get_core_state = 0; 
							start_cpu_num = st0[`CpuNumWidth]; 
							cpu_start_adr = st1[`DataTransAddrBit]; 
							cpu0_control = 1; 
							_uart_num = 0; 
							uart_turn_flag = 0; 
						end
				2'b11 : begin 
							get_core_state = 0; 
							start_cpu_num = 0; 
							cpu_start_adr = 0; 
							cpu0_control = 0;  
							_uart_num = st0[`CpuNumWidth]; 
							uart_turn_flag = 1; 
						end
				default : begin 
							get_core_state = 0; 
							start_cpu_num = 0; 
							cpu_start_adr = 0; 
							cpu0_control = 0; 
							_uart_num = 0;  
							uart_turn_flag = 0; 
						end
			endcase
		end else
		begin
			get_core_state = 0; 
			start_cpu_num = 0; 
			cpu_start_adr = 0; 
			cpu0_control = 0;
			_uart_num = 0;
			uart_turn_flag = 0;
		end 
	end
	
	
	// uart输出端口控制
	always @(posedge clk)
	begin
		if(rst)
			cpu_uart_num <= 0;
		else if(uart_turn_flag)
			cpu_uart_num <= _uart_num;
		else if(cpu_uart_rd_o & !cpu_uart_adr_o)
			cpu_uart_num <= 0;
	end 
	// uart数据 读写
	assign cpu_uart_rd_o = is_alu && insn[`AluTypeBit] == 4'hc && (st0[`UartAddrBit] == 4'b1111) & cpu_state;
	assign cpu_uart_wr_o = is_to_mem  & (st0[`UartAddrBit] == 4'b1111) & cpu_state;
	assign cpu_uart_adr_o = st0[0];
	assign cpu_uart_dat_o = st1[7:0];


    
/********************* cpu状态 ********************/
	/* integer fw;
    initial fw = $fopen("E:/data_out.txt","w");
    	
	always @(posedge clk)
	begin
		if(!rst && cpu_state)
        	$fwrite(fw, "%h\n", insn);
	end  */
    
	always @(*)
	begin
		if(rst)
        	insn = 0;
        else if(cpu_state)
        	insn = cache_inst_dout;
        else
        	insn = _insn;
	end
    
    always @(posedge clk)
    begin
    	if(rst)
    		_insn <= 0;
        else
        	_insn <= insn;
    end

    assign cache_inst_valid = 1;
    assign cache_inst_rd_wr = 0;
    assign cache_inst_addr = _pc;
    

	always @(*)
	begin
		if(rst)
        	cache_data_valid = 0;
        else if((is_to_mem || is_from_mem) && (st0[`UartAddrBit] != 4'b1111))
        	cache_data_valid = 1;
        else
        	cache_data_valid = 0;
	end
	
    always @(*)
	begin
		if(rst)
        	cache_data_rd_wr = 0;
        // else if(is_to_mem && !cache_data_wr_wait)
        else if(is_to_mem)
        	cache_data_rd_wr = 1;
        else
        	cache_data_rd_wr = 0;
	end
    
    always @(*)
    begin
    	if(rst)
        	cache_data_addr = 0;
        else if(is_to_mem || is_from_mem)
        	cache_data_addr = st0[`DataTransAddrBit];
        else
        	cache_data_addr = 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		_st1 <= 0;
    	else if(cpu_state)
    		_st1 <= st1;
    end
    
    always @(*)
    begin
    	if(rst)
        	cache_data_din = 0;
        else if(is_to_mem && cpu_state)
        	cache_data_din = st1;
        else
        	cache_data_din = _st1;
    end
endmodule // j1