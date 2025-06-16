`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/08 16:27:25
// Design Name: 
// Module Name: ex_level
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


module ex_level(
    input wire                         clk           ,
    input wire                         reset         ,
    //allowin
    input wire                         wen           ,
    //from ds
    input wire [195:                0] ds_to_es_bus  ,
    input wire                         mul_ce,
    input wire                         mulu_ce,
    //to ms
    output wire[75:                 0] es_to_ms_bus  ,
    //to br
    output wire[32:                 0] br_bus        ,
    // data sram interface
    output wire       data_sram_en   ,
    output wire[ 3:0] data_sram_wen  ,
    output wire[31:0] data_sram_addr ,
    output wire[31:0] data_sram_wdata,
	
	output wire[4:0] es_to_ds_dest,
	output wire[31:0] es_to_ds_value,
	output wire es_load_op,
	output wire es_gr_we,
	
	output wire calculate_stall
);

reg  [195:0] ds_to_es_bus_r;
wire [11:0] es_alu_op     ;
wire        es_src1_is_pc ;
wire        es_src2_is_imm; 
wire        es_mem_we     ;
wire [ 4:0] es_dest       ;
wire [31:0] es_imm        ;
wire [31:0] es_rj_value   ;
wire [31:0] es_rkd_value  ;
wire [31:0] es_pc         ;

wire        es_res_from_mem;
wire        es_load_op_in     ;
wire        es_gr_we_in;
wire        es_mul;
wire        es_mulh;
wire        es_mulhu;
wire        es_div;
wire        es_mod;
wire        es_divu;
wire        es_modu;
wire        es_ld_b;
wire        es_ld_h;
wire        es_ld_bu;
wire        es_ld_hu;
wire        es_st_b;
wire        es_st_h;

assign {br_bus         ,
        
        es_ld_b        ,
		es_ld_h        ,
		es_ld_bu       ,
		es_ld_hu       ,
		es_st_b        ,
		es_st_h        ,

        es_mul         ,
        es_mulh        ,
		es_mulhu       ,
		es_div         ,
		es_mod         ,
		es_divu        ,
		es_modu        ,

        es_alu_op      ,  //149:138
        es_load_op_in     ,  //137:137
        es_src1_is_pc  ,  //136:136
        es_src2_is_imm ,  //135:135
        es_gr_we_in    ,  //134:134
        es_mem_we      ,  //133:133
        es_dest        ,  //132:128
        es_imm         ,  //127:96
        es_rj_value    ,  //95 :64
        es_rkd_value   ,  //63 :32
        es_pc             //31 :0
       } = ds_to_es_bus_r;
assign es_gr_we = es_gr_we_in;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_result ;
wire [31:0] es_result;

assign es_load_op = es_load_op_in;
assign es_res_from_mem = es_load_op_in;
assign es_to_ms_bus = {es_load_op_in  ,
                       es_ld_b        ,
                       es_ld_h        ,
                       es_ld_bu       ,
                       es_ld_hu       ,					   

                       es_res_from_mem,  //70:70
                       es_gr_we_in       ,  //69:69
                       es_dest        ,  //68:64
                       es_result      ,  //63:32
                       es_pc             //31:0
                      };

wire mul_dout_valid,mulu_dout_valid;
reg [4:0] mul_state,mulu_state;

always@(posedge clk)
begin
    if(reset) begin
        mul_state <= 4'h0;
        mulu_state <= 4'h0;
    end
    else if(wen) begin
        mul_state <= mul_ce; 
        mulu_state <= mulu_ce;
    end
    else begin
        mul_state <= {mul_state,1'b0};
        mulu_state <= {mulu_state,1'b0};
    end
end


assign mul_dout_valid = ~(|mul_state);
assign mulu_dout_valid = ~(|mulu_state);

assign calculate_stall    = ((es_div|es_mod) & ~div_dout_valid) || ((es_divu|es_modu) & ~divu_dout_valid) || 
                            ((es_mul|es_mulh) & ~mul_dout_valid) || (es_mulhu & ~mulu_dout_valid);

always @(posedge clk) begin
    if (reset) begin     
        ds_to_es_bus_r <= 197'h0;
    end
    else if (wen) begin 
        ds_to_es_bus_r <= ds_to_es_bus;
    end
    else begin 
        ds_to_es_bus_r <= ds_to_es_bus_r;
    end
end

assign es_alu_src1 = es_src1_is_pc  ? es_pc[31:0] : 
                                      es_rj_value;
                                      
assign es_alu_src2 = es_src2_is_imm ? es_imm : 
                                      es_rkd_value;

alu u_alu(
    .alu_op     (es_alu_op    ),
    .alu_src1   (es_alu_src1  ),
    .alu_src2   (es_alu_src2  ),
    .alu_result (es_alu_result)
    );

//乘法部件
wire[31:0] src1;
wire[31:0] src2;
wire[63:0] unsigned_prod;
wire[63:0] signed_prod;

mult_signed mul(
.CLK(clk),
.A(es_alu_src1),
.B(es_alu_src2),
.P(signed_prod)
);

mult_unsigned mulu(
.CLK(clk),
.A(es_alu_src1),
.B(es_alu_src2),
.P(unsigned_prod)
);


//除法部件
reg div_dividend_valid;
wire div_dividend_ready;
wire[31:0] div_dividend_data;
reg div_divisor_valid;
wire div_divisor_ready;
wire[31:0] div_divisor_data;
wire div_dout_valid;
wire[63:0] div_dout_data;

reg divu_dividend_valid;
wire divu_dividend_ready;
wire[31:0] divu_dividend_data;
reg divu_divisor_valid;
wire divu_divisor_ready;
wire[31:0] divu_divisor_data;
wire divu_dout_valid;
wire[63:0] divu_dout_data;

assign div_dividend_data=es_rj_value;
assign div_divisor_data=es_rkd_value;
assign divu_dividend_data=es_rj_value;
assign divu_divisor_data=es_rkd_value;

wire div_bus;
wire mod_bus;
wire divu_bus;
wire modu_bus;
assign div_bus=ds_to_es_bus[153];
assign mod_bus=ds_to_es_bus[152];
assign divu_bus=ds_to_es_bus[151];
assign modu_bus=ds_to_es_bus[150];

always@(posedge clk)begin
  if(reset)begin 
    div_dividend_valid<=1'b0;
	div_divisor_valid<=1'b0;
	end 
  else if((div_bus|mod_bus) & ~div_dividend_valid)begin
    div_dividend_valid<=1'b1;
	div_divisor_valid<=1'b1;
	end
  else if(div_dividend_valid & div_dividend_ready)begin
    div_dividend_valid<=1'b0;
	div_divisor_valid<=1'b0;
	end 
end 

always@(posedge clk)begin
  if(reset)begin 
    divu_dividend_valid<=1'b0;
	divu_divisor_valid<=1'b0;
	end 
  else if((divu_bus|modu_bus) & ~divu_dividend_valid)begin
    divu_dividend_valid<=1'b1;
	divu_divisor_valid<=1'b1;
	end
  else if(divu_dividend_valid & divu_dividend_ready)begin
    divu_dividend_valid<=1'b0;
	divu_divisor_valid<=1'b0;
	end 
end

div_signed u_div(
                 .aclk(clk),
				 .s_axis_dividend_tvalid(div_dividend_valid),
				 .s_axis_dividend_tready(div_dividend_ready),
				 .s_axis_dividend_tdata(div_dividend_data),
				 .s_axis_divisor_tvalid(div_divisor_valid),
				 .s_axis_divisor_tready(div_divisor_ready),
				 .s_axis_divisor_tdata(div_divisor_data),
				 .m_axis_dout_tvalid(div_dout_valid),
				 .m_axis_dout_tdata(div_dout_data)
				 );	

div_unsigned u_divu(
                 .aclk(clk),
				 .s_axis_dividend_tvalid(divu_dividend_valid),
				 .s_axis_dividend_tready(divu_dividend_ready),
				 .s_axis_dividend_tdata(divu_dividend_data),
				 .s_axis_divisor_tvalid(divu_divisor_valid),
				 .s_axis_divisor_tready(divu_divisor_ready),
				 .s_axis_divisor_tdata(divu_divisor_data),
				 .m_axis_dout_tvalid(divu_dout_valid),
				 .m_axis_dout_tdata(divu_dout_data)
				 );						 
 
assign es_result={32{es_mul}}    & unsigned_prod[31:0]  | 
                 {32{es_mulh}}   & signed_prod[63:32]   |
				 {32{es_mulhu}}  & unsigned_prod[63:32] |
				 {32{es_div}}    & div_dout_data[63:32] |
				 {32{es_mod}}    & div_dout_data[31:0]  |
				 {32{es_divu}}   & divu_dout_data[63:32]|
				 {32{es_modu}}   & divu_dout_data[31:0] |
				 {32{|es_alu_op}}& es_alu_result;

assign data_sram_en    = (es_load_op_in || es_mem_we);
assign data_sram_wen   = es_mem_we ? (es_st_b? (4'h1 << es_alu_result[1:0]):
									  es_st_h? (es_alu_result[1] ? 4'b1100:
												                   4'b0011):
                                                4'hf): 
								      4'h0  ;
assign data_sram_addr  = es_alu_result;
assign data_sram_wdata = es_st_b? {4{es_rkd_value[7:0]}}:
                         es_st_h? {2{es_rkd_value[15:0]}}:
                                     es_rkd_value;

assign es_to_ds_dest= es_dest;
assign es_to_ds_value=es_result;

endmodule
