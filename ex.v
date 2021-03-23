`include "defines.v"
module ex(
	input wire rst,

	input wire flush,
	//è¯‘ç é˜¶æ®µé€è¿‡æ¥çš„ä¿¡æ¯
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	input wire[`RegBus] reg1_i,
	input wire[`RegBus] reg2_i,
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,

	input wire[`RegBus] link_address_i,
	input wire is_in_delayslot_i,

	input wire[`RegBus] inst_i,

	//æ‰§è¡Œçš„ç»“æž?
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,

	output reg stallreq,

	//åŠ è½½å­˜å‚¨æŒ‡ä»¤
	output wire[`AluOpBus] aluop_o,
	output wire[`RegBus] mem_addr_o,
	output wire[`RegBus] reg2_o,

	output reg data_sram_en,
	output reg [3:0] data_sram_wen,
	output reg [31:0] data_sram_addr,
	output reg [31:0] data_sram_wdata,

	input wire[`RegBus] hi_i,
	input wire[`RegBus] lo_i,
	input wire[`RegBus] wb_hi_i,
	input wire[`RegBus] wb_lo_i,
	input wire wb_whilo_i,
	input wire[`RegBus] mem_hi_i,
	input wire[`RegBus] mem_lo_i,
	input wire mem_whilo_i,
	output reg[`RegBus] hi_o,
	output reg[`RegBus] lo_o,
	output reg whilo_o,

	input wire[`DoubleRegBus] div_result_i,
	input wire div_ready_i,

	output reg[`RegBus] div_opdata1_o,
	output reg[`RegBus] div_opdata2_o,
	output reg div_start_o,
	output reg signed_div_o,

	input wire mem_cp0_reg_we,
	input wire[4:0] mem_cp0_reg_waddr,
	input wire[`RegBus] mem_cp0_reg_wdata,
	input wire wb_cp0_reg_we,
	input wire[4:0] wb_cp0_reg_waddr,
	input wire[`RegBus] wb_cp0_reg_wdata,
	input wire[`RegBus] cp0_reg_data_i,
	output reg[4:0] cp0_reg_raddr_o,
	output reg cp0_reg_we_o,
	output reg[4:0] cp0_reg_waddr_o,
	output reg[`RegBus] cp0_reg_wdata_o,

	input wire[31:0] excepttype_i,
	input wire[`RegBus] current_inst_address_i,
	output wire[31:0] excepttype_o,
	output wire is_in_delayslot_o,
	output wire[`RegBus] current_inst_address_o,

	output wire[`RegBus] badvaddr_o,

	input wire [`InstAddrBus] pc_i,
  	output wire [`InstAddrBus] pc_o
);

assign pc_o = pc_i ;


reg trapassert;
reg ovassert;
reg loadassert;
reg storeassert;

assign excepttype_o = { excepttype_i[31:12],ovassert,trapassert,excepttype_i[9:8],2'b0,storeassert,loadassert,4'b0 } ;
assign is_in_delayslot_o = is_in_delayslot_i ;
assign current_inst_address_o = current_inst_address_i ;

//åŠ è½½å­˜å‚¨
assign aluop_o = aluop_i ;
assign mem_addr_o = reg1_i + { {16{inst_i[15]}} , inst_i[15:0] };
assign reg2_o = reg2_i ;
//ä¿å­˜é€»è¾‘è¿ç®—çš„ç»“æž?
reg[`RegBus] logicout;
//ä¿å­˜ç§»ä½è¿ç®—çš„ç»“æž?
reg[`RegBus] shiftres;
//ä¿å­˜ç®—æœ¯è¿ç®—çš„ç»“æž?
reg[`RegBus] arithmeticres;
reg[`DoubleRegBus] mulres; //ä¹˜æ³•è¿ç®—çš„ç»“æž?
reg[`RegBus] moveres;

reg[`RegBus] HI;
reg[`RegBus] LO;

wire ov_sum; //æº¢å‡ºæƒ…å†µ
wire reg1_eq_reg2; //ç¬¬ä¸€ä¸ªæ“ä½œæ•°æ˜¯å¦ç­‰äºŽç¬¬äºŒä¸ªæ“ä½œæ•°
wire reg1_lt_reg2;  //æ˜¯å¦å°äºŽ
wire[`RegBus] reg2_i_mux; //æ“ä½œæ•?2 çš„è¡¥ç ?
wire[`RegBus] reg1_i_not; //1 çš„åç ?
wire[`RegBus] result_sum; // åŠ æ³•ç»“æžœ
wire[`RegBus] opdata1_mult; //ä¹˜æ³•æ“ä½œä¸­çš„è¢«ä¹˜æ•?
wire[`RegBus] opdata2_mult; //ä¹˜æ³•æ“ä½œä¸­çš„ä¹˜æ•°
wire[`DoubleRegBus] hilo_temp; // ä¸´æ—¶ä¿å­˜ä¹˜æ³•ç»“æžœï¼?64ä½?

//å‡æ³•æˆ–è?…æ¯”è¾ƒè¿ç®—ï¼Œç¬¬äºŒä¸ªæ“ä½œæ•°å–ååŠ ä¸€
assign reg2_i_mux = (   (aluop_i == `EXE_SUB_OP) ||
						(aluop_i == `EXE_SUBU_OP) ||
						(aluop_i == `EXE_SLT_OP) ||
						(aluop_i == `EXE_TLT_OP) ||
						(aluop_i == `EXE_TLTI_OP) ||
						(aluop_i == `EXE_TGE_OP) ||
						(aluop_i == `EXE_TGEI_OP) ||
						(aluop_i == `EXE_SLT_OP)  ) ? ( ~reg2_i )+1 : reg2_i;				
//åŠ æ³•ï¼Œå‡æ³•ï¼Œæ¯”è¾ƒçš„ç»“æž?
assign result_sum = reg1_i + reg2_i_mux ;

//ä¸¤ç§æƒ…å†µï¼?1.æ­£æ­£ä¹‹å’Œä¸ºè´Ÿæ•?2.è´Ÿè´Ÿä¹‹å’Œä¸ºæ­£æ•?
assign ov_sum = ( ( !reg1_i[31] && !reg2_i_mux[31] && result_sum[31] ) || ( reg1_i[31] && reg2_i_mux[31] && !result_sum[31] ) );
//æœ‰ç¬¦å·æƒ…å†µï¼š1.è´Ÿæ•°<æ­£æ•° 2.æ­£æ­£çœ‹result_sum 3.è´Ÿè´Ÿçœ‹result_sum 
assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP ||
						aluop_i == `EXE_TLT_OP ||
						aluop_i == `EXE_TLTI_OP ||
						aluop_i == `EXE_TGE_OP ||
						aluop_i == `EXE_TGEI_OP ) 
						?
						( (reg1_i[31] && !reg2_i[31]) ||
						  (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
						  (reg1_i[31] && reg2_i[31] && result_sum[31])
						)
						:
						(reg1_i < reg2_i)
						;

assign reg1_i_not = ~reg1_i ;

//ç¬¬ä¸€æ®µï¼šæ ¹æ®è¿ç®—å­ç±»åž‹è¿›è¡Œè¿ç®?
//é€»è¾‘è¿ç®—
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		logicout = `ZeroWord;
	end
	else begin
		case (aluop_i)
			`EXE_OR_OP:begin
				logicout = reg1_i | reg2_i ;
			end
			`EXE_AND_OP:begin
				logicout = reg1_i & reg2_i ;
			end
			`EXE_NOR_OP:begin
				logicout = ~ (reg1_i | reg2_i) ;
			end
			`EXE_XOR_OP:begin
				logicout = reg1_i ^ reg2_i ;
			end
			default: begin
				logicout = `ZeroWord;
			end
		endcase
	end
end

//ç§»ä½è¿ç®—
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		shiftres = `ZeroWord;
	end
	else begin
		case (aluop_i)
			`EXE_SLL_OP:begin
				shiftres = reg2_i << reg1_i[4:0];
			end
			`EXE_SRL_OP:begin
				shiftres = reg2_i >> reg1_i[4:0] ;
			end
			`EXE_SRA_OP:begin
				shiftres = ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
												| reg2_i >> reg1_i[4:0];
			end
			default: begin
				shiftres = `ZeroWord;
			end
		endcase
	end
end

//ç®—æœ¯è¿ç®—
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		arithmeticres = `ZeroWord;
	end
	else begin
		case (aluop_i)
			`EXE_SLT_OP,`EXE_SLTU_OP:begin
				arithmeticres = reg1_lt_reg2;
			end
			`EXE_ADD_OP,`EXE_ADDU_OP,`EXE_ADDI_OP,`EXE_ADDIU_OP:begin
				arithmeticres = result_sum;
			end
			`EXE_SUB_OP,`EXE_SUBU_OP:begin
				arithmeticres = result_sum;
			end
			default:begin
				arithmeticres = `ZeroWord;
			end
		endcase
	end
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		data_sram_en = `ChipDisable;
	end
	else begin
		case (aluop_i)
			`EXE_LB_OP,`EXE_LBU_OP,`EXE_LH_OP,`EXE_LW_OP,`EXE_LHU_OP,`EXE_LWR_OP : begin
				data_sram_addr = mem_addr_o;
				data_sram_wen = { 4{`WriteDisable} };
				data_sram_en = `ChipEnable;
			end
			`EXE_SB_OP : begin
				data_sram_addr = mem_addr_o;
				
				data_sram_en = `ChipEnable;
				data_sram_wdata = {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
				case (mem_addr_o[1:0])
					2'b00:begin
						data_sram_wen = 4'b0001 ;
					end
					2'b01:begin
						data_sram_wen = 4'b0010 ;
					end
					2'b10:begin
						data_sram_wen = 4'b0100 ;
					end
					2'b11:begin
						data_sram_wen = 4'b1000 ;
					end
					default:begin
						data_sram_wen = 4'b0000 ;
					end
				endcase
			end
			`EXE_SH_OP:begin
				data_sram_addr = mem_addr_o;
				
				data_sram_en = `ChipEnable;
				data_sram_wdata = {reg2_i[15:0],reg2_i[15:0]};
				case(mem_addr_o[1:0])
					2'b00:begin
						data_sram_wen = 4'b0011 ;
					end
					2'b10:begin
						data_sram_wen = 4'b1100 ;
					end
					default:begin
						data_sram_wen = 4'b0000 ;
					end
				endcase
			end
			`EXE_SW_OP:begin
				data_sram_addr = mem_addr_o;
				data_sram_wen = { 4{`WriteEnable} };
				data_sram_en = `ChipEnable;
				data_sram_wdata = reg2_i;
				//mem_sel_o = 4'b1111;
			end
			`EXE_SWL_OP:begin
				data_sram_addr = mem_addr_o;
				data_sram_wen = { 4{`WriteEnable} };
				data_sram_en = `ChipEnable;
				case(mem_addr_o[1:0])
					2'b00:begin
						//mem_sel_o = 4'b1111;
						data_sram_wdata = reg2_i;
					end
					2'b01:begin
						//mem_sel_o = 4'b0111;
						data_sram_wdata = {8'b0,reg2_i[31:8]};
					end
					2'b10:begin
						//mem_sel_o = 4'b0011;
						data_sram_wdata = {16'b0,reg2_i[31:16]};
					end
					2'b11:begin
						//mem_sel_o = 4'b0001;
						data_sram_wdata = {24'b0,reg2_i[31:24]};
					end
					default:begin
						//mem_sel_o = 4'b0000;
					end
				endcase
			end
			`EXE_SWL_OP:begin
				data_sram_addr = mem_addr_o;
				data_sram_wen = { 4{`WriteEnable} };
				data_sram_en = `ChipEnable;
				case(mem_addr_o[1:0])
					2'b00:begin
						//mem_sel_o = 4'b1000;
						data_sram_wdata = {reg2_i[7:0],24'b0};
					end
					2'b01:begin
						//mem_sel_o = 4'b1100;
						data_sram_wdata = {reg2_i[15:0],16'b0};
					end
					2'b10:begin
						//mem_sel_o = 4'b1110;
						data_sram_wdata = {reg2_i[23:0],8'b0};
					end
					2'b11:begin
						//mem_sel_o = 4'b1111;
						data_sram_wdata = reg2_i[31:0];
					end
					default:begin
						//mem_sel_o = 4'b0000;
					end
				endcase
			end
			default:begin
				data_sram_en = `ChipDisable;
			end
		endcase
	end
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		stallreq = `NoStop;
		div_opdata1_o = `ZeroWord;
		div_opdata2_o = `ZeroWord;
		div_start_o = `DivStop;
		signed_div_o = 1'b0;
	end
	else begin
		stallreq = `NoStop;
		div_opdata1_o = `ZeroWord;
		div_opdata2_o = `ZeroWord;
		div_start_o = `DivStop;
		signed_div_o = 1'b0;

		case(aluop_i)
			`EXE_DIV_OP:begin
				if(div_ready_i == `DivResultNotReady) begin
					div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStart;
					signed_div_o = 1'b1;
					stallreq = `Stop;
				end
				else if(div_ready_i == `DivResultReady) begin
					div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStop;
					signed_div_o = 1'b1;
					stallreq= `NoStop;
				end
				else begin
					stallreq = `NoStop;
					div_opdata1_o = `ZeroWord;
					div_opdata2_o = `ZeroWord;
					div_start_o = `DivStop;
					signed_div_o = 1'b0;
				end
			end
			`EXE_DIVU_OP:begin
				if(div_ready_i == `DivResultNotReady) begin
					div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStart;
					signed_div_o = 1'b0;
					stallreq= `Stop;
				end
				else if(div_ready_i == `DivResultReady) begin
					div_opdata1_o = reg1_i;
					div_opdata2_o = reg2_i;
					div_start_o = `DivStop;
					signed_div_o = 1'b0;
					stallreq = `NoStop;
				end
				else begin
					stallreq = `NoStop;
					div_opdata1_o = `ZeroWord;
					div_opdata2_o = `ZeroWord;
					div_start_o = `DivStop;
					signed_div_o = 1'b0;
				end
			end
			default: begin
				
			end
		endcase
	end
end



//å–å¾—ä¹˜æ³•æ“ä½œçš„æ“ä½œæ•°ï¼Œå¦‚æžœæ˜¯æœ‰ç¬¦å·é™¤æ³•ä¸”æ“ä½œæ•°æ˜¯è´Ÿæ•°ï¼Œé‚£ä¹ˆå–ååŠ ä¸?
assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;

assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;		
//ä¸´æ—¶ä¹˜æ³•ç»“æžœ
assign hilo_temp = opdata1_mult * opdata2_mult;	
//å¯¹ä¹˜æ³•ç»“æžœä¿®æ­£ï¼Œæœ‰ç¬¦å·çš„æƒ…å†µï¼Œå¼‚å·å–ååŠ ä¸?ï¼ŒåŒå·ä¸å˜ï¼Œæ— ç¬¦å·æƒ…å†µä¸å˜ã??
always @ (*) begin
	if(rst == `RstEnable) begin
		mulres <= {`ZeroWord,`ZeroWord};
	end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP))begin
		if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin
			mulres <= ~hilo_temp + 1;
		end else begin
		  mulres <= hilo_temp;
		end
	end else begin
			mulres <= hilo_temp;
	end
end

// Last HI LO
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		{HI,LO} = {`ZeroWord,`ZeroWord};
	end
	else if ( mem_whilo_i == `WriteEnable ) begin
		{HI,LO} = {mem_hi_i,mem_lo_i};
	end
	else if ( wb_whilo_i == `WriteEnable ) begin
		{HI,LO} = {wb_hi_i,wb_lo_i};
	end
	else begin
		{HI,LO} = {hi_i,lo_i};
	end
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		moveres = `ZeroWord;
	end
	else begin
		moveres = `ZeroWord;
		case (aluop_i)
			`EXE_MFHI_OP: begin
				moveres = HI;
			end
			`EXE_MFLO_OP: begin
				moveres = LO;
			end
			`EXE_MFC0_OP:begin
				cp0_reg_raddr_o = inst_i[15:11];
				moveres = cp0_reg_data_i;
				if(mem_cp0_reg_we == `WriteEnable && mem_cp0_reg_waddr == inst_i[15:11] ) begin
					moveres = mem_cp0_reg_wdata;
				end
				else if(wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_waddr == inst_i[15:11] ) begin
					moveres = wb_cp0_reg_wdata;
				end
			end
			default:begin
				
			end
		endcase
	end
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		trapassert = `TrapNotAssert;
	end
	else begin
		trapassert = `TrapNotAssert;
		case(aluop_i)
			`EXE_TEQ_OP,`EXE_TEQI_OP:begin
				if(reg1_i == reg2_i) begin
					trapassert = `TrapAssert;
				end
			end
			`EXE_TGE_OP,`EXE_TGEI_OP,`EXE_TGEIU_OP,`EXE_TGEU_OP: begin
				if(~reg1_lt_reg2) begin
					trapassert = `TrapAssert;
				end
			end
			`EXE_TLT_OP,`EXE_TLTI_OP,`EXE_TLTIU_OP,`EXE_TLTU_OP: begin
				if (reg1_lt_reg2) begin
					trapassert = `TrapAssert;
				end
			end
			`EXE_TNE_OP,`EXE_TNEI_OP:begin
				if(reg1_i != reg2_i) begin
					trapassert = `TrapAssert;
				end
			end
			default:begin
				trapassert = `TrapNotAssert;
			end
		endcase
	end
end

always @(*) begin
	if( (aluop_i == `EXE_ADD_OP || aluop_i == `EXE_ADDI_OP || aluop_i ==`EXE_SUB_OP )  
		&& ov_sum == 1'b1) begin
			wreg_o = `WriteDisable;
			ovassert = 1'b1;
	end
	else begin
		wreg_o = wreg_i;
		ovassert = 1'b0;
	end

	if( ((aluop_i == `EXE_LH_OP || aluop_i == `EXE_LHU_OP) && (mem_addr_o[0] != 1'b0)) || ((aluop_i == `EXE_LW_OP) && (mem_addr_o[1:0] != 2'b00)) ) begin
		loadassert = 1'b1;
		data_sram_en = 1'b0;
	end
	else begin
		loadassert = 1'b0;
		data_sram_en = 1'b1;
	end

	if( (aluop_i == `EXE_SH_OP && mem_addr_o[0] != 1'b0) || (aluop_i == `EXE_SW_OP && mem_addr_o[1:0] != 2'b00) ) begin
		storeassert = 1'b1;
		data_sram_en = 1'b0;
	end
	else begin
		storeassert = 1'b0;
		data_sram_en = 1'b1;
	end
end 

assign badvaddr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

//write cp0
always @(*) begin
	if (aluop_i == `EXE_MTC0_OP) begin
		cp0_reg_we_o = `WriteEnable;
		cp0_reg_waddr_o = inst_i[15:11];
		cp0_reg_wdata_o = reg1_i;
	end
	else begin
		cp0_reg_we_o = `WriteDisable;
		cp0_reg_waddr_o = 5'b00000;
		cp0_reg_wdata_o = `ZeroWord;
	end
end

//HI LO 
always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		whilo_o = `WriteDisable;
		hi_o = `ZeroWord;
		lo_o = `ZeroWord;
	end
	else if ( (aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP) ) begin
		whilo_o = `WriteEnable;
		hi_o = mulres[63:32];
		lo_o = mulres[31:0];
	end
	else if ( aluop_i == `EXE_MTHI_OP ) begin
		whilo_o = `WriteEnable;
		hi_o = reg1_i;
		lo_o = LO;
	end
	else if ( aluop_i == `EXE_MTLO_OP ) begin
		whilo_o = `WriteEnable;
		hi_o = HI;
		lo_o = reg1_i;
	end
	else if ( aluop_i == `EXE_DIV_OP || aluop_i == `EXE_DIVU_OP ) begin
		whilo_o = `WriteEnable;
		hi_o = div_result_i[63:32];
		lo_o = div_result_i[31:0];
	end
	else begin
		whilo_o = `WriteDisable;
		//hi_o = `ZeroWord;
		//lo_o = `ZeroWord;
	end
end

//ç¬¬äºŒæ®µï¼šæ ¹æ®è¿ç®—ç±»åž‹ï¼Œé?‰æ‹©ä¸?ä¸ªè¿ç®—ç»“æžœä½œä¸ºæœ€ç»ˆç»“æž?
always @(*) begin
	wd_o = wd_i;
	wreg_o = wreg_i;
	case (alusel_i)
		`EXE_RES_LOGIC: begin
			wdata_o = logicout;
		end
		`EXE_RES_SHIFT: begin
			wdata_o = shiftres;
		end
		`EXE_RES_ARITHMETIC: begin
			wdata_o = arithmeticres;
		end
		`EXE_RES_MUL: begin
			wdata_o = mulres[31:0];
		end
		`EXE_RES_JUMP_BRANCH:begin
			wdata_o = link_address_i;
		end
		`EXE_RES_MOVE:begin
			wdata_o = moveres;
		end
		default: begin
			wdata_o = `ZeroWord;
		end
	endcase
end

always @(*) begin
	if (rst == `RstEnable) begin
		// reset
		data_sram_wen = 4'b0000;
	end
	else if (flush == 1'b1) begin
		data_sram_wen = 4'b0000;
		data_sram_en = 1'b0;
	end
end

endmodule