`include "defines.v"
module mem(

	input wire rst,


	//æ¥è‡ªæ‰§è¡Œé˜¶æ®µçš„å??
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus] wdata_i,

	input wire[`AluOpBus] aluop_i,
	input wire[`RegBus] mem_addr_i,
	input wire[`RegBus] reg2_i,

	//æ¥è‡ªå¤–éƒ¨å­˜å‚¨å™¨çš„ä¿¡æ¯
	input wire[`RegBus] mem_data_i,

	//è®¿å­˜é˜¶æ®µçš„ç»“æž?
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,

	input wire[`RegBus] hi_i,
	input wire[`RegBus] lo_i,
	input wire whilo_i,

	output reg[`RegBus] hi_o,
	output reg[`RegBus] lo_o,
	output reg whilo_o,

	input wire cp0_reg_we_i,
	input wire[4:0] cp0_reg_waddr_i,
	input wire[`RegBus] cp0_reg_wdata_i,
	output reg cp0_reg_we_o,
	output reg[4:0] cp0_reg_waddr_o,
	output reg[`RegBus] cp0_reg_wdata_o,

	input wire[31:0] excepttype_i,
	input wire is_in_delayslot_i,
	input wire[`RegBus] current_inst_address_i,
	input wire[`RegBus] cp0_status_i,
	input wire[`RegBus] cp0_cause_i,
	input wire[`RegBus] cp0_epc_i,
	input wire wb_cp0_reg_we,
	input wire[4:0] wb_cp0_reg_waddr,
	input wire[`RegBus] wb_cp0_reg_wdata,
	output reg[31:0] excepttype_o,
	output wire[`RegBus] cp0_epc_o,
	output wire is_in_delayslot_o,
	output wire[`RegBus] current_inst_address_o,

	input wire[`RegBus] badvaddr_i,
	output wire[`RegBus] badvaddr_o,

	input wire [`InstAddrBus] pc_i,
  	output wire [`InstAddrBus] pc_o
); 

reg[`RegBus] cp0_status;
reg[`RegBus] cp0_cause;
reg[`RegBus] cp0_epc;

assign is_in_delayslot_o =  is_in_delayslot_i ;
assign current_inst_address_o = current_inst_address_i ;

assign badvaddr_o = (excepttype_i[16] == 1'b1) ? pc_i : badvaddr_i;

assign pc_o = pc_i ;
//reg mem_we;
//assign mem_we_o = { 4{mem_we} } ;

//last cp0
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		cp0_status = `ZeroWord;
		cp0_epc = `ZeroWord;
	end
	else if ( wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_waddr == `CP0_REG_STATUS ) begin
		cp0_status = wb_cp0_reg_wdata;
	end
	else if ( wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_waddr == `CP0_REG_EPC ) begin
		cp0_epc = wb_cp0_reg_wdata;
	end
	else if ( wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_waddr == `CP0_REG_CAUSE ) begin
		cp0_cause[9:8] = wb_cp0_reg_wdata[9:8];
		cp0_cause[22] = wb_cp0_reg_wdata[22];
		cp0_cause[23] = wb_cp0_reg_wdata[23];

	end
	else begin
		cp0_status = cp0_status_i;
		cp0_epc = cp0_epc_i;
		cp0_cause = cp0_cause_i;
	end
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		excepttype_o = `ZeroWord;
	end
	else begin
		excepttype_o = `ZeroWord;
		if(current_inst_address_i != `ZeroWord) begin
			if( ((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00)
			&& (cp0_status[1] == 1'b0) && (cp0_status[0]== 1'b1)
			 ) begin
			 	excepttype_o = 32'h00000001;
			 end
			else if(excepttype_i[8] == 1'b1) begin
				excepttype_o = 32'h00000008;//syscall
			end			
			else if(excepttype_i[9] == 1'b1) begin
				excepttype_o = 32'h0000000a;//inst_invalid
			end
			else if(excepttype_i[10] == 1'b1) begin
				excepttype_o = 32'h0000000d;//trap
			end
			else if(excepttype_i[11] == 1'b1) begin
				excepttype_o = 32'h0000000c;//ov
			end
			else if(excepttype_i[12] == 1'b1) begin
				excepttype_o = 32'h0000000e;//eret
			end
			else if(excepttype_i[31] == 1'b1) begin
				excepttype_o = 32'h00000002;//break
			end
			else if(excepttype_i[4] == 1'b1) begin
				excepttype_o = 32'h00000004;//load
			end
			else if(excepttype_i[5] == 1'b1) begin
				excepttype_o = 32'h00000005;//store
			end
			else if(excepttype_i[16] == 1'b1) begin
				excepttype_o = 32'h00000004;//ft
			end
		end
	end 
end

assign cp0_epc_o = cp0_epc ;

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		wd_o = `NOPRegAddr;
		wreg_o = `WriteDisable;
		wdata_o = `ZeroWord;

		hi_o = `ZeroWord;
		lo_o = `ZeroWord;
		whilo_o = `WriteDisable;

		cp0_reg_we_o = `WriteDisable;
		cp0_reg_waddr_o = 5'b00000;
		cp0_reg_wdata_o = `ZeroWord;

		//mem_addr_o = `ZeroWord;
		//mem_we = `WriteDisable;
		//mem_sel_o = 4'b0000;
		//mem_data_o = `ZeroWord;
		//mem_ce_o = `ChipDisable;
	end
	else begin
		wd_o = wd_i;
		wreg_o = wreg_i;
		wdata_o = wdata_i;

		hi_o = hi_i;
		lo_o = lo_i;
		whilo_o = whilo_i;

		cp0_reg_we_o = cp0_reg_we_i;
		cp0_reg_waddr_o = cp0_reg_waddr_i;
		cp0_reg_wdata_o = cp0_reg_wdata_i;

		//mem_addr_o = `ZeroWord;
		//mem_we = `WriteDisable;
		//mem_sel_o = 4'b1111;
		//mem_ce_o = `ChipDisable;

		case(aluop_i)
			`EXE_LB_OP:begin
				//mem_addr_o = mem_addr_i;
				//mem_we = `WriteDisable;
				//mem_ce_o = `ChipEnable;
				case(mem_addr_i[1:0])
					2'b00:begin
						wdata_o = {{24{mem_data_i[7]}},mem_data_i[7:0]};
						//mem_sel_o = 4'b1000;
					end
					2'b01:begin
						
						wdata_o = {{24{mem_data_i[15]}},mem_data_i[15:8]};
						//mem_sel_o = 4'b0100;
					end
					2'b10:begin
						wdata_o = {{24{mem_data_i[23]}},mem_data_i[23:16]};
						//mem_sel_o = 4'b0010;
					end
					2'b11:begin
						wdata_o = { {24{mem_data_i[31]}},mem_data_i[31:24]};
						//mem_sel_o = 4'b0001;
					end
					default:begin
						wdata_o = `ZeroWord;
					end
				endcase
			end
			`EXE_LBU_OP:begin
				//mem_addr_o = mem_addr_i;
				//mem_we = `WriteDisable;
				//mem_ce_o = `ChipEnable;
				case(mem_addr_i[1:0])
					2'b00:begin
						
						wdata_o = {{24{1'b0}},mem_data_i[7:0]};
						//mem_sel_o = 4'b1000;
					end
					2'b01:begin
						
						wdata_o = {{24{1'b0}},mem_data_i[15:8]};
						//mem_sel_o = 4'b0100;
					end
					2'b10:begin
						wdata_o = {{24{1'b0}},mem_data_i[23:16]};
						//mem_sel_o = 4'b0010;
					end
					2'b11:begin
						wdata_o = {{24{1'b0}},mem_data_i[31:24]};
						//mem_sel_o = 4'b0001;
					end
					default:begin
						wdata_o = `ZeroWord;
					end
				endcase
			end
			`EXE_LH_OP:begin
				//mem_addr_o = mem_addr_i;
				//mem_we = `WriteDisable;
				//mem_ce_o = `ChipEnable;
				case(mem_addr_i[1:0])
					2'b00:begin
						wdata_o = {{16{mem_data_i[15]}},mem_data_i[15:0]};
						//mem_sel_o = 4'b1100;
					end
					2'b10:begin
						
						wdata_o = {{16{mem_data_i[31]}},mem_data_i[31:16]};
						//mem_sel_o = 4'b0011;
					end
					default:begin
						wdata_o = `ZeroWord;
					end
				endcase
			end
			`EXE_LHU_OP:begin
				//mem_addr_o = mem_addr_i;
				//mem_we = `WriteDisable;
				//mem_ce_o = `ChipEnable;
				case(mem_addr_i[1:0])
					2'b00:begin
						
						wdata_o = {{16{1'b0}},mem_data_i[15:0]};
						//mem_sel_o = 4'b1100;
					end
					2'b10:begin
						wdata_o = {{16{1'b0}},mem_data_i[31:16]};
						//mem_sel_o = 4'b0011;
					end
					default:begin
						wdata_o = `ZeroWord;
					end
				endcase
			end
			`EXE_LW_OP:begin
				//mem_addr_o = mem_addr_i;
				//mem_we = `WriteDisable;
				//mem_ce_o = `ChipEnable;
				wdata_o = mem_data_i;
				//mem_sel_o = 4'b1111;
			end
			`EXE_LWL_OP:begin
				//mem_addr_o = {mem_addr_i[31:2],2'b00};
				//mem_we = `WriteDisable;
				//mem_ce_o = `ChipEnable;
				//mem_sel_o = 4'b1111;
				case(mem_addr_i[1:0])
					2'b00:begin
						wdata_o = {mem_data_i[7:0],reg2_i[23:0]};
					end
					2'b01:begin
						wdata_o = {mem_data_i[15:0],reg2_i[15:0]};
					end
					2'b10:begin
						
						wdata_o = {mem_data_i[23:0],reg2_i[7:0]};
					end
					2'b11:begin
						
						wdata_o = mem_data_i[31:0];
					end
					default:begin
						wdata_o = `ZeroWord;
					end
				endcase
			end
			`EXE_LWR_OP:begin
				//mem_addr_o = {mem_addr_i[31:2],2'b00};
				//mem_we = `WriteDisable;
				//mem_ce_o = `ChipEnable;
				//mem_sel_o = 4'b1111;
				case(mem_addr_i[1:0])
					2'b00:begin
						wdata_o = {reg2_i[31:8],mem_data_i[31:24]};
					end
					2'b01:begin
						wdata_o = {reg2_i[31:16],mem_data_i[31:16]};
					end
					2'b10:begin
						wdata_o = {reg2_i[31:24],mem_data_i[31:8]};
					end
					2'b11:begin
						wdata_o = mem_data_i;
					end
					default:begin
						wdata_o = `ZeroWord;
					end
				endcase
			end


		endcase
	end
end
endmodule