`define ForthFile			"E:/j1_32.hex"
`define RamSize				0:8191
`define RomSize				0:4095

`define PcWidth 			13:0	// ��ַ��
`define DataWidth 			31:0	// ���ݿ�
`define PcWordLength		14		// ��ַ�ֳ���bit��
`define DataWordLength		32		// �����ֳ���bit��

`define UartDataWidth		7:0		// �������ݿ�
`define UartDataLengh		8		// �������ݿ�

`define ZeroWord 			32'h00000000
							
`define IsImmediateBit		31		// ����������
`define ImmediateBit		30:0	// ������
`define InstTypeBit			31:29	// alu��branch������
`define AluTypeBit			11:8	// alu����������
`define DataStackDeltaBit	1:0		// ���ݶ�ջ����λ
`define ReturnStackDeltaBit	3:2		// ���ض�ջ����λ
`define T_Bit				4		// alu��@ָ��λ
`define NTo_T_Bit			5		// alu�ģ�ָ��λ
`define TToRBit				6		// T->R
`define TToNBit				7		// T->N
`define RToPCBit			12		// R->PC

`define DataTransAddrBit	31:2	// ����ת��ַλ
`define AddrTransDataBit	29:0	// ��ַת����λ
`define BranchAddrBit		28:0	// ��תָ��ĵ�ַλ

`define UartAddrBit			31:28	// uart�ĵ�ַλ

`define CpuNumWidth 		1:0		// cpu������λ��
`define CpuNum		 		4		// cpu������
`define CpuSelWidth			3:0		// cpu�б��

`define BusWidth			127:0	// ���߿�