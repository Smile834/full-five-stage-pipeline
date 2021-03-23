`include "defines.v"
module mycpu_top(

	input wire clk,
	input wire resetn,
	input wire [5:0] ext_int,

	output wire inst_sram_en,
	output wire [3:0] inst_sram_wen,
	output wire [31:0] inst_sram_addr,
	output wire [31:0] inst_sram_wdata,
	input wire [31:0] inst_sram_rdata,

	output wire data_sram_en,
	output wire [3:0] data_sram_wen,
	output wire [31:0] data_sram_addr,
	output wire [31:0] data_sram_wdata,
	input wire [31:0] data_sram_rdata,

	output wire [31:0] debug_wb_pc,
	output wire [3:0] debug_wb_rf_wen,
	output wire [4:0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata
);

//连接if_id与id的变?
wire[`InstAddrBus] pc;
wire[`InstAddrBus] id_pc_i;
wire[`InstBus] id_inst_i;

//icache与if_id之间的变量

wire[`InstAddrBus] if_id_pc_i;

//连接id与regfile的变?
wire reg1_read;
wire reg2_read;

wire[`RegBus] reg1_data;
wire[`RegBus] reg2_data;

wire[`RegAddrBus] reg1_addr;
wire[`RegAddrBus] reg2_addr;

//连接id与id_ex的变?
wire[`AluOpBus] id_aluop_o;
wire[`AluSelBus] id_alusel_o;
wire[`RegBus] id_reg1_o;
wire[`RegBus] id_reg2_o;
wire id_wreg_o;
wire[`RegAddrBus] id_wd_o;
wire id_is_in_delayslot_o;
wire[`RegBus] id_link_address_o;
wire[`RegBus] id_inst_o;

wire[`InstAddrBus] id_pc_o;	

//连接id_ex与ex的变?
wire[`AluOpBus] ex_aluop_i;
wire[`AluSelBus] ex_alusel_i;
wire[`RegBus] ex_reg1_i;
wire[`RegBus] ex_reg2_i;
wire ex_wreg_i;
wire[`RegAddrBus] ex_wd_i;
wire ex_is_in_delayslot_i;	
wire[`RegBus] ex_link_address_i;
wire[`RegBus] ex_inst_i;
wire[`InstAddrBus] ex_pc_i;	

//连接ex与ex_mem的变?
wire ex_wreg_o;
wire[`RegAddrBus] ex_wd_o;
wire[`RegBus] ex_wdata_o;
wire[`AluOpBus] ex_aluop_o;
wire[`RegBus] ex_mem_addr_o;
wire[`RegBus] ex_reg2_o;
wire[`InstAddrBus] ex_pc_o;	

//连接ex_mem与mem的变?
wire mem_wreg_i;
wire[`RegAddrBus] mem_wd_i;
wire[`RegBus] mem_wdata_i;
wire[`AluOpBus] mem_aluop_i;
wire[`RegBus] mem_mem_addr_i;
wire[`RegBus] mem_reg2_i;
wire[`InstAddrBus] mem_pc_i;

wire[`RegBus] mem_hi_i;
wire[`RegBus] mem_lo_i;
wire[`RegBus] mem_whilo_i;	

//连接mem与mem_wb的变?
wire mem_wreg_o;
wire[`RegAddrBus] mem_wd_o;
wire[`RegBus] mem_wdata_o;
wire[`InstAddrBus] mem_pc_o;
wire[`RegBus] mem_hi_o;
wire[`RegBus] mem_lo_o;
wire mem_whilo_o;

//连接mem_wb与wb的变?
wire wb_wreg_i;
wire[`RegAddrBus] wb_wd_i;
wire[`RegBus] wb_wdata_i;
wire[`RegBus] wb_hi_i;
wire[`RegBus] wb_lo_i;
wire wb_whilo_i;

//dcache and mem_wb
wire mem_wb_wreg_i;
wire[`RegAddrBus] mem_wb_wd_i;
wire[`RegBus] mem_wb_wdata_i; 
wire[`InstAddrBus] mem_wb_pc_i;

//HI LO  and  ex
wire[`RegBus] ex_hi_i;
wire[`RegBus] ex_lo_i;
wire[`RegBus] ex_hi_o;
wire[`RegBus] ex_lo_o;
wire ex_whilo_o;

//ex and div
wire[`RegBus] ex_div_opdata1_o;
wire[`RegBus] ex_div_opdata2_o;
wire ex_div_start_o;
wire ex_signed_div_o;
wire[`DoubleRegBus] ex_div_result_i;
wire ex_div_ready_i;


//暂停流水?
wire[5:0] stall;
wire stallreq_from_id;	
wire stallreq_from_ex;


wire is_in_delayslot_i;
wire next_inst_in_delayslot_o;
wire id_branch_flag_o;
wire[`RegBus] branch_target_address;

//pc_reg
wire[31:0] pc_excepttype_o;

//icache
wire[31:0] icache_excepttype_o;


//ctrl
wire flush;
wire[`RegBus] ctrl_new_pc_o;

//id
wire[31:0] id_excepttype_o;
wire[`RegBus] id_current_inst_address_o;

wire[31:0] id_excepttype_i;

//ex

wire[`RegBus] ex_cp0_reg_data_i;
wire[4:0] ex_cp0_reg_raddr_o;
wire ex_cp0_reg_we_o;
wire[4:0] ex_cp0_reg_waddr_o;
wire[`RegBus] ex_cp0_reg_wdata_o;

wire[`RegBus] ex_current_inst_address_i;
wire[31:0] ex_excepttype_i;
wire[31:0] ex_excepttype_o;
wire ex_is_in_delayslot_o;
wire[`RegBus] ex_current_inst_address_o;

wire[`RegBus] ex_badvaddr_o;



//mem
wire mem_cp0_reg_we_o;
wire[4:0] mem_cp0_reg_waddr_o;
wire[`RegBus] mem_cp0_reg_wdata_o;
wire mem_cp0_reg_we_i;
wire[4:0] mem_cp0_reg_waddr_i;
wire[`RegBus] mem_cp0_reg_wdata_i;

wire[31:0] mem_excepttype_i;
wire mem_is_in_delayslot_i;
wire[`RegBus] mem_current_inst_address_i;
wire[31:0] mem_excepttype_o;
wire mem_is_in_delayslot_o;
wire[`RegBus] mem_current_inst_address_o;
wire[`RegBus] mem_cp0_epc_o;

wire[`RegBus] mem_badvaddr_o;
wire[`RegBus] mem_badvaddr_i;

//wb
wire wb_cp0_reg_we_i;
wire[4:0] wb_cp0_reg_waddr_i;
wire[`RegBus] wb_cp0_reg_wdata_i;

//cp0
wire[`RegBus] cp0_status_o;
wire[`RegBus] cp0_cause_o;
wire[`RegBus] cp0_epc_o;


wire[3:0] ram_sel_o;

wire[31:0] ex_data_sram_addr;


//pc_reg实例?
pc_reg pc_reg0(
	.clk(clk),   
	.rst(resetn),
	.stall(stall),
	.branch_flag_i(id_branch_flag_o),
	.branch_target_address_i(branch_target_address),
	.flush(flush),
	.new_pc(ctrl_new_pc_o),
	.pc(pc),
//	.excepttype_o(pc_excepttype_o),
	.ce(inst_sram_en)
	);

icache icache0(
	.clk(clk),
	.rst(resetn),

	.stall(stall),
	.flush(flush),

	.pc_pc(pc),
	.new_pc(ctrl_new_pc_o),
	.icache_pc(if_id_pc_i),

//	.excepttype_i(pc_excepttype_o),
	.excepttype_o(icache_excepttype_o),

	.branch_flag_i(id_branch_flag_o),
	.branch_target_address_i(branch_target_address)
	);

//assign inst_sram_addr = id_branch_flag_o ? branch_target_address : ( flush ? ctrl_new_pc_o : pc );
assign inst_sram_addr = flush ? ctrl_new_pc_o : (id_branch_flag_o ? branch_target_address : pc ) ;


//if_id实例?
if_id if_id0(
	.clk(clk),
	.rst(resetn),
	.stall(stall),

 	.flush(flush),

 	.excepttype_i(icache_excepttype_o),
 	.excepttype_o(id_excepttype_i),

	.if_pc(if_id_pc_i),
	.if_inst(inst_sram_rdata),
	.id_pc(id_pc_i),
	.id_inst(id_inst_i)
	);

//id实例?
id id0(
	.rst(resetn),

	.pc_i(id_pc_i),
	.pc_o(id_pc_o),

	.inst_i(id_inst_i),



	.ex_aluop_i(ex_aluop_o),

	//Regfile
	.reg1_data_i(reg1_data),
	.reg2_data_i(reg2_data),

 	//处于执行阶段的指令要写入的目的寄存器信息
	.ex_wreg_i(ex_wreg_o),
	.ex_wdata_i(ex_wdata_o),
	.ex_wd_i(ex_wd_o),

  	//处于访存阶段的指令要写入的目的寄存器信息
	.mem_wreg_i(mem_wreg_o),
	.mem_wdata_i(mem_wdata_o),
	.mem_wd_i(mem_wd_o),

	.dcache_wreg_i(mem_wb_wreg_i),
	.dcache_wdata_i(mem_wb_wdata_i),
	.dcache_wd_i(mem_wb_wd_i),


	.reg1_read_o(reg1_read),
	.reg1_addr_o(reg1_addr),

	.reg2_read_o(reg2_read),
	.reg2_addr_o(reg2_addr),

	//送到id_ex阶段的信?
	.aluop_o(id_aluop_o),
	.alusel_o(id_alusel_o),
	.reg1_o(id_reg1_o),
	.reg2_o(id_reg2_o),
	.wd_o(id_wd_o),
	.wreg_o(id_wreg_o),
	.inst_o(id_inst_o),

	.stallreq(stallreq_from_id),
	.excepttype_i(id_excepttype_i),
	.excepttype_o(id_excepttype_o),
	.current_inst_address_o(id_current_inst_address_o),

	.is_in_delayslot_i(is_in_delayslot_i),

	.next_inst_in_delayslot_o(next_inst_in_delayslot_o),
	.branch_flag_o(id_branch_flag_o),
	.branch_target_address_o(branch_target_address),
	.link_addr_o(id_link_address_o),
	.is_in_delayslot_o(id_is_in_delayslot_o)
	);


//regfile实例?
regfile regfile1(
	.clk(clk),
	.rst(resetn),

	//写端?
	.we(wb_wreg_i),
	.waddr(wb_wd_i),
	.wdata(wb_wdata_i),

	//读端?1
	.re1(reg1_read),
	.raddr1(reg1_addr),
	.rdata1(reg1_data),

	//读端?2
	.re2(reg2_read),
	.raddr2(reg2_addr),
	.rdata2(reg2_data)
);

//id_ex实例?
id_ex id_ex0(
	.clk(clk),
	.rst(resetn),
	.stall(stall),

	.pc_i(id_pc_o),
	.pc_o(ex_pc_i),

	//从译码阶段传过来的信?
	.id_aluop(id_aluop_o),
	.id_alusel(id_alusel_o),
	.id_reg1(id_reg1_o),
	.id_reg2(id_reg2_o),
	.id_wd(id_wd_o),
	.id_wreg(id_wreg_o),
	.id_link_address(id_link_address_o),
	.id_is_in_delayslot(id_is_in_delayslot_o),
	.next_inst_in_delayslot(next_inst_in_delayslot_o),
	.id_inst(id_inst_o),

	.flush(flush),
	.id_current_inst_address(id_current_inst_address_o),
	.id_excepttype(id_excepttype_o),
	.ex_current_inst_address(ex_current_inst_address_i),
	.ex_excepttype(ex_excepttype_i),

	//???到执行阶段的??
	.ex_aluop(ex_aluop_i),
	.ex_alusel(ex_alusel_i),
	.ex_reg1(ex_reg1_i),
	.ex_reg2(ex_reg2_i),
	.ex_wd(ex_wd_i),
	.ex_wreg(ex_wreg_i),
	.ex_link_address(ex_link_address_i),
  	.ex_is_in_delayslot(ex_is_in_delayslot_i),
	.is_in_delayslot_o(is_in_delayslot_i),

	.ex_inst(ex_inst_i)	
	

);

//ex实例?
ex ex0(
	.rst(resetn),
	.flush(flush),

	.pc_i(ex_pc_i),
	.pc_o(ex_pc_o),

	//译码阶段送过来的信息
	.aluop_i(ex_aluop_i),
	.alusel_i(ex_alusel_i),
	.reg1_i(ex_reg1_i),
	.reg2_i(ex_reg2_i),
	.wd_i(ex_wd_i),
	.wreg_i(ex_wreg_i),
	.link_address_i(ex_link_address_i),
	.is_in_delayslot_i(ex_is_in_delayslot_i),
	.inst_i(ex_inst_i),

	//执行的结?
	.wd_o(ex_wd_o),
	.wreg_o(ex_wreg_o),
	.wdata_o(ex_wdata_o),

	.aluop_o(ex_aluop_o),
	.mem_addr_o(ex_mem_addr_o),
	.reg2_o(ex_reg2_o),

	.data_sram_en(data_sram_en),
	.data_sram_wen(data_sram_wen),
	.data_sram_addr(ex_data_sram_addr),
	.data_sram_wdata(data_sram_wdata),

	.hi_i(ex_hi_i),
	.lo_i(ex_lo_i),
	.wb_hi_i(wb_hi_i),
	.wb_lo_i(wb_lo_i),
	.wb_whilo_i(wb_whilo_i),
	.mem_hi_i(mem_hi_o),
	.mem_lo_i(mem_lo_o),
	.mem_whilo_i(mem_whilo_o),
	.hi_o(ex_hi_o),
	.lo_o(ex_lo_o),
	.whilo_o(ex_whilo_o),

	.div_result_i(ex_div_result_i),
	.div_ready_i(ex_div_ready_i),
	.div_opdata1_o(ex_div_opdata1_o),
	.div_opdata2_o(ex_div_opdata2_o),
	.div_start_o(ex_div_start_o),
	.signed_div_o(ex_signed_div_o),

	.mem_cp0_reg_we(mem_cp0_reg_we_o),
	.mem_cp0_reg_waddr(mem_cp0_reg_waddr_o),
	.mem_cp0_reg_wdata(mem_cp0_reg_wdata_o),
	.wb_cp0_reg_we(wb_cp0_reg_we_i),
	.wb_cp0_reg_waddr(wb_cp0_reg_waddr_i),
	.wb_cp0_reg_wdata(wb_cp0_reg_wdata_i),
	.cp0_reg_data_i(ex_cp0_reg_data_i),
	.cp0_reg_raddr_o(ex_cp0_reg_raddr_o),
	.cp0_reg_we_o(ex_cp0_reg_we_o),
	.cp0_reg_waddr_o(ex_cp0_reg_waddr_o),
	.cp0_reg_wdata_o(ex_cp0_reg_wdata_o),

	.excepttype_i(ex_excepttype_i),
	.current_inst_address_i(ex_current_inst_address_i),
	.excepttype_o(ex_excepttype_o),
	.is_in_delayslot_o(ex_is_in_delayslot_o),
	.current_inst_address_o(ex_current_inst_address_o),

	.badvaddr_o(ex_badvaddr_o),

	.stallreq(stallreq_from_ex)
);

div div0(
	.clk(clk),
	.rst(resetn),
	
	.signed_div_i(ex_signed_div_o),
	.opdata1_i(ex_div_opdata1_o),
	.opdata2_i(ex_div_opdata2_o),
	.start_i(ex_div_start_o),
	.annul_i(1'b0),
	
	.result_o(ex_div_result_i),
	.ready_o(ex_div_ready_i)
);


assign data_sram_addr = (ex_data_sram_addr < 32'h80000000) ? ex_data_sram_addr :
                        (ex_data_sram_addr < 32'hA0000000) ? (ex_data_sram_addr - 32'h80000000) :
                        (ex_data_sram_addr < 32'hC0000000) ? (ex_data_sram_addr - 32'hA0000000) :
                        (ex_data_sram_addr < 32'hE0000000) ? (ex_data_sram_addr) :
                        (ex_data_sram_addr <= 32'hFFFFFFFF) ? (ex_data_sram_addr) : 
                        32'h00000000;
//ex_mem实例?
ex_mem ex_mem0(
	.clk(clk),
	.rst(resetn),
	.stall(stall),

	.pc_i(ex_pc_o),
	.pc_o(mem_pc_i),

	.badvaddr_i(ex_badvaddr_o),
	.badvaddr_o(mem_badvaddr_i),

	//来自执行阶段的信?
	.ex_wd(ex_wd_o),
	.ex_wreg(ex_wreg_o),
	.ex_wdata(ex_wdata_o),
	.ex_aluop(ex_aluop_o),
	.ex_mem_addr(ex_mem_addr_o),
	.ex_reg2(ex_reg2_o),	

	.ex_hi(ex_hi_o),
	.ex_lo(ex_lo_o),
	.ex_whilo(ex_whilo_o),
	.mem_hi(mem_hi_i),
	.mem_lo(mem_lo_i),
	.mem_whilo(mem_whilo_i),

	.ex_cp0_reg_we(ex_cp0_reg_we_o),
	.ex_cp0_reg_waddr(ex_cp0_reg_waddr_o),
	.ex_cp0_reg_wdata(ex_cp0_reg_wdata_o),
	.mem_cp0_reg_we(mem_cp0_reg_we_i),
	.mem_cp0_reg_waddr(mem_cp0_reg_waddr_i),
	.mem_cp0_reg_wdata(mem_cp0_reg_wdata_i),

	.flush(flush),
	.ex_excepttype(ex_excepttype_o),
	.ex_is_in_delayslot(ex_is_in_delayslot_o),
	.ex_current_inst_address(ex_current_inst_address_o),
	.mem_excepttype(mem_excepttype_i),
	.mem_is_in_delayslot(mem_is_in_delayslot_i),
	.mem_current_inst_address(mem_current_inst_address_i),
		


	//送到访存阶段的信?
	.mem_wd(mem_wd_i),
	.mem_wreg(mem_wreg_i),
	.mem_wdata(mem_wdata_i),

	.mem_aluop(mem_aluop_i),
	.mem_mem_addr(mem_mem_addr_i),
	.mem_reg2(mem_reg2_i)
);

//mem实例?
mem mem0(
	.rst(resetn),

	.pc_i(mem_pc_i),
	.pc_o(mem_pc_o),

	.badvaddr_i(mem_badvaddr_i),
	.badvaddr_o(mem_badvaddr_o),

	//来自执行阶段???
	.wd_i(mem_wd_i),
	.wreg_i(mem_wreg_i),
	.wdata_i(mem_wdata_i),

	.aluop_i(mem_aluop_i),
	.mem_addr_i(mem_mem_addr_i),
	.reg2_i(mem_reg2_i),

	//访存阶段的结?
	.wd_o(mem_wd_o),
	.wreg_o(mem_wreg_o),
	.wdata_o(mem_wdata_o),

	.hi_i(mem_hi_i),
	.lo_i(mem_lo_i),
	.whilo_i(mem_whilo_i),

	.hi_o(mem_hi_o),
	.lo_o(mem_lo_o),
	.whilo_o(mem_whilo_o),

	.cp0_reg_we_i(mem_cp0_reg_we_i),
	.cp0_reg_waddr_i(mem_cp0_reg_waddr_i),
	.cp0_reg_wdata_i(mem_cp0_reg_wdata_i),
	.cp0_reg_we_o(mem_cp0_reg_we_o),
	.cp0_reg_waddr_o(mem_cp0_reg_waddr_o),
	.cp0_reg_wdata_o(mem_cp0_reg_wdata_o),

	.excepttype_i(mem_excepttype_i),
	.is_in_delayslot_i(mem_is_in_delayslot_i),
	.current_inst_address_i(mem_current_inst_address_i),
	.cp0_status_i(cp0_status_o),
	.cp0_cause_i(cp0_cause_o),
	.cp0_epc_i(cp0_epc_o),
	.wb_cp0_reg_we(wb_cp0_reg_we_i),
	.wb_cp0_reg_waddr(wb_cp0_reg_waddr_i),
	.wb_cp0_reg_wdata(wb_cp0_reg_wdata_i),
	.excepttype_o(mem_excepttype_o),
	.cp0_epc_o(mem_cp0_epc_o),
	.is_in_delayslot_o(mem_is_in_delayslot_o),
	.current_inst_address_o(mem_current_inst_address_o),

	//来自数据存储器的信息
	.mem_data_i(data_sram_rdata)

	//送到数据存储器的信息
	//.mem_sel_o(ram_sel_o),
	//.mem_data_o(data_sram_wdata)
);


//mem_wb实例?
mem_wb mem_wb0(
	.clk(clk),
	.rst(resetn),
	.stall(stall),
	.flush(flush),

	.pc_i(mem_pc_o),
	.pc_o(debug_wb_pc),

	//访存阶段的结?
	.mem_wd(mem_wd_o),
	.mem_wreg(mem_wreg_o),
	.mem_wdata(mem_wdata_o),

	.mem_hi(mem_hi_o),
	.mem_lo(mem_lo_o),
	.mem_whilo(mem_whilo_o),

	.wb_hi(wb_hi_i),
	.wb_lo(wb_lo_i),
	.wb_whilo(wb_whilo_i),

	.mem_cp0_reg_we(mem_cp0_reg_we_o),
	.mem_cp0_reg_waddr(mem_cp0_reg_waddr_o),
	.mem_cp0_reg_wdata(mem_cp0_reg_wdata_o),
	.wb_cp0_reg_we(wb_cp0_reg_we_i),
	.wb_cp0_reg_waddr(wb_cp0_reg_waddr_i),
	.wb_cp0_reg_wdata(wb_cp0_reg_wdata_i),

	//送到回写阶段的信?
	.wb_wd(wb_wd_i),
	.wb_wreg(wb_wreg_i),
	.wb_wdata(wb_wdata_i)
);

hilo_reg hilo_reg0(

	.clk(clk),
	.rst(resetn),

	//write
	.we(wb_whilo_i),
	.hi_i(wb_hi_i),
	.lo_i(wb_lo_i),

	//read
	.hi_o(ex_hi_i),
	.lo_o(ex_lo_i)
);

cp0_reg cp0_reg0(

	.clk(clk),
	.rst(resetn),

	.badvaddr_i(mem_badvaddr_o),

	.we_i(wb_cp0_reg_we_i),
	.waddr_i(wb_cp0_reg_waddr_i),
	.raddr_i(ex_cp0_reg_raddr_o),
	.data_i(wb_cp0_reg_wdata_i),

	.int_i(ext_int),

	.data_o(ex_cp0_reg_data_i),
	.count_o(),
	.compare_o(),
	.status_o(cp0_status_o),
	.cause_o(cp0_cause_o),
	.epc_o(cp0_epc_o),
	.config_o(),
	.prid_o(),
	.badvaddr_o(),

	.excepttype_i(mem_excepttype_o),
	.current_inst_addr_i(mem_current_inst_address_o),
	.is_in_delayslot_i(mem_is_in_delayslot_o),

	.timer_int_o()
);


ctrl ctrl0(
		.rst(resetn),
		.stallreq_from_id(stallreq_from_id),	
  	//来自执行阶段的暂停请?
		.stallreq_from_ex(stallreq_from_ex),

		.excepttype_i(mem_excepttype_o),
		.cp0_epc_i(mem_cp0_epc_o),
		.new_pc(ctrl_new_pc_o),
		.flush(flush),


		.stall(stall)       	
);


// debug
assign debug_wb_rf_wen =  {4{wb_wreg_i}};
assign debug_wb_rf_wnum = wb_wd_i;
assign debug_wb_rf_wdata = wb_wdata_i;



assign inst_sram_wen = 4'b0000;
assign inst_sram_wdata = `ZeroWord;

endmodule