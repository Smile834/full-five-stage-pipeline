`include "defines.v"
module pc_reg(
	//时钟信号，复位信号，指令地址，指令存储器使能信号
	input wire clk,   
	input wire rst,

	input wire[5:0] stall,//控制模块

	//来自译码阶段的信?
	input wire branch_flag_i,
	input wire[`RegBus] branch_target_address_i,

	input wire flush,
	input wire[`RegBus] new_pc,

	output reg[`InstAddrBus] pc,
//	output wire [31:0] excepttype_o,

	output reg ce
);



always @(posedge clk) begin
	if (rst == `RstEnable) begin
		pc <= 32'hbfc00000;
	end
	else if (ce == `ChipEnable) begin
		if (flush == 1'b1) begin
			pc <= new_pc + 32'h4;
		end
		else if (stall[0] == `NoStop )begin
			if(branch_flag_i == `Branch) begin
				pc <= branch_target_address_i + 32'h4;
			end
			else begin
				pc <= pc + 32'h4;  //使能的的时??，pc每时钟周期加4
			end
		end
	end
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		ce = `ChipDisable ;
	end
	else if (stall[0] == `Stop) begin
		ce = `ChipDisable ;
	end
	else begin
		ce = `ChipEnable ;
	end
end

endmodule