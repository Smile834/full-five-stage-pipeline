`include "defines.v"
module mem_wb(
	input wire clk,
	input wire rst,
	input wire[5:0] stall,
	input wire flush,


	//访存阶段的结果
	input wire[`RegAddrBus] mem_wd,
	input wire mem_wreg,
	input wire[`RegBus] mem_wdata,

	input wire[`RegBus] mem_hi,
	input wire[`RegBus] mem_lo,
	input wire mem_whilo,

	output reg[`RegBus] wb_hi,
	output reg[`RegBus] wb_lo,
	output reg wb_whilo,

	//送到回写阶段的信息
	output reg[`RegAddrBus] wb_wd,
	output reg wb_wreg,
	output reg[`RegBus] wb_wdata,

	input wire mem_cp0_reg_we,
	input wire[4:0] mem_cp0_reg_waddr,
	input wire[`RegBus] mem_cp0_reg_wdata,
	output reg wb_cp0_reg_we,
	output reg[4:0] wb_cp0_reg_waddr,
	output reg[`RegBus] wb_cp0_reg_wdata,

	input wire [`InstAddrBus] pc_i,
  	output reg [`InstAddrBus] pc_o
);


always @(posedge clk) begin
	if (rst == `RstEnable) begin
		// reset
		wb_wd <= `NOPRegAddr;
		wb_wreg <= `WriteDisable;
		wb_wdata <= `ZeroWord;

		wb_hi <= `ZeroWord;
		wb_lo <= `ZeroWord;
		wb_whilo <= `WriteDisable;

		wb_cp0_reg_we <= `WriteDisable;
		wb_cp0_reg_waddr <= 5'b00000;
		wb_cp0_reg_wdata <= `ZeroWord;

		pc_o <= `ZeroWord;
	end
	else if (flush == 1'b1) begin
		// reset
		wb_wd <= `NOPRegAddr;
		wb_wreg <= `WriteDisable;
		wb_wdata <= `ZeroWord;

		wb_hi <= `ZeroWord;
		wb_lo <= `ZeroWord;
		wb_whilo <= `WriteDisable;

		wb_cp0_reg_we <= `WriteDisable;
		wb_cp0_reg_waddr <= 5'b00000;
		wb_cp0_reg_wdata <= `ZeroWord;

		pc_o <= `ZeroWord;
	end
	else if(stall[4] == `Stop && stall[5] == `NoStop) begin
		wb_wd <= `NOPRegAddr;
		wb_wreg <= `WriteDisable;
		wb_wdata <= `ZeroWord;

		wb_hi <= `ZeroWord;
		wb_lo <= `ZeroWord;
		wb_whilo <= `WriteDisable;

		wb_cp0_reg_we <= `WriteDisable;
		wb_cp0_reg_waddr <= 5'b00000;
		wb_cp0_reg_wdata <= `ZeroWord;

		pc_o <= `ZeroWord;
	end 
	else if(stall[4] == `NoStop)begin
		wb_wd <= mem_wd;
		wb_wreg <= mem_wreg;
		wb_wdata <= mem_wdata;

		wb_hi <= mem_hi;
		wb_lo <= mem_lo;
		wb_whilo <= mem_whilo;

		wb_cp0_reg_we <= mem_cp0_reg_we;
		wb_cp0_reg_waddr <= mem_cp0_reg_waddr;
		wb_cp0_reg_wdata <= mem_cp0_reg_wdata;

		pc_o <= pc_i;
	end
end
endmodule