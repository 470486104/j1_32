`define ForthFile			"E:/j1_32.hex"
`define RamSize				0:8191
`define RomSize				0:4095

`define PcWidth 			13:0	// 地址宽
`define DataWidth 			31:0	// 数据宽
`define PcWordLength		14		// 地址字长（bit）
`define DataWordLength		32		// 数据字长（bit）

`define UartDataWidth		7:0		// 串口数据宽
`define UartDataLengh		8		// 串口数据宽

`define ZeroWord 			32'h00000000
							
`define IsImmediateBit		31		// 立即数类型
`define ImmediateBit		30:0	// 立即数
`define InstTypeBit			31:29	// alu、branch等类型
`define AluTypeBit			11:8	// alu操作的类型
`define DataStackDeltaBit	1:0		// 数据堆栈增减位
`define ReturnStackDeltaBit	3:2		// 返回堆栈增减位
`define T_Bit				4		// alu的@指令位
`define NTo_T_Bit			5		// alu的！指令位
`define TToRBit				6		// T->R
`define TToNBit				7		// T->N
`define RToPCBit			12		// R->PC

`define DataTransAddrBit	31:2	// 数据转地址位
`define AddrTransDataBit	29:0	// 地址转数据位
`define BranchAddrBit		28:0	// 跳转指令的地址位

`define UartAddrBit			31:28	// uart的地址位

`define CpuNumWidth 		1:0		// cpu核心数位宽
`define CpuNum		 		4		// cpu核心数
`define CpuSelWidth			3:0		// cpu列表宽

`define BusWidth			127:0	// 总线宽