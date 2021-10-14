`include "define.v"
module wb_j1_cpu_master
#(
	parameter is_master = 1,
	parameter num = 0
 )
(
	input clk, 
	input rst, 
	
	input  wire	[`DataWidth]		dat_i			,
	input  wire						ack_i			,
	// output wire	[`CpuNumWidth]		cpu_num			,
	output reg	[`PcWidth]			adr_o			,
	output reg	[`DataWidth]		dat_o			,
	output reg						we_o			,
	output reg						cyc_o			,
	
	input  wire	[`DataWidth]		inst_i			,
	input  wire						inst_ack_i		,
	output wire	 					inst_cyc_o		,
	output wire	[`PcWidth]			inst_pc_o		,
	
	input  wire	[`UartDataWidth]	cpu_uart_dat_i	,
	output reg	[`CpuNumWidth]		cpu_uart_num	,
	output wire	[`UartDataWidth]	cpu_uart_dat_o	,
	output wire						cpu_uart_rd_o	,
	output wire						cpu_uart_wr_o	,
	output wire						cpu_uart_adr_o	,
	
	input  wire [`CpuSelWidth]		core_state		,
	output reg						cpu0_control	,
	output reg  [`CpuNumWidth]		start_cpu_num   ,
	output reg  [`PcWidth]			cpu_start_adr   
);

	// assign cpu_num = num;
	
	wire cpu_state;	// 0�ô� 1ִ��
	reg data_state, insn_state;	 // 0�ô� 1ִ��
	reg is_fetch_inst;
	assign cpu_state = data_state & insn_state;

	reg [`DataWidth] insn,_insn;			//ָ��
	
	wire [`DataWidth] immediate = { 1'b0, insn[`ImmediateBit] };	
	
	reg [4:0] dsp;	// ��ǰջ��ָ��
	reg [4:0] _dsp;	// �ڵ�ǰ���ڵ�ָ��ִ�к�� ջ��ָ��
	reg [`DataWidth] st0; // ջ��Ԫ��		T 
	reg [`DataWidth] _st0;	 // �ڵ�ǰ���ڵ�ָ��ִ�к�� ջ�������ݴ� alu�Ľ�����ո�ֵ�� st0
	wire _dstkW;		 // ���ݶ�ջдʹ��
	reg [`PcWidth] pc;
	reg [`PcWidth] _pc;
	reg [4:0] rsp; // ���ض�ջ ջ��ָ��
	reg [4:0] _rsp;
	wire _rstkW;		 // ���ض�ջдʹ�� 
	reg [`DataWidth] _rstkD; //д�뵽����ջ����			// RAM write enable
	
	wire [`PcWidth] pc_plus_1;
	assign pc_plus_1 = pc + 1;

	reg get_core_state, uart_turn_flag;
	reg[`CpuNumWidth] _uart_num;

	wire is_alu		= (insn[`InstTypeBit] == 3'b011);
	wire is_lit		= (insn[`IsImmediateBit]);
	wire is_jump	= (insn[`InstTypeBit] == 3'b000);
	wire is_cjump	= (insn[`InstTypeBit] == 3'b001);
	wire is_call	= (insn[`InstTypeBit] == 3'b010);
	
	wire is_from_mem = (is_alu & (insn[`AluTypeBit] == 4'hc)); // @
	wire is_to_mem = (is_alu & insn[`NTo_T_Bit]);	// !

	assign _dstkW = (is_lit | (is_alu & insn[`TToNBit])) & cpu_state;
	assign _rstkW = (is_call | (is_alu & insn[`TToRBit])) & cpu_state;

	wire [1:0] dd = insn[`DataStackDeltaBit];	// D stack delta	ջ��ָ���ƶ�
	wire [1:0] rd = insn[`ReturnStackDeltaBit];	// R stack delta	ջ��ָ���ƶ�

	// The D and R stacks
	reg [`DataWidth] dstack[0:31];
	reg [`DataWidth] rstack[0:31];
	always @(posedge clk)		//��ϵͳʱ�������� ��� ʹ��= 1 ������д�뵽��ջ
	begin
		if (_dstkW)
			dstack[_dsp] = st0;	// ��ִ��st0<=_st0ʱ�˴�st0�����ϸ�ʱ�ӵ�ֵ������_st0
		if (_rstkW)
			rstack[_rsp] = _rstkD;
	end
	wire [`DataWidth] st1 = dstack[dsp];	// ��ջ�� 
	wire [`DataWidth] rst0 = rstack[rsp];	// ���ض�ջ ջ��Ԫ��



/* reg aaa;
always @*
begin
	if(insn == 32'h60000023 && is_master == 1)
		aaa=1;
	if(insn == 32'h60000c00 && is_master == 1)
		aaa=1;
	if(is_master == 1)
		aaa=0;
end  

reg bbb;
always @(posedge clk)
begin
	if(is_master)
	begin
		bbb <= 1;
	end
end
 */


	// Compute the new value of T.
	always @(*)
	begin
		if(cpu_state)
		begin
			if (is_alu)
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
					4'b1100: _st0 = (st0[`UartAddrBit] == 4'b1111) ? {24'b0,cpu_uart_dat_i} : dat_i;
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
			if (is_jump |
					(is_cjump & (|st0 == 0)) |
					is_call)
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
			st0 <= get_core_state ? core_state[2:1] : _st0;
			rsp <= _rsp;
		end
	end

	// ���ķ���
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
	
	
	// uart����˿ڿ���
	always @(posedge clk)
	begin
		if(rst)
			cpu_uart_num <= 0;
		else if(uart_turn_flag)
			cpu_uart_num <= _uart_num;
		else if(cpu_uart_rd_o & !cpu_uart_adr_o)
			cpu_uart_num <= 0;
	end 
	// uart���� ��д
	assign cpu_uart_rd_o = is_from_mem & (st0[`UartAddrBit] == 4'b1111) & cpu_state;
	assign cpu_uart_wr_o = is_to_mem  & (st0[`UartAddrBit] == 4'b1111) & cpu_state;
	assign cpu_uart_adr_o = st0[0];
	assign cpu_uart_dat_o = st1[7:0];

// cpu״̬

	// ȡ����״̬
	always @(*)
	begin
		if(rst)
		begin
			insn = 0;
			data_state = 1;
		end 
		else begin
			if(!ack_i & (is_fetch_inst ~^ inst_ack_i)) // ��ǰramû���������� �� �ɹ�ȡָʱ
				if((inst_i[`InstTypeBit] == 3'b011) && ((inst_i[`AluTypeBit] == 4'hc) || inst_i[`NTo_T_Bit]))
					data_state = (&st0[`UartAddrBit]); // �����ram����ָ���� @ �� ! ָ��Ҷ�д��ַ����ȥuart��ʱ cpuתΪȡ����״̬
				else
					data_state = 1;
			else
				data_state = 1;
			// �ж��Ƿ�ɹ�ȡָ������_insnΪ��ָ��
			insn = (is_fetch_inst ~^ inst_ack_i) ? inst_i : _insn;
		end 
	end

	always @(*)
	begin
		if(rst)
		begin
			cyc_o = 1'b0;
			adr_o = 0;
			dat_o = 0;
			we_o = 0;
		end else if(!data_state)
		begin // cpuΪȡ����״̬ʱ ��������ʹ��Ȩ
			cyc_o = 1'b1;
			adr_o = st0[`DataTransAddrBit];
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

	always @(posedge clk)
	begin
		if((inst_pc_o[13:12] != 0) & data_state)
		begin
			is_fetch_inst <= 1; // ��ʾcpu׼��ȥ����ramȡָ
			_insn <= insn; // ���ָ��
		end else
		begin
			is_fetch_inst <= 0;
			_insn <= insn;
		end 
	end 

	always @(*)
	begin
		if(!inst_ack_i)
			insn_state = !is_fetch_inst; // ����is_fetch_inst״̬ תΪ����ramȡָ״̬
		else
			insn_state = 1;		
	end

	assign inst_pc_o = data_state ? _pc : pc; // ��Ϊȡ����״̬ʱȡָ���pcֵ���ı�
	assign inst_cyc_o = insn_state ? 0 : 1; // cpuΪȡָ��״̬ʱ ��������ʹ��Ȩ
	
endmodule // j1