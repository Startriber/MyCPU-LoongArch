`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/08 16:24:15
// Design Name: 
// Module Name: id_level
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module id_level(
    input wire                         clk           ,
    input wire                         reset         ,
    //allowin
    input wire                         wen           ,
    //from fs
    input wire [64                 :0] fs_to_ds_bus  ,
    //to es
    output wire[196:                0] ds_to_es_bus  ,
    output wire                        mul_ce,
    output wire                        mulu_ce,
    //to rf: for write back
    input wire                         rf_valid      ,
    input wire [37                 :0] ws_to_rf_bus  ,

    input wire[4:0] es_to_ds_dest,
	input wire[31:0] es_to_ds_value,
	input wire es_load_op,
	input wire es_gr_we,
	
	input wire [37                 :0] ms_to_ds_bus  ,
	input wire                         ms_load_op    ,
	
	output wire load_stall
 	
);



reg  [64:0] fs_to_ds_bus_r;


wire [31:0] ds_inst;
wire [31:0] ds_pc  ;
wire ds_prediction;
assign {ds_prediction,
        ds_inst,
        ds_pc  } = fs_to_ds_bus_r;

wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;
assign {rf_we   ,  //37:37
        rf_waddr,  //36:32
        rf_wdata   //31:0
       } = ws_to_rf_bus & {38{rf_valid}};

wire[4:0] ms_to_ds_dest;
wire[31:0] ms_to_ds_value;
wire ms_gr_we;

assign {ms_gr_we,
        ms_to_ds_dest,
        ms_to_ds_value} = ms_to_ds_bus;


wire[4:0] ws_to_ds_dest;
wire[31:0] ws_to_ds_value;
wire ws_gr_we;

assign ws_gr_we = rf_we;
assign ws_to_ds_dest = rf_waddr;
assign ws_to_ds_value = rf_wdata;

wire        br_taken;
wire [31:0] br_target;

wire [11:0] alu_op;
wire        load_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        dst_is_r1;
wire        gr_we;
wire        mem_we;
wire        src_reg_is_rd;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] ds_imm;
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rj;
wire [ 4:0] rd;
wire [ 4:0] rkd;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;
  
wire        inst_add_w; 
wire        inst_sub_w;  
wire        inst_slt;    
wire        inst_sltu;   
wire        inst_nor;    
wire        inst_and;    
wire        inst_or;     
wire        inst_xor;    
wire        inst_slli_w;  
wire        inst_srli_w;  
wire        inst_srai_w;  
wire        inst_addi_w; 
wire        inst_ld_w;  
wire        inst_st_w;   
wire        inst_jirl;   
wire        inst_b;      
wire        inst_bl;     
wire        inst_beq;    
wire        inst_bne;    
wire        inst_lu12i_w;

wire        inst_slti;
wire        inst_sltui;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sll_w;
wire        inst_srl_w;
wire        inst_sra_w;
wire        inst_pcaddu12i;
wire        inst_mul_w;
wire        inst_mulh_w;
wire        inst_mulh_wu;
wire        inst_div_w;
wire        inst_mod_w;
wire        inst_div_wu;
wire        inst_mod_wu;

wire        inst_blt;
wire        inst_bge;
wire        inst_bltu;
wire        inst_bgeu;
wire        inst_ld_b;
wire        inst_ld_h;
wire        inst_ld_bu;
wire        inst_ld_hu;
wire        inst_st_b;
wire        inst_st_h;

wire        imm_sext;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

wire [33:0] br_bus;

assign br_bus       = {ds_prediction,br_taken,br_target};


assign ds_to_es_bus = {br_bus      ,

                       inst_ld_b   ,
					   inst_ld_h   ,
					   inst_ld_bu  ,
					   inst_ld_hu  ,
					   inst_st_b   ,
					   inst_st_h   ,

                       inst_mul_w  ,
                       inst_mulh_w ,
					   inst_mulh_wu,
					   inst_div_w  ,
					   inst_mod_w  ,
					   inst_div_wu ,
					   inst_mod_wu ,
 
                       alu_op      ,  //149:138
                       load_op     ,  //137:137
                       src1_is_pc  ,  //136:136
                       src2_is_imm ,  //135:135
                       gr_we       ,  //134:134
                       mem_we      ,  //133:133
                       dest        ,  //132:128
                       ds_imm      ,  //127:96
                       rj_value    ,  //95 :64
                       rkd_value   ,  //63 :32
                       ds_pc          //31 :0
                      };


wire sel_ex_A,sel_ex_B;
wire sel_mem_A,sel_mem_B;
wire sel_wb_A,sel_wb_B;

assign sel_ex_A = (es_gr_we && rj == es_to_ds_dest);
assign sel_ex_B = (es_gr_we && rkd == es_to_ds_dest);
assign sel_mem_A = (ms_gr_we && rj == ms_to_ds_dest);
assign sel_mem_B = (ms_gr_we && rkd == ms_to_ds_dest);
assign sel_wb_A = (ws_gr_we && rj == ws_to_ds_dest);
assign sel_wb_B = (ws_gr_we && rkd == ws_to_ds_dest);

assign load_stall=(es_load_op && (sel_ex_A | sel_ex_B)) || (ms_load_op && (sel_mem_A | sel_mem_B));

always @(posedge clk) begin
    if (reset) begin     
        fs_to_ds_bus_r <= 65'h0;
    end
    else if(wen)begin
	    fs_to_ds_bus_r <= fs_to_ds_bus;
	end 
    else begin
	    fs_to_ds_bus_r <= fs_to_ds_bus_r;
	end
end

assign op_31_26  = ds_inst[31:26];
assign op_25_22  = ds_inst[25:22];
assign op_21_20  = ds_inst[21:20];
assign op_19_15  = ds_inst[19:15];

assign rj   = ds_inst[ 9: 5];
assign rd   = ds_inst[ 4: 0];
assign rkd   = src_reg_is_rd ? ds_inst[4:0] : ds_inst[14:10];

assign i12  = ds_inst[21:10];
assign i20  = ds_inst[24: 5];
assign i16  = ds_inst[25:10];
assign i26  = {ds_inst[ 9: 0], ds_inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~ds_inst[25];

assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h08];
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h09];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'h0d];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'h0e];
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'h0f];
assign inst_sll_w  = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h01] & op_19_15_d[5'h0e];
assign inst_srl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h01] & op_19_15_d[5'h0f];
assign inst_sra_w  = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h01] & op_19_15_d[5'h10];
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~ds_inst[25];
assign inst_mul_w  = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h01] & op_19_15_d[5'h18];
assign inst_mulh_w = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h01] & op_19_15_d[5'h19];
assign inst_mulh_wu= op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h01] & op_19_15_d[5'h1a];
assign inst_div_w  = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h02] & op_19_15_d[5'h00];
assign inst_mod_w  = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h02] & op_19_15_d[5'h01];
assign inst_div_wu = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h02] & op_19_15_d[5'h02];
assign inst_mod_wu = op_31_26_d[6'h00] & op_25_22_d[4'h00] & op_21_20_d[2'h02] & op_19_15_d[5'h03];

assign inst_blt    = op_31_26_d[6'h18];
assign inst_bge    = op_31_26_d[6'h19];
assign inst_bltu   = op_31_26_d[6'h1a];
assign inst_bgeu   = op_31_26_d[6'h1b];
assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h00];
assign inst_ld_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h01];
assign inst_ld_bu  = op_31_26_d[6'h0a] & op_25_22_d[4'h08];
assign inst_ld_hu  = op_31_26_d[6'h0a] & op_25_22_d[4'h09];
assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h04];
assign inst_st_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h05];


assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w | inst_jirl | inst_bl | inst_pcaddu12i|inst_ld_b|inst_ld_h|inst_ld_bu|inst_ld_hu|inst_st_b|inst_st_h;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_and | inst_andi;
assign alu_op[ 3] = inst_or | inst_ori;
assign alu_op[ 4] = inst_nor;
assign alu_op[ 5] = inst_xor | inst_xori;
assign alu_op[ 6] = inst_slli_w | inst_sll_w;
assign alu_op[ 7] = inst_srli_w | inst_srl_w;
assign alu_op[ 8] = inst_srai_w | inst_sra_w;
assign alu_op[ 9] = inst_slt | inst_slti;
assign alu_op[10] = inst_sltu | inst_sltui;
assign alu_op[11] = inst_lu12i_w;

assign imm_sext = ~(inst_andi | inst_ori | inst_xori);

wire [31:0] pcadder;
wire [31:0] imm12;

wire Isbr;
wire condition_br;
wire no_conditon_single_br;

assign pcadder = (inst_bl | inst_jirl) ? 32'h4 : {i20,12'b0};
assign imm12   = {{20{imm_sext & i12[11]}},i12};

assign Isbr = inst_beq | inst_bne | inst_blt | inst_bltu | inst_bge | inst_bgeu | no_conditon_single_br |inst_jirl;

assign ds_imm = (src1_is_pc | inst_lu12i_w) ? pcadder : imm12;

assign br_offs = no_conditon_single_br ? {{ 4{i26[25]}}, i26[25:0], 2'b0} : 
                 Isbr                  ? {{14{i16[15]}}, i16[15:0], 2'b0} : 
                                           32'h4;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_blt | inst_bltu | inst_bge | inst_bgeu | inst_st_b | inst_st_h;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w | inst_srli_w | inst_srai_w | inst_addi_w | inst_ld_w | inst_st_w | inst_lu12i_w | inst_jirl | inst_bl |
					   inst_slti | inst_sltui  | inst_andi | inst_ori | inst_xori | inst_pcaddu12i | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu | inst_st_b | inst_st_h ;
					   
assign mul_ce = inst_mul_w | inst_mulh_w;
assign mulu_ce = inst_mulh_wu;


assign load_op       = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_blt & ~inst_bltu & ~inst_bge & ~inst_bgeu & ~inst_st_b & ~inst_st_h;
assign mem_we        = inst_st_w | inst_st_b|inst_st_h;
assign dest          = dst_is_r1 ? 5'd1 :
                       rd;

assign rf_raddr1 =rj;
assign rf_raddr2 = rkd;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );


assign rj_value  = sel_ex_A ? es_to_ds_value : 
                   sel_mem_A ? ms_to_ds_value :
                   sel_wb_A ? ws_to_ds_value :
                   rf_rdata1; 
assign rkd_value = sel_ex_B ? es_to_ds_value : 
                   sel_mem_B ? ms_to_ds_value :
                   sel_wb_B ? ws_to_ds_value :
                   rf_rdata2; 

wire rj_ne_rd;
wire rj_lt_rd;
wire rj_lt_rd_u;

wire [31:0] xor_rst;

assign xor_rst = rkd_value ^ rj_value;

assign rj_lt_rd = (~rkd_value[31] & rj_value[31]) | (~(rkd_value[31] ^ rj_value[31]) & rj_lt_rd_u);
assign rj_lt_rd_u = rj_value < rkd_value;
assign rj_ne_rd = |xor_rst;



assign condition_br = inst_beq  && !rj_ne_rd
                   || inst_bne  &&  rj_ne_rd
				   || inst_blt  &&  rj_lt_rd
				   || inst_bge  && !rj_lt_rd
				   || inst_bltu &&  rj_lt_rd_u
				   || inst_bgeu && !rj_lt_rd_u;

assign no_conditon_single_br = inst_b | inst_bl;

assign br_taken = (   condition_br
                   || inst_jirl
                   || no_conditon_single_br
                  ); 
wire [31:0] real_pc,real_offs;
assign real_pc = inst_jirl ? rj_value : ds_pc;
assign real_offs = inst_jirl ? jirl_offs : br_offs;
assign br_target = real_pc + real_offs;
                                                
												  
											  
endmodule
