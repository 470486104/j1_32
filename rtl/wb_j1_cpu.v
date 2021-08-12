`include "define.v"
module wb_j1_cpu
#(
	parameter is_master = 1,
	parameter num = 0
 )
(
	input clk, 
	input rst, 
	input wire[1:0] key2,
	
	input  wire	[`DataWidth]		dat_i			,
	input  wire						ack_i			,
	input  wire	[`DataWidth]		inst_i			,
	output wire	[`CpuNumWidth]		cpu_num			,
	output reg	[`DataWidth]		adr_o			,
	output reg	[`DataWidth]		dat_o			,
	output reg						we_o			,
	output reg						cyc_o			,
	output wire	[`PcWidth]			pc_o			,
	
	input  wire	[`UartDataWidth]	cpu_uart_dat_i	,
	output reg	[`CpuNumWidth]		cpu_uart_num	,
	output wire	[`UartDataWidth]	cpu_uart_dat_o	,
	output wire						cpu_uart_rd_o	,
	output wire						cpu_uart_wr_o	,
	output wire						cpu_uart_adr_o	
);

	assign cpu_num = num;
	/* always @(posedge clk)
	begin
		cpu_num <= 0;
	end */
	
	assign pc_o = cpu_state ? _pc : pc;
	
	reg cpu_state;	// 0访存 1执行
	// reg ack;
	// reg [`DataWidth] data_input;
	reg [`DataWidth] insn;			//指令
	
	wire [`DataWidth] immediate = { 1'b0, insn[`ImmediateBit] };	
	
	reg [4:0] dsp;	// 当前栈顶指针
	reg [4:0] _dsp;	// 在当前周期的指令执行后的 栈顶指针
	reg [`DataWidth] st0; // 栈顶元素		T 
	reg [`DataWidth] _st0;	 // 在当前周期的指令执行后的 栈顶数据暂存 alu的结果最终赋值到 st0
	wire _dstkW;		 // 数据堆栈写使胍
	reg [`PcWidth] pc;
	reg [`PcWidth] _pc;
	reg [4:0] rsp; // 返回堆栈 栈顶指针
	reg [4:0] _rsp;
	reg _rstkW;		 // 返回堆栈写使能 
	reg [`DataWidth] _rstkD; //写入到返回栈数据			// RAM write enable
	
	wire [`PcWidth] pc_plus_1;
	assign pc_plus_1 = pc + 1;
	
/*******************************堆栈栈顶数据更新*******************************/
	// The D and R stacks
	reg [`DataWidth] dstack[0:31];
	reg [`DataWidth] rstack[0:31];
	always @(posedge clk)		//在系统时钟上升沿 如果 使能= 1 把数据写入到堆栈
	begin
		if(cpu_state)
		begin
			if (_dstkW)
				dstack[_dsp] = st0;	// 在执行st0<=_st0时此处st0仍是上个时钟的值并不是_st0
			if (_rstkW)
				rstack[_rsp] = _rstkD;
		end 

	end
	(* KEEP="TRUE" *)wire [`DataWidth] st1;
	assign st1 = dstack[dsp];	// 次栈顶 
	wire [`DataWidth] rst0 = rstack[rsp];	// 返回堆栈 栈顶元素


/*******************************取指 访存*******************************/

	
	always @(*)
	begin
		if(rst)
		begin
			insn = 0;
			cpu_state = 1;
		end 
		else begin
			if(!ack_i)
				if((inst_i[`InstTypeBit] == 3'b011) && ((inst_i[`AluTypeBit] == 4'hc) || inst_i[`NTo_T_Bit]))
				begin
					if(st0[`UartAddrBit] != 4'b1111)
						begin
							cpu_state = 0;
						end 
					else
					begin
						cpu_state = 1;
					end 
				end else
				begin
					cpu_state = 1;
				end 
			else
			begin
				cpu_state = 1;
			end 
			insn = inst_i;
		end 
	end

/******************************译码阶段 decode*********************************/
	// st0sel is the ALU operation.	For branch and call the operation
	// is T, for 0branch it is N.	For ALU ops it is loaded from the instruction
	// field.
	reg [3:0] st0sel;	//指令类型 
	always @(*)
	begin
		if(cpu_state)
			case (insn[`InstTypeBit])
				3'b000: st0sel = 0;			// ubranch
				3'b010: st0sel = 0;			// call
				3'b001: st0sel = 1;			// 0branch
				3'b011: st0sel = insn[`AluTypeBit]; // ALU
				default: st0sel = 4'b0000;
			endcase
		else
			st0sel = 0;	
	end


/******************************执行阶段 *********************************/
	// Compute the new value of T.
	always @(*)
	begin
		if(cpu_state)
		begin
			if (insn[`IsImmediateBit])
				_st0 = immediate;
			else
				case (st0sel)
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
					4'b1100: _st0 = (st0[`UartAddrBit] == 4'b1111) ? {24'b0,cpu_uart_dat_i} : dat_i;
					4'b1101: _st0 = st1 << st0;
					4'b1110: _st0 = {19'b0,rsp, 3'b000, dsp};
					4'b1111: _st0 = {`DataWordLength{(st1 < st0)}};
					default: _st0 = `ZeroWord;
				endcase
		end else
			_st0 = st0;
	end

	wire is_alu = (insn[`InstTypeBit] == 3'b011);
	wire is_lit = (insn[`IsImmediateBit]);
	wire is_from_mem = (is_alu & (insn[`AluTypeBit] == 4'hc)); // @
	wire is_to_mem = (is_alu & insn[`NTo_T_Bit]);	// !

	assign _dstkW = is_lit | (is_alu & insn[`TToNBit]);

	wire [1:0] dd = insn[`DataStackDeltaBit];	// D stack delta	栈顶指针移动
	wire [1:0] rd = insn[`ReturnStackDeltaBit];	// R stack delta	栈顶指针移动

	always @(*)
	begin
		if(cpu_state)
		begin
			if (is_lit) begin					// literal
				_dsp = dsp + 1;
				_rsp = rsp;
				_rstkW = 0;
				_rstkD = _pc;
			end else if (is_alu) begin				
				_dsp = dsp + {dd[1], dd[1], dd[1], dd}; // dd是补码 若为负dd[1]=1 若为正dd[1]=0 
				_rsp = rsp + {rd[1], rd[1], rd[1], rd};
				_rstkW = insn[`TToRBit];
				_rstkD = st0;
			end else begin						// jump/call
				// predicated jump is like DROP
				if (insn[`InstTypeBit] == 3'b001) begin		// ?branch
					_dsp = dsp - 1;
				end else begin
					_dsp = dsp;
				end
				if (insn[`InstTypeBit] == 3'b010) begin 	// call
					_rsp = rsp + 1;
					_rstkW = 1;
					_rstkD = {pc_plus_1[`AddrTransDataBit], 2'b00};
				end else begin
					_rsp = rsp;
					_rstkW = 0;
					_rstkD = _pc;
				end
			end
		end else
		begin
			_dsp = dsp;
			_rsp = rsp;
			_rstkW = 0;
			_rstkD = 0;
		end 
	end

	always @(*)
	begin
		if (rst)
		begin
			_pc = 0;
		end else if(cpu_state)
		begin
			if ((insn[`InstTypeBit] == 3'b000) |
					((insn[`InstTypeBit] == 3'b001) & (|st0 == 0)) |
					(insn[`InstTypeBit] == 3'b010))
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
		end else if(cpu_state)
		begin
			dsp <= _dsp;
			pc <= _pc;
			st0 <= _st0;
			rsp <= _rsp;
		end
	end
	
	/* generate
		if(is_master)
		begin
			
		end 
	endgenerate */
	
	always @(posedge clk)
	begin
		if(rst)
			cpu_uart_num <= 0;
		else
			cpu_uart_num <= key2;
	end 
	
	
	assign cpu_uart_rd_o = is_from_mem & (st0[`UartAddrBit] == 4'b1111);
	assign cpu_uart_wr_o = is_to_mem  & (st0[`UartAddrBit] == 4'b1111);
	assign cpu_uart_adr_o = st0[0];
	assign cpu_uart_dat_o = st1[7:0];


	always @(*)
	begin
		if(rst)
		begin
			cyc_o = 1'b0;
			adr_o = 0;
			dat_o = 0;
			we_o = 0;
		end else if(!cpu_state)
		begin
			cyc_o = 1'b1;
			adr_o = st0;
			dat_o = st1;
			we_o = inst_i[`NTo_T_Bit];
		end else
		begin
			cyc_o = 1'b0;
			adr_o = 0;
			dat_o = 0;
			we_o = 0;
		end 
	end

endmodule // j1