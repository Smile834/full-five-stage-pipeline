`include "defines.v"
module if_id(
	//取??阶段的指令及其地址，译码阶段的指令及其地址
	input wire clk,
	input wire rst,

	input wire[5:0] stall,

	input wire flush,

	input wire[31:0] excepttype_i,
	output reg[31:0] excepttype_o,

	input wire[`InstAddrBus] if_pc,
	input wire[`InstBus] if_inst,
	output reg[`InstAddrBus] id_pc,
	output reg[`InstBus] id_inst
);

always @(posedge clk) begin
	if (rst == `RstEnable) begin
		// reset
		id_pc <= `ZeroWord;
		id_inst <= `ZeroWord;
	end
	else if (flush == 1'b1) begin
		id_pc <= `ZeroWord;
		id_inst <= `ZeroWord;
	end
	else if (stall[1] == `Stop && stall[2] == `NoStop) begin
		id_pc <= `ZeroWord;
		id_inst <= `ZeroWord;
	end
	else if (stall[1] == `NoStop) begin
		id_pc <= if_pc;
		id_inst <= if_inst;
		excepttype_o <= excepttype_i;
	end
end

endmodule