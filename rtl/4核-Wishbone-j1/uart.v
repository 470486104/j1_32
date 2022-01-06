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


module uart
#(
	parameter BAUD_RATE	= 'd300_0000	,
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

	localparam BAUD_COUNT = (CLK_FREQ / BAUD_RATE) - 1;	// �����ʼ���
	localparam BAUD_COUNT_MID = (BAUD_COUNT / 2) - 1;	// �����ʼ�����ֵ
    localparam BAUD_WIDTH = $clog2(BAUD_COUNT+1);		// �����ʼ�����λ��
	
    reg rx1,rx2,rx3;
    reg rx_en;	// rxʹ��
    reg[BAUD_WIDTH-1:0] rx_buad_count;
    reg[3:0] rx_bit_count; // �ֽڼ���
    
    reg tx_en;	// txʹ��
    reg[BAUD_WIDTH-1:0] tx_buad_count;
    reg[3:0] tx_bit_count;// �ֽڼ���
    reg[7:0] tx_reg;	// �����ֽ��ݴ�
    
    reg	rx_data_ok;
    reg[7:0] rx_data;	
    reg[7:0] data_out;	
	
    wire rx_rd = rd & !adr[1];
    wire tx_wr = wr & !adr[0];
    
	assign dout = adr[1] ? {6'b0,tx_en,rx_data_ok} : data_out;
	assign dout1 = adr[0] ? {6'b0,tx_en,rx_data_ok} : data_out;

    // Rx
    always @(posedge clk)
    begin
    	if(rst)
    	begin
    		rx1 <= 1;
    		rx2 <= 1;
    		rx3 <= 1;
    	end else 
    	begin	// ����
    		rx1 <= rx;
    		rx2 <= rx1;
    		rx3 <= rx2;
    	end
    end
    
    always @(posedge clk)
    begin
    	if(rst)
        	rx_en <= 0;
        else if(!rx2 && rx3 && !rx_en) // rx2�½��� rx3������ ��ʼ����
        	rx_en <= 1;
        else if((rx_bit_count == 'd9) && rx_buad_count == BAUD_COUNT && rx_en) // �Ѿ�����8��bit��rx_bit_count==0ʱΪbit�Ŀ�ʼλ
        	rx_en <= 0;
   	end
    
    always @(posedge clk)
    begin
    	if(rst)
    		rx_buad_count <= 0;
    	else if(rx_en)
        	if(rx_buad_count == BAUD_COUNT) // ����һ��bit��ʱ��
            	rx_buad_count <= 0;
            else							// ��ʱ����һ��bit
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
        	if(rx_buad_count == BAUD_COUNT) // һ��bit�������
            	rx_bit_count <= rx_bit_count + 1;
        end else
        	rx_bit_count <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		rx_data <= 0;
        else if(rx_en)
        	if(|rx_bit_count && rx_buad_count == BAUD_COUNT_MID && rx_bit_count <= 'd8) // ��bitʱ���м�ʱ ����һ��bit
            	rx_data <= {rx3,rx_data[7:1]};
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		rx_data_ok <= 0;
        else if((rx_bit_count == 'd8) && (rx_buad_count == BAUD_COUNT_MID) && rx_en) // ������8��bit�����Ա��ⲿģ��ȡ��
        	rx_data_ok <= 1;
        else if(rx_rd)
        	rx_data_ok <= 0;
    end
    
    always @(*)
    begin
    	if(rst)
        	data_out = 0;
        else if(rx_data_ok) // �ݴ�����׵�����
        	data_out = rx_data;
        else
        	data_out = 0;
    end
    
    // Tx
    always @(posedge clk)
    begin
    	if(rst)
    		tx_en <= 0;
        else if(tx_wr && !tx_en) // ��ʼ����
        	tx_en <= 1;
        else if(tx_bit_count == 9 && tx_buad_count == BAUD_COUNT && tx_en) // ��������ʼλ��1�ֽڡ�ֹͣλ
        	tx_en <= 0;
    end
    
    always @(posedge clk)
    begin
    	if(rst)
    		tx_buad_count <= 0;
        else if(tx_en)
        	if(tx_buad_count == BAUD_COUNT) // ����һ��bit��ʱ��
            	tx_buad_count <= 0;         
            else							// ��ʱ����һ��bit
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
        	if(tx_buad_count == BAUD_COUNT) // һ��bit�������
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
            if(tx_buad_count == BAUD_COUNT)  // ����1��bit
            	{tx_reg, tx} <= {1'b1, tx_reg};
        end else
        begin
        	tx <= 1;
        	tx_reg <= 0;
        end 
    end
    
endmodule
