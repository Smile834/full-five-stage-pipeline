`include "defines.v"
module regfile(
	input wire clk,
	input wire rst,

	//写端?
	input wire we,
	input wire[`RegAddrBus] waddr,
	input wire[`RegBus] wdata,

	//读端?1
	input wire re1,
	input wire[`RegAddrBus] raddr1,
	output reg[`RegBus] rdata1,

	//读端?2
	input wire re2,
	input wire[`RegAddrBus] raddr2,
	output reg[`RegBus] rdata2

);

//定义32?32位寄存器
reg[`RegBus] regs[`RegNum-1:0];

//写操?
always @(posedge clk) begin
	if (rst == `RstDisable) begin
		if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
			regs[waddr] <= wdata;
		end
		
	end
end

//读端?1 的读操作
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		rdata1 = `ZeroWord;
	end
	else if (raddr1 == `RegNumLog2'h0) begin
		rdata1 = `ZeroWord;
	end
	//回写阶段的数据相?
	else if ( (raddr1 == waddr) && (we == `WriteEnable)  
				&& (re1 == `ReadEnable) )begin
		rdata1 = wdata;			
	end
	else if (re1 == `ReadEnable) begin
		rdata1 = regs[raddr1];
	end
	else begin
		rdata1 = `ZeroWord;
	end
end

//读端?2 的读操作
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		rdata2 = `ZeroWord;
	end
	else if (raddr2 == `RegNumLog2'h0) begin
		rdata2 = `ZeroWord;
	end
	//回写阶段的数据相?
	else if ( (raddr2 == waddr) && (we == `WriteEnable)  
				&& (re2 == `ReadEnable) )begin
		rdata2 = wdata;			
	end
	else if (re2 == `ReadEnable) begin
		rdata2 = regs[raddr2];
	end
	else begin
		rdata2 = `ZeroWord;
	end
end
endmodule