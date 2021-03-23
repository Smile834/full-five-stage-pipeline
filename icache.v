`include "defines.v"
module icache(
	input wire clk,
	input wire rst,

	input wire[5:0] stall,
	input wire flush,

	input wire branch_flag_i,
	input wire[`RegBus] branch_target_address_i,

	input wire[`InstAddrBus] pc_pc,
	input wire[`InstAddrBus] new_pc,

//	input wire[31:0] excepttype_i,
	output wire[31:0] excepttype_o,

	output reg[`InstAddrBus] icache_pc

	);

reg excepttype_is_ft_adel;
assign excepttype_o = {15'b0,excepttype_is_ft_adel,16'b0};

always @ (*) begin
	excepttype_is_ft_adel = (icache_pc[1:0] != 2'b00) ? 1'b1 : 1'b0;  
end

always @(posedge clk) begin
	if (rst == `RstEnable) begin
		// reset
		icache_pc <= `ZeroWord;
	end
	else if (flush == 1'b1) begin
		icache_pc <= new_pc;
	end
	else if (stall[1] == `Stop && stall[2] == `NoStop) begin
		icache_pc <= `ZeroWord;
	end
	else if (stall[1] == `NoStop) begin
		if ( branch_flag_i == `Branch) begin
			icache_pc <= branch_target_address_i;
		end
		else begin
			icache_pc <= pc_pc;
		end
	end
end

endmodule