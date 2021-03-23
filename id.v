`include "defines.v"
module id(
	//è¾“å…¥çš„æŒ‡ä»¤åœ°?ä¸ŽæŒ‡?
	input wire rst,
	input wire[`InstAddrBus] pc_i,
  	output wire [`InstAddrBus] pc_o,

	input wire[`InstBus] inst_i,

	//è¯»å–çš„Regfileçš???
	input wire[`RegBus] reg1_data_i,
	input wire[`RegBus] reg2_data_i,

	//å¤„äºŽæ‰§è¡Œé˜¶æ®µçš„æŒ‡ä»¤çš„è¿ç®—ç»“æžœ
	input wire ex_wreg_i,
	input wire[`RegBus] ex_wdata_i,
	input wire[`RegAddrBus] ex_wd_i,

	input wire dcache_wreg_i,
	input wire[`RegBus] dcache_wdata_i,
	input wire[`RegAddrBus] dcache_wd_i,

	//å½“å‰ä½ä¸Žè¯‘ç é˜¶æ®µçš„æŒ‡ä»¤æ˜¯å¦ä½äºŽå»¶è¿Ÿæ§½
	input wire is_in_delayslot_i,

	//å¤„äºŽè®¿å­˜é˜¶æ®µçš„æŒ‡ä»¤çš„è¿ç®—ç»“æžœ
	input wire mem_wreg_i,
	input wire[`RegBus] mem_wdata_i,
	input wire[`RegAddrBus] mem_wd_i,

	input wire[`AluOpBus] ex_aluop_i,

	//è¾“å‡ºåˆ°Regfileçš„ä¿¡?
	output reg reg1_read_o,
	output reg[`RegAddrBus] reg1_addr_o,

	output reg reg2_read_o,
	output reg[`RegAddrBus] reg2_addr_o,

	//é€åˆ°æ‰§è¡Œé˜¶æ®µçš„ä¿¡?
	output reg[`AluOpBus] aluop_o,
	output reg[`AluSelBus] alusel_o,
	output reg[`RegBus] reg1_o,
	output reg[`RegBus] reg2_o,
	//ç›®çš„å¯„å­˜å™¨çš„åœ°å€ ? ä½¿èƒ½ä¿¡å·
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,

	output wire stallreq,

	output reg next_inst_in_delayslot_o,
	output reg branch_flag_o,
	output reg[`RegBus] branch_target_address_o,
	output reg[`RegBus] link_addr_o, //è¿”å›žçš„åœ°?
	output reg is_in_delayslot_o,

	input wire[31:0] excepttype_i,
	output wire[31:0] excepttype_o,
	output wire[`RegBus] current_inst_address_o,

	output wire[`RegBus] inst_o
);

assign inst_o = inst_i;
assign pc_o = pc_i ;

reg excepttype_is_syscall;
reg excepttype_is_break;
reg excepttype_is_eret;

assign current_inst_address_o = pc_i ;

//æŒ‡ä»¤?
wire[5:0] op = inst_i[31:26];
wire[4:0] op2 = inst_i[10:6];
//åŠŸèƒ½?
wire[5:0] op3 = inst_i[5:0];
wire[4:0] op4 = inst_i[20:16];
//æŒ‡ä»¤?è¦çš„ç«‹å³?
reg[`RegBus] imm;

//æŒ‡ç¤ºæŒ‡ä»¤ æ˜¯å¦æœ‰æ•ˆ
reg instvalid;

assign excepttype_o = {excepttype_is_break,14'b0,excepttype_i[16],3'b0,excepttype_is_eret,2'b0,instvalid,excepttype_is_syscall,8'b0};


wire[`RegBus] pc_plus_8;
wire[`RegBus] pc_plus_4;
wire[`RegBus] imm_sll2_signedext;

reg stallreq_shift;

assign pc_plus_8 = pc_i + 8 ;
assign pc_plus_4 = pc_i + 4 ;
assign imm_sll2_signedext = { {14{inst_i[15]}},inst_i[15:0],2'b00} ;


//ç¬¬ä¸€? å¯¹æŒ‡ä»¤è¿›è¡Œè¯‘?
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		aluop_o = `EXE_NOP_OP;
		alusel_o = `EXE_RES_NOP;
		wd_o = `NOPRegAddr;
		wreg_o = `WriteDisable;
		instvalid = `InstInvalid;
		reg1_read_o = 1'b0;
		reg1_addr_o = `NOPRegAddr;
		reg2_read_o = 1'b0;
		reg2_addr_o = `NOPRegAddr;
		imm = 32'h0;

		link_addr_o = `ZeroWord;
		branch_flag_o = `NotBranch;
		branch_target_address_o = `ZeroWord;
		next_inst_in_delayslot_o = `NotInDelaySlot;

		excepttype_is_syscall = 1'b0;
		excepttype_is_break = 1'b0;
		excepttype_is_eret = 1'b0;
	end
	else begin
		aluop_o = `EXE_NOP_OP;
		alusel_o = `EXE_RES_NOP;
		wd_o = inst_i[15:11];
		wreg_o = `WriteDisable;
		instvalid = `InstInvalid;
		reg1_read_o = 1'b0;
		reg1_addr_o = inst_i[25:21];
		reg2_read_o = 1'b0;
		reg2_addr_o = inst_i[20:16];
		imm = `ZeroWord;

		link_addr_o = `ZeroWord;
		branch_flag_o = `NotBranch;
		branch_target_address_o = `ZeroWord;
		next_inst_in_delayslot_o = `NotInDelaySlot;

		excepttype_is_syscall = 1'b0;
		excepttype_is_break = 1'b0;
		excepttype_is_eret = 1'b0;

		case(op)
			`EXE_SPECIAL_INST: begin
				case (op2)
					5'b00000: begin
						case (op3)
							`EXE_OR: begin  //or
								alusel_o = `EXE_RES_LOGIC;
								aluop_o = `EXE_OR_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
							
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_AND: begin  //and
								alusel_o = `EXE_RES_LOGIC;
								aluop_o = `EXE_AND_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
							
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_XOR: begin  //xor
								alusel_o = `EXE_RES_LOGIC;
								aluop_o = `EXE_XOR_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
							
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_NOR: begin
								alusel_o = `EXE_RES_LOGIC;
								aluop_o = `EXE_NOR_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;

								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_SLLV: begin
								alusel_o = `EXE_RES_SHIFT;
								aluop_o = `EXE_SLL_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_SRLV: begin
								alusel_o = `EXE_RES_SHIFT;
								aluop_o = `EXE_SRL_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_SRAV: begin
								alusel_o = `EXE_RES_SHIFT;
								aluop_o = `EXE_SRA_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_SLT:begin
								alusel_o = `EXE_RES_ARITHMETIC;
								aluop_o = `EXE_SLT_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_SLTU:begin
								alusel_o = `EXE_RES_ARITHMETIC;
								aluop_o = `EXE_SLTU_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_ADD:begin
								alusel_o = `EXE_RES_ARITHMETIC;
								aluop_o = `EXE_ADD_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_ADDU:begin
								alusel_o = `EXE_RES_ARITHMETIC;
								aluop_o = `EXE_ADDU_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_SUB:begin
								alusel_o = `EXE_RES_ARITHMETIC;
								aluop_o = `EXE_SUB_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_SUBU:begin
								alusel_o = `EXE_RES_ARITHMETIC;
								aluop_o = `EXE_SUBU_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteEnable;
								instvalid = `InstValid;
							end
							`EXE_MULT:begin
								
								aluop_o = `EXE_MULT_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteDisable;
								instvalid = `InstValid;
							end
							`EXE_MULTU:begin
								
								aluop_o = `EXE_MULTU_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								
								wreg_o = `WriteDisable;
								instvalid = `InstValid;
							end
							`EXE_JR: begin
								alusel_o = `EXE_RES_JUMP_BRANCH;
								aluop_o = `EXE_JR_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b0;
								
								wreg_o = `WriteDisable;
								instvalid = `InstValid;

								link_addr_o = `ZeroWord;
								branch_flag_o = `Branch;
								branch_target_address_o = reg1_o;
								next_inst_in_delayslot_o = `InDelaySlot;
							end
							`EXE_JALR:begin
								alusel_o = `EXE_RES_JUMP_BRANCH;
								aluop_o = `EXE_JALR_OP;
								
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b0;
								
								wreg_o = `WriteEnable;
								wd_o = inst_i[15:11];
								instvalid = `InstValid;

								link_addr_o = pc_plus_8;
								branch_flag_o = `Branch;
								branch_target_address_o = reg1_o;
								next_inst_in_delayslot_o = `InDelaySlot;
							end
							`EXE_MFHI:begin
								wreg_o = `WriteEnable;
								aluop_o = `EXE_MFHI_OP;
								alusel_o = `EXE_RES_MOVE;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_MFLO:begin
								wreg_o = `WriteEnable;
								aluop_o = `EXE_MFLO_OP;
								alusel_o = `EXE_RES_MOVE;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_MTHI:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_MTHI_OP;
								alusel_o = `EXE_RES_MOVE;
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_MTLO:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_MTLO_OP;
								alusel_o = `EXE_RES_MOVE;
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_DIV:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_DIV_OP;
								//alusel_o = `EXE_RES_MOVE;
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								instvalid = `InstValid;
							end
							`EXE_DIVU:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_DIVU_OP;
								//alusel_o = `EXE_RES_MOVE;
								reg1_read_o = 1'b1;
								reg2_read_o = 1'b1;
								instvalid = `InstValid;
							end
							`EXE_TEQ:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_SYSCALL_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_TGE:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_TGE_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_TGEU:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_TGEU_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_TLT:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_TLT_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_TLTU:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_TLTU_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_TNE:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_TNE_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
							end
							`EXE_SYSCALL:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_SYSCALL_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
								excepttype_is_syscall = 1'b1;
							end
							`EXE_BREAK:begin
								wreg_o = `WriteDisable;
								aluop_o = `EXE_BREAK_OP;
								alusel_o = `EXE_RES_NOP;
								reg1_read_o = 1'b0;
								reg2_read_o = 1'b0;
								instvalid = `InstValid;
								excepttype_is_break = 1'b1;
							end


							
							default:begin
								
							end
                        
						endcase //case op3
					end
					

					default:begin
					end

				
				endcase //case op2
			end
			`EXE_ORI: begin
				alusel_o = `EXE_RES_LOGIC;
				aluop_o = `EXE_OR_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {16'h0,inst_i[15:0]};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_ANDI: begin
				alusel_o = `EXE_RES_LOGIC;
				aluop_o = `EXE_AND_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {16'h0,inst_i[15:0]};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_XORI: begin
				alusel_o = `EXE_RES_LOGIC;
				aluop_o = `EXE_XOR_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {16'h0,inst_i[15:0]};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_LUI: begin
				alusel_o = `EXE_RES_LOGIC;
				aluop_o = `EXE_OR_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {inst_i[15:0],16'h0};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_SLTI: begin
				alusel_o = `EXE_RES_ARITHMETIC;
				aluop_o = `EXE_SLT_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {{16{inst_i[15]}},inst_i[15:0]};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_SLTIU: begin
				alusel_o = `EXE_RES_ARITHMETIC;
				aluop_o = `EXE_SLTU_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {{16{inst_i[15]}},inst_i[15:0]};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_ADDI: begin
				alusel_o = `EXE_RES_ARITHMETIC;
				aluop_o = `EXE_ADDI_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {{16{inst_i[15]}},inst_i[15:0]};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_ADDIU: begin
				alusel_o = `EXE_RES_ARITHMETIC;
				aluop_o = `EXE_ADDIU_OP;
				
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {{16{inst_i[15]}},inst_i[15:0]};

				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];

				instvalid = `InstValid;
			end
			`EXE_SPECIAL_INST:begin
				case(op3)
					`EXE_MUL:begin
						alusel_o = `EXE_RES_MUL;
						aluop_o = `EXE_MUL_OP;
						
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b1;

						wreg_o = `WriteEnable;
						instvalid = `InstValid;
					end
				endcase
			end
			`EXE_J:begin
				alusel_o = `EXE_RES_JUMP_BRANCH;
				aluop_o = `EXE_J_OP;
								
				reg1_read_o = 1'b0;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;

				link_addr_o = `ZeroWord;
				branch_flag_o = `Branch;
				branch_target_address_o = 
				{pc_plus_4[31:28],inst_i[25:0],2'b00};

				next_inst_in_delayslot_o = `InDelaySlot;
			end
			`EXE_JAL:begin
				alusel_o = `EXE_RES_JUMP_BRANCH;
				aluop_o = `EXE_JAL_OP;
								
				reg1_read_o = 1'b0;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteEnable;
				wd_o = 5'b11111;
				instvalid = `InstValid;

				link_addr_o = pc_plus_8;
				branch_flag_o = `Branch;
				branch_target_address_o = 
				{pc_plus_4[31:28],inst_i[25:0],2'b00};

				next_inst_in_delayslot_o = `InDelaySlot;
			end
			`EXE_BEQ:begin
				alusel_o = `EXE_RES_JUMP_BRANCH;
				aluop_o = `EXE_BEQ_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;

				if (reg1_o == reg2_o) begin
					branch_flag_o = `Branch;
					branch_target_address_o = pc_plus_4+imm_sll2_signedext;	
				end

				next_inst_in_delayslot_o = `InDelaySlot;
			end
			`EXE_BGTZ:begin
				alusel_o = `EXE_RES_JUMP_BRANCH;
				aluop_o = `EXE_BGTZ_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;

				if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
					branch_flag_o = `Branch;
					branch_target_address_o = pc_plus_4+imm_sll2_signedext;
					
				end

				next_inst_in_delayslot_o = `InDelaySlot;
			end
			`EXE_BLEZ:begin
				alusel_o = `EXE_RES_JUMP_BRANCH;
				aluop_o = `EXE_BLEZ_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;

				if ((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
					branch_flag_o = `Branch;
					branch_target_address_o = pc_plus_4+imm_sll2_signedext;
					
				end

				next_inst_in_delayslot_o = `InDelaySlot;
			end
			`EXE_BNE:begin
				alusel_o = `EXE_RES_JUMP_BRANCH;
				aluop_o = `EXE_BGTZ_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;

				if (reg1_o != reg2_o) begin
					branch_flag_o = `Branch;
					branch_target_address_o = pc_plus_4+imm_sll2_signedext;
					
				end

				next_inst_in_delayslot_o = `InDelaySlot;
			end
			`EXE_LB:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_LB_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
			end
			`EXE_LBU:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_LBU_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
			end
			`EXE_LH:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_LH_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
			end
			`EXE_LHU:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_LHU_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
			end
			`EXE_LW:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_LW_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
								
				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
			end
			`EXE_LWL:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_LWL_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
			end
			`EXE_LWR:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_LWR_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteEnable;
				wd_o = inst_i[20:16];
				instvalid = `InstValid;
			end
			`EXE_SB:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_SB_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;
			end
			`EXE_SH:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_SH_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;
			end
			`EXE_SW:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_SW_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;
			end
			`EXE_SWL:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_SWL_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;
			end
			`EXE_SWR:begin
				alusel_o = `EXE_RES_LOAD_STORE;
				aluop_o = `EXE_SWR_OP;
								
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
								
				wreg_o = `WriteDisable;
				instvalid = `InstValid;
			end
			`EXE_REGIMM_INST:begin
				case (op4)
					`EXE_BGEZ:begin
						alusel_o = `EXE_RES_JUMP_BRANCH;
						aluop_o = `EXE_BGEZ_OP;
										
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
										
						wreg_o = `WriteDisable;
						instvalid = `InstValid;

						if (reg1_o[31] == 1'b0) begin
							branch_flag_o = `Branch;
							branch_target_address_o = pc_plus_4+imm_sll2_signedext;	
						end
						next_inst_in_delayslot_o = `InDelaySlot;
					end
					`EXE_BGEZAL:begin
						alusel_o = `EXE_RES_JUMP_BRANCH;
						aluop_o = `EXE_BGEZAL_OP;
										
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
										
						wreg_o = `WriteEnable;
						wd_o = 5'b11111;
						instvalid = `InstValid;

						link_addr_o = pc_plus_8;

						if (reg1_o[31] == 1'b0) begin
							branch_flag_o = `Branch;
							branch_target_address_o = pc_plus_4+imm_sll2_signedext;

							
						end
						next_inst_in_delayslot_o = `InDelaySlot;
					end
					`EXE_BLTZ:begin
						alusel_o = `EXE_RES_JUMP_BRANCH;
						aluop_o = `EXE_BLTZ_OP;
										
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
										
						wreg_o = `WriteDisable;
						instvalid = `InstValid;

						if ((reg1_o[31] == 1'b1)) begin
							branch_flag_o = `Branch;
							branch_target_address_o = pc_plus_4+imm_sll2_signedext;

							
						end
						next_inst_in_delayslot_o = `InDelaySlot;
					end
					`EXE_BLTZAL:begin
						alusel_o = `EXE_RES_JUMP_BRANCH;
						aluop_o = `EXE_BGTZ_OP;
										
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
										
						wreg_o = `WriteEnable;
						wd_o = 5'b11111;
						link_addr_o = pc_plus_8;
						instvalid = `InstValid;

						if (reg1_o[31] == 1'b1) begin
							branch_flag_o = `Branch;
							branch_target_address_o = pc_plus_4+imm_sll2_signedext;

							
						end
						next_inst_in_delayslot_o = `InDelaySlot;
					end
					`EXE_TEQI:begin
						wreg_o = `WriteDisable;
						aluop_o = `EXE_TEQI_OP;
						alusel_o = `EXE_RES_NOP;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
						imm = { {16{inst_i[15]}},inst_i[15:0]};
						instvalid = `InstValid;
					end
					`EXE_TGEI:begin
						wreg_o = `WriteDisable;
						aluop_o = `EXE_TGEI_OP;
						alusel_o = `EXE_RES_NOP;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
						imm = { {16{inst_i[15]}},inst_i[15:0]};
						instvalid = `InstValid;
					end
					`EXE_TGEIU:begin
						wreg_o = `WriteDisable;
						aluop_o = `EXE_TGEIU_OP;
						alusel_o = `EXE_RES_NOP;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
						imm = { {16{inst_i[15]}},inst_i[15:0]};
						instvalid = `InstValid;
					end
					`EXE_TLTI:begin
						wreg_o = `WriteDisable;
						aluop_o = `EXE_TLTI_OP;
						alusel_o = `EXE_RES_NOP;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
						imm = { {16{inst_i[15]}},inst_i[15:0]};
						instvalid = `InstValid;
					end
					`EXE_TLTIU:begin
						wreg_o = `WriteDisable;
						aluop_o = `EXE_TLTIU_OP;
						alusel_o = `EXE_RES_NOP;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
						imm = { {16{inst_i[15]}},inst_i[15:0]};
						instvalid = `InstValid;
					end
					`EXE_TNEI:begin
						wreg_o = `WriteDisable;
						aluop_o = `EXE_TNEI_OP;
						alusel_o = `EXE_RES_NOP;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b0;
						imm = { {16{inst_i[15]}},inst_i[15:0]};
						instvalid = `InstValid;
					end

					default:begin
						
					end


				endcase
			end




			default:begin
				
			end
		endcase  //case op

		if (inst_i[31:21] == 11'b00000000000) begin
			if(op3 == `EXE_SLL) begin


				alusel_o = `EXE_RES_SHIFT;
				aluop_o = `EXE_SLL_OP;
				
				reg1_read_o = 1'b0;
				reg2_read_o = 1'b1;
				imm[4:0] = inst_i[10:6];

				wreg_o = `WriteEnable;
				wd_o = inst_i[15:11];

				instvalid = `InstValid;

				
			end
			else if (op3 == `EXE_SRL) begin
				alusel_o = `EXE_RES_SHIFT;
				aluop_o = `EXE_SRL_OP;
				
				reg1_read_o = 1'b0;
				reg2_read_o = 1'b1;
				imm[4:0] = inst_i[10:6];

				wreg_o = `WriteEnable;
				wd_o = inst_i[15:11];

				instvalid = `InstValid;
			end
			else if (op3 == `EXE_SRA) begin
				alusel_o = `EXE_RES_SHIFT;
				aluop_o = `EXE_SRA_OP;
				
				reg1_read_o = 1'b0;
				reg2_read_o = 1'b1;
				imm[4:0] = inst_i[10:6];

				wreg_o = `WriteEnable;
				wd_o = inst_i[15:11];

				instvalid = `InstValid;
			end
		end

		if( inst_i[31:21] == 11'b01000000000 && inst_i[10:0] == 11'b00000000000 ) begin
			aluop_o = `EXE_MFC0_OP;
			alusel_o = `EXE_RES_MOVE;
			wd_o = inst_i[20:16];
			wreg_o = `WriteEnable;
			instvalid = `InstValid;
			reg1_read_o = 1'b0;
			reg2_read_o = 1'b0;
		end
		else if( inst_i[31:21] == 11'b01000000100 && inst_i[10:0] == 11'b00000000000 ) begin
			aluop_o = `EXE_MTC0_OP;
			alusel_o = `EXE_RES_MOVE;
			wreg_o = `WriteDisable;
			instvalid = `InstValid;
			reg1_read_o = 1'b1;
			reg1_addr_o = inst_i[20:16];
			reg2_read_o = 1'b0;
		end

		if(inst_i == `EXE_ERET) begin
			aluop_o = `EXE_ERET_OP;
			alusel_o = `EXE_RES_NOP;
			wreg_o = `WriteDisable;
			instvalid = `InstValid;
			reg1_read_o = 1'b0;
			reg2_read_o = 1'b0;
			excepttype_is_eret = 1'b1;
		end


	end


end

//ç¬¬äºŒ? ç¡®å®šè¿›è¡Œè¿ç®—çš„æºæ“ä½œ?1
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		reg1_o = `ZeroWord;
	end
	
	//æ•°æ®å‰æŽ¨ï¼Œè§£å†³æ•°æ®ç›¸å…³ï¼ˆex,mem?
	else if ( (reg1_read_o==1'b1) && (ex_wreg_i == 1'b1)
				&& (ex_wd_i == reg1_addr_o) ) begin
					reg1_o = ex_wdata_i;
	end
	else if ((reg1_read_o==1'b1) && (mem_wreg_i == 1'b1)
				&& (mem_wd_i == reg1_addr_o)) begin
					reg1_o = mem_wdata_i;
	end
	else if (reg1_read_o == 1'b1) begin
		reg1_o = reg1_data_i;
	end
	else if (reg1_read_o == 1'b0) begin
		reg1_o = imm;
	end
	else begin
		reg1_o = `ZeroWord;
	end
end

//ç¬¬ä¸‰? ç¡®å®šè¿›è¡Œè¿ç®—çš„æºæ“ä½œ?1
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		reg2_o = `ZeroWord;
	end
	
	//æ•°æ®å‰æŽ¨ï¼Œè§£å†³æ•°æ®ç›¸å…³ï¼ˆex,mem?
	else if ( (reg2_read_o==1'b1) && (ex_wreg_i == 1'b1)
				&& (ex_wd_i == reg2_addr_o) ) begin
					reg2_o = ex_wdata_i;
	end
	else if ((reg2_read_o==1'b1) && (mem_wreg_i == 1'b1)
				&& (mem_wd_i == reg2_addr_o)) begin
					reg2_o = mem_wdata_i;
	end
	else if (reg2_read_o == 1'b1) begin
		reg2_o = reg2_data_i;
	end
	else if (reg2_read_o == 1'b0) begin
		reg2_o = imm;
	end
	else begin
		reg2_o = `ZeroWord;
	end
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		is_in_delayslot_o = `NotInDelaySlot;
	end
	else begin
		is_in_delayslot_o = is_in_delayslot_i;
	end
end

reg stallreq_for_reg1_loadrelate;
reg stallreq_for_reg2_loadrelate;

reg stallreq_for_branch;

wire pre_inst_is_load;

assign pre_inst_is_load = ( 
						(ex_aluop_i == `EXE_LB_OP) ||
						(ex_aluop_i == `EXE_LBU_OP) ||
						(ex_aluop_i == `EXE_LH_OP) ||
						(ex_aluop_i == `EXE_LHU_OP) ||
						(ex_aluop_i == `EXE_LW_OP) ||
						(ex_aluop_i == `EXE_LWR_OP) ||
						(ex_aluop_i == `EXE_LWL_OP) ||
						(ex_aluop_i == `EXE_LL_OP) ||
						(ex_aluop_i == `EXE_SC_OP)  ) ? 1'b1 : 1'b0;

// wire pre_inst_is_except;
// assign pre_inst_is_except = (ex_aluop_i == `EXE_SYSCALL_OP) ? 1'b1 : 1'b0 ;

// always @(*) begin
// 	stallreq_for_branch = `NoStop;
// 	if ( pre_inst_is_except == 1'b1 && alusel_o == `EXE_RES_JUMP_BRANCH) begin
// 		stallreq_for_branch = `Stop;
// 	end
// end	

always @(*) begin
	stallreq_for_reg1_loadrelate = `NoStop;
	if (rst == `RstEnable) begin
		// reset
		reg1_o = `ZeroWord;
	end
	else if ( pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o
			&& reg1_read_o == 1'b1 ) begin
		stallreq_for_reg1_loadrelate = `Stop;
	end
end	

always @(*) begin
	stallreq_for_reg2_loadrelate = `NoStop;
	if (rst == `RstEnable) begin
		// reset
		reg2_o = `ZeroWord;
	end
	else if ( pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o
			&& reg2_read_o == 1'b1 ) begin
		stallreq_for_reg2_loadrelate = `Stop;
	end
end	


assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate | stallreq_for_branch;				

endmodule