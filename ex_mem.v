`include "defines.v"
module ex_mem(

	input wire clk,
	input wire rst,
	input wire[5:0] stall,


	//æ¥è‡ªæ‰§è¡Œé˜¶æ®µçš„ä¿¡æ?
	input wire[`RegAddrBus] ex_wd,
	input wire ex_wreg,
	input wire[`RegBus] ex_wdata,

	input wire[`AluOpBus] ex_aluop,
	input wire[`RegBus] ex_mem_addr,
	input wire[`RegBus] ex_reg2,

	input wire[`RegBus] ex_hi,
	input wire[`RegBus] ex_lo,
	input wire ex_whilo,

	output reg[`RegBus] mem_hi,
	output reg[`RegBus] mem_lo,
	output reg mem_whilo,

	//é€åˆ°è®¿å­˜é˜¶æ®µçš„ä¿¡æ?
	output reg[`RegAddrBus] mem_wd,
	output reg mem_wreg,
	output reg[`RegBus] mem_wdata,

	output reg[`AluOpBus] mem_aluop,
	output reg[`RegBus] mem_mem_addr,
	output reg[`RegBus] mem_reg2,

	input wire ex_cp0_reg_we,
	input wire[4:0] ex_cp0_reg_waddr,
	input wire[`RegBus] ex_cp0_reg_wdata,
	output reg mem_cp0_reg_we,
	output reg[4:0] mem_cp0_reg_waddr,
	output reg[`RegBus] mem_cp0_reg_wdata,

	input wire flush,
	input wire[31:0] ex_excepttype,
	input wire ex_is_in_delayslot,
	input wire[`RegBus] ex_current_inst_address,
	output reg[31:0] mem_excepttype,
	output reg mem_is_in_delayslot,
	output reg[`RegBus] mem_current_inst_address,

	input wire[`RegBus] badvaddr_i,
	output reg[`RegBus] badvaddr_o,

	input wire [`InstAddrBus] pc_i,
  	output reg [`InstAddrBus] pc_o
);


always @(posedge clk) begin
	if (rst == `RstEnable) begin
		// reset
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;

		mem_aluop <= `EXE_NOP_OP;
		mem_mem_addr <= `ZeroWord;
		mem_reg2 <= `ZeroWord;

		mem_hi <= `ZeroWord;
		mem_lo <= `ZeroWord;
		mem_whilo <= `WriteDisable;

		mem_cp0_reg_we <= `WriteDisable;
		mem_cp0_reg_waddr <= 5'b0000;
		mem_cp0_reg_wdata <= `ZeroWord;

		mem_excepttype <= `ZeroWord;
		mem_is_in_delayslot <= `NotInDelaySlot;
		mem_current_inst_address <= `ZeroWord;

		pc_o <= `ZeroWord;
	end
	else if(flush == 1'b1) begin
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;

		mem_aluop <= `EXE_NOP_OP;
		mem_mem_addr <= `ZeroWord;
		mem_reg2 <= `ZeroWord;


		mem_hi <= `ZeroWord;
		mem_lo <= `ZeroWord;
		mem_whilo <= `WriteDisable;

		mem_cp0_reg_we <= `WriteDisable;
		mem_cp0_reg_waddr <= 5'b0000;
		mem_cp0_reg_wdata <= `ZeroWord;

		mem_excepttype <= `ZeroWord;
		mem_is_in_delayslot <= `NotInDelaySlot;
		mem_current_inst_address <= `ZeroWord;

		pc_o <= `ZeroWord;
	end
	else if (stall[3] == `Stop && stall[4] == `NoStop) begin
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;

		mem_aluop <= `EXE_NOP_OP;
		mem_mem_addr <= `ZeroWord;
		mem_reg2 <= `ZeroWord;


		mem_hi <= `ZeroWord;
		mem_lo <= `ZeroWord;
		mem_whilo <= `WriteDisable;

		mem_cp0_reg_we <= `WriteDisable;
		mem_cp0_reg_waddr <= 5'b0000;
		mem_cp0_reg_wdata <= `ZeroWord;

		mem_excepttype <= `ZeroWord;
		mem_is_in_delayslot <= `NotInDelaySlot;
		mem_current_inst_address <= `ZeroWord;

		pc_o <= `ZeroWord;
	end
	else if (stall[3] == `NoStop)begin
		mem_wd <= ex_wd;
		mem_wreg <= ex_wreg;
		mem_wdata <= ex_wdata;

		mem_aluop <= ex_aluop;
		mem_mem_addr <= ex_mem_addr;
		mem_reg2 <= ex_reg2;

		mem_hi <= ex_hi;
		mem_lo <= ex_lo;
		mem_whilo <= ex_whilo;

		mem_cp0_reg_we <= ex_cp0_reg_we;
		mem_cp0_reg_waddr <= ex_cp0_reg_waddr;
		mem_cp0_reg_wdata <= ex_cp0_reg_wdata;

		mem_excepttype <= ex_excepttype;
		mem_is_in_delayslot <= ex_is_in_delayslot;
		mem_current_inst_address <= ex_current_inst_address;

		pc_o <= pc_i;

		badvaddr_o <= badvaddr_i;
	end
end
endmodule